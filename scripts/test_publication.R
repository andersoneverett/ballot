source("R/publication.R")
normalize <- function(x) trimws(gsub("[[:space:]]+", " ", paste(x, collapse = " ") ))
m <- read_measures()
stopifnot(nrow(m) > 0L)
for (i in seq_len(nrow(m))) {
  r <- m[i, ]
  lines <- readLines(r$text_path, encoding = "UTF-8", warn = FALSE)
  quoted <- sub("^> ?", "", lines[startsWith(lines, ">")])
  extracted <- official_narrative(r$text_path)$paras
  stopifnot(length(extracted) > 0L, identical(normalize(quoted), normalize(extracted)))
  question <- paste(capture.output(measure_question(r)), collapse = "\n")
  for (paragraph in extracted) stopifnot(grepl(paragraph, question, fixed = TRUE))
  if (nzchar(r$outcome)) {
    result <- paste(capture.output(measure_result(r)), collapse = "\n")
    stopifnot(grepl(paste0('datetime="', r$results_checked, '"'), result, fixed = TRUE))
    stopifnot(!grepl("NaN|Inf%", result))
  }
}
f <- m[m$cycle_id == "2026-general" & m$letter == "F", , drop = FALSE]
stopifnot(nrow(f) == 1L)
f_text <- paste(official_narrative(f$text_path)$paras, collapse = "\n\n")
for (date in c("November 7, 2028", "December 5, 2028", "December 3, 2026")) stopifnot(grepl(date, f_text, fixed = TRUE))
stopifnot(grepl("Voting for", f_text, fixed = TRUE), grepl("Voting against", f_text, fixed = TRUE))
g <- m[m$cycle_id == "2026-general" & m$letter == "G", , drop = FALSE]
stopifnot(nrow(g) == 1L)
g_text <- paste(official_narrative(g$text_path)$paras, collapse = "\n\n")
stopifnot(grepl("LEGISLATION, BUDGET, AND BOARD OF ESTIMATES\n\nQuestion G", g_text, fixed = TRUE))
g_page <- paste(capture.output(measure_question(g)), collapse = "\n")
stopifnot(grepl("Source note:", g_page, fixed = TRUE))
zero <- f
zero$for_votes <- "0"; zero$against_votes <- "0"; zero$outcome <- "Failed"
zero_result <- paste(capture.output(measure_result(zero)), collapse = "\n")
stopifnot(grepl("No votes reported", zero_result, fixed = TRUE), !grepl("NaN|vote-bar|Failed", zero_result))
message("Publication regression checks passed for ", nrow(m), " measures.")
