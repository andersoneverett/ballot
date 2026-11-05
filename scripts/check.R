source("R/publication.R")

valid_date <- function(x) {
  if (!length(x)) return(TRUE)
  parsed <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  all(grepl("^\\d{4}-\\d{2}-\\d{2}$", x) & !is.na(parsed) & format(parsed, "%Y-%m-%d") == x)
}
path_exists <- function(path) file.exists(sub("#.*$", "", path))

m <- read_data("measures"); s <- read_data("sources"); e <- read_data("events")
cycles <- read_data("elections"); articles <- read_data("articles")
required <- list(
  measures = c("id", "cycle_id", "question", "jurisdiction", "title", "explanation", "if_for", "if_against", "explanation_source_id", "ballot_text_path", "guide_path", "implementation_status", "last_verified", "next_milestone", "authorized_amount_usd"),
  elections = c("cycle_id", "year", "election_type", "election_date", "title", "path", "published"),
  articles = c("article_id", "title", "description", "date", "path", "author", "cycle_id", "status"),
  sources = c("source_id", "title", "publisher", "url", "published_date", "accessed_date", "notes"),
  results = c("measure_id", "for_votes", "against_votes", "certified_outcome", "certified_date", "source_id"),
  events = c("event_id", "measure_id", "event_date", "event_type", "summary", "source_id")
)
for (name in names(required)) stopifnot(all(required[[name]] %in% names(read_data(name))))
stopifnot(nrow(m) > 0L, !anyDuplicated(m$id), !anyDuplicated(s$source_id), !anyDuplicated(e$event_id))
stopifnot(!anyDuplicated(cycles$cycle_id), !anyDuplicated(cycles$path), all(cycles$published %in% c("true", "false")))
stopifnot(all(grepl("^[0-9]{4}$", cycles$year)), valid_date(cycles$election_date), all(path_exists(cycles$path)))
stopifnot(all(grepl("^elections/[0-9]{4}/[^/]+/index\\.qmd$", cycles$path)))
stopifnot(all(m$cycle_id %in% cycles$cycle_id), !anyDuplicated(paste(m$cycle_id, m$jurisdiction, m$question)))
stopifnot(all(startsWith(m$id, paste0(m$cycle_id, "-"))), all(path_exists(m$ballot_text_path)), all(path_exists(m$guide_path)))
stopifnot(all(m$explanation_source_id %in% s$source_id), all(nzchar(m$explanation)), all(nzchar(m$if_for)), all(nzchar(m$if_against)))
stopifnot(all(e$measure_id %in% m$id), all(e$source_id %in% s$source_id))
stopifnot(all(m$implementation_status %in% c("Not assessed", "Awaiting effective date", "In progress", "Implemented", "Delayed", "Challenged", "Not applicable")))
stopifnot(valid_date(e$event_date), valid_date(s$accessed_date), valid_date(s$published_date[nzchar(s$published_date)]), valid_date(m$last_verified[nzchar(m$last_verified)]))
if (nrow(s)) stopifnot(all(nzchar(s$source_id)), all(nzchar(s$title)), all(nzchar(s$publisher)), all(grepl("^https?://[^[:space:]]+$", s$url)), all(nzchar(s$accessed_date)))
assessed <- m$implementation_status != "Not assessed"
stopifnot(all(m$id[assessed] %in% e$measure_id), all(nzchar(m$last_verified[assessed])))
if (nrow(e)) stopifnot(all(nzchar(e$event_id)), all(nzchar(e$summary)), all(nzchar(e$event_type)))
if (nrow(articles)) {
  stopifnot(!anyDuplicated(articles$article_id), !anyDuplicated(articles$path), all(articles$cycle_id %in% cycles$cycle_id), all(articles$status %in% c("draft", "published")))
  published <- articles$status == "published"
  stopifnot(valid_date(articles$date[published]), all(path_exists(articles$path[published])), all(nzchar(articles$title[published])), all(nzchar(articles$author[published])))
}
message("Publication records validated: ", nrow(m), " measures across ", nrow(cycles), " election cycle(s).")

