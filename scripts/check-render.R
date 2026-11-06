# Validate the rendered public publication, including intentional empty states.
if (!requireNamespace("xml2", quietly = TRUE)) stop("Install the xml2 package locally and in CI.")
read_csv <- function(name, data_root = "data") read.csv(file.path(data_root, paste0(name, ".csv")), stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL, check.names = FALSE)
html_path <- function(path) sub("\\.qmd$", ".html", path)
parse_rendered_pages <- function(root) {
  files <- normalizePath(list.files(root, pattern = "\\.html$", recursive = TRUE, full.names = TRUE), mustWork = TRUE, winslash = "/")
  pages <- list()
  for (page in files) {
    raw <- paste(readLines(page, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (grepl("{{< include", raw, fixed = TRUE)) stop("Unexpanded include in ", page)
    document <- xml2::read_html(raw, encoding = "UTF-8")
    xml2::xml_remove(xml2::xml_find_all(document, "//*[self::script or self::style]"))
    ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
    body <- xml2::xml_find_first(document, "//body")
    pages[[page]] <- list(links = xml2::xml_attr(xml2::xml_find_all(document, "//a[@href]"), "href"), ids = ids[!is.na(ids)], details = length(xml2::xml_find_all(document, "//details")), text = gsub("\\s+", " ", xml2::xml_text(body, trim = TRUE), perl = TRUE))
  }
  pages
}
split_local_url <- function(href) {
  marker <- regexpr("#", href, fixed = TRUE)[1]
  before <- if (marker > 0) substr(href, 1, marker - 1) else href
  fragment <- if (marker > 0) substring(href, marker + 1) else NULL
  list(path = sub("\\?.*$", "", before), fragment = fragment)
}
resolve_local_target <- function(source_page, path, root) {
  if (startsWith(path, "/ballot/")) candidate <- file.path(root, sub("^/ballot/", "", path))
  else if (startsWith(path, "/")) candidate <- file.path(root, sub("^/", "", path))
  else if (nzchar(path)) candidate <- file.path(dirname(source_page), path)
  else candidate <- source_page
  candidate <- normalizePath(candidate, mustWork = FALSE, winslash = "/")
  if (dir.exists(candidate)) candidate <- file.path(candidate, "index.html")
  candidate
}
validate_local_links <- function(root, pages = NULL) {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  if (is.null(pages)) pages <- parse_rendered_pages(root)
  errors <- character()
  for (page in names(pages)) for (href in pages[[page]]$links) {
    if (!nzchar(href) || startsWith(href, "//") || grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href)) next
    parts <- split_local_url(href)
    target <- resolve_local_target(page, utils::URLdecode(parts$path), root)
    broken <- !file.exists(target)
    if (!broken && !is.null(parts$fragment) && nzchar(parts$fragment) && grepl("\\.html$", target, ignore.case = TRUE)) {
      key <- normalizePath(target, mustWork = TRUE, winslash = "/")
      broken <- is.null(pages[[key]]) || !utils::URLdecode(parts$fragment) %in% pages[[key]]$ids
    }
    if (broken) errors <- c(errors, paste0(page, ": ", href))
  }
  if (length(errors)) stop("Broken local links: ", paste(unique(errors), collapse = "; "))
  invisible(TRUE)
}
validate_rendered_site <- function(root = "docs", data_root = "data") {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  cycles <- read_csv("elections", data_root); measures <- read_csv("measures", data_root); articles <- read_csv("articles", data_root)
  required <- c("index.html", "about.html", "elections/index.html", html_path(cycles$path[cycles$published == "true"]), html_path(articles$path[articles$status == "published"]))
  for (name in required) if (!file.exists(file.path(root, name))) stop("Missing rendered page: ", name)
  pages <- parse_rendered_pages(root)
  validate_local_links(root, pages)
  for (i in seq_len(nrow(cycles))) {
    if (cycles$published[i] != "true") next
    guide <- normalizePath(file.path(root, html_path(cycles$path[i])), mustWork = TRUE, winslash = "/")
    parsed <- pages[[guide]]
    rows <- measures[measures$cycle_id == cycles$cycle_id[i], , drop = FALSE]
    if (is.null(parsed) || parsed$details < nrow(rows)) stop("Official wording missing from ", guide)
    for (anchor in sub("^.*#", "", rows$guide_path)) if (!anchor %in% parsed$ids) stop("Missing guide anchor ", anchor)
  }
  text <- paste(vapply(pages, function(page) page$text, character(1)), collapse = "\n")
  for (phrase in c("How I Would Vote", "Original recommendation", "LEAN YES", "Vote: YES", "RStudio", "Codex", "Next reporting step", "Opening research file")) if (grepl(phrase, text, fixed = TRUE)) stop("Public copy contains retired language: ", phrase)
  if (!any(articles$status == "published") && grepl("Reporting & Analysis", text, fixed = TRUE)) stop("Public copy contains an empty reporting section")
  results <- read_csv("results", data_root)
  if (!nrow(results)) {
    for (i in seq_len(nrow(cycles))) {
      if (cycles$published[i] != "true" || !any(measures$cycle_id == cycles$cycle_id[i])) next
      key <- normalizePath(file.path(root, html_path(cycles$path[i])), mustWork = TRUE, winslash = "/")
      if (!grepl("Results not yet recorded.", pages[[key]]$text, fixed = TRUE)) stop("Missing empty-results copy in ", key)
    }
  }
  message("PASS: ", length(required), " public pages, ", nrow(measures), " questions, local links, and neutral copy.")
  invisible(TRUE)
}
if (sys.nframe() == 0L) validate_rendered_site()
