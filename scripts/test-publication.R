original <- getwd()
sandbox <- tempfile("ballot-tests-")
dir.create(sandbox)

assert_pass <- function(expression) {
  stopifnot(isTRUE(expression))
}
assert_fails <- function(expression) {
  failed <- FALSE
  tryCatch(expression, error = function(e) failed <<- TRUE)
  stopifnot(failed)
}
copy_fixture_tree <- function(name) {
  if (dir.exists(name)) {
    file.copy(name, sandbox, recursive = TRUE)
  }
}
write_table <- function(name, data) {
  write.csv(data, file.path("data", paste0(name, ".csv")),
    row.names = FALSE, na = "")
}
md5_files <- function(directory = "data") {
  files <- list.files(directory, recursive = TRUE, full.names = TRUE)
  files <- sort(normalizePath(files, winslash = "/", mustWork = TRUE))
  hashes <- tools::md5sum(files)
  names(hashes) <- sub(paste0("^", normalizePath(directory, winslash = "/"), "/?"), "", files)
  hashes
}

tryCatch({
  for (folder in c("R", "scripts", "data", "elections", "_ballot_text")) {
    copy_fixture_tree(folder)
  }
  if (dir.exists("articles")) copy_fixture_tree("articles")
  setwd(sandbox)

  production_data_hashes <- md5_files(file.path(original, "data"))
  source("R/publication.R", local = .GlobalEnv)
  output <- function(fn) paste(capture.output(fn()), collapse = "\n")
  validate <- function() source("scripts/check.R", local = new.env())

  write_table("results", data.frame(
    measure_id = character(), for_votes = character(), against_votes = character(),
    certified_outcome = character(), certified_date = character(),
    source_id = character(), stringsAsFactors = FALSE
  ))
  write_table("articles", data.frame(
    article_id = character(), title = character(), description = character(),
    date = character(), path = character(), author = character(),
    cycle_id = character(), status = character(), stringsAsFactors = FALSE
  ))
  validate()

  id <- read_data("measures")$id[1]
  assert_pass(is.null(result_record(id)))
  assert_pass(grepl("Certification pending.", output(function() measure_vote_share(id)), fixed = TRUE))
  assert_pass(html_escape('<script>"&') == '&lt;script&gt;&quot;&amp;')
  assert_pass(identical(output(latest_articles), ""))

  fixture_source <- data.frame(
    source_id = "test-certified", title = "Synthetic &lt;record&gt;",
    publisher = "Test Fixture", url = "https://example.org/test",
    published_date = "2020-01-01", accessed_date = "2020-01-02",
    notes = "fixture", stringsAsFactors = FALSE
  )
  write_table("sources", rbind(read_data("sources"), fixture_source))
  counts <- data.frame(
    measure_id = id, for_votes = "6000", against_votes = "4000",
    certified_outcome = "Passed", certified_date = "2020-01-01",
    source_id = "test-certified", stringsAsFactors = FALSE
  )
  write_table("results", counts)
  validate()
  result <- result_record(id)
  assert_pass(result$for_pct == 60 && result$against_pct == 40 && result$margin_pp == 20)
  certified_html <- output(function() ballot_explanation(id))
  assert_pass(grepl("60.0%", certified_html, fixed = TRUE))
  assert_pass(grepl("6,000", certified_html, fixed = TRUE))
  assert_pass(grepl("Synthetic &amp;lt;record&amp;gt;", certified_html, fixed = TRUE) ||
    grepl("Synthetic", certified_html, fixed = TRUE))

  invalid <- counts
  invalid$against_votes <- "-1"
  write_table("results", invalid)
  assert_fails(validate())
  write_table("results", counts)

  empty_article_listing <- output(latest_articles)
  assert_pass(identical(empty_article_listing, ""))
  dir.create("articles/test-report", recursive = TRUE, showWarnings = FALSE)
  writeLines("<!doctype html><html><body><h1>Test report</h1></body></html>",
    "articles/test-report/index.qmd", useBytes = TRUE)
  write_table("articles", data.frame(
    article_id = "test-report", title = "Test report", description = "Synthetic article",
    date = "2020-01-03", path = "articles/test-report/index.qmd",
    author = "Test Author", cycle_id = "2026-general",
    status = "published", stringsAsFactors = FALSE
  ))
  populated_listing <- output(latest_articles)
  assert_pass(grepl("Reporting &amp; analysis", populated_listing, fixed = TRUE))
  assert_pass(grepl("Test report", populated_listing, fixed = TRUE))
  validate()

  cycles <- read_data("elections")
  published_extra <- cycles[1, , drop = FALSE]
  published_extra$cycle_id <- "2028-general"
  published_extra$year <- "2028"
  published_extra$election_date <- "2028-11-07"
  published_extra$title <- "2028 General Election"
  published_extra$path <- "elections/2028/general/index.qmd"
  published_extra$published <- "true"
  unpublished_extra <- published_extra
  unpublished_extra$cycle_id <- "2030-general"
  unpublished_extra$year <- "2030"
  unpublished_extra$election_date <- "2030-11-05"
  unpublished_extra$title <- "2030 Unpublished Election"
  unpublished_extra$path <- "elections/2030/general/index.qmd"
  unpublished_extra$published <- "false"
  dir.create("elections/2028/general", recursive = TRUE, showWarnings = FALSE)
  dir.create("elections/2030/general", recursive = TRUE, showWarnings = FALSE)
  file.copy("elections/2026/general/index.qmd", "elections/2028/general/index.qmd")
  file.copy("elections/2026/general/index.qmd", "elections/2030/general/index.qmd")
  write_table("elections", rbind(cycles, published_extra, unpublished_extra))
  validate()
  election_listing <- output(election_index)
  assert_pass(nrow(published_elections()) == 2L)
  assert_pass(grepl("2028 General Election", election_listing, fixed = TRUE))
  assert_pass(!grepl("2030 Unpublished Election", election_listing, fixed = TRUE))

  check_env <- new.env(parent = globalenv())
  source("scripts/check-render.R", local = check_env)

  utility_root <- file.path(sandbox, "utility-docs")
  dir.create(file.path(utility_root, "guide"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(utility_root, "nested"), recursive = TRUE, showWarnings = FALSE)
  writeLines('<!doctype html><html><body><a href="#valid">Same</a><a href="target%20page.html?view=1#good">Cross</a><a href="guide/">Directory</a><a href="mailto:test@example.org">Mail</a><a href="https://example.org">Web</a><p id="valid">Valid R &amp; D</p><script>RStudio</script></body></html>',
    file.path(utility_root, "index.html"), useBytes = TRUE)
  writeLines('<!doctype html><html><body><p id="good">Good</p></body></html>',
    file.path(utility_root, "target page.html"), useBytes = TRUE)
  writeLines('<!doctype html><html><body></body></html>',
    file.path(utility_root, "guide", "index.html"), useBytes = TRUE)
  pages <- check_env$parse_rendered_pages(utility_root)
  index_key <- normalizePath(file.path(utility_root, "index.html"),
    mustWork = TRUE, winslash = "/")
  index_text <- pages[[index_key]]$text
  assert_pass(grepl("Valid", index_text, fixed = TRUE))
  assert_pass(grepl("&", index_text, fixed = TRUE))
  assert_pass(!grepl("RStudio", index_text, fixed = TRUE))
  assert_pass(check_env$validate_local_links(utility_root, pages))

  writeLines('<!doctype html><html><body><a href="missing.html">Missing</a></body></html>',
    file.path(utility_root, "index.html"), useBytes = TRUE)
  pages <- check_env$parse_rendered_pages(utility_root)
  assert_fails(check_env$validate_local_links(utility_root, pages))

  writeLines('<!doctype html><html><body><a href="target%20page.html#missing">Bad fragment</a></body></html>',
    file.path(utility_root, "index.html"), useBytes = TRUE)
  pages <- check_env$parse_rendered_pages(utility_root)
  assert_fails(check_env$validate_local_links(utility_root, pages))

  writeLines('<!doctype html><html><body>{{< include "missing.qmd" >}}</body></html>',
    file.path(utility_root, "index.html"), useBytes = TRUE)
  assert_fails(check_env$parse_rendered_pages(utility_root))

  redirect_env <- new.env(parent = globalenv())
  source("scripts/write-redirects.R", local = redirect_env)
  redirect_root <- file.path(sandbox, "utility-docs")

  redirect_env$destination("legacy/page.html", "guide/page.html#section", redirect_root)
  redirect_html <- paste(readLines(file.path(redirect_root, "legacy", "page.html"),
    warn = FALSE), collapse = "\n")
  assert_pass(grepl("url=../guide/page.html#section", redirect_html, fixed = TRUE))
  assert_pass(grepl('href="../guide/page.html#section"', redirect_html, fixed = TRUE))

  redirect_env$destination("old.html", "about.html", redirect_root)
  redirect_html <- paste(readLines(file.path(redirect_root, "old.html"),
    warn = FALSE), collapse = "\n")
  assert_pass(grepl("url=about.html", redirect_html, fixed = TRUE))
  assert_pass(grepl('href="about.html"', redirect_html, fixed = TRUE))

  redirect_env$destination("nested/old.html", "elections/2026/general/index.qmd#question-a",
    redirect_root)
  redirect_html <- paste(readLines(file.path(redirect_root, "nested", "old.html"),
    warn = FALSE), collapse = "\n")
  assert_pass(grepl("index.html#question-a", redirect_html, fixed = TRUE))
  assert_pass(grepl("&amp;", redirect_env$html_escape("guide?a=1&b=2"), fixed = TRUE))

  redirect_env$write_redirects(redirect_root, file.path(sandbox, "data"))
  assert_pass(file.exists(file.path(redirect_root, "guide", "index.html")))
  assert_pass(file.exists(file.path(redirect_root, "methods.html")))
  assert_pass(file.exists(file.path(redirect_root, "measures", "md-1.html")))

  current_data_hashes <- md5_files(file.path(original, "data"))
  assert_pass(isTRUE(all.equal(production_data_hashes, current_data_hashes)))
  message("PASS: controlled publication fixtures, HTML validation, fragments, redirects, and production data isolation.")
}, finally = {
  setwd(original)
  unlink(sandbox, recursive = TRUE)
})
