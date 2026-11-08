# Builds one page per measure from data/measures.csv: ballots/<year>/question-<letter>/index.qmd.
# Runs before `quarto render`. Generated pages are not committed.
source("R/publication.R")
m <- read_measures(); b <- read_data("ballots")
unlink(Sys.glob("ballots/*/question-*"), recursive = TRUE)
for (i in seq_len(nrow(m))) {
  r <- m[i, ]; x <- b[b$cycle_id == r$cycle_id, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  dir <- file.path("ballots", x$year, paste0("question-", tolower(r$letter)))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  page <- c("---", sprintf('title: "Question %s: %s"', r$letter, gsub('"', "'", r$title)), sprintf('subtitle: "%s"', gsub('"', "'", x$title)), "body-classes: measure-page", "---", "", "```{r}", "#| results: asis", 'source("R/publication.R")', sprintf('measure_page("%s", "%s")', r$cycle_id, r$letter), "```")
  writeLines(page, file.path(dir, "index.qmd"), useBytes = TRUE)
}
cat(sprintf("Wrote %d measure pages\n", nrow(m)))
