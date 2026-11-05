# Baltimore Ballot

Independent civic coverage of Baltimore City ballot decisions and what follows. Published at https://andersoneverett.github.io/ballot/ and authored in RStudio with Quarto.

## Reader-Facing Structure

Home, Ballot Guides, About, and real published articles. The registered guides cover Baltimore City Questions A–H in the 2024 General Election and A–I in the 2026 General Election. Each measure has a neutral explanation, expandable official wording, type and topic metadata, ballot-origin attribution, and recorded results. Statewide questions and candidate directories are outside the current scope.

The homepage features the latest published cycle; the guide index retains previous published cycles. The original personal recommendations are removed, and legacy redirects must be preserved. No empty reporting section appears when there are no published articles.

## RStudio Setup

Clone https://github.com/andersoneverett/ballot in RStudio using File → New Project → Version Control → Git. Open publication.Rproj. Install rendering packages once with `install.packages(c("knitr", "rmarkdown", "xml2"))` and install Quarto if needed.

Use `quarto preview` in the Terminal to review changes. GitHub Actions tests, renders, checks links, and deploys pushes to main; pull requests build without deployment. Do not commit generated docs/. A successful source commit alone does not confirm a successful build or deployment.

## Add An Election

1. Add a data/elections.csv record with a unique cycle_id, year, election_type, election_date, title, permanent path, and published=true when ready. Guides live at elections/YEAR/TYPE/index.qmd. Register the guide before enabling it publicly.
2. Add measures with new cycle-scoped IDs such as 2028-general-baltimore-a. Keep previous cycles intact. Add official wording under _ballot_text/CYCLE/ using lowercase filenames. Copy a current guide's helper calls and relative include paths. Every guide anchor must match guide_path in data/measures.csv.
3. Register supporting evidence in data/sources.csv and type/topic/origin metadata in data/measure_tags.csv. Use existing categories unless a taxonomy change is explicitly approved. See TAGGING.md.
4. Add sourced outcomes and any available counts in data/results.csv. Unofficial and Certified describe source status; neither is a publication gate. Keep checked dates distinct from certification dates.

## Articles And Community Perspectives

Copy templates/article.qmd to articles/SLUG/index.qmd. Write and source the story, set the actual author and date, and remove draft:true only when ready. Register published articles in data/articles.csv with article_id, title, description, date, path, author, cycle_id, and status=published. Include officials and community perspectives through sourced reporting, not fabricated profiles or placeholder directories.

## Results And Research

The 2024 City results use final official returns and are recorded as Certified; the 2026 City results currently use an Unofficial snapshot. See data/sources.csv for evidence and limitations and RESULTS_SETUP.md for maintenance. Never infer implementation, borrowing issuance, or spending from passage.

DATA_GUIDE.md covers geographic and spending research. Research tables support articles rather than empty public navigation destinations. Explanations, results, tags, and research join through stable measure IDs.

## Checks

Run these commands from the project root:

```sh
Rscript scripts/test-publication.R
Rscript scripts/test-tags.R
quarto render
Rscript scripts/check-render.R
```

Tests use disposable fixture workspaces; synthetic records must never enter production data. Render checks cover required pages, anchors, official wording, local links and fragments, entity decoding, and legacy redirects. Separately review desktop and mobile layouts, keyboard focus, expandable wording, result labels, and source links. Report checks that could not be run.

## Design

See DESIGN.md for the user-selected purple-led palette, white page background, and spacing-led layout. Keep rules and boxes sparse. Preserve explicit outcome and voting labels, responsive wrapping, and visible keyboard focus. The publication uses its own wordmark and does not claim city or team affiliation.

Filters remain intentionally deferred. Navigation changes are separate from content backfills and visual cleanup.
