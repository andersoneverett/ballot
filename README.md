# Baltimore Ballot

Independent civic coverage of Baltimore City ballot decisions and what follows. Published at https://andersoneverett.github.io/ballot/ and authored in RStudio with Quarto.

## Publication

Home, Ballot Guides, About, and real published articles. The election guides cover Baltimore City Questions A–H in 2024 and A–I in 2026, with neutral explanations, official wording, metadata, ballot origins, and sourced results. Statewide questions and candidate directories are outside scope. Empty reporting sections are not published.

Current election guides and their URLs are permanent historical records. Legacy routes from retired site structures are intentionally removed, with no forwarding pages. Old bookmarks may return Not Found.

## Local Setup

Clone the repository in RStudio and open publication.Rproj. Install Quarto and install the R packages with `install.packages(c("knitr", "rmarkdown", "xml2"))`. Use `quarto preview` from the project root. Project-owned processing and tests remain R-first. Do not commit generated docs/.

## Data And Publishing

- Register each election in data/elections.csv with a unique cycle_id and permanent elections/YEAR/TYPE/index.qmd path. Set published=true only when ready.
- Add new cycle-scoped measure IDs in data/measures.csv; never overwrite prior elections. Add official wording under _ballot_text/CYCLE/ and preserve quotations. Guide anchors must match guide_path.
- Attach evidence in data/sources.csv and type/topic/origin records in data/measure_tags.csv. See TAGGING.md; do not change the taxonomy without approval.
- Maintain outcomes and optional counts in data/results.csv following RESULTS_SETUP.md. The 2024 records are Certified from final official returns; 2026 retains an Unofficial snapshot. Checked dates are not certification dates. Passage is not implementation, issuance, or spending.
- Copy templates/article.qmd for real reporting, set author/date, remove draft:true when ready, and register published articles in data/articles.csv. Do not invent community perspectives or placeholder directories.
- DATA_GUIDE.md covers separate geographic and spending research. Stable measure IDs join the evidence.

## Checks

Run from the project root in this order, stopping if any command fails:

```sh
Rscript scripts/test-publication.R
Rscript scripts/test-tags.R
Rscript -e 'unlink("docs", recursive = TRUE)'
quarto render
Rscript scripts/check-render.R
```

The cleanup command deletes only generated docs/ output so retired pages cannot linger. Rendering validates production data first. Fixtures use temporary workspaces and must never alter production records. The rendered-site check validates required pages, guide anchors, disclosure counts, local links and fragments, entity decoding, and retired public copy. It does not compare every quotation with its source.

GitHub Actions uses cached R dependencies, runs tests, clears generated output, renders, and checks the site. Pull requests upload a downloadable preview without deploying; non-PR runs upload the Pages artifact and deploy. A successful commit is not proof of a successful release.

Separately review all top-level pages and both election guides on desktop/mobile, including keyboard focus, source links, results, wrapping, and expandable wording. Report source inspection, executed checks, user-reported outcomes, deployment, and visual review separately.

## Design And Scope

The requested next visual update uses black and Baltimore gold as the dominant identity with purple accents, consistent top-level page alignment, a rebuilt homepage, formal About content, and a simpler footer. The earlier purple-led direction is superseded; the visual implementation is a separate task. Preserve white backgrounds and the election-guide structure. No city or team logos. Filters and additional research remain deferred.
