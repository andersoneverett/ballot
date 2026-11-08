#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(xml2))

SRC <- "data/charter.xml"
args <- commandArgs(trailingOnly = TRUE)
OUT <- if (length(args) > 0) args[[1]] else "charter"

CITY <- "https://codes.baltimorecity.gov/us/md/cities/baltimore/charter"
RELEASE <- "October 15, 2026 release (publication 2026-09-28)"
ARTICLE_META <- paste0(
  'toc: true\n',
  'toc-title: "In This Article"\n',
  'toc-depth: 3\n',
  'page-navigation: true\n'
)
CHANGED_2026 <- c("III", "IV", "VI")
DESC <- c(
  I = "Definitions, how the City holds property, and special funds such as the Children and Youth Fund and Inner Harbor Park.",
  II = "The long list of powers the City has, starting with regulating buildings.",
  III = "The City Council and its work, including its General Counsel.",
  IV = "The Mayor, including how the Mayor approves or vetoes legislation.",
  V = "The Comptroller's office.",
  VI = "The City budget and the Board of Estimates, including how contracts are bid and awarded.",
  VII = "The City's executive departments, such as Public Works, Law, the Fire Department and Legislative Reference.",
  VIII = "Franchises: how the City lets outside parties use public property.",
  IX = "Transition rules from the 1994 revision of the charter.",
  X = "The Office of the Inspector General.",
  XI = "The Charter Review Commission."
)

slug <- function(s) {
  s <- tolower(s %||% "")
  s <- gsub("[^a-z0-9]+", "-", s)
  gsub("^-+|-+$", "", s)
}

`%||%` <- function(x, y) {
  if (length(x) == 0 || is.na(x) || x == "") y else x
}

esc <- function(s) {
  s <- s %||% ""
  s <- gsub("&", "&amp;", s, fixed = TRUE)
  s <- gsub("<", "&lt;", s, fixed = TRUE)
  gsub(">", "&gt;", s, fixed = TRUE)
}

RAW_XML <- NULL

annotation_source_inner <- function(annotation) {
  children <- xml_children(annotation)
  marker <- if (length(children)) {
    tryCatch(xml_text(children[[1]], trim = FALSE), error = function(e) "")
  } else {
    tryCatch(xml_text(annotation, trim = FALSE), error = function(e) "")
  }
  marker <- trimws(marker)
  if (!nzchar(marker)) return(NULL)
  positions <- gregexpr(marker, RAW_XML, fixed = TRUE)[[1]]
  if (length(positions) == 1 && positions[[1]] == -1) return(NULL)
  for (pos in positions) {
    before <- substr(RAW_XML, 1, pos - 1)
    opens <- gregexpr("<annotation", before, fixed = TRUE)[[1]]
    if (length(opens) == 1 && opens[[1]] == -1) next
    open <- opens[[length(opens)]]
    after_open <- substr(RAW_XML, open, nchar(RAW_XML))
    gt <- regexpr(">", after_open, fixed = TRUE)[[1]]
    if (gt == -1) next
    start <- open + gt
    after_marker <- substr(RAW_XML, pos, nchar(RAW_XML))
    close <- regexpr("</annotation>", after_marker, fixed = TRUE)[[1]]
    if (close == -1) next
    close_abs <- pos + close - 2
    if (close_abs >= start) return(substr(RAW_XML, start, close_abs))
  }
  NULL
}

source_inner <- function(el) {
  if (is.null(RAW_XML)) return(NULL)
  name <- tryCatch(xml_name(el), error = function(e) "")
  if (!nzchar(name) || name == "annotation") return(NULL)
  marker <- tryCatch(xml_text(el, trim = FALSE), error = function(e) "")
  marker <- trimws(marker)
  if (!nzchar(marker)) return(NULL)
  positions <- gregexpr(marker, RAW_XML, fixed = TRUE)[[1]]
  if (length(positions) == 1 && positions[[1]] == -1) return(NULL)
  closing <- paste0("</", name, ">")
  for (pos in positions) {
    opening <- paste0("<", name)
    opens <- gregexpr(opening, RAW_XML, fixed = TRUE)[[1]]
    if (length(opens) == 1 && opens[[1]] == -1) next
    starts_before <- opens[opens < pos]
    if (!length(starts_before)) next
    start_tag <- starts_before[[length(starts_before)]]
    start_end <- regexpr(">", substr(RAW_XML, start_tag, nchar(RAW_XML)), fixed = FALSE)[[1]]
    if (start_end == -1) next
    start <- start_tag + start_end
    closes <- gregexpr(closing, RAW_XML, fixed = TRUE)[[1]]
    if (length(closes) == 1 && closes[[1]] == -1) next
    closes_after <- closes[closes > pos]
    if (!length(closes_after)) next
    close_abs <- closes_after[[1]] - 1
    if (close_abs >= start) return(substr(RAW_XML, start, close_abs))
  }
  NULL
}

