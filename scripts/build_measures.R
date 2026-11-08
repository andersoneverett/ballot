# Builds one page per measure from data/measures.csv: elections/<year>/<type>/question-<letter>/index.qmd.
# Runs before `quarto render`. Generated pages are not committed.
source("R/publication.R")
m <- read_measures(); e <- read_data("elections")
unlink(Sys.glob("elections/*/*/question-*"), recursive = TRUE)
for (i in seq_len(nrow(m))) {
  r <- m[i, ]; el <- e[e$cycle_id == r$cycle_id, , drop = FALSE]
  stopifnot(nrow(el) == 1L)
  dir <- file.path(dirname(el$path), paste0("question-", tolower(r$letter)))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  page <- c("---", sprintf('title: "Question %s: %s"', r$letter, gsub('"', "'", r$title)), sprintf('subtitle: "%s"', gsub('"', "'", el$title)), "---", "", "```{r}", "#| results: asis", 'source("R/publication.R")', sprintf('measure_page("%s", "%s")', r$cycle_id, r$letter), "```")
  writeLines(page, file.path(dir, "index.qmd"), useBytes = TRUE)
}
cat(sprintf("Wrote %d measure pages\n", nrow(m)))
