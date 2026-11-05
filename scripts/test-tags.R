source("R/publication.R")
source("R/measure-tags.R")
measures <- read_data("measures")
tags <- read_data("measure_tags")
stopifnot(validate_measure_tags(tags, measures$id))
fails <- function(expression) {
  failed <- FALSE
  tryCatch(expression, error = function(e) failed <<- TRUE)
  stopifnot(failed)
}
for (id in measures$id) {
  html <- paste(capture.output(measure_tags(id)), collapse = "\n")
  row <- tags[tags$measure_id == id, , drop = FALSE]
  stopifnot(grepl('aria-label="Measure Type And Topics"', html, fixed = TRUE), grepl(html_escape(row$measure_type), html, fixed = TRUE))
  for (topic in trimws(strsplit(row$topics, ";", fixed = TRUE)[[1]])) stopifnot(grepl(html_escape(topic), html, fixed = TRUE))
  stopifnot(!grepl("<a ", html, fixed = TRUE))
}
invalid <- tags; invalid$measure_type[1] <- "Other"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Unknown Topic"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;Housing"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;Schools;Infrastructure;Public Utilities"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- ""; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- "Housing;"; fails(validate_measure_tags(invalid, measures$id))
invalid <- tags; invalid$topics[1] <- NA_character_; fails(validate_measure_tags(invalid, measures$id))
fails(validate_measure_tags(tags[-1, , drop = FALSE], measures$id))
fails(validate_measure_tags(rbind(tags, tags[1, , drop = FALSE]), measures$id))
invalid <- tags; invalid$measure_id[1] <- "unknown-measure"; fails(validate_measure_tags(invalid, measures$id))
message("PASS: measure tag coverage, allowed labels, rendering, and invalid tag rejection. Production data was not modified.")
