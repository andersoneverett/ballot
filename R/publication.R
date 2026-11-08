read_data <- function(name) read.csv(file.path("data", paste0(name, ".csv")), stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL, check.names = FALSE)
html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}
result_record <- function(id) {
  x <- read_data("results")
  x <- x[x$measure_id == id, , drop = FALSE]
  if (!nrow(x)) return(NULL)
  stopifnot(nrow(x) == 1L)
  x$has_counts <- nzchar(x$for_votes) && nzchar(x$against_votes)
  x$for_votes <- as.numeric(x$for_votes)
  x$against_votes <- as.numeric(x$against_votes)
  x$total_votes <- x$for_votes + x$against_votes
  x$for_pct <- x$against_pct <- x$margin_pp <- NA_real_
  if (x$has_counts && is.finite(x$total_votes) && x$total_votes > 0) {
    x$for_pct <- 100 * x$for_votes / x$total_votes
    x$against_pct <- 100 * x$against_votes / x$total_votes
    x$margin_pp <- x$for_pct - x$against_pct
  }
  x
}
format_votes <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
measure_vote_share <- function(id) {
  x <- result_record(id)
  if (is.null(x)) {
    cat('<p class="result-pending">Results not yet recorded.</p>\n')
    return(invisible(NULL))
  }
  cat(sprintf('<div class="result-card" data-outcome="%s"><p class="result-label"><strong class="result-outcome">%s</strong><span class="result-status">%s Results</span></p>', html_escape(x$outcome), html_escape(x$outcome), html_escape(x$status)))
  if (x$has_counts) {
    cat(sprintf('<div class="result-counts"><span>For <strong>%.1f%%</strong> · %s votes</span><span>Against <strong>%.1f%%</strong> · %s votes</span></div>', x$for_pct, format_votes(x$for_votes), x$against_pct, format_votes(x$against_votes)))
    cat(sprintf('<div class="vote-bar" role="img" aria-label="For %.1f percent; Against %.1f percent"><span class="vote-for" style="width:%.8f%%"></span><span class="vote-against" style="width:%.8f%%"></span></div><p class="result-margin">Margin: %.1f percentage points</p>', x$for_pct, x$against_pct, x$for_pct, x$against_pct, abs(x$margin_pp)))
  }
  cat('</div>\n')
}
ballot_explanation <- function(id) {
  m <- read_data("measures"); x <- m[m$id == id, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  measure_vote_share(id)
  cat(sprintf('<p>%s</p><div class="decision-grid"><div><strong>If Approved</strong><p>%s</p></div><div><strong>If Rejected</strong><p>%s</p></div></div>\n', html_escape(x$explanation), html_escape(x$if_for), html_escape(x$if_against)))
}
cycle_result_note <- function(cycle_id) {
  m <- read_data("measures"); ids <- m$id[m$cycle_id == cycle_id]
  results <- read_data("results")
  if (!all(ids %in% results$measure_id)) cat('<p class="result-pending">Results have not yet been recorded for some or all questions.</p>\n')
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
