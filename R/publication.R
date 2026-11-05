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
  x$for_votes <- as.numeric(x$for_votes)
  x$against_votes <- as.numeric(x$against_votes)
  x$total_votes <- x$for_votes + x$against_votes
  x$for_pct <- 100 * x$for_votes / x$total_votes
  x$against_pct <- 100 * x$against_votes / x$total_votes
  x$margin_pp <- x$for_pct - x$against_pct
  x
}
format_votes <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
source_link <- function(id) {
  s <- read_data("sources")
  s <- s[s$source_id == id, , drop = FALSE]
  if (nrow(s) != 1L) stop("Missing or duplicate source: ", id)
  sprintf('<a href="%s">%s</a>', html_escape(s$url), html_escape(s$title))
}

measure_vote_share <- function(id) {
  x <- result_record(id)
  if (is.null(x)) {
    cat('<p class="result-pending"><strong>Results:</strong> Certification pending.</p>\n')
    return(invisible(NULL))
  }
  cat(sprintf('<div class="certified-result"><p class="result-label">%s · Certified result</p><div class="result-counts"><span>For <strong>%.1f%%</strong> · %s votes</span><span>Against <strong>%.1f%%</strong> · %s votes</span></div>', html_escape(x$certified_outcome), x$for_pct, format_votes(x$for_votes), x$against_pct, format_votes(x$against_votes)))
  cat(sprintf('<div class="vote-bar" role="img" aria-label="For %.1f percent; Against %.1f percent"><span class="vote-for" style="width:%.8f%%"></span><span class="vote-against" style="width:%.8f%%"></span></div>', x$for_pct, x$against_pct, x$for_pct, x$against_pct))
  cat(sprintf('<p class="result-detail">Margin: %.1f percentage points · Certified %s · %s</p></div>\n', abs(x$margin_pp), html_escape(x$certified_date), source_link(x$source_id)))
}
ballot_explanation <- function(id) {
  m <- read_data("measures"); x <- m[m$id == id, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  cat(sprintf('<p>%s</p><div class="decision-grid"><div><strong>If approved</strong><p>%s</p></div><div><strong>If rejected</strong><p>%s</p></div></div>\n', html_escape(x$explanation), html_escape(x$if_for), html_escape(x$if_against)))
  measure_vote_share(id)
}
cycle_result_note <- function(cycle_id) {
  ids <- read_data("measures"); ids <- ids$id[ids$cycle_id == cycle_id]
  results <- read_data("results")
  if (!all(ids %in% results$measure_id)) cat('<p class="result-pending">Certified results are pending for some or all questions.</p>\n')
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
  cat(sprintf('<section class="featured-guide" aria-label="Current Election Guide"><p class="section-label">Election Guide</p><h2><a href="%s">%s</a></h2><p>%s Baltimore City ballot questions. Plain-language explanations, official wording, and certified results.</p><a class="guide-button" href="%s">Explore The Guide <span aria-hidden="true">→</span></a></section>\n', html_escape(html_path(x$path)), html_escape(x$title), count, html_escape(html_path(x$path))))
}
election_index <- function() {
  d <- published_elections()
  if (!nrow(d)) return(invisible(NULL))
  cat('<ul class="cycle-list">')
  for (i in seq_len(nrow(d))) {
    x <- d[i, ]; path <- sub("^elections/", "", html_path(x$path))
    cat(sprintf('<li><h2><a href="%s">%s</a></h2><p>Baltimore City Ballot Questions</p></li>', html_escape(path), html_escape(x$title)))
  }
  cat('</ul>\n')
}
latest_articles <- function() {
  d <- read_data("articles"); d <- d[d$status == "published", , drop = FALSE]
  if (!nrow(d)) return(invisible(NULL))
  d <- head(d[order(d$date, decreasing = TRUE), , drop = FALSE], 6)
  cat('<section id="reporting"><h2>Reporting &amp; analysis</h2><ul class="article-list">')
  for (i in seq_len(nrow(d))) {
    x <- d[i, ]
    cat(sprintf('<li><p class="section-label">%s</p><h3><a href="%s">%s</a></h3><p>%s</p></li>', html_escape(x$date), html_escape(html_path(x$path)), html_escape(x$title), html_escape(x$description)))
  }
  cat('</ul></section>\n')
}
measure_timeline <- function(id) {
  e <- read_data("events")
  e <- e[e$measure_id == id, , drop = FALSE]
  if (nrow(e) == 0L) {
    cat('<p>No implementation events have yet been verified for this publication. This does not establish that no action has occurred.</p>\n')
    return(invisible(NULL))
  }
  e <- e[order(e$event_date, e$event_id), , drop = FALSE]
  cat('<div class="table-scroll" tabindex="0" role="region" aria-label="Evidence timeline"><table class="table"><caption>Sourced timeline</caption><thead><tr><th scope="col">Date</th><th scope="col">Event</th><th scope="col">Evidence</th></tr></thead><tbody>')
  for (i in seq_len(nrow(e))) cat(sprintf('<tr><td>%s</td><td><strong>%s</strong><br>%s</td><td>%s</td></tr>', html_escape(e$event_date[i]), html_escape(e$event_type[i]), html_escape(e$summary[i]), source_link(e$source_id[i])))
  cat('</tbody></table></div>\n')
}

research_table <- function(data, headers, caption) {
  cat(sprintf('<div class="table-scroll" tabindex="0" role="region" aria-label="%s"><table class="table"><caption>%s</caption><thead><tr>', html_escape(caption), html_escape(caption)))
  for (h in headers) cat(sprintf('<th scope="col">%s</th>', html_escape(h)))
  cat('</tr></thead><tbody>')
  for (i in seq_len(nrow(data))) {
    cat('<tr>')
    for (cell in data[i, ]) cat(sprintf('<td>%s</td>', cell))
    cat('</tr>')
  }
  cat('</tbody></table></div>\n')
}
geography_table <- function() {
  p <- read_data("precinct_results")
  if (!nrow(p)) {
    cat('<p>Awaiting certified geographic results. Precinct-level vote counts and percentages will be listed here when verified.</p>\n')
    return(invisible(NULL))
  }
  m <- read_data("measures"); idx <- match(p$measure_id, m$id)
  total <- as.numeric(p$for_votes) + as.numeric(p$against_votes)
  share <- ifelse(total > 0, sprintf("%.1f%%", 100 * as.numeric(p$for_votes) / total), "No valid For/Against votes")
  display <- data.frame(measure = html_escape(paste("Question", m$question[idx], "—", m$title[idx])), geography = html_escape(p$geography_name), type = html_escape(p$geography_type), for_votes = html_escape(p$for_votes), against_votes = html_escape(p$against_votes), for_pct = html_escape(share), source = vapply(p$source_id, source_link, character(1)))
  research_table(display, c("Measure", "Reporting unit", "Unit type", "For votes", "Against votes", "For share", "Source"), "Certified geographic results; records may not yet cover the entire jurisdiction")
}
spending_table <- function() {
  s <- read_data("spending")
  if (!nrow(s)) {
    cat('<p>No spending entries have yet been verified. This does not establish that no funding has been allocated or spent.</p>\n')
    return(invisible(NULL))
  }
  s <- s[order(s$event_date, decreasing = TRUE), , drop = FALSE]
  display <- data.frame(project = html_escape(s$project_name), measure = html_escape(s$measure_id), stage = html_escape(s$stage), amount = html_escape(paste0("$", formatC(as.numeric(s$amount_usd), format = "f", digits = 2, big.mark = ","))), date = html_escape(s$event_date), location = html_escape(s$location_name), service_area = html_escape(s$service_area), source = vapply(s$source_id, source_link, character(1)))
  research_table(display, c("Project", "Measure", "Stage", "Amount", "Date", "Location", "Service area", "Source"), "Spending records: do not sum across financial stages")
}
