# Baltimore Ballot data guide

All CSV identifiers are text. Preserve leading zeros. Measure IDs are cycle-scoped (for example, `2026-general-baltimore-a`), so prior cycles remain intact when a future election uses the same question letter. No results, geographic boundaries, or spending have been fabricated. Start with RESULTS_SETUP.md for certified jurisdiction totals.

## Geographic records

`precinct_results.csv` stores one complete certified For/Against total per measure and reporting unit across all included voting methods. Use `geography_type=precinct` for actual precincts; use `unallocated` for separately reported mail, provisional, early, or other votes that cannot be assigned to precincts. Assign stable geography IDs to these unallocated records and name their scope explicitly. Never count both an aggregate and its components.

Import a certified jurisdiction result first. The validator rejects geographic subtotals exceeding it; it does not treat smaller subtotals as complete coverage. Reconcile both option totals exactly before claiming complete coverage or interpreting a map as all votes. Record any missing voting methods in the article and retain source files.

`geographies.csv` records precinct and neighborhood identifiers, jurisdiction, names, boundary vintages, and boundary sources. Actual GeoJSON or other boundary files can be added once sourced and matched. The current code does not pretend to have boundaries or make a map without them.

`geographic_crosswalk.csv` records a precinct-to-neighborhood relationship and weight. Weights for each precinct must sum to one. Exact containment and area/population estimates must be distinguished. Do not label allocated neighborhood votes as observed votes. An area weight is not evidence that votes were uniformly distributed. No neighborhood vote allocation is performed automatically in this version.

## Spending records

Use one `spending.csv` row per documented financial transaction or action at a defined stage. `record_id` identifies the unique record; `project_id` groups successive actions for one project. Link each record to a measure only when the source establishes that funding connection. Preserve the funding source even when several programs support the same project.

Stages: Authorized, Budgeted, Awarded, Expended. A dollar progressing through stages is not new money each time. Do not sum across stages or mix cumulative snapshots with incremental transactions. For a later cumulative report, derive and document an increment or retain it outside this transaction ledger. Reversals may be negative and require a sourced explanation in accompanying reporting.

Record project name, agency, event date, amount in unformatted dollars, location name, location precision, service area, beneficiaries where known, and source ID. Use `site`, `area`, `citywide`, or `unspecified` for location precision. Latitude/longitude are optional paired fields allowed only for verified site points. Citywide or unknown spending must remain unmapped, not pinned to an arbitrary address.

A project’s address and its service area are different facts. Neighborhood support is not a criterion for deserving public investment. Differences between support and investment require context about need, eligibility, existing capital plans, service coverage, and implementation constraints before interpretation.

## Initial reporting scope

Begin with Baltimore City Question A (affordable housing): establish certified support first, then trace appropriations, awards, expenditures, and documented beneficiaries. No claim of passage or spending is made by the empty starter tables.
