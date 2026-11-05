# Maintaining Election Results

Results are entered manually. There is no API or scheduled retrieval. Unofficial and Certified are descriptive source statuses, not permission to publish.

## Columns

`data/results.csv` contains one row per measure:

- `measure_id`: existing cycle-scoped ID from measures.csv.
- `outcome`: Passed or Failed, supported by the linked source. Do not invent a resolved outcome for an unresolved result; omit the row until one can be supported.
- `status`: Unofficial or Certified, matching the source.
- `for_votes` and `against_votes`: optional nonnegative integer counts, without commas. Supply both or leave both blank. Zero is a count, not a placeholder for unavailable data.
- `checked_date`: YYYY-MM-DD date when the source was checked, on or after Election Day and not in the future. This is not a certification date.
- `source_id`: a matching source in data/sources.csv supporting the outcome and any counts entered.

## Updating A Record

1. Inspect the source and register its URL, publisher, and actual access date in data/sources.csv.
2. Enter or update the measure's row. An outcome may be published without vote counts or a certification date. Label unofficial returns Unofficial; do not describe them as certified.
3. Run `Rscript scripts/test-publication.R`, `Rscript scripts/test-tags.R`, `quarto render`, and `Rscript scripts/check-render.R`. Compare rendered values with the source before pushing. Do not commit generated docs/.
4. When the source changes, update the same row and checked date. Change status to Certified only when supported by the source.

## Display

The page displays the outcome, source status, checked date, and evidence link. Counts, percentages, bars, and margins appear only when both counts are available. Shares use For plus Against votes, not all ballots. Outcomes are sourced, not inferred by the rendering function. Missing records say Results not yet recorded; they do not imply certification is required.

## Current Coverage

As of November 5, 2026, the result table contains eight 2024 Baltimore City measures recorded as Certified from final official returns and nine 2026 City measures recorded as Unofficial. Consult data/sources.csv for the precise source limitations. A checked date is not a certification date, and a passed measure is not an implementation finding.

## Geographic Data

The separate precinct dataset retains its certified geographic-data workflow. Geographic rows require jurisdiction-wide counts for reconciliation; an outcome-only record is insufficient for that calculation. The citywide result imports do not establish that precinct data or implementation events have been imported.
