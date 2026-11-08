# Validates data/*.csv. Errors stop the build; notes are reminders.
# --links also checks every URL (dead links warn); add --strict to make dead links fail (used by the weekly workflow).
source("R/publication.R")
args <- commandArgs(trailingOnly = TRUE)
errors <- character(); notes <- character(); dead <- 0L
err <- function(...) errors <<- c(errors, sprintf(...))
note <- function(...) notes <<- c(notes, sprintf(...))
blank <- function(x) !nzchar(trimws(x))
bad_date <- function(x) is.na(suppressWarnings(as.Date(x, format = "%Y-%m-%d")))

m <- read_data("measures"); s <- read_data("sources"); b <- read_data("ballots")
absent <- setdiff(measure_columns, names(m))
if (length(absent)) stop("data/measures.csv is missing columns: ", paste(absent, collapse = ", "))
absent <- setdiff(ballot_columns, names(b))
if (length(absent)) stop("data/ballots.csv is missing columns: ", paste(absent, collapse = ", "))
if (!nrow(m)) stop("data/measures.csv has no rows.")

for (f in c("source_id", "title", "publisher", "url", "accessed_date")) if (any(blank(s[[f]]))) err("sources.csv: empty %s for %s", f, paste(s$source_id[blank(s[[f]])], collapse = ", "))
if (anyDuplicated(s$source_id)) err("sources.csv: duplicate source_id")
if (anyDuplicated(s$url)) err("sources.csv: two sources share a url")
if (any(!grepl("^https?://", s$url))) err("sources.csv: url must start with http(s):// for %s", paste(s$source_id[!grepl("^https?://", s$url)], collapse = ", "))
if (any(bad_date(s$accessed_date))) err("sources.csv: accessed_date must be YYYY-MM-DD for %s", paste(s$source_id[bad_date(s$accessed_date)], collapse = ", "))

if (anyDuplicated(b$cycle_id)) err("ballots.csv: duplicate cycle_id")
if (anyDuplicated(b$year)) err("ballots.csv: two ballots share a year, so they would share web addresses")
for (i in seq_len(nrow(b))) {
  id <- b$cycle_id[i]
  for (f in c("cycle_id", "title", "intro")) if (blank(b[[f]][i])) err("ballots.csv: %s is missing %s", id, f)
  if (!grepl("^[0-9]{4}$", b$year[i])) err("ballots.csv: %s year must be four digits", id)
  if (bad_date(b$election_date[i])) err("ballots.csv: %s election_date must be YYYY-MM-DD", id)
  if (!b$published[i] %in% c("true", "false")) err("ballots.csv: published must be true or false for %s", id)
}

