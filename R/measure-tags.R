measure_type_labels <- c("Bond", "Charter Change")
measure_origin_labels <- c("City Council–Referred", "Citizen Petition")
measure_topic_labels <- c("Housing", "Schools", "Neighborhood Development", "Infrastructure", "Budget And Spending", "Government Structure", "Public Utilities", "Families And Children", "Contracting")
validate_measure_tags <- function(tags, measure_ids, source_ids = read_data("sources")$source_id) {
  required <- c("measure_id", "measure_type", "topics", "ballot_origin", "origin_source_id")
  if (!all(required %in% names(tags))) stop("Tag data is missing required columns.")
  if (anyNA(tags[required])) stop("Tag fields cannot contain NA values.")
  if (anyDuplicated(tags$measure_id) || any(!nzchar(tags$measure_id))) stop("Tag measure IDs must be nonempty and unique.")
  if (!setequal(tags$measure_id, measure_ids)) stop("Every active measure needs one tag record; unknown measure IDs are not allowed.")
  if (!all(tags$measure_type %in% measure_type_labels)) stop("Measure type must be Bond or Charter Change.")
  if (!all(tags$ballot_origin %in% measure_origin_labels)) stop("Invalid ballot origin.")
  if (any(!nzchar(tags$origin_source_id)) || !all(tags$origin_source_id %in% source_ids)) stop("Each ballot origin needs a registered source.")
  for (i in seq_len(nrow(tags))) {
    value <- tags$topics[i]
    topics <- trimws(strsplit(value, ";", fixed = TRUE)[[1]])
    if (startsWith(value, ";") || endsWith(value, ";") || length(topics) < 1L || length(topics) > 3L || any(!nzchar(topics)) || anyDuplicated(topics) || !all(topics %in% measure_topic_labels)) stop("Invalid topic tags for ", tags$measure_id[i])
  }
  invisible(TRUE)
}
measure_tags <- function(id) {
  tags <- read_data("measure_tags"); sources <- read_data("sources")
  validate_measure_tags(tags, read_data("measures")$id, sources$source_id)
  row <- tags[tags$measure_id == id, , drop = FALSE]
  if (nrow(row) != 1L) stop("Missing tag record: ", id)
  evidence <- sources[sources$source_id == row$origin_source_id, , drop = FALSE]
  if (nrow(evidence) != 1L) stop("Missing or duplicate origin source: ", row$origin_source_id)
  topics <- trimws(strsplit(row$topics, ";", fixed = TRUE)[[1]])
  type_class <- if (row$measure_type == "Bond") "measure-kind-bond" else "measure-kind-charter"
  origin_text <- if (row$ballot_origin == "City Council–Referred") "City Council" else "Citizen Petition"
  cat('<div class="measure-meta" role="group" aria-label="Measure Type, Origin, And Topics">')
  cat(sprintf('<span class="measure-kind %s"><span class="visually-hidden">Measure Type: </span>%s</span>', type_class, html_escape(row$measure_type)))
  cat('<ul class="measure-topics" aria-label="Topics">')
  for (topic in topics) cat(sprintf('<li>%s</li>', html_escape(topic)))
  cat('</ul>')
  cat(sprintf('<p class="measure-origin">Placed On The Ballot By: <a href="%s" aria-label="%s: View Ballot Origin Source">%s</a></p>', html_escape(evidence$url), html_escape(row$ballot_origin), html_escape(origin_text)))
  cat('</div>\n')
}