cite_href <- function(path) {
  parts <- if (is.null(path) || is.na(path) || path == "") {
    character()
  } else {
    trimws(strsplit(path, "|", fixed = TRUE)[[1]])
  }
  parts <- parts[nzchar(parts)]
  if (!length(parts)) {
    return(NULL)
  }
  href <- paste0("article-", slug(parts[[1]]), ".html")
  if (length(parts) > 1) {
    href <- paste0(href, "#s-", slug(gsub("\u00a7", "", parts[[2]], fixed = TRUE)))
  }
  href
}

inline <- function(el) {
  children <- xml_children(el)
  if (length(children) > 0) {
    inner <- source_inner(el)
    if (is.null(inner)) {
      raw <- as.character(el)
      inner <- sub("^<[^>]+>", "", raw)
      inner <- sub("</[^>]+>$", "", inner)
    }
    for (child in children) {
      child_name <- xml_name(child)
      child_raw <- as.character(child)
      child_inner <- inline(child)
      if (child_name == "cite") {
        href <- cite_href(xml_attr(child, "path"))
        child_inner <- if (is.null(href)) child_inner else sprintf('<a href="%s">%s</a>', esc(href), child_inner)
      }
      inner <- gsub(child_raw, child_inner, inner, fixed = TRUE)
    }
    return(inner)
  }
  out <- character()
  for (node in xml_contents(el)) {
    node_name <- xml_name(node)
    if (node_name == "text") {
      out <- c(out, esc(xml_text(node)))
    } else {
      inner <- inline(node)
      if (node_name == "cite") {
        href <- cite_href(xml_attr(node, "path"))
        if (!is.null(href)) {
          out <- c(out, sprintf('<a href="%s">%s</a>', esc(href), inner))
        } else {
          out <- c(out, inner)
        }
      } else {
        out <- c(out, inner)
      }
    }
  }
  paste0(out, collapse = "")
}

label <- function(el) {
  num_node <- xml_find_first(el, "./num")
  head_node <- xml_find_first(el, "./heading")
  num <- if (inherits(num_node, "xml_missing")) "" else xml_text(num_node)
  head <- if (inherits(head_node, "xml_missing")) "" else xml_text(head_node)
  c(num = num %||% "", head = head %||% "")
}

render_blocks <- function(el, depth = 0) {
  parts <- character()
  for (child in xml_children(el)) {
    t <- xml_name(child)
    if (t %in% c("prefix", "num", "heading", "meta")) {
      next
    }
    if (t == "text") {
      parts <- c(parts, paste0("<p>", if (length(xml_children(child))) inline(child) else xml_text(child), "</p>"))
    } else if (t == "para") {
      info <- label(child)
      lead <- ""
      if (nzchar(info[["num"]])) {
        lead <- paste0(lead, '<span class="charter-num">', esc(info[["num"]]), '</span> ')
      }
      if (nzchar(info[["head"]])) {
        lead <- paste0(lead, '<span class="charter-subhead">', esc(info[["head"]]), '</span> ')
      }
      parts <- c(parts, paste0('<div class="charter-para charter-depth-', min(depth + 1, 4), '">'))
      if (nzchar(lead)) {
        parts <- c(parts, paste0("<p>", trimws(lead), "</p>"))
      }
      parts <- c(parts, render_blocks(child, depth + 1))
      parts <- c(parts, "</div>")
    } else if (t == "annotations") {
      items <- character()
      kinds <- character()
      for (annotation in xml_children(child)) {
        if (xml_name(annotation) == "annotation") {
          inner <- annotation_source_inner(annotation)
          if (is.null(inner)) {
            raw <- as.character(annotation)
            inner <- sub("^<annotation[^>]*>", "", raw)
            inner <- sub("</annotation>$", "", inner)
          }
          inner <- gsub("</?text>", "", inner, perl = TRUE)
          cites <- xml_find_all(annotation, ".//cite")
          if (length(cites)) {
            for (cite_node in cites) {
              cite_raw <- as.character(cite_node)
              href <- cite_href(xml_attr(cite_node, "path"))
              cite_inner <- esc(xml_text(cite_node))
              replacement <- if (is.null(href)) cite_inner else sprintf('<a href="%s">%s</a>', esc(href), cite_inner)
              inner <- gsub(cite_raw, replacement, inner, fixed = TRUE)
            }
          }
          items <- c(items, inner)
          kinds <- c(kinds, xml_attr(annotation, "type") %||% "Note")
        }
      }
      if (length(items)) {
        parts <- c(parts, paste0(
          '<p class="charter-history"><strong>',
          esc(paste(sort(unique(kinds)), collapse = ", ")),
          ':</strong> ',
          paste(items, collapse = "; "),
          "</p>"
        ))
      }
    } else {
      txt <- trimws(inline(child))
      if (nzchar(txt)) {
        parts <- c(parts, paste0("<p>", txt, "</p>"))
      }
    }
  }
  paste(parts[nzchar(parts)], collapse = "\n")
}

