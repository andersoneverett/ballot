original <- getwd()
sandbox <- tempfile("ballot-tests-")
dir.create(sandbox)
assert_pass <- function(x) stopifnot(isTRUE(x))
assert_fails <- function(expression) {
  failed <- FALSE
  tryCatch(expression, error = function(e) failed <<- TRUE)
  stopifnot(failed)
}
write_table <- function(name, data) write.csv(data, file.path("data", paste0(name, ".csv")), row.names = FALSE, na = "")
md5_files <- function(directory) {
  files <- sort(normalizePath(list.files(directory, recursive = TRUE, full.names = TRUE), winslash = "/", mustWork = TRUE))
  hashes <- tools::md5sum(files)
  names(hashes) <- substring(files, nchar(normalizePath(directory, winslash = "/")) + 2)
  hashes
}
tryCatch({
  production_hashes <- md5_files("data")
  for (folder in c("R", "scripts", "data", "elections", "_ballot_text", "articles")) if (dir.exists(folder)) stopifnot(file.copy(folder, sandbox, recursive = TRUE))
  setwd(sandbox)
  source("R/publication.R", local = .GlobalEnv)
  output <- function(fn) paste(capture.output(fn()), collapse = "\n")
  validate <- function() source("scripts/check.R", local = new.env())
  empty_results <- data.frame(measure_id = character(), outcome = character(), status = character(), for_votes = character(), against_votes = character(), checked_date = character(), source_id = character())
  write_table("results", empty_results)
  articles <- read_data("articles"); write_table("articles", articles[FALSE, , drop = FALSE])
  validate()
  id <- read_data("measures")$id[1]
  assert_pass(is.null(result_record(id)))
  assert_pass(grepl("Results not yet recorded.", output(function() measure_vote_share(id)), fixed = TRUE))
  assert_pass(html_escape('<script>"&') == '&lt;script&gt;&quot;&amp;')
  assert_pass(identical(output(latest_articles), ""))
  checked <- format(Sys.Date(), "%Y-%m-%d")
  fixture_source <- data.frame(source_id = "test-result", title = "Synthetic <record>", publisher = "Test Fixture", url = "https://example.org/test", published_date = "", accessed_date = checked, notes = "fixture", stringsAsFactors = FALSE)
  write_table("sources", rbind(read_data("sources"), fixture_source))
  counts <- data.frame(measure_id = id, outcome = "Passed", status = "Unofficial", for_votes = "6000", against_votes = "4000", checked_date = checked, source_id = "test-result", stringsAsFactors = FALSE)
  write_table("results", counts); validate()
  result <- result_record(id)
  assert_pass(result$for_pct == 60 && result$against_pct == 40 && result$margin_pp == 20)
  html <- output(function() ballot_explanation(id))
  for (phrase in c("Passed", "Unofficial Results", "60.0%", "6,000", "Synthetic &lt;record&gt;")) assert_pass(grepl(phrase, html, fixed = TRUE))
  assert_pass(!grepl("Certified Results", html, fixed = TRUE))
  certified <- counts; certified$status <- "Certified"
  write_table("results", certified); validate()
  assert_pass(grepl("Certified Results", output(function() measure_vote_share(id)), fixed = TRUE))
  no_counts <- counts; no_counts$for_votes <- ""; no_counts$against_votes <- ""; no_counts$outcome <- "Failed"
  write_table("results", no_counts); validate()
  html <- output(function() measure_vote_share(id))
  assert_pass(grepl("Failed", html, fixed = TRUE))
  assert_pass(!grepl("NaN|NA|vote-bar|result-counts", html))
  assert_pass(!result_record(id)$has_counts)
  for (field in c("for_votes", "against_votes")) {
    invalid <- counts; invalid[[field]] <- "-1"; write_table("results", invalid); assert_fails(validate())
    invalid <- counts; invalid[[field]] <- ""; write_table("results", invalid); assert_fails(validate())
  }
  invalid <- counts; invalid$for_votes <- "0"; invalid$against_votes <- "0"; write_table("results", invalid); assert_fails(validate())
  invalid <- counts; invalid$status <- "Unknown"; write_table("results", invalid); assert_fails(validate())
  invalid <- counts; invalid$source_id <- "missing-source"; write_table("results", invalid); assert_fails(validate())
  invalid <- counts; invalid$checked_date <- ""; write_table("results", invalid); assert_fails(validate())
  invalid <- counts; invalid$checked_date <- format(Sys.Date() + 1, "%Y-%m-%d"); write_table("results", invalid); assert_fails(validate())
  write_table("results", rbind(counts, counts)); assert_fails(validate())
  write_table("results", counts)
  dir.create("articles/test-report", recursive = TRUE, showWarnings = FALSE)
  writeLines("Test report", "articles/test-report/index.qmd")
  cycle <- read_data("measures")$cycle_id[1]
  write_table("articles", data.frame(article_id = "test-report", title = "Test Report", description = "Synthetic article", date = checked, path = "articles/test-report/index.qmd", author = "Test Author", cycle_id = cycle, status = "published", stringsAsFactors = FALSE))
  validate()
  assert_pass(grepl("Reporting &amp; Analysis", output(latest_articles), fixed = TRUE))
  assert_pass(grepl("Test Report", output(latest_articles), fixed = TRUE))
  cycles <- read_data("elections")
  cycles$published <- "false"; cycles$published[1] <- "true"
  extra <- cycles[1, , drop = FALSE]
  extra$cycle_id <- "2096-test"; extra$year <- "2096"; extra$election_date <- "2096-11-06"; extra$title <- "2096 Test Election"; extra$path <- "elections/2096/test/index.qmd"; extra$published <- "true"
  draft <- extra; draft$cycle_id <- "2098-test"; draft$year <- "2098"; draft$election_date <- "2098-11-04"; draft$title <- "2098 Unpublished Election"; draft$path <- "elections/2098/test/index.qmd"; draft$published <- "false"
  for (path in c(extra$path, draft$path)) { dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE); stopifnot(file.copy(cycles$path[1], path)) }
  write_table("elections", rbind(cycles, extra, draft)); validate()
  assert_pass(nrow(published_elections()) == 2L)
  assert_pass(grepl("2096 Test Election", output(election_index), fixed = TRUE))
  assert_pass(grepl("2096 Test Election", output(featured_election), fixed = TRUE))
  assert_pass(!grepl("2098 Unpublished Election", output(election_index), fixed = TRUE))
  check_env <- new.env(parent = globalenv()); source("scripts/check-render.R", local = check_env)
  root <- file.path(sandbox, "utility-docs")
  dir.create(file.path(root, "guide"), recursive = TRUE, showWarnings = FALSE)
  writeLines('<html><body><a href="#valid">Same</a><a href="target%20page.html?view=1#good">Cross</a><a href="guide/">Directory</a><a href="mailto:test@example.org">Mail</a><a href="https://example.org">Web</a><p id="valid">Valid R &amp; D</p><script>RStudio</script></body></html>', file.path(root, "index.html"))
  writeLines('<html><body><p id="good">Good</p></body></html>', file.path(root, "target page.html"))
  writeLines('<html><body></body></html>', file.path(root, "guide", "index.html"))
  pages <- check_env$parse_rendered_pages(root)
  key <- normalizePath(file.path(root, "index.html"), winslash = "/", mustWork = TRUE)
  assert_pass(grepl("&", pages[[key]]$text, fixed = TRUE))
  assert_pass(!grepl("RStudio", pages[[key]]$text, fixed = TRUE))
  assert_pass(check_env$validate_local_links(root, pages))
  for (href in c("missing.html", "#missing", "target%20page.html#missing")) {
    writeLines(sprintf('<html><body><a href="%s">Bad</a></body></html>', href), file.path(root, "index.html"))
    assert_fails(check_env$validate_local_links(root))
  }
  writeLines('<html><body>{{< include "missing.qmd" >}}</body></html>', file.path(root, "index.html"))
  assert_fails(check_env$parse_rendered_pages(root))
  redirect_env <- new.env(parent = globalenv()); source("scripts/write-redirects.R", local = redirect_env)
  cases <- list(c("legacy/page.html", "guide/page.html#section", "../guide/page.html#section"), c("old.html", "about.html", "about.html"), c("nested/old.html", "elections/2026/general/index.qmd#question-a", "../elections/2026/general/index.html#question-a"), c("plain.html", "elections/2026/general/index.qmd", "elections/2026/general/index.html"))
  for (case in cases) {
    redirect_env$destination(case[1], case[2], root)
    html <- paste(readLines(file.path(root, case[1]), warn = FALSE), collapse = "\n")
    assert_pass(grepl(paste0("url=", case[3]), html, fixed = TRUE))
    assert_pass(grepl(paste0('href="', case[3], '"'), html, fixed = TRUE))
  }
  assert_pass(grepl("&amp;", redirect_env$html_escape("guide?a=1&b=2"), fixed = TRUE))
  redirect_env$write_redirects(root, file.path(sandbox, "data"))
  for (path in c("guide/index.html", "methods.html", "measures/md-1.html")) assert_pass(file.exists(file.path(root, path)))
  assert_pass(isTRUE(all.equal(production_hashes, md5_files(file.path(original, "data")))))
  message("PASS: optional counts, unofficial and certified outcomes, validation, HTML, redirects, and data isolation.")
}, finally = { setwd(original); unlink(sandbox, recursive = TRUE) })
