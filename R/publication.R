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
tracker_table <- function() {
  d <- read_data("measures")
  cat('<div class="table-scroll" tabindex="0" role="region" aria-label="Ballot measures"><table id="measure-table" class="table"><caption>2026 Maryland and Baltimore City ballot measures. Percentages use For plus Against votes.</caption><thead><tr><th scope="col">Measure</th><th scope="col">Jurisdiction</th><th scope="col">Certified result</th><th scope="col">For</th><th scope="col">Against</th><th scope="col">Implementation</th></tr></thead><tbody>')
  for (i in seq_len(nrow(d))) {
    x <- d[i, ]; result <- result_record(x$id)
    href <- sub("\\.qmd$", ".html", x$page)
    status <- if (is.null(result)) "Awaiting certified results" else paste(result$certified_outcome, "— certified")
    for_share <- if (is.null(result)) "Not available" else sprintf("%.1f%% (%s votes)", result$for_pct, format_votes(result$for_votes))
    against_share <- if (is.null(result)) "Not available" else sprintf("%.1f%% (%s votes)", result$against_pct, format_votes(result$against_votes))
    cat(sprintf('<tr><th scope="row"><a href="%s">Question %s — %s</a></th><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', html_escape(href), html_escape(x$question), html_escape(x$title), html_escape(x$jurisdiction), html_escape(status), html_escape(for_share), html_escape(against_share), html_escape(x$implementation_status)))
  }
  cat('</tbody></table></div>\n')
}
source_link <- function(id) {
  s <- read_data("sources")
  s <- s[s$source_id == id, , drop = FALSE]
  if (nrow(s) != 1L) stop("Missing or duplicate source: ", id)
  sprintf('<a href="%s">%s</a>', html_escape(s$url), html_escape(s$title))
}
measure_summary <- function(id) {
  d <- read_data("measures"); x <- d[d$id == id, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  result <- result_record(id)
  status <- if (is.null(result)) "Awaiting certified results" else paste(result$certified_outcome, "— certified")
  checked <- if (nzchar(x$last_verified)) x$last_verified else "Not yet assessed"
  cat(sprintf('<p><span class="status">%s</span> <span class="status">%s</span></p><p><strong>Implementation last verified:</strong> %s<br><strong>Next milestone:</strong> %s</p>\n', html_escape(status), html_escape(x$implementation_status), html_escape(checked), html_escape(x$next_milestone)))
}
measure_vote_share <- function(id) {
  x <- result_record(id)
  if (is.null(x)) {
    cat('<p>Awaiting certified results. Vote shares, counts, and margin will appear here after a certified result and its source are entered. Missing data is not displayed as zero.</p>\n')
    return(invisible(NULL))
  }
  cat(sprintf('<p><strong>For:</strong> %.1f%% (%s votes)<br><strong>Against:</strong> %.1f%% (%s votes)</p>', x$for_pct, format_votes(x$for_votes), x$against_pct, format_votes(x$against_votes)))
  cat(sprintf('<div class="vote-bar" role="img" aria-label="For %.1f percent; Against %.1f percent"><span class="vote-for" style="width:%.8f%%"></span><span class="vote-against" style="width:%.8f%%"></span></div>', x$for_pct, x$against_pct, x$for_pct, x$against_pct))
  direction <- if (x$margin_pp > 0) "For ahead" else if (x$margin_pp < 0) "Against ahead" else "Equal vote totals"
  cat(sprintf('<p><strong>Vote margin:</strong> %s · %.1f percentage points<br><strong>Votes on this question:</strong> %s<br><strong>Certified:</strong> %s<br><strong>Result source:</strong> %s</p>\n', direction, abs(x$margin_pp), format_votes(x$total_votes), html_escape(x$certified_date), source_link(x$source_id)))
  cat('<p class="result-note">Share = option votes ÷ (For votes + Against votes). Blank or invalid responses and ballots without a vote on this question are excluded. Rounded percentages may not sum to exactly 100%. A vote share describes support among voters answering this question, not among all residents. The outcome label is transcribed from the certified record.</p>\n')
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