if (anyDuplicated(m[c("cycle_id", "letter")])) err("measures.csv: duplicate cycle_id and letter")
for (i in seq_len(nrow(m))) {
  r <- m[i, ]; id <- paste(r$cycle_id, r$letter)
  for (f in measure_required) if (blank(r[[f]])) err("%s: missing %s", id, f)
  if (!blank(r$letter) && !grepl("^[A-Z]$", r$letter)) err("%s: letter must be one capital letter", id)
  if (!blank(r$cycle_id) && !r$cycle_id %in% b$cycle_id) err("%s: cycle_id is not in ballots.csv", id)
  if (!blank(r$type) && !r$type %in% measure_types) err("%s: type must be one of %s", id, paste(measure_types, collapse = " or "))
  if (!blank(r$proposer) && !r$proposer %in% measure_proposers) err("%s: proposer must be one of %s", id, paste(measure_proposers, collapse = " or "))
  topics <- trimws(strsplit(r$topics, ";", fixed = TRUE)[[1]])
  if (!blank(r$topics) && (length(topics) > 3L || anyDuplicated(topics) || !all(topics %in% measure_topics))) err("%s: topics must be 1 to 3 different known topics separated by semicolons", id)
  words <- trimws(strsplit(r$keywords, ";", fixed = TRUE)[[1]])
  if (!blank(r$keywords) && (length(words) < 2L || length(words) > 8L || any(!nzchar(words)) || anyDuplicated(tolower(words)))) err("%s: keywords must be 2 to 8 different phrases separated by semicolons", id)
  for (f in c("text_source", "origin_source")) if (!blank(r[[f]]) && !r[[f]] %in% s$source_id) err("%s: %s '%s' is not in sources.csv", id, f, r[[f]])
  for (f in c("arguments_for", "arguments_against")) for (u in markdown_urls(r[[f]])) if (!u %in% s$url) err("%s: %s links to %s, which is not in sources.csv (add it with a title and accessed date)", id, f, u)
  wording <- file.path("_ballot_text", r$cycle_id, paste0("baltimore-", tolower(r$letter), ".qmd"))
  if (!file.exists(wording)) err("%s: official wording file not found in _ballot_text", id) else if (!length(official_narrative(wording)$paras)) err("%s: no question text could be read from %s", id, wording)
  if (any(!blank(unlist(r[c("outcome", "status", "for_votes", "against_votes", "results_checked", "result_source")])))) {
    for (f in c("outcome", "status", "results_checked", "result_source")) if (blank(r[[f]])) err("%s: result is partly filled in; missing %s", id, f)
    if (!blank(r$outcome) && !r$outcome %in% c("Passed", "Failed")) err("%s: outcome must be Passed or Failed", id)
    if (!blank(r$status) && !r$status %in% c("Unofficial", "Certified")) err("%s: status must be Unofficial or Certified", id)
    if (!blank(r$result_source) && !r$result_source %in% s$source_id) err("%s: result_source '%s' is not in sources.csv", id, r$result_source)
    if (!blank(r$results_checked) && bad_date(r$results_checked)) err("%s: results_checked must be YYYY-MM-DD", id)
    if (blank(r$for_votes) != blank(r$against_votes)) {
      err("%s: enter both vote counts or neither", id)
    } else if (!blank(r$for_votes)) {
      if (!grepl("^[0-9]+$", r$for_votes) || !grepl("^[0-9]+$", r$against_votes)) {
        err("%s: vote counts must be whole numbers", id)
      } else if ((as.numeric(r$for_votes) > as.numeric(r$against_votes)) != (r$outcome == "Passed")) {
        err("%s: outcome %s does not match the vote counts", id, r$outcome)
      }
    }
  }
}

for (f in measure_recommended) if (any(blank(m[[f]]))) note("%s is empty for %d of %d measures", f, sum(blank(m[[f]])), nrow(m))
cited <- unlist(lapply(c(m$arguments_for, m$arguments_against), markdown_urls))
unused <- setdiff(s$source_id, c(m$text_source, m$origin_source, m$result_source, s$source_id[s$url %in% cited]))
if (length(unused)) note("sources.csv has sources no measure uses: %s", paste(unused, collapse = ", "))

if ("--links" %in% args) {
  files <- c(list.files(c("_ballot_text", "ballots"), pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE), "index.qmd", "about.qmd", "privacy.qmd")
  text <- vapply(files[file.exists(files)], function(f) paste(readLines(f, warn = FALSE), collapse = "\n"), "")
  found <- unlist(regmatches(text, gregexpr("https?://[^\\s)>\"']+", text, perl = TRUE)))
  urls <- sort(unique(sub("[.,;]+$", "", c(s$url, found))))
  on_github <- identical(Sys.getenv("GITHUB_ACTIONS"), "true")
  for (u in urls) {
    code <- tryCatch(attr(curlGetHeaders(u, redirect = TRUE, timeout = 20), "status"), error = function(x) NA_integer_)
    if (!is.na(code) && (code < 400 || code %in% c(403, 405, 429))) next
    dead <- dead + 1L
    msg <- sprintf("Dead link (%s): %s", if (is.na(code)) "no response" else paste("HTTP", code), u)
    if (on_github) cat("::warning::", msg, "\n", sep = "") else message("WARNING: ", msg)
  }
  message("Checked ", length(urls), " links; ", dead, " dead.")
}

for (x in notes) message("NOTE: ", x)
if (length(errors)) {
  for (x in errors) message("ERROR: ", x)
  quit(status = 1)
}
if (dead > 0L && "--strict" %in% args) quit(status = 1)
message("Data validated: ", nrow(m), " measures, ", sum(!blank(m$outcome)), " results.")
