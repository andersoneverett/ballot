# Write safe legacy redirects after Quarto renders the public publication.

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

relative_path <- function(from_file, to_file) {
  from_parts <- strsplit(sub("^/?", "", normalizePath(dirname(from_file), mustWork = FALSE, winslash = "/")), "/", fixed = TRUE)[[1]]
  to_parts <- strsplit(sub("^/?", "", normalizePath(dirname(to_file), mustWork = FALSE, winslash = "/")), "/", fixed = TRUE)[[1]]
  from_parts <- from_parts[nzchar(from_parts)]
  to_parts <- to_parts[nzchar(to_parts)]
  common <- 0L
  limit <- min(length(from_parts), length(to_parts))
  while (common < limit && from_parts[common + 1L] == to_parts[common + 1L]) common <- common + 1L
  parts <- c(rep("..", length(from_parts) - common))
  if (common < length(to_parts)) parts <- c(parts, to_parts[(common + 1L):length(to_parts)])
  parts <- c(parts, basename(to_file))
  paste(parts[nzchar(parts)], collapse = "/")
}

destination <- function(old, new, root) {
  old_path <- file.path(root, old)
  filename <- sub("\\.qmd$", ".html", sub("#.*$", "", new))
  anchor <- if (grepl("#", new, fixed = TRUE)) sub("^.*#", "", new) else NULL
  target <- file.path(root, filename)
  relative <- relative_path(old_path, target)
  if (!is.null(anchor)) relative <- paste0(relative, "#", anchor)
  relative <- html_escape(relative)
  dir.create(dirname(old_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(sprintf('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=%s"><link rel="canonical" href="%s"><title>Moved | Baltimore Ballot</title></head><body><p>This page has moved to <a href="%s">Baltimore Ballot</a>.</p></body></html>', relative, relative, relative),
    old_path, useBytes = TRUE)
}

write_redirects <- function(root = "docs", data_root = "data") {
  root <- normalizePath(root, mustWork = TRUE, winslash = "/")
  measures <- read.csv(file.path(data_root, "measures.csv"), stringsAsFactors = FALSE,
    colClasses = "character", na.strings = NULL, check.names = FALSE)
  mapping <- read.csv(file.path(data_root, "GUIDE_MAPPING.csv"), stringsAsFactors = FALSE,
    colClasses = "character", na.strings = NULL, check.names = FALSE)
  for (i in seq_len(nrow(mapping))) {
    match <- measures[measures$id == mapping$measure_id[i], , drop = FALSE]
    if (nrow(match) == 1L) {
      destination(paste0("measures/", mapping$old_id[i], ".html"),
        match$guide_path, root)
    }
  }
  destination("guide/index.html", "elections/2026/general/index.html", root)
  destination("tracker.html", "elections/2026/general/index.html", root)
  destination("geography.html", "index.html", root)
  destination("spending.html", "index.html", root)
  destination("methods.html", "about.html#editorial-standards", root)
  destination("articles/index.html", "index.html", root)
  invisible(TRUE)
}

if (sys.nframe() == 0L) write_redirects()
