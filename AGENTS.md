# Baltimore Ballot: notes for people and AI assistants

Plain-language guides to Baltimore City ballot questions, built with Quarto and R and published with GitHub Pages. Readers are residents, so clarity and neutrality matter more than cleverness.

## Where things live

- `data/measures.csv` is the only place measure facts are entered: one row per ballot question. Pages are generated from it by `R/publication.R`. Never type measure facts into a `.qmd` page.
- `scripts/build_measures.R` writes one page per measure (`elections/<year>/<type>/question-<letter>/`) and `scripts/build_charter.R` writes the charter pages. Both run before `quarto render`, and their output is not committed. Run them before `quarto preview`.
- `data/sources.csv` holds each source once (title, publisher, URL, dates, notes). `data/elections.csv` holds one row per election.
- `_ballot_text/` holds the official question wording, copied exactly from the official source, including apparent errors. Do not edit or "fix" it.
- `styles.css` is the only stylesheet. Colors are named once at the top (`--bb-*`); do not type hex colors elsewhere.
- Run `Rscript scripts/check.R` before committing. Errors must be fixed; notes about empty fields are reminders, not failures. Links are checked weekly by `.github/workflows/links.yml`.
- Search is site-wide (top menu). Pages are searchable by default.
- Page addresses are permanent. Never rename or reuse a measure's address; if a page must move, leave a redirect.

## Writing summaries

- Plain language, short sentences, about an 8th grade reading level. Say what a vote FOR and a vote AGAINST would do.
- Neutral. Never endorse, recommend a vote, or use loaded words.
- An approved measure is an election outcome, not proof that anything was built, funded, or carried out. Do not repeat disclaimers on pages; the About page and footer carry them.
- Keep the existing wording style and capitalization of titles.

## Arguments, dates, and money

- Fill `effective`, `fiscal_impact`, `arguments_for`, and `arguments_against` only from sources that were actually read. If the source is unclear, leave the cell blank.
- Name the outlet or person inside the sentence (for example "told WYPR"). Attribute claims to whoever made them, and label estimates as estimates.
- Include real criticism and real support, in roughly equal depth.
- Prefer government records, the official election site, and public media. Avoid paywalled sources.
- Never invent quotes, numbers, or dates.

## Results

- Vote counts come from the State Board of Elections results page named in `sources.csv`. When refreshing, update every affected row and the source's refresh time in `sources.csv`.
- `status` is Unofficial until certified results are published.

## Keywords

- `keywords` are 2 to 8 everyday words or phrases a resident might search for, separated by semicolons (for example "baby bonus"). They differ from `topics`, which is a fixed list. They appear on the measure page as "Also known as".

## Changing the code

- A new `measures.csv` column needs three edits: `measure_columns` in `R/publication.R`, the page display (`measure_page` in `R/publication.R`), and a rule in `scripts/check.R`.
- Keep it simple. Do not add files, columns, or options that nothing uses.
