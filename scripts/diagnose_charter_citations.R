library(xml2)
options(width = 200)
slug <- function(s) gsub("^-+|-+$", "", gsub("[^a-z0-9]+", "-", tolower(s)))
root <- read_xml("data/charter.xml"); xml_ns_strip(root)
arts <- xml_find_all(root, "/document/container")
num_of <- function(n) xml_text(xml_find_first(n, "./num"))
nums <- vapply(arts, num_of, "")
cat("Articles in order:", paste(nums, collapse = ", "), "\n\n")
targets <- lapply(arts, function(a) vapply(xml_find_all(a, ".//section"), function(s) slug(num_of(s)), ""))
for (i in seq_along(arts)) cat(sprintf("Article %s sections (%d): %s\n", nums[i], length(targets[[i]]), paste(targets[[i]], collapse = ", ")))
cat("\n")
cites <- xml_find_all(root, "//cite")
paths <- xml_attr(cites, "path")
rows <- list()
for (i in seq_along(cites)) {
  p <- paths[i]
  if (is.na(p) || !nzchar(trimws(p))) next
  parts <- trimws(strsplit(p, "|", fixed = TRUE)[[1]])
  a <- match(parts[1], nums)
  sec <- if (length(parts) > 1 && nzchar(parts[2])) slug(sub("\u00a7", "", parts[2], fixed = TRUE)) else ""
  status <- if (is.na(a)) "unknown article" else if (nzchar(sec) && !sec %in% targets[[a]]) "missing section" else "ok"
  from_section <- xml_text(xml_find_first(cites[[i]], "ancestor::section/num"))
  rows[[length(rows) + 1L]] <- data.frame(
    from_article = num_of(xml_find_first(cites[[i]], "ancestor::container[last()]")),
    from_section = ifelse(is.na(from_section), "", from_section),
    path = p, text = substr(xml_text(cites[[i]]), 1, 60), status = status,
    stringsAsFactors = FALSE)
}
tab <- if (length(rows)) do.call(rbind, rows) else data.frame()
cat("Citation status counts:\n"); print(table(tab$status))
cat("\nUnresolved citations:\n")
bad <- tab[tab$status != "ok", , drop = FALSE]
if (nrow(bad)) print(bad, row.names = FALSE) else cat("none\n")
cat("\nAll citations pointing at Article XI:\n")
xi <- tab[startsWith(tab$path, "XI"), , drop = FALSE]
if (nrow(xi)) print(xi, row.names = FALSE) else cat("none\n")
