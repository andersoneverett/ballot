read_data <- function(name) read.csv(file.path("data", paste0(name, ".csv")), stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL, check.names = FALSE)
html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}
format_votes <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

# data/measures.csv: one row per ballot question, and the only place measure facts are entered.
measure_columns <- c("cycle_id", "letter", "type", "title", "summary", "if_for", "if_against", "effective", "fiscal_impact", "proposer", "arguments_for", "arguments_against", "topics", "keywords", "text_source", "origin_source", "outcome", "status", "for_votes", "against_votes", "results_checked", "result_source")
measure_required <- c("cycle_id", "letter", "type", "title", "summary", "if_for", "if_against", "proposer", "topics", "keywords", "text_source", "origin_source")
measure_recommended <- c("effective", "fiscal_impact", "arguments_for", "arguments_against")
measure_types <- c("Bond", "Charter Change")
measure_proposers <- c("City Council", "Citizen Petition")
measure_topics <- c("Housing", "Schools", "Neighborhood Development", "Infrastructure", "Budget And Spending", "Government Structure", "Public Utilities", "Families And Children", "Contracting")

read_measures <- function(cycle_id = NULL) {
  m <- read_data("measures")
  if (!is.null(cycle_id)) m <- m[m$cycle_id == cycle_id, , drop = FALSE]
  m$anchor <- paste0("question-baltimore-", tolower(m$letter))
  m$text_path <- file.path("_ballot_text", m$cycle_id, paste0("baltimore-", tolower(m$letter), ".qmd"))
  m[order(m$letter), , drop = FALSE]
}

measure_tags <- function(m) {
  type_class <- if (m$type == "Bond") "measure-kind-bond" else "measure-kind-charter"
  topics <- trimws(strsplit(m$topics, ";", fixed = TRUE)[[1]])
  keywords <- trimws(strsplit(m$keywords, ";", fixed = TRUE)[[1]])
  cat('<div class="measure-meta" role="group" aria-label="Measure Type, Origin, And Topics">')
  cat(sprintf('<span class="measure-kind %s"><span class="visually-hidden">Measure Type: </span>%s</span>', type_class, html_escape(m$type)))
  cat('<ul class="measure-topics" aria-label="Topics">')
  for (topic in topics) cat(sprintf('<li>%s</li>', html_escape(topic)))
  cat('</ul>')
  cat(sprintf('<p class="measure-origin">Placed On The Ballot By: %s</p>', html_escape(m$proposer)))
  cat(sprintf('<p class="measure-origin">Also known as: %s</p>', html_escape(paste(keywords, collapse = " · "))))
  cat('</div>\n')
}

measure_result <- function(m) {
  if (!nzchar(m$outcome)) return(cat('<p class="result-pending">Results not yet recorded.</p>\n'))
  cat(sprintf('<div class="result-card" data-outcome="%s"><p class="result-label"><strong class="result-outcome">%s</strong><span class="result-status">%s Results</span></p>', html_escape(m$outcome), html_escape(m$outcome), html_escape(m$status)))
  if (nzchar(m$for_votes)) {
    f <- as.numeric(m$for_votes); a <- as.numeric(m$against_votes)
    fp <- 100 * f / (f + a); ap <- 100 - fp
    cat(sprintf('<div class="result-counts"><span>For <strong>%.1f%%</strong> · %s votes</span><span>Against <strong>%.1f%%</strong> · %s votes</span></div>', fp, format_votes(f), ap, format_votes(a)))
    cat(sprintf('<div class="vote-bar" role="img" aria-label="For %.1f percent; Against %.1f percent"><span class="vote-for" style="width:%.8f%%"></span><span class="vote-against" style="width:%.8f%%"></span></div><p class="result-margin">Margin: %.1f percentage points</p>', fp, ap, fp, ap, abs(fp - ap)))
  }
  cat('</div>\n')
}

fact_grid <- function(items) {
  items <- items[nzchar(items)]
  if (!length(items)) return(invisible(NULL))
  cat('<div class="decision-grid">')
  for (i in seq_along(items)) cat(sprintf('<div><strong>%s</strong><p>%s</p></div>', html_escape(names(items)[i]), html_escape(items[[i]])))
  cat('</div>\n')
}

