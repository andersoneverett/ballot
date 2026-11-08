read_data <- function(name) read.csv(file.path("data", paste0(name, ".csv")), stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL, check.names = FALSE)
html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}
format_votes <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
first_sentence <- function(x) sub("^(.+?[.!?])\\s.*$", "\\1", x, perl = TRUE)

# data/measures.csv: one row per ballot question, and the only place measure facts are entered.
# data/ballots.csv: one row per ballot (a set of questions), with its short narrative.
measure_columns <- c("cycle_id", "letter", "type", "title", "summary", "if_for", "if_against", "effective", "fiscal_impact", "proposer", "arguments_for", "arguments_against", "topics", "keywords", "text_source", "origin_source", "outcome", "status", "for_votes", "against_votes", "results_checked", "result_source")
measure_required <- c("cycle_id", "letter", "type", "title", "summary", "if_for", "if_against", "proposer", "topics", "keywords", "text_source", "origin_source")
measure_recommended <- c("effective", "fiscal_impact", "arguments_for", "arguments_against")
ballot_columns <- c("cycle_id", "year", "election_type", "election_date", "title", "intro", "published")
measure_types <- c("Bond", "Charter Change")
measure_proposers <- c("City Council", "Citizen Petition")
measure_topics <- c("Housing", "Schools", "Neighborhood Development", "Infrastructure", "Budget And Spending", "Government Structure", "Public Utilities", "Families And Children", "Contracting")

read_measures <- function(cycle_id = NULL) {
  m <- read_data("measures")
  if (!is.null(cycle_id)) m <- m[m$cycle_id == cycle_id, , drop = FALSE]
  m$text_path <- file.path("_ballot_text", m$cycle_id, paste0("baltimore-", tolower(m$letter), ".qmd"))
  m[order(m$letter), , drop = FALSE]
}

published_ballots <- function() {
  b <- read_data("ballots"); b <- b[b$published == "true", , drop = FALSE]
  b[order(b$election_date, decreasing = TRUE), , drop = FALSE]
}

measure_tags <- function(m) {
  type_class <- if (m$type == "Bond") "measure-kind-bond" else "measure-kind-charter"
  topics <- trimws(strsplit(m$topics, ";", fixed = TRUE)[[1]])
  cat('<div class="measure-meta" role="group" aria-label="Measure Type, Origin, And Topics">')
  cat(sprintf('<span class="measure-kind %s"><span class="visually-hidden">Measure Type: </span>%s</span>', type_class, html_escape(m$type)))
  cat('<ul class="measure-topics" aria-label="Topics">')
  for (topic in topics) cat(sprintf('<li>%s</li>', html_escape(topic)))
  cat('</ul>')
  cat(sprintf('<p class="measure-origin">Placed On The Ballot By: %s</p>', html_escape(m$proposer)))
  cat('</div>\n')
}

measure_keywords <- function(m) {
  keywords <- trimws(strsplit(m$keywords, ";", fixed = TRUE)[[1]])
  cat(sprintf('<p class="measure-origin">Also known as: %s</p>\n', html_escape(paste(keywords, collapse = " · "))))
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

# Source links, then the official wording (the toggle kept in each _ballot_text file).
measure_sources <- function(m) {
  s <- read_data("sources")
  roles <- c(text_source = "Explanation and wording", origin_source = "How it reached the ballot", result_source = "Results")
  items <- character()
  for (col in names(roles)) {
    if (!nzchar(m[[col]])) next
    x <- s[s$source_id == m[[col]], , drop = FALSE]
    items <- c(items, sprintf('<li>%s: <a href="%s">%s</a>, %s</li>', roles[[col]], html_escape(x$url), html_escape(x$title), html_escape(x$publisher)))
  }
  cat("\n## Sources\n\n<ul>", paste(items, collapse = ""), "</ul>\n\n", sep = "")
  cat(readLines(m$text_path, encoding = "UTF-8", warn = FALSE), sep = "\n")
  cat("\n")
}

# One full page for one measure, in priority order: result, summary, what the vote meant, arguments, sources.
# Called from the generated ballots/<year>/question-<letter>/index.qmd.
measure_page <- function(cycle_id, letter) {
  m <- read_measures(cycle_id); m <- m[m$letter == letter, , drop = FALSE]
  if (nrow(m) != 1L) stop("Expected exactly one measure for ", cycle_id, " ", letter)
  m <- m[1, ]
  b <- read_data("ballots"); b <- b[b$cycle_id == cycle_id, , drop = FALSE]
  cat(sprintf('<p><a href="../../#ballot-%s">← %s</a></p>\n', b$year, html_escape(b$title)))
  measure_tags(m)
  measure_result(m)
  cat(sprintf('<p>%s</p>\n', html_escape(m$summary)))
  fact_grid(c("If Approved" = m$if_for, "If Rejected" = m$if_against, "Fiscal Impact" = m$fiscal_impact, "Takes Effect" = m$effective))
  if (nzchar(m$arguments_for) || nzchar(m$arguments_against)) {
    cat("\n## Arguments\n\n")
    fact_grid(c("Argument For" = m$arguments_for, "Argument Against" = m$arguments_against))
  }
  measure_sources(m)
  measure_keywords(m)
}

ballot_status <- function(ms) {
  s <- ms$status[nzchar(ms$status)]
  if (!length(s)) return("Results not yet recorded.")
  if (length(s) < nrow(ms)) return("Some results not yet recorded.")
  if (all(s == "Certified")) return("Certified results.")
  if (all(s == "Unofficial")) return("Unofficial results; not yet certified.")
  "Results partly certified."
}

# The Ballot Guides page: each ballot with its status line, narrative, and one card per question.
ballot_archive <- function() {
  b <- published_ballots(); m <- read_measures()
  for (i in seq_len(nrow(b))) {
    x <- b[i, ]; ms <- m[m$cycle_id == x$cycle_id, , drop = FALSE]
    cat(sprintf("\n## %s {#ballot-%s .ballot-heading}\n\n", x$title, x$year))
    cat(sprintf('<p class="result-pending">%s</p>\n\n', ballot_status(ms)))
    cat(x$intro, "\n\n", sep = "")
    cards <- vapply(seq_len(nrow(ms)), function(j) {
      r <- ms[j, ]
      sprintf('<a class="charter-card" href="%s/question-%s/"><small>Question %s · %s</small><b>%s</b><small>%s</small></a>', x$year, tolower(r$letter), r$letter, html_escape(r$type), html_escape(r$title), html_escape(first_sentence(r$summary)))
    }, "")
    cat("```{=html}\n<div class=\"charter-grid\">\n", paste(cards, collapse = "\n"), "\n</div>\n```\n", sep = "")
  }
}

featured_ballot <- function() {
  b <- published_ballots()
  if (!nrow(b)) return(invisible(NULL))
  x <- b[1, ]; count <- sum(read_data("measures")$cycle_id == x$cycle_id)
  link <- sprintf("ballots/index.html#ballot-%s", x$year)
  cat(sprintf('<section class="featured-guide" aria-label="Current Ballot Guide"><p class="section-label">Ballot Guide</p><h2><a href="%s">%s</a></h2><p>%s Baltimore City ballot questions. Plain-language explanations, official wording, and sourced results.</p><a class="guide-button" href="%s">Explore The Guide <span aria-hidden="true">→</span></a></section>\n', html_escape(link), html_escape(x$title), count, html_escape(link)))
}
