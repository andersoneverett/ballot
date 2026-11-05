source("R/publication.R")
m <- read_data("measures"); s <- read_data("sources"); e <- read_data("events")
required <- list(
  measures = c("id", "question", "jurisdiction", "title", "original_position", "implementation_status", "last_verified", "next_milestone", "authorized_amount_usd", "page"),
  sources = c("source_id", "title", "publisher", "url", "published_date", "accessed_date", "notes"),
  results = c("measure_id", "for_votes", "against_votes", "certified_outcome", "certified_date", "source_id"),
  events = c("event_id", "measure_id", "event_date", "event_type", "summary", "source_id")
)
for (name in names(required)) {
  if (!all(required[[name]] %in% names(read_data(name)))) stop("Missing columns in data/", name, ".csv")
}
stopifnot(nrow(m) > 0L, !anyDuplicated(m$id), !anyDuplicated(s$source_id), !anyDuplicated(e$event_id))
stopifnot(all(file.exists(m$page)), all(e$measure_id %in% m$id), all(e$source_id %in% s$source_id))
stopifnot(all(m$implementation_status %in% c("Not assessed", "Awaiting effective date", "In progress", "Implemented", "Delayed", "Challenged", "Not applicable")))
valid_date <- function(x) {
  if (!length(x)) return(TRUE)
  parsed <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  all(grepl("^\\d{4}-\\d{2}-\\d{2}$", x) & !is.na(parsed) & format(parsed, "%Y-%m-%d") == x)
}
stopifnot(valid_date(e$event_date), valid_date(s$accessed_date), valid_date(s$published_date[nzchar(s$published_date)]), valid_date(m$last_verified[nzchar(m$last_verified)]))
if (nrow(s)) stopifnot(all(nzchar(s$source_id)), all(nzchar(s$title)), all(nzchar(s$publisher)), all(grepl("^https?://[^[:space:]]+$", s$url)), all(nzchar(s$accessed_date)))
assessed <- m$implementation_status != "Not assessed"
stopifnot(all(m$id[assessed] %in% e$measure_id), all(nzchar(m$last_verified[assessed])))
if (nrow(e)) stopifnot(all(nzchar(e$event_id)), all(nzchar(e$summary)), all(nzchar(e$event_type)))
message("Publication records validated: ", nrow(m), " measures; ", nrow(e), " events; ", nrow(s), " sources.")

r <- read_data("results")
stopifnot(!anyDuplicated(r$measure_id), all(r$measure_id %in% m$id), all(r$source_id %in% s$source_id))
stopifnot(valid_date(r$certified_date))
if (nrow(r)) {
  # Require digit-only counts; no commas, blanks, negatives, decimals, or percentages.
  stopifnot(all(grepl("^[0-9]+$", r$for_votes)), all(grepl("^[0-9]+$", r$against_votes)))
  for_votes <- as.numeric(r$for_votes); against_votes <- as.numeric(r$against_votes)
  stopifnot(all(is.finite(for_votes)), all(is.finite(against_votes)), all(for_votes + against_votes > 0))
  stopifnot(all(r$certified_outcome %in% c("Passed", "Failed", "Pending determination")))
  stopifnot(all(nzchar(r$source_id)), all(nzchar(r$certified_date)))
  stopifnot(all(as.Date(r$certified_date) <= Sys.Date()))
  source_access <- s$accessed_date[match(r$source_id, s$source_id)]
  stopifnot(all(as.Date(source_access) >= as.Date(r$certified_date)))
}
message("Certified result records validated: ", nrow(r), ".")

