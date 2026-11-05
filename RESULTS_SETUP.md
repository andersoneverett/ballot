# Preparing for certified results

The infrastructure is ready; the certified data has not been imported.

## What will populate

- Each election guide: For %, Against %, raw counts, certified outcome, margin, certification date, and evidence link.
- Questions without a certified row continue to say "Certification pending." They are never plotted as 0%.

## When the certified release is available

1. Verify the official record is certified, not an unofficial count or the certification of ballot wording. Add that specific record to `data/sources.csv` with its direct URL and actual access date. Preserve a local copy of the release for reproducibility where permitted.
2. Add one row per question to `data/results.csv`. Use the cycle-scoped IDs from `data/measures.csv`: `2026-general-md-1` through `2026-general-md-3` and `2026-general-baltimore-a` through `2026-general-baltimore-i`. Use integer counts without commas or percent signs. Do not enter a partial row for an unavailable result; omit it until complete.
3. Run `quarto render`, review totals against the official release and inspect the relevant election guide, then commit and push the source. GitHub Actions renders and deploys it; do not commit generated `docs/`.

## Result columns

| Column | Value |
|---|---|
| measure_id | Existing ID from measures.csv |
| for_votes | Complete certified For total for the measure's entire jurisdiction |
| against_votes | Complete certified Against total for the same scope |
| certified_outcome | Passed, Failed, or Pending determination, transcribed from the official result |
| certified_date | Actual certification date in YYYY-MM-DD format |
| source_id | Matching source_id in sources.csv supporting the certified counts, date, and outcome |

The CSV contains headers only until genuine certified data is available. Unavailable, blank, and zero are different. Enter zero only when the certified release explicitly reports zero. Do not add statewide totals to county subtotals or add an overall total to its voting-method components.

## Percentages

Shares use votes cast For or Against the question, not the number of ballots cast in the entire election. R calculates them from the counts and derives the margin from unrounded shares. Display rounding may differ from the official website's precision. The outcome comes from the certified record, not an automatic majority assumption.

## Future geographic analysis

If the final release includes precinct results, retain precinct codes as text (including leading zeros), jurisdiction, measure ID, and separate For/Against counts. Establish whether mail, provisional, and early votes are allocated to precincts or reported separately. Reconcile all included records to the certified jurisdiction totals before publishing a map. Geographic vote patterns describe places, not the voting behavior of individuals.

The official 2026 election-data index lists raw election data and precinct-reference resources, but its final general-election file format and coverage need to be inspected after release. This version does not guess column names, download URLs, certification dates, or geographic coverage.

## Codex handoff after release

"Read RESULTS_SETUP.md and the official certified release. Inspect the actual file format, build an importer mapping the 12 publication measures to complete jurisdiction totals, and reconcile the counts before writing data/results.csv. Preserve provenance and distinguish precinct rows from voting-method totals. Run R validation and a Quarto render; inspect the results pages. Do not publish unofficial data as certified."

## Checks and limits

The build validates unique measure IDs, source references, required fields, certification dates, nonnegative integer counts, and nonzero denominators. R/Quarto execution and visual render remain pending in this workspace. The code cannot establish that a source is genuinely certified: inspect that record before import. No scheduled retrieval has been activated. Publishing is automated on pushes to main after successful checks.
