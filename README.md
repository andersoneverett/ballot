# Baltimore Ballot

Independent civic coverage of Baltimore elections and public decisions. Published at https://andersoneverett.github.io/ballot/ and authored in RStudio with Quarto.

## Reader-facing structure

Home, Ballot Guides, About, and published articles. The 2026 General Election guide contains Maryland Questions 1–3 and Baltimore City Questions A–I: neutral explanations, official wording, and certified results when available. The original personal guide and recommendations are removed. Former URLs redirect to the new guide or relevant publication page.

## RStudio setup

Clone https://github.com/andersoneverett/ballot in RStudio using File → New Project → Version Control → Git. Open publication.Rproj. Install rendering packages once with `install.packages(c("knitr", "rmarkdown"))` and install Quarto if needed.

Use `quarto preview` in the Terminal to review changes. Commit and push the source to main; GitHub Actions tests, renders, checks links, and deploys. Do not commit generated docs/.

## Add a future election

1. Add a `data/elections.csv` record with a unique cycle_id, year, election_type, election_date, title, permanent path, and published=true when ready. Guides live at `elections/YEAR/TYPE/index.qmd`. Register the guide before enabling it on the public site.
2. Add measure records with new cycle-scoped IDs such as `2028-general-baltimore-a`. Keep previous cycles intact. Add official wording under `_ballot_text/CYCLE/`. Copy the structure of the current cycle guide and use the new IDs and relative include paths. Each guide anchor must match guide_path in measures.csv.
3. Add verified source records and certified totals as they become available. The homepage features the most recent published cycle; the guide index retains every published cycle. Never replace an earlier guide to publish the next one.

## Articles and community perspectives

Copy templates/article.qmd to articles/SLUG/index.qmd. Write and source the story, set actual author/date, and remove draft:true only when ready. Register published articles in data/articles.csv (article_id, title, description, date, path, author, cycle_id, status=published). The homepage lists only actual published articles. With no published records, it shows no empty reporting section. Include officials and community voices through sourced reporting rather than fabricated profiles or a placeholder candidate directory.

## Results and research

See RESULTS_SETUP.md for certified results and DATA_GUIDE.md for geographic and spending research. Internal research tables are retained for articles; they are not public navigation destinations. Results share a stable measure_id with explanations and research. GUIDE_MAPPING.csv documents the migration from the starter’s IDs.

## Checks

Run `Rscript scripts/test-publication.R`, `quarto render`, and `python3 scripts/check-render.py`. R tests use a disposable fixture workspace; synthetic data never enters published research records. The render checker verifies required pages, guide anchors, official wording, absence of personal recommendations and setup language, working local links, and safe legacy redirects.

## Design

See DESIGN.md for official sources of the black/gold/white/gray palette. The publication uses its own wordmark and does not claim city affiliation.
