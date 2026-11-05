# Validate the rendered public publication, including intentional empty states.

root <- normalizePath("docs", mustWork = TRUE, winslash = "/")
read_csv <- function(name) read.csv(file.path("data", paste0(name, ".csv")),
  stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL,
  check.names = FALSE)

cycles <- read_csv("elections")
measures <- read_csv("measures")
articles <- read_csv("articles")
html_path <- function(path) sub("\\.qmd$", ".html", path)

required <- c("index.html", "about.html", "elections/index.html")
required <- c(required, html_path(cycles$path[cycles$published == "true"]))
required <- c(required, html_path(articles$path[articles$status == "published"]))
for (name in required) {
  if (!file.exists(file.path(root, name))) stop("Missing rendered page: ", name)
}

attributes_of <- function(raw, tag, attribute) {
  tag_pattern <- sprintf("<%s\\b[^>]*>", tag)
  matches <- gregexpr(tag_pattern, raw, perl = TRUE, ignore.case = TRUE)[[1]]
  if (matches[1] == -1) return(character())
  tags <- regmatches(raw, list(matches))[[1]]
  values <- character()
  attr_pattern <- sprintf("\\b%s\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')", attribute)
  for (element in tags) {
    match <- regexec(attr_pattern, element, perl = TRUE, ignore.case = TRUE)
    parts <- regmatches(element, match)[[1]]
    if (length(parts) >= 2L) values <- c(values, if (nzchar(parts[2])) parts[2] else parts[3])
  }
  values
}

extract_ids <- function(raw) {
  pattern <- "<[^>]+>"
  matches <- gregexpr(pattern, raw, perl = TRUE, ignore.case = TRUE)[[1]]
  if (matches[1] == -1) return(character())
  tags <- regmatches(raw, list(matches))[[1]]
  values <- character()
  for (element in tags) {
    match <- regexec("\\bid\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')", element, perl = TRUE, ignore.case = TRUE)
    parts <- regmatches(element, match)[[1]]
    if (length(parts) >= 2L) values <- c(values, if (nzchar(parts[2])) parts[2] else parts[3])
  }
  values
}

html_text <- function(raw) {
  raw <- gsub("<(script|style)\\b[^>]*>.*?</\\1>", " ", raw, perl = TRUE, ignore.case = TRUE)
  raw <- gsub("<[^>]+>", " ", raw)
  raw <- gsub("&nbsp;", " ", raw, fixed = TRUE)
  raw <- gsub("\\s+", " ", raw, perl = TRUE)
  trimws(raw)
}

decode_url <- function(value) utils::URLdecode(value)

pages <- list()
errors <- character()
html_files <- list.files(root, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
for (page in html_files) {
  raw <- readLines(page, warn = FALSE, encoding = "UTF-8")
  raw <- paste(raw, collapse = "\n")
  if (grepl("\\{\\{< include", raw, fixed = TRUE)) stop("Unexpanded include in ", page)

  links <- attributes_of(raw, "a", "href")
  ids <- extract_ids(raw)
  detail_match <- gregexpr("<details(?:\\s|>)", raw, perl = TRUE, ignore.case = TRUE)[[1]]
  detail_count <- if (detail_match[1] == -1) 0L else length(detail_match)
  pages[[page]] <- list(links = links, ids = ids, details = detail_count)
  for (href in links) {
    if (grepl("^([A-Za-z][A-Za-z0-9+.-]*:|//)", href) || href == "" || startsWith(href, "#")) next
    parts <- strsplit(href, "[?#]", perl = TRUE)[[1]]
    path <- if (length(parts)) parts[1] else ""
    if (!nzchar(path)) next
    path <- decode_url(path)
    if (startsWith(path, "/ballot/")) {
      target <- file.path(root, sub("^/ballot/", "", path))
    } else if (startsWith(path, "/")) {
      target <- file.path(root, sub("^/", "", path))
    } else {
      target <- normalizePath(file.path(dirname(page), path), mustWork = FALSE, winslash = "/")
    }
    if (!file.exists(target)) {
      errors <- c(errors, paste0(sub(paste0("^", root, "/?"), "", page, perl = TRUE), ": ", href))
    }
  }
}
if (length(errors)) stop("Broken local links: ", paste(errors, collapse = "; "))

for (i in seq_len(nrow(cycles))) {
  if (cycles$published[i] != "true") next
  guide <- file.path(root, html_path(cycles$path[i]))
  guide_key <- normalizePath(guide, mustWork = TRUE, winslash = "/")
  parsed <- pages[[guide_key]]
  cycle_measures <- measures[measures$cycle_id == cycles$cycle_id[i], , drop = FALSE]
  if (is.null(parsed) || parsed$details < nrow(cycle_measures)) {
    stop("Official wording missing from ", guide)
  }
  for (j in seq_len(nrow(cycle_measures))) {
    anchor <- sub("^.*#", "", cycle_measures$guide_path[j])
    if (!anchor %in% parsed$ids) stop("Missing guide anchor ", anchor)
  }
}

public_text <- paste(vapply(html_files, function(page) {
  html_text(paste(readLines(page, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
}, character(1)), collapse = "\n")
forbidden <- c("How I Would Vote", "Original recommendation", "LEAN YES", "Vote: YES", "RStudio", "Codex", "Next reporting step", "Opening research file")
for (phrase in forbidden) if (grepl(phrase, public_text, fixed = TRUE)) stop("Public copy contains retired language: ", phrase)

if (!any(articles$status == "published")) {
  if (grepl("Reporting & analysis", public_text, fixed = TRUE)) stop("Public copy contains an empty reporting section")
}

results <- read_csv("results")
if (!nrow(results)) {
  guide_text <- character()
  for (i in seq_len(nrow(cycles))) {
    if (cycles$published[i] != "true") next
    guide <- file.path(root, html_path(cycles$path[i]))
    guide_text <- c(guide_text, html_text(paste(readLines(guide, warn = FALSE, encoding = "UTF-8"), collapse = "\n")))
  }
  if (!any(grepl("Certification pending.", paste(guide_text, collapse = "\n"), fixed = TRUE))) {
    stop("Missing pending-results copy")
  }
}

for (stale in c("guide/index.html", "tracker.html", "geography.html", "spending.html", "methods.html")) {
  if (!file.exists(file.path(root, stale))) stop("Missing legacy redirect ", stale)
}
message("PASS: ", length(required), " public pages, ", nrow(measures), " questions, local links, neutral copy, and legacy redirects.")
