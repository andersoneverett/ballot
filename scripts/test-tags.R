source("R/publication.R")
source("R/measure-tags.R")
measures <- read_data("measures"); tags <- read_data("measure_tags"); sources <- read_data("sources")
stopifnot(validate_measure_tags(tags, measures$id, sources$source_id))
fails <- function(expression) {
  failed <- FALSE
  tryCatch(expression, error = function(e) failed <<- TRUE)
  stopifnot(failed)
}
for (id in measures$id) {
  html <- paste(capture.output(measure_tags(id)), collapse = "\n")
  row <- tags[tags$measure_id == id, , drop = FALSE]
  evidence <- sources[sources$source_id == row$origin_source_id, , drop = FALSE]
  stopifnot(grepl('class="measure-meta"', html, fixed = TRUE), grepl(html_escape(row$measure_type), html, fixed = TRUE))
  stopifnot(grepl('class="measure-topics"', html, fixed = TRUE), grepl('class="measure-origin"', html, fixed = TRUE))
  stopifnot(grepl("Placed On The Ballot By:", html, fixed = TRUE), grepl(html_escape(row$ballot_origin), html, fixed = TRUE))
  stopifnot(grepl(paste0('href="', html_escape(evidence$url), '"'), html, fixed = TRUE))
  stopifnot(!grepl("measure-tag-origin", html, fixed = TRUE))
  for (topic in trimws(strsplit(row$topics, ";", fixed = TRUE)[[1]])) stopifnot(grepl(html_escape(topic), html, fixed = TRUE))
  result <- result_record(id)
  if (!is.null(result)) {
    rendered <- paste(capture.output(measure_vote_share(id)), collapse = "\n")
    stopifnot(grepl('class="result-card"', rendered, fixed = TRUE), grepl(paste0('data-outcome="', html_escape(result$outcome), '"'), rendered, fixed = TRUE))
  }
}
invalid <- tags; invalid$measure_type[1] <- "Other"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$ballot_origin[1] <- "Other"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$ballot_origin[1] <- ""; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$origin_source_id[1] <- "unknown-source"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$origin_source_id[1] <- ""; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Unknown Topic"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;Housing"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;Schools;Infrastructure;Public Utilities"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- ""; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- NA_character_; fails(validate_measure_tags(invalid, measures$id))
fails(validate_measure_tags(tags[-1, , drop = FALSE], measures$id))
fails(validate_measure_tags(rbind(tags, tags[1, , drop = FALSE]), measures$id))
invalid <- tags; invalid$measure_id[1] <- "unknown-measure"; fails(validate_measure_tags(invalid, measures$id))
message("PASS: metadata hierarchy, sourced origins, result markup, and invalid tag rejection. Production data was not modified.")