p <- read_data("precinct_results"); g <- read_data("geographies")
crosswalk <- read_data("geographic_crosswalk"); spending <- read_data("spending")
required_extra <- list(
  precinct_results = c("measure_id", "geography_type", "geography_id", "geography_name", "for_votes", "against_votes", "certified_date", "source_id"),
  geographies = c("geography_type", "geography_id", "jurisdiction", "geography_name", "boundary_vintage", "boundary_source_id"),
  geographic_crosswalk = c("precinct_id", "neighborhood_id", "allocation_method", "weight", "boundary_vintage", "source_id"),
  spending = c("record_id", "measure_id", "project_id", "project_name", "stage", "amount_usd", "funding_source", "responsible_agency", "event_date", "location_name", "location_precision", "latitude", "longitude", "service_area", "beneficiaries", "source_id")
)
for (name in names(required_extra)) stopifnot(all(required_extra[[name]] %in% names(read_data(name))))
if (nrow(g)) {
  stopifnot(!anyDuplicated(paste(g$geography_type, g$geography_id)), all(g$geography_type %in% c("precinct", "neighborhood")), all(g$boundary_source_id %in% s$source_id))
  stopifnot(all(nzchar(g$geography_id)), all(nzchar(g$geography_name)), all(nzchar(g$jurisdiction)), all(nzchar(g$boundary_vintage)))
}
if (nrow(p)) {
  stopifnot(all(p$measure_id %in% m$id), all(p$source_id %in% s$source_id), all(nzchar(p$geography_id)), all(nzchar(p$geography_name)))
  stopifnot(all(p$geography_type %in% c("precinct", "unallocated")), !anyDuplicated(paste(p$measure_id, p$geography_type, p$geography_id)))
  stopifnot(valid_date(p$certified_date), all(as.Date(p$certified_date) <= Sys.Date()))
  stopifnot(all(grepl("^[0-9]+$", p$for_votes)), all(grepl("^[0-9]+$", p$against_votes)))
  stopifnot(all(is.finite(as.numeric(p$for_votes))), all(is.finite(as.numeric(p$against_votes))))
  located <- p$geography_type == "precinct"
  stopifnot(all(p$geography_id[located] %in% g$geography_id[g$geography_type == "precinct"]))
  for (id in unique(p$measure_id)) {
    result <- result_record(id)
    if (is.null(result)) stop("Import the certified jurisdiction total before its geographic rows: ", id)
    rows <- p[p$measure_id == id, , drop = FALSE]
    stopifnot(sum(as.numeric(rows$for_votes)) <= result$for_votes, sum(as.numeric(rows$against_votes)) <= result$against_votes)
  }
}
if (nrow(crosswalk)) {
  stopifnot(all(crosswalk$precinct_id %in% g$geography_id[g$geography_type == "precinct"]), all(crosswalk$neighborhood_id %in% g$geography_id[g$geography_type == "neighborhood"]))
  stopifnot(all(crosswalk$source_id %in% s$source_id), all(crosswalk$allocation_method %in% c("exact containment", "area estimate", "population estimate")))
  weights <- as.numeric(crosswalk$weight)
  stopifnot(all(is.finite(weights)), all(weights > 0 & weights <= 1), !anyDuplicated(paste(crosswalk$precinct_id, crosswalk$neighborhood_id)))
  stopifnot(all(abs(tapply(weights, crosswalk$precinct_id, sum) - 1) < 0.000001))
}
if (nrow(spending)) {
  stopifnot(!anyDuplicated(spending$record_id), all(nzchar(spending$record_id)), all(nzchar(spending$project_id)), all(nzchar(spending$project_name)))
  stopifnot(all(spending$measure_id %in% m$id), all(spending$source_id %in% s$source_id), valid_date(spending$event_date))
  stopifnot(all(spending$stage %in% c("Authorized", "Budgeted", "Awarded", "Expended")))
  amounts <- as.numeric(spending$amount_usd)
  stopifnot(all(grepl("^-?[0-9]+(\\.[0-9]{1,2})?$", spending$amount_usd)), all(is.finite(amounts)))
  stopifnot(all(nzchar(spending$funding_source)), all(nzchar(spending$responsible_agency)), all(nzchar(spending$service_area)))
  stopifnot(all(spending$location_precision %in% c("site", "area", "citywide", "unspecified")))
  has_lat <- nzchar(spending$latitude); has_lon <- nzchar(spending$longitude)
  stopifnot(all(has_lat == has_lon))
  if (any(has_lat)) {
    lat <- as.numeric(spending$latitude[has_lat]); lon <- as.numeric(spending$longitude[has_lat])
    stopifnot(all(is.finite(lat) & lat >= -90 & lat <= 90), all(is.finite(lon) & lon >= -180 & lon <= 180))
    stopifnot(all(spending$location_precision[has_lat] == "site"))
  }
}
message("Geographic and spending records validated.")
