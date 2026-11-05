# Measure Type, Origin, And Topic Metadata

Metadata is stored in data/measure_tags.csv and joined to measures by the cycle-scoped measure_id. Each active measure needs exactly one record.

Use one measure_type: Bond or Charter Change. This appears as a compact badge. Bond uses pale gold; Charter Change uses pale purple.

Use one ballot_origin: City Council–Referred or Citizen Petition. Origin identifies the formal ballot-placement route, not endorsements or implementation responsibility. Each origin requires origin_source_id referencing data/sources.csv. Render it as a plain attribution line linked to evidence, not another badge. For 2026, the city election board lists Council records for A-H and identifies I as proposed by voter petition.

Use one to three semicolon-separated topics from the vocabulary in R/measure-tags.R. Render topics as quiet text with dot separators, not boxed pills or filter links. Capitalize Every Word In Displayed Labels.

Election pages source R/publication.R and R/measure-tags.R, then call measure_tags(id) before ballot_explanation(id). This interface remains unchanged for the 2024 backfill.

Run Rscript scripts/test-tags.R with the publication tests before rendering. GitHub Actions already runs both. No new package, scripting runtime, or deployment setting is required.
