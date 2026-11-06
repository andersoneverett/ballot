# Maintaining Election Results

Results are maintained manually. Unofficial and Certified describe source status, not permission to publish.

## Columns

data/results.csv has one row per measure:

- measure_id: existing cycle-scoped ID from measures.csv.
- outcome: Passed or Failed, supported by the source. Omit unresolved outcomes rather than inventing them.
- status: Unofficial or Certified, matching the source.
- for_votes and against_votes: optional nonnegative integer counts without commas. Supply both or leave both blank. Zero is a count, not missing data.
- checked_date: source-check date in YYYY-MM-DD form, on or after Election Day and not in the future. It is not a certification date.
- source_id: matching evidence in data/sources.csv supporting the outcome and supplied counts.

## Updating A Record

1. Inspect the source and register its URL, publisher, and actual access date.
2. Update the existing measure row, keeping its stable ID. An outcome may be published without counts or a certification date. Do not label unofficial returns Certified.
3. Follow README.md's Checks sequence, including clearing disposable docs/ output before rendering. Stop on failure. Compare rendered values with the source and do not commit docs/.
4. Change checked_date when rechecking and status only when supported by evidence.

## Display And Coverage

The display includes outcome, source status, checked date, and evidence. Counts, percentages, bars, and margins appear only when both counts exist. Shares use For plus Against, not all ballots. Rendering does not infer outcomes from counts. Missing records say Results not yet recorded; certification is not required to publish.

As of November 5, 2026, eight 2024 Baltimore City measures are recorded as Certified from final official returns and nine 2026 City measures as Unofficial. Consult sources.csv for limitations. Passage does not establish implementation, bond issuance, or spending.

## Geographic Data

Precinct data has a separate certified-data workflow. Geographic rows require jurisdiction counts for reconciliation; outcome-only records are insufficient. Citywide results do not imply that precinct records or implementation events have been imported.
