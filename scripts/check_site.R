# Checks HTML references in the rendered artifact; no external network requests.
library(xml2)

check_site <- function(root, prefix = "/ballot/") {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  pages <- list.files(root, pattern = "\\.html?$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (!length(pages)) stop("No rendered HTML pages found in ", root)
  errors <- character()
  cache <- new.env(parent = emptyenv())
  document <- function(path) {
    if (!exists(path, envir = cache, inherits = FALSE)) assign(path, read_html(path), envir = cache)
    get(path, envir = cache, inherits = FALSE)
  }
  fail <- function(page, url, reason) {
    errors <<- c(errors, sprintf("%s: %s [%s]", substring(page, nchar(root) + 2L), url, reason))
  }
  for (page in pages) {
    doc <- document(page)
    urls <- c(
      xml_attr(xml_find_all(doc, "//a[@href] | //area[@href] | //link[@href]"), "href"),
      xml_attr(xml_find_all(doc, "//script[@src] | //img[@src] | //iframe[@src] | //source[@src] | //video[@src] | //audio[@src] | //embed[@src]"), "src"),
      xml_attr(xml_find_all(doc, "//video[@poster]"), "poster"),
      xml_attr(xml_find_all(doc, "//object[@data]"), "data")
    )
    for (url in unique(urls[!is.na(urls)])) {
      url <- trimws(url)
      if (!nzchar(url) || startsWith(url, "//") || grepl("^[A-Za-z][A-Za-z0-9+.-]*:", url)) next
      fragment <- if (grepl("#", url, fixed = TRUE)) sub("^[^#]*#", "", url) else ""
      fragment <- sub(":~:.*$", "", fragment)
      path <- utils::URLdecode(sub("\\?.*$", "", sub("#.*$", "", url)))
      if (!nzchar(path)) {
        target <- page
      } else if (startsWith(path, "/")) {
        if (identical(path, sub("/$", "", prefix))) path <- paste0(path, "/")
        if (!startsWith(path, prefix)) {
          fail(page, url, "root-relative URL is outside the project site prefix")
          next
        }
        target <- file.path(root, substring(path, nchar(prefix) + 1L))
      } else {
        target <- file.path(dirname(page), path)
      }
      if (dir.exists(target)) target <- file.path(target, "index.html")
      if (!file.exists(target)) {
        fail(page, url, "missing local file")
        next
      }
      target <- normalizePath(target, winslash = "/", mustWork = TRUE)
      if (nzchar(fragment) && tolower(fragment) != "top" && grepl("\\.html?$", target, ignore.case = TRUE)) {
        dest <- document(target)
        ids <- c(xml_attr(xml_find_all(dest, "//*[@id]"), "id"), xml_attr(xml_find_all(dest, "//a[@name]"), "name"))
        if (!utils::URLdecode(fragment) %in% ids) fail(page, url, "missing HTML fragment target")
      }
    }
  }
  unique(errors)
}

self_test <- function() {
  root <- tempfile("site-check-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  dir.create(file.path(root, "nested"))
  writeLines('<html><body id="home"><a href="nested/#section">Nested</a><a href="/ballot/nested/index.html?view=1#section">Root</a><a href="#home">Here</a><a href="https://example.org/">External</a></body></html>', file.path(root, "index.html"))
  writeLines('<html><body id="section"><a href="../#home">Back</a></body></html>', file.path(root, "nested", "index.html"))
  stopifnot(length(check_site(root)) == 0L)
  writeLines('<html><body><a href="missing.html">Missing file</a><a href="nested/#absent">Missing anchor</a><script src="missing.js"></script></body></html>', file.path(root, "index.html"))
  errors <- check_site(root)
  stopifnot(length(errors) == 4L, sum(grepl("missing local file", errors, fixed = TRUE)) == 2L, sum(grepl("missing HTML fragment target", errors, fixed = TRUE)) == 2L)
  message("Rendered-site checker self-tests passed.")
}

args <- commandArgs(trailingOnly = TRUE)
if (identical(args, "--self-test")) {
  self_test()
} else {
  root <- if (length(args)) args[1] else "docs"
  prefix <- if (length(args) > 1L) args[2] else "/ballot/"
  errors <- check_site(root, prefix)
  if (length(errors)) {
    for (error in errors) message("ERROR: ", error)
    quit(status = 1)
  }
  message("Rendered HTML links and asset references validated in ", root, ".")
}