collect <- function(container, trail = character()) {
  out <- list()
  for (child in xml_children(container)) {
    t <- xml_name(child)
    if (t == "section") {
      out[[length(out) + 1]] <- list(trail = trail, section = child)
    } else if (t == "container") {
      info <- label(child)
      pre_node <- xml_find_first(child, "./prefix")
      pre <- if (inherits(pre_node, "xml_missing")) "" else xml_text(pre_node)
      heading <- trimws(paste(pre, info[["num"]]))
      if (nzchar(info[["head"]])) {
        heading <- paste0(heading, if (nzchar(heading)) " \u2014 " else " \u2014 ", info[["head"]])
      }
      out <- c(out, collect(child, c(trail, heading)))
    }
  }
  out
}

front <- function(title, extra = "") {
  title <- gsub('"', "'", title, fixed = TRUE)
  paste0("---\ntitle: \"", title, "\"\n", extra, "---\n\n")
}

full_note <- function() {
  paste0(
    "::: {.charter-note}\n",
    "Source: [City of Baltimore Law Library](", CITY, "), ", RELEASE, ". ",
    "This copy is for reading and searching and is not the official version. ",
    "Charter amendments adopted after this release, including the November 2026 ballot questions, ",
    "may not appear yet.\n:::\n\n"
  )
}

short_note <- function(num) {
  extra <- if (num %in% CHANGED_2026) {
    " Parts of this article were changed by the November 2026 ballot questions and may not appear here yet."
  } else {
    ""
  }
  paste0(
    "::: {.charter-note}\n",
    "Source: [City of Baltimore Law Library](", CITY, "/", num, "), ", RELEASE, ".", extra,
    "\n:::\n\n"
  )
}

card <- function(num, head, href, n) {
  desc <- unname(DESC[num])
  if (length(desc) == 0 || is.na(desc)) desc <- ""
  paste0(
    '<a class="charter-card" href="', href, '">',
    '<span class="charter-card-kicker">Article ', esc(num), '</span>',
    '<span class="charter-card-title">', esc(head), '</span>',
    '<span class="charter-card-text">', esc(desc), '</span>',
    '<span class="charter-card-meta">', n, ' section', if (n == 1) "" else "s", '</span></a>'
  )
}

landing <- function(rows) {
  out <- c(
    front("Charter of Baltimore City", "page-navigation: true\n"),
    full_note(),
    paste0(
      "The Charter is Baltimore's governing document, often described as the City's constitution. ",
      "Browse by article below, or use the search box in the left menu to find a word or phrase, ",
      "such as \"lowest bidder\" or \"Board of Estimates\".\n"
    ),
    "## Browse by article\n"
  )
  cards <- paste(
    vapply(rows, function(row) card(row$num, row$head, row$href, row$n), character(1)),
    collapse = "\n"
  )
  out <- c(out, paste0("```{=html}\n<div class=\"charter-grid\">\n", cards, "\n</div>\n```\n"))
  paste(out, collapse = "\n")
}

write_utf8 <- function(path, content) {
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeLines(content, con = con, sep = "", useBytes = TRUE)
}

if (!file.exists(SRC)) {
  stop("Missing data/charter.xml", call. = FALSE)
}

root <- read_xml(SRC)
xml_ns_strip(root)
RAW_XML <- paste(readLines(SRC, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
articles <- xml_find_all(root, "/document/container")
if (length(articles) == 0) {
  stop("No articles found in charter.xml", call. = FALSE)
}

dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
old <- list.files(OUT, pattern = "\\.qmd$", full.names = TRUE, recursive = FALSE)
if (length(old)) unlink(old)

rows <- list()
total <- 0
for (article in articles) {
  prefix_node <- xml_find_first(article, "./prefix")
  prefix <- if (inherits(prefix_node, "xml_missing")) "Article" else xml_text(prefix_node)
  if (!nzchar(prefix %||% "")) prefix <- "Article"
  info <- label(article)
  num <- info[["num"]]
  head <- info[["head"]]
  title <- trimws(paste(prefix, num))
  if (nzchar(head)) title <- paste0(title, if (nzchar(title)) " \u2014 " else "", head)

  sections <- collect(article)
  total <- total + length(sections)
  page <- c(
    front(title, ARTICLE_META),
    short_note(num)
  )
  last <- NULL
  for (entry in sections) {
    trail <- entry$trail
    if (!is.null(trail) && length(trail) > 0 && !identical(trail, last)) {
      page <- c(page, paste0("\n## ", paste(trail, collapse = " / "), "\n"))
    }
    last <- trail

    section <- entry$section
    section_info <- label(section)
    section_num <- section_info[["num"]]
    section_head <- section_info[["head"]]
    page <- c(
      page,
      paste0("\n### \u00a7 ", section_num, ". ", section_head, " {#s-", slug(section_num), "}\n"),
      paste0("```{=html}\n", render_blocks(section), "\n```\n")
    )
  }

  name <- paste0("article-", slug(num), ".qmd")
  write_utf8(file.path(OUT, name), paste(page, collapse = "\n"))
  rows[[length(rows) + 1]] <- list(
    num = num,
    head = head,
    href = sub("\\.qmd$", ".html", name),
    n = length(sections)
  )
}

write_utf8(file.path(OUT, "index.qmd"), landing(rows))
cat(sprintf("Wrote %d articles, %d sections\n", length(articles), total))
