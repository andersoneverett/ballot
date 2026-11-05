# Baltimore Ballot

Everett Anderson’s independent publication following ballot decisions, neighborhood support, and public investment in Baltimore, with relevant Maryland statewide coverage. Built with Quarto and R; written and analyzed in RStudio; hosted on GitHub Pages.

Repository: https://github.com/andersoneverett/ballot

Publication URL after Pages is enabled and deployment succeeds: https://andersoneverett.github.io/ballot/

## First-time setup in RStudio

1. Install R, RStudio, Git, and Quarto if needed. In RStudio choose File → New Project → Version Control → Git, paste the repository URL, and open the resulting project (`publication.Rproj`).
2. Run `install.packages(c("knitr", "rmarkdown"))` once in the R console. In RStudio’s Terminal run `quarto preview` to view the site locally. Stop preview with Ctrl+C.
3. Edit a `.qmd` article or CSV record, preview it, then commit and push from RStudio. GitHub Actions tests, renders, and deploys main automatically. Generated `docs/` is ignored and does not need to be committed.

GitHub repository Settings → Pages → Build and deployment → Source must be set to **GitHub Actions**. If that setting has not been enabled, the build still creates a downloadable preview artifact, but deployment needs the one-time setting. After enabling it, rerun the failed deployment job or use Actions → Build and publish Baltimore Ballot → Run workflow.

## Daily workflow

Write or edit content → `quarto preview` → `Rscript scripts/test-publication.R` → `quarto render` → commit and push. Pull requests run checks and produce a rendered artifact without deploying; pushes to main publish after checks pass.

## What is here

- Editorial home page, searchable measure tracker, geographic research page, spending ledger, reporting index, About and methods.
- Twelve measure files covering Maryland Questions 1–3 and Baltimore City Questions A–I.
- A ballot-only archive retaining the original guide’s opinions and explanations, annotated with all 12 official question entries and vote choices. Candidate commentary is outside the initial publication scope.
- Certified-count percentage and margin displays with support bars. No vote counts are invented.
- Geographic and financial records ready for sourced imports. No geographic boundaries or fake map points are supplied.
- An article template, RStudio project, validation, behavior tests, rendered-site checks, and build/deployment workflow.

## Data and reporting

Read `RESULTS_SETUP.md` for certified counts and `DATA_GUIDE.md` for precincts, neighborhood crosswalks, and spending. `data/results.csv` is the single source for certified counts and outcomes. Measures without certified records show "Awaiting certified results". Amounts transcribed from the old guide are not spending entries.

The first substantive spending case study will follow housing (Question A). Do not advance implementation status without a supporting event and source. The source registry records the official ballot wording; the other research tables start empty.

## Publish a new article

Copy `templates/article.qmd` to `articles/SHORT-SLUG/index.qmd`, write and source it, set the actual publication date, then remove `draft: true` when ready. Link the article from `articles/index.qmd`. Add `date-modified` and a correction note for subsequent factual corrections.

## Local checks

- `Rscript scripts/test-publication.R`: verifies rendering helpers, counts, margins, escaping, and validation failures using isolated synthetic test data; no example votes enter the publication.
- `quarto render`: validates source records and produces the static site in `docs/`.
- `python3 scripts/check-render.py`: checks generated pages, internal links, includes, empty states, and absence of fabricated results.

GitHub runs these commands on every push to main and every pull request. The code checks consistency, not whether a cited source actually supports a factual claim. Research still requires editorial verification.

## References

- https://quarto.org/docs/publishing/github-pages.html
- https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages
- https://elections.maryland.gov/elections/2026/ballot_questions.html
- https://elections.maryland.gov/elections/2026/General_results/index.html
