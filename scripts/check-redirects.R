# Run after quarto render; validate redirects without changing generated files.
source("scripts/check-render.R")
validate_redirects <- function(root = "docs", data_root = "data") {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  mapping <- read_csv("GUIDE_MAPPING", data_root)
  measures <- read_csv("measures", data_root)
  stopifnot(!anyDuplicated(mapping$old_id), all(nzchar(mapping$old_id)))
  expected <- c("guide/index.html" = "elections/2026/general/index.html",
    "tracker.html" = "elections/2026/general/index.html",
    "geography.html" = "index.html", "spending.html" = "index.html",
    "methods.html" = "about.html#editorial-standards",
    "articles/index.html" = "index.html")
  retired <- paste0("2026-general-md-", 1:3)
  for (i in seq_len(nrow(mapping))) {
    rows <- measures[measures$id == mapping$measure_id[i], , drop = FALSE]
    if (nrow(rows) == 1L) {
      target <- sub("\\.qmd(?=#|$)", ".html", rows$guide_path, perl = TRUE)
    } else if (!nrow(rows) && mapping$measure_id[i] %in% retired) {
      target <- "index.html"
    } else stop("Unresolved legacy mapping: ", mapping$old_id[i])
    expected[paste0("measures/", mapping$old_id[i], ".html")] <- target
  }
  pages <- parse_rendered_pages(root)
  for (old in names(expected)) {
    page <- file.path(root, old)
    if (!file.exists(page)) stop("Missing legacy redirect: ", old)
    document <- xml2::read_html(page)
    refresh <- xml2::xml_attr(xml2::xml_find_all(document, "//meta[@http-equiv='refresh']"), "content")
    if (length(refresh) != 1L || is.na(refresh) || !grepl("^0;[[:space:]]*url=", refresh)) stop("Invalid refresh: ", old)
    targets <- list(refresh = sub("^0;[[:space:]]*url=", "", refresh),
      canonical = xml2::xml_attr(xml2::xml_find_all(document, "//link[@rel='canonical']"), "href"),
      fallback = xml2::xml_attr(xml2::xml_find_all(document, "//body//a"), "href"))
    wanted <- split_local_url(expected[[old]])
    wanted_path <- normalizePath(file.path(root, wanted$path), mustWork = TRUE, winslash = "/")
    if (!is.null(wanted$fragment) && !wanted$fragment %in% pages[[wanted_path]]$ids) stop("Missing destination anchor: ", old)
    for (kind in names(targets)) {
      href <- targets[[kind]]
      if (length(href) != 1L || is.na(href) || !nzchar(href) || grepl("^[A-Za-z][A-Za-z0-9+.-]*:|^//|\\?", href)) stop("Invalid ", kind, " target: ", old)
      actual <- split_local_url(href)
      actual_path <- resolve_local_target(page, utils::URLdecode(actual$path), root)
      if (!identical(actual_path, wanted_path) || !identical(actual$fragment, wanted$fragment)) stop("Wrong ", kind, " destination: ", old)
    }
  }
  message("PASS: ", length(expected), " legacy redirects, refresh targets, canonical links, fallback links, and destination anchors.")
  invisible(TRUE)
}
if (sys.nframe() == 0L) validate_redirects()
