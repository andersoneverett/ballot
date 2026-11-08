# Baltimore Ballot: notes for people and AI assistants

Plain-language guides to Baltimore City ballot questions, built with Quarto and R and published with GitHub Pages. Readers are residents, so clarity and neutrality matter more than cleverness. The site tracks sets of ballot measures (a "ballot"), not elections.

## Where things live

- `data/measures.csv` is the only place measure facts are entered: one row per ballot question. Pages are generated from it by `R/publication.R`. Never type measure facts into a `.qmd` page.
- `data/ballots.csv` has one row per ballot (title like "2026 Ballot", date, and a short narrative paragraph). The narrative is shown on the Ballot Guides page; write it from the data in `measures.csv` and update it if the data changes.
- `scripts/build_measures.R` writes one page per measure (`ballots/<year>/question-<letter>/`) and `scripts/build_charter.R` writes the charter pages. Both run before `quarto render`, and their output is not committed. Run them before `quarto preview`.
- `data/sources.csv` holds each source once (title, publisher, URL, dates, notes). Any link used in the arguments must be registered here; `check.R` enforces it, and the measure page lists those sources under Sources.
- `_ballot_text/` holds the official question wording, copied exactly from the official source, including apparent errors. Do not edit or "fix" it. The measure page shows only its central narrative (headings, the "Voting for/against" lines, and the For/Against choices are left out).
- `styles.css` is the only stylesheet. Colors are named once at the top (`--bb-*`); do not type hex colors elsewhere.
- Run `Rscript scripts/check.R` before committing. Errors must be fixed; notes about empty fields are reminders, not failures. Links are checked weekly by `.github/workflows/links.yml`.
- Search is site-wide (top menu). Pages are searchable by default.
- Page addresses are permanent. Never rename or reuse a measure's address; if a page must move, leave a redirect.

## Writing

- Plain language, short sentences, about an 8th grade reading level.
- `if_approved` states what would happen and the facts that go with it: amounts, dates, and who decides what. It does not repeat the official wording.
- Neutral. Never endorse, recommend a vote, or use loaded words.
- An approved measure is an election outcome, not proof that anything was built, funded, or carried out. Do not repeat disclaimers on pages; the About page and footer carry them.
- Keep the existing wording style and capitalization of titles.

## Arguments and sources

- `arguments_for` and `arguments_against` are markdown. Link each source where it is used, for example `[Nate Golden](https://example.org/story)`, and escape dollar signs as `\$`.
- Fill them only from sources that were actually read. Check each claim against the article before writing it, and attribute it to whoever made it. Label estimates as estimates.
- Prefer government records, the official election site, and public media. Avoid paywalled sources.
- Never invent quotes, numbers, or dates. If a source is unclear, leave the cell blank.

## Results

- Vote counts come from the State Board of Elections results page named in `sources.csv`. When refreshing, update every affected row and the source's refresh time in `sources.csv`.
- `status` is Unofficial until certified results are published. The Ballot Guides page shows each ballot's status line from these values.
- The side with more votes is gold; the other side is purple. Passed is gold; Failed is purple.

## Keywords

- `keywords` are 2 to 8 everyday words or phrases a resident might search for, separated by semicolons (for example "baby bonus"). They differ from `topics`, which is a fixed list. They appear at the bottom of the measure page as "Also known as".

## Changing the code

- A new `measures.csv` column needs three edits: `measure_columns` in `R/publication.R`, the page display (`measure_page` in `R/publication.R`), and a rule in `scripts/check.R`.
- Keep it simple. Do not add files, columns, or options that nothing uses.
