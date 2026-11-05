# Verification status

Source prepared for the initial Baltimore Ballot build on 2026-11-05.

Local source checks cover guide coverage, source wording, YAML, relative page references, include paths, and tracker filter behavior. R and Quarto are unavailable in the preparation workspace, so the GitHub workflow performs the actual R tests, render, and generated-page checks. Inspect the workflow run for its current outcome.

Certified vote counts, precinct results, boundaries, crosswalks, spending, and implementation events have not been imported. Their empty states are intentional. The only source record currently registers the official ballot wording.

A successful build produces a preview artifact. Live publication additionally requires GitHub Pages enabled with GitHub Actions as its source and a successful deploy job.
