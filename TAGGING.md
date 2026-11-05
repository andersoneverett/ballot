# Measure Type And Topic Tags

Tags are stored in data/measure_tags.csv, joined to data/measures.csv by the cycle-scoped measure_id. This avoids changing the existing explanations or result data. Each active measure needs exactly one tag record.

Use one measure_type: Bond or Charter Change. Use one to three topics separated by semicolons. Approved topic labels are listed in R/measure-tags.R. Keep every word capitalized in displayed labels. Topic assignments are editorial groupings; measure type describes the ballot instrument.

Election pages source R/publication.R and R/measure-tags.R, then call measure_tags(id) immediately before ballot_explanation(id). Reuse this pattern when adding 2024 or future cycles. Tags are descriptive labels, not links or filters.

Run Rscript scripts/test-tags.R alongside the existing publication tests before rendering. GitHub Actions runs both tests. No Python or new R package is required.