r <- read_data("results")
stopifnot(!anyDuplicated(r$measure_id), all(r$measure_id %in% m$id), all(r$source_id %in% s$source_id), valid_date(r$certified_date))
if (nrow(r)) {
  stopifnot(all(grepl("^[0-9]+$", r$for_votes)), all(grepl("^[0-9]+$", r$against_votes)))
  for_votes <- as.numeric(r$for_votes); against_votes <- as.numeric(r$against_votes)
  stopifnot(all(is.finite(for_votes)), all(is.finite(against_votes)), all(for_votes + against_votes > 0))
  stopifnot(all(r$certified_outcome %in% c("Passed", "Failed", "Pending determination")), all(nzchar(r$source_id)), all(nzchar(r$certified_date)))
  stopifnot(all(as.Date(r$certified_date) <= Sys.Date()))
  stopifnot(all(as.Date(s$accessed_date[match(r$source_id, s$source_id)]) >= as.Date(r$certified_date)))
}

p <- read_data("precinct_results"); g <- read_data("geographies"); crosswalk <- read_data("geographic_crosswalk"); spending <- read_data("spending")
required_extra <- list(
  precinct_results = c("measure_id", "geography_type", "geography_id", "geography_name", "for_votes", "against_votes", "certified_date", "source_id"),
  geographies = c("geography_type", "geography_id", "jurisdiction", "geography_name", "boundary_vintage", "boundary_source_id"),
  geographic_crosswalk = c("precinct_id", "neighborhood_id", "allocation_method", "weight", "boundary_vintage", "source_id"),
  spending = c("record_id", "measure_id", "project_id", "project_name", "stage", "amount_usd", "funding_source", "responsible_agency", "event_date", "location_name", "location_precision", "latitude", "longitude", "service_area", "beneficiaries", "source_id")
)
for (name in names(required_extra)) stopifnot(all(required_extra[[name]] %in% names(read_data(name))))
if (nrow(g)) stopifnot(!anyDuplicated(paste(g$geography_type, g$geography_id)), all(g$geography_type %in% c("precinct", "neighborhood")), all(g$boundary_source_id %in% s$source_id))
if (nrow(p)) {
  stopifnot(all(p$measure_id %in% m$id), all(p$source_id %in% s$source_id), all(p$geography_type %in% c("precinct", "unallocated")), !anyDuplicated(paste(p$measure_id, p$geography_type, p$geography_id)), valid_date(p$certified_date))
  stopifnot(all(grepl("^[0-9]+$", p$for_votes)), all(grepl("^[0-9]+$", p$against_votes)))
  for (id in unique(p$measure_id)) { result <- result_record(id); if (is.null(result)) stop("Import the certified jurisdiction total before geographic rows: ", id); rows <- p[p$measure_id == id, , drop = FALSE]; stopifnot(sum(as.numeric(rows$for_votes)) <= result$for_votes, sum(as.numeric(rows$against_votes)) <= result$against_votes) }
}
if (nrow(crosswalk)) { weights <- as.numeric(crosswalk$weight); stopifnot(all(crosswalk$source_id %in% s$source_id), all(weights > 0 & weights <= 1), all(abs(tapply(weights, crosswalk$precinct_id, sum) - 1) < 0.000001)) }
if (nrow(spending)) {
  stopifnot(!anyDuplicated(spending$record_id), all(spending$measure_id %in% m$id), all(spending$source_id %in% s$source_id), valid_date(spending$event_date), all(spending$stage %in% c("Authorized", "Budgeted", "Awarded", "Expended")))
  stopifnot(all(grepl("^-?[0-9]+(\\.[0-9]{1,2})?$", spending$amount_usd)), all(spending$location_precision %in% c("site", "area", "citywide", "unspecified")))
  has_lat <- nzchar(spending$latitude); stopifnot(all(has_lat == nzchar(spending$longitude)))
}
message("Result, geographic, and spending records validated.")
