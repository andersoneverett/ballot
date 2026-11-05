# Validate the rendered public publication, including intentional empty states.

if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("The xml2 package is required. Install it locally and in CI with install.packages(\"xml2\").")
}

read_csv <- function(name, data_root = "data") {
  read.csv(file.path(data_root, paste0(name, ".csv")),
    stringsAsFactors = FALSE, colClasses = "character", na.strings = NULL,
    check.names = FALSE)
}

html_path <- function(path) sub("\\.qmd$", ".html", path)

parse_rendered_pages <- function(root) {
  html_files <- normalizePath(
    list.files(root, pattern = "\\.html$", recursive = TRUE, full.names = TRUE),
    mustWork = TRUE, winslash = "/"
  )
  pages <- list()

  for (page in html_files) {
    raw <- paste(readLines(page, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    if (grepl("{{< include", raw, fixed = TRUE)) {
      stop("Unexpanded include in ", page)
    }

    document <- xml2::read_html(raw, encoding = "UTF-8")
    removable <- xml2::xml_find_all(document, "//*[self::script or self::style]")
    if (length(removable)) xml2::xml_remove(removable)

    link_nodes <- xml2::xml_find_all(document, "//a[@href]")
    links <- xml2::xml_attr(link_nodes, "href")
    id_nodes <- xml2::xml_find_all(document, "//*[@id]")
    ids <- xml2::xml_attr(id_nodes, "id")
    details <- xml2::xml_find_all(document, "//details")
    body <- xml2::xml_find_first(document, "//body")
    visible_text <- if (inherits(body, "xml_node")) xml2::xml_text(body, trim = TRUE) else xml2::xml_text(document, trim = TRUE)
    visible_text <- gsub("\\s+", " ", visible_text, perl = TRUE)

    pages[[normalizePath(page, mustWork = TRUE, winslash = "/")]] <- list(
      links = links,
      ids = ids[!is.na(ids)],
      details = length(details),
      text = visible_text
    )
  }
  pages
}

split_local_url <- function(href) {
  before_fragment <- strsplit(href, "#", fixed = TRUE)[[1]][1]
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    sub("^.*#", "", href)
  } else {
    NULL
  }
  path <- sub("\\?.*$", "", before_fragment)
  list(path = path, fragment = fragment)
}

resolve_local_target <- function(source_page, path, root) {
  if (startsWith(path, "/ballot/")) {
    candidate <- file.path(root, sub("^/ballot/", "", path))
  } else if (startsWith(path, "/")) {
    candidate <- file.path(root, sub("^/", "", path))
  } else if (nzchar(path)) {
    candidate <- file.path(dirname(source_page), path)
  } else {
    candidate <- source_page
  }
  candidate <- normalizePath(candidate, mustWork = FALSE, winslash = "/")
  if (dir.exists(candidate)) candidate <- file.path(candidate, "index.html")
  if (endsWith(candidate, "/")) candidate <- paste0(candidate, "index.html")
  candidate
}

validate_local_links <- function(root, pages = NULL) {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  if (is.null(pages)) pages <- parse_rendered_pages(root)
  errors <- character()

  for (source_page in names(pages)) {
    for (href in pages[[source_page]]$links) {
      if (!nzchar(href) || startsWith(href, "//")) next
      if (grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href)) next

      parts <- split_local_url(href)
      path <- utils::URLdecode(parts$path)
      fragment <- if (!is.null(parts$fragment)) utils::URLdecode(parts$fragment) else NULL
      target <- resolve_local_target(source_page, path, root)

      if (!file.exists(target)) {
        errors <- c(errors, paste0(sub(paste0("^", root, "/?"), "", source_page), ": ", href))
        next
      }

      if (!is.null(fragment) && nzchar(fragment)) {
        target <- normalizePath(target, mustWork = TRUE, winslash = "/")
        if (!is.null(pages[[target]]) && grepl("\\.html$", target, ignore.case = TRUE)) {
          if (!fragment %in% pages[[target]]$ids) {
            errors <- c(errors, paste0(sub(paste0("^", root, "/?"), "", source_page), ": ", href))
          }
        } else if (grepl("\\.html$", target, ignore.case = TRUE)) {
          target_pages <- parse_rendered_pages(dirname(target))
          if (!fragment %in% target_pages[[target]]$ids) {
            errors <- c(errors, paste0(sub(paste0("^", root, "/?"), "", source_page), ": ", href))
          }
        }
      }
    }
  }
  if (length(errors)) stop("Broken local links: ", paste(unique(errors), collapse = "; "))
  invisible(TRUE)
}

validate_rendered_site <- function(root = "docs", data_root = "data") {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  cycles <- read_csv("elections", data_root)
  measures <- read_csv("measures", data_root)
  articles <- read_csv("articles", data_root)

  required <- c("index.html", "about.html", "elections/index.html")
  required <- c(required, html_path(cycles$path[cycles$published == "true"]))
  required <- c(required, html_path(articles$path[articles$status == "published"]))
  for (name in required) {
    if (!file.exists(file.path(root, name))) stop("Missing rendered page: ", name)
  }

  pages <- parse_rendered_pages(root)
  validate_local_links(root, pages)

  for (i in seq_len(nrow(cycles))) {
    if (cycles$published[i] != "true") next
    guide <- normalizePath(file.path(root, html_path(cycles$path[i])), mustWork = TRUE, winslash = "/")
    parsed <- pages[[guide]]
    cycle_measures <- measures[measures$cycle_id == cycles$cycle_id[i], , drop = FALSE]
    if (is.null(parsed) || parsed$details < nrow(cycle_measures)) {
      stop("Official wording missing from ", guide)
    }
    for (j in seq_len(nrow(cycle_measures))) {
      anchor <- sub("^.*#", "", cycle_measures$guide_path[j])
      if (!anchor %in% parsed$ids) stop("Missing guide anchor ", anchor)
    }
  }

  public_text <- paste(vapply(pages, function(page) page$text, character(1)), collapse = "\n")
  forbidden <- c("How I Would Vote", "Original recommendation", "LEAN YES", "Vote: YES", "RStudio", "Codex", "Next reporting step", "Opening research file")
  for (phrase in forbidden) {
    if (grepl(phrase, public_text, fixed = TRUE)) stop("Public copy contains retired language: ", phrase)
  }

  if (!any(articles$status == "published") && grepl("Reporting & analysis", public_text, fixed = TRUE)) {
    stop("Public copy contains an empty reporting section")
  }

  results <- read_csv("results", data_root)
  if (!nrow(results)) {
    guide_text <- character()
    for (i in seq_len(nrow(cycles))) {
      if (cycles$published[i] != "true") next
      guide <- file.path(root, html_path(cycles$path[i]))
      guide_page <- pages[[normalizePath(guide, mustWork = TRUE, winslash = "/")]]
      guide_text <- c(guide_text, guide_page$text)
    }
    if (!grepl("Certification pending.", paste(guide_text, collapse = "\n"), fixed = TRUE)) {
      stop("Missing pending-results copy")
    }
  }

  for (stale in c("guide/index.html", "tracker.html", "geography.html", "spending.html", "methods.html")) {
    if (!file.exists(file.path(root, stale))) stop("Missing legacy redirect ", stale)
  }
  message("PASS: ", length(required), " public pages, ", nrow(measures), " questions, local links, neutral copy, and legacy redirects.")
  invisible(TRUE)
}

if (sys.nframe() == 0L) validate_rendered_site()