measure_section <- function(m) {
  cat(sprintf('\n### Question %s — %s {#%s}\n\n', m$letter, m$title, m$anchor))
  measure_tags(m)
  measure_result(m)
  cat(sprintf('<p>%s</p>\n', html_escape(m$summary)))
  fact_grid(c("If Approved" = m$if_for, "If Rejected" = m$if_against))
  fact_grid(c("Fiscal Impact" = m$fiscal_impact, "Takes Effect" = m$effective))
  fact_grid(c("Argument For" = m$arguments_for, "Argument Against" = m$arguments_against))
  cat("\n")
  cat(readLines(m$text_path, encoding = "UTF-8", warn = FALSE), sep = "\n")
  cat("\n")
}

measure_sections <- function(cycle_id) {
  m <- read_measures(cycle_id)
  for (i in seq_len(nrow(m))) measure_section(m[i, , drop = FALSE])
}

fmt_letters <- function(x) {
  x <- sort(x); g <- cumsum(c(1, diff(match(x, LETTERS)) != 1))
  runs <- vapply(split(x, g), function(r) if (length(r) > 2) paste0(r[1], "–", r[length(r)]) else paste(r, collapse = ", "), "")
  paste0(if (length(x) > 1) "Questions " else "Question ", paste(runs, collapse = ", "))
}
number_word <- function(n) if (n <= 10) c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten")[n] else as.character(n)

cycle_result_note <- function(cycle_id) {
  m <- read_measures(cycle_id); done <- m[nzchar(m$outcome), , drop = FALSE]
  if (nrow(done) < nrow(m)) cat('<p class="result-pending">Results have not yet been recorded for some or all questions.</p>\n')
  if (!nrow(done)) return(invisible(NULL))
  s <- read_data("sources"); url <- s$url[s$source_id == done$result_source[1]]
  label <- if (all(done$status == "Certified")) "final official election returns" else "unofficial election returns"
  checked <- format(max(as.Date(done$results_checked)), "%B %d, %Y"); checked <- sub(" 0", " ", checked)
  passed <- done$letter[done$outcome == "Passed"]; failed <- done$letter[done$outcome == "Failed"]
  if (!length(failed) && length(passed) == nrow(m)) {
    lead <- sprintf("All %s Baltimore City measures passed according to [%s](%s), checked %s.", number_word(nrow(m)), label, url, checked)
  } else {
    parts <- c(if (length(passed)) paste0(fmt_letters(passed), " passed."), if (length(failed)) paste0(fmt_letters(failed), " failed."))
    lead <- sprintf("%s Vote counts come from the [%s](%s), checked %s.", paste(parts, collapse = " "), label, url, checked)
  }
  cat("\n", lead, " These are election outcomes, not a record of completed implementation.\n\n", sep = "")
}

published_elections <- function() {
  d <- read_data("elections"); d <- d[d$published == "true", , drop = FALSE]
  d[order(d$election_date, decreasing = TRUE), , drop = FALSE]
}
html_path <- function(path) sub("\\.qmd$", ".html", path)
featured_election <- function() {
  d <- published_elections()
  if (!nrow(d)) return(invisible(NULL))
  x <- d[1, ]; m <- read_data("measures"); count <- sum(m$cycle_id == x$cycle_id)
  cat(sprintf('<section class="featured-guide" aria-label="Current Election Guide"><p class="section-label">Election Guide</p><h2><a href="%s">%s</a></h2><p>%s Baltimore City ballot questions. Plain-language explanations, official wording, and sourced results.</p><a class="guide-button" href="%s">Explore The Guide <span aria-hidden="true">→</span></a></section>\n', html_escape(html_path(x$path)), html_escape(x$title), count, html_escape(html_path(x$path))))
}
election_index <- function() {
  d <- published_elections()
  if (!nrow(d)) return(invisible(NULL))
  cat('<ul class="cycle-list">')
  for (i in seq_len(nrow(d))) {
    x <- d[i, ]; path <- sub("^elections/", "", html_path(x$path))
    cat(sprintf('<li><h2><a href="%s">%s</a></h2></li>', html_escape(path), html_escape(x$title)))
  }
  cat('</ul>\n')
}
