measure_type_labels <- c("Bond", "Charter Change")
measure_topic_labels <- c("Housing", "Schools", "Neighborhood Development", "Infrastructure", "Budget And Spending", "Government Structure", "Public Utilities", "Families And Children", "Contracting")
validate_measure_tags <- function(tags, measure_ids) {
  required <- c("measure_id", "measure_type", "topics")
  if (!all(required %in% names(tags))) stop("Tag data is missing required columns.")
  if (anyNA(tags[required])) stop("Tag fields cannot contain NA values.")
  if (anyDuplicated(tags$measure_id) || any(!nzchar(tags$measure_id))) stop("Tag measure IDs must be nonempty and unique.")
  if (!setequal(tags$measure_id, measure_ids)) stop("Every active measure needs one tag record; unknown measure IDs are not allowed.")
  if (!all(tags$measure_type %in% measure_type_labels)) stop("Measure type must be Bond or Charter Change.")
  for (i in seq_len(nrow(tags))) {
    value <- tags$topics[i]
    topics <- trimws(strsplit(value, ";", fixed = TRUE)[[1]])
    if (startsWith(value, ";") || endsWith(value, ";") || length(topics) < 1L || length(topics) > 3L || any(!nzchar(topics)) || anyDuplicated(topics) || !all(topics %in% measure_topic_labels)) stop("Invalid topic tags for ", tags$measure_id[i])
  }
  invisible(TRUE)
}
measure_tags <- function(id) {
  tags <- read_data("measure_tags")
  validate_measure_tags(tags, read_data("measures")$id)
  row <- tags[tags$measure_id == id, , drop = FALSE]
  if (nrow(row) != 1L) stop("Missing tag record: ", id)
  topics <- trimws(strsplit(row$topics, ";", fixed = TRUE)[[1]])
  cat('<ul class="measure-tags" aria-label="Measure Type And Topics">')
  cat(sprintf('<li class="measure-tag measure-tag-type"><span class="visually-hidden">Measure Type: </span>%s</li>', html_escape(row$measure_type)))
  for (topic in topics) cat(sprintf('<li class="measure-tag measure-tag-topic"><span class="visually-hidden">Topic: </span>%s</li>', html_escape(topic)))
  cat('</ul>\n')
}
