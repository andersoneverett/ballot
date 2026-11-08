# Builds the Charter pages (charter/*.qmd) from data/charter.xml. Runs before `quarto render`.
library(xml2)

out_dir <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[[1]] else "charter"
CITY <- "https://codes.baltimorecity.gov/us/md/cities/baltimore/charter"

`%||%` <- function(x, y) if (length(x) == 0 || is.na(x) || !nzchar(x)) y else x
slug <- function(s) gsub("^-+|-+$", "", gsub("[^a-z0-9]+", "-", tolower(s)))
esc <- function(s) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", s, fixed = TRUE), fixed = TRUE), fixed = TRUE)
txt <- function(el, path) {
  n <- xml_find_first(el, path)
  if (inherits(n, "xml_missing")) "" else xml_text(n)
}
kids <- function(el) as.list(xml_children(el))
title_of <- function(n) {
  t <- trimws(paste(txt(n, "./prefix"), txt(n, "./num")))
  h <- txt(n, "./heading")
  if (nzchar(h)) paste0(t, " \u2014 ", h) else t
}
front <- function(title, extra = "") {
  paste0('---\ntitle: "', gsub('"', "'", title), '"\nsearch: true\n', extra, "---\n")
}

if (!file.exists("data/charter.xml")) stop("Missing data/charter.xml")
release <- readLines("data/charter-release.txt", warn = FALSE, encoding = "UTF-8")
info <- read.csv("data/charter.csv", colClasses = "character", na.strings = "", encoding = "UTF-8")
root <- read_xml("data/charter.xml")
xml_ns_strip(root)
articles <- as.list(xml_find_all(root, "/document/container"))
if (!length(articles)) stop("No articles found in data/charter.xml")
nums <- vapply(articles, txt, "", "./num")

cite_href <- function(path) {
  p <- trimws(strsplit(path %||% "", "|", fixed = TRUE)[[1]])
  i <- match(p[1], nums)
  if (is.na(i)) return(NA_character_)
  paste0(sprintf("article-%02d.html", i),
         if (length(p) > 1 && nzchar(p[2])) paste0("#s-", slug(sub("\u00a7", "", p[2], fixed = TRUE))))
}

inline <- function(el) {
  parts <- lapply(as.list(xml_contents(el)), function(n) {
    type <- xml_type(n)
    if (type %in% c("text", "cdata")) return(esc(xml_text(n)))
    if (type != "element") return("")
    inner <- inline(n)
    href <- if (xml_name(n) == "cite") cite_href(xml_attr(n, "path")) else NA_character_
    if (is.na(href)) inner else sprintf('<a href="%s">%s</a>', href, inner)
  })
  paste(unlist(parts), collapse = "")
}

blocks <- function(el) {
  out <- vapply(kids(el), function(n) {
    switch(xml_name(n),
      text = paste0("<p>", inline(n), "</p>"),
      para = {
        num <- txt(n, "./num")
        hd <- txt(n, "./heading")
        lead <- trimws(paste0(c(if (nzchar(num)) paste0("<strong>", esc(num), "</strong> "), if (nzchar(hd)) esc(hd)), collapse = ""))
        paste0('<div class="charter-para">', if (nzchar(lead)) paste0("<p>", lead, "</p>"), blocks(n), "</div>")
      },
      annotations = {
        a <- kids(n)
        if (!length(a)) "" else paste0("<p><small>",
          paste(unique(vapply(a, function(x) xml_attr(x, "type") %||% "Note", "")), collapse = ", "), ": ",
          paste(vapply(a, inline, ""), collapse = "; "), "</small></p>")
      },
      prefix = , num = , heading = , meta = "",
      paste0("<p>", inline(n), "</p>"))
  }, "")
  paste(out[nzchar(out)], collapse = "\n")
}

sections <- function(node, trail = character()) {
  out <- list()
  for (n in kids(node)) {
    nm <- xml_name(n)
    if (nm == "section") {
      out[[length(out) + 1]] <- list(trail = trail, node = n)
    } else if (nm == "container") {
      out <- c(out, sections(n, c(trail, title_of(n))))
    }
  }
  out
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
unlink(list.files(out_dir, "[.]qmd$", full.names = TRUE))
meta <- 'toc: true\ntoc-title: "In This Article"\ntoc-depth: 3\npage-navigation: true\n'
counts <- integer(length(articles))

for (i in seq_along(articles)) {
  a <- articles[[i]]
  secs <- sections(a)
  counts[i] <- length(secs)
  note <- info$note[match(nums[i], info$num)] %||% ""
  page <- c(front(title_of(a), meta),
            sprintf("::: {.charter-note}\nSource: [City of Baltimore Law Library](%s/%s), %s. %s\n:::\n", CITY, nums[i], release[1], note))
  last <- character()
  for (s in secs) {
    if (length(s$trail) && !identical(s$trail, last)) {
      page <- c(page, paste0("\n## ", paste(s$trail, collapse = " / "), "\n"))
    }
    last <- s$trail
    num <- txt(s$node, "./num")
    page <- c(page,
              sprintf("\n### \u00a7 %s. %s {#s-%s}\n", num, txt(s$node, "./heading"), slug(num)),
              paste0("```{=html}\n", blocks(s$node), "\n```\n"))
  }
  writeLines(page, sprintf("%s/article-%02d.qmd", out_dir, i), useBytes = TRUE)
}

cards <- vapply(seq_along(articles), function(i) {
  d <- info$description[match(nums[i], info$num)] %||% ""
  sprintf('<a class="charter-card" href="article-%02d.html"><small>Article %s</small><b>%s</b><small>%s</small><small>%d section%s</small></a>',
          i, esc(nums[i]), esc(txt(articles[[i]], "./heading")), esc(d), counts[i], if (counts[i] == 1) "" else "s")
}, "")
landing <- c(
  front("Charter of Baltimore City", "page-navigation: true\n"),
  sprintf("::: {.charter-note}\nSource: [City of Baltimore Law Library](%s), %s. This copy is for reading and searching and is not the official version. %s\n:::\n", CITY, release[1], release[2] %||% ""),
  "The Charter is Baltimore's governing document, often described as the City's constitution. Browse by article below, or use the search box in the left menu to find a word or phrase, such as lowest bidder or Board of Estimates.\n",
  "## Browse by article\n",
  paste0('```{=html}\n<div class="charter-grid">\n', paste(cards, collapse = "\n"), "\n</div>\n```\n")
)
writeLines(landing, file.path(out_dir, "index.qmd"), useBytes = TRUE)
cat(sprintf("Wrote %d articles, %d sections\n", length(articles), sum(counts)))
