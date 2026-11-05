# Verification Status

## Publication Baseline — November 5, 2026

Baltimore Ballot is a populated Baltimore City publication to refine, not a scaffold to rebuild. The 2024 backfill is complete; do not reopen completed research or replace historical records to update a later election.

- The 2024 General Election guide contains Questions A–H, added in 209f192 with explanations, official-wording includes, results, type/topic tags, ballot origins, and sources. Results are recorded as Certified from final official returns. The user confirmed their publication implementation; this is not a finding that the measures themselves have been implemented. No separate certification date is asserted.
- The 2026 guide retains Questions A–I and its Unofficial results snapshot. Source status and checked dates remain attached to the records.
- Implementation remains Not assessed. Passage is not evidence of spending, bond issuance, or completed projects.
- The visual direction remains white pages, purple identity, and spacing-led hierarchy from 5f33519. No subsequent cleanup is a redesign.

## Completed Repository Cleanup

- 13e7dd0 aligned results-policy copy, removed retired CSS-class documentation, and reused the gold design token.
- e03cf45 added explicit legacy-redirect destination validation before artifact upload and deployment.
- ef7f6f9 updated artifact and Pages actions for Node 24, pinned both jobs to Ubuntu 24.04, and retained hidden files in the Pages artifact.
- 05ee014, 0a88439, and ac24d2a removed only the unused 2026 statewide wording includes. Legacy mapping records and redirects remain. Baltimore City wording is retained.
- b1ec5b3 documented the complete local verification sequence and the limits of automated checks.
- 8081405 made standalone preview uploads PR-only; publishing runs retain the Pages artifact.
- 4e0184b enabled caching for knitr, rmarkdown, xml2, and required dependencies, retaining an explicit package-availability check and separate Quarto setup. Cache performance has not been measured in this chat.
- 3e769dd cleared nine obsolete 2026 next_milestone task notes without changing other measure fields or implementation status.

This closeout synchronizes maintenance documentation only. It does not change publication data, official quotations, anchors, navigation, design, or executable code.

## Verification Evidence And Limits

Commit contents and changed-file scopes were inspected through GitHub during the cleanup. R and Quarto were not executed in the chat environment.

The user explicitly reported that the e03cf45 run and redirect check passed, later reported that the README checkpoint b1ec5b3 passed, and reported that the dependency-caching update 4e0184b passed. The user subsequently confirmed completion of the milestone cleanup. These are user-reported outcomes, not independently retrieved Actions logs, timing measurements, or browser-review evidence. Do not extrapolate them to a later commit.

Live-page fetch attempts were unsuccessful, including a closeout attempt for the homepage, Ballot Guides index, and 2026 guide. Fetch failures do not establish an outage. No completed desktop/mobile visual review, keyboard interaction review, or contrast check is claimed. The closeout commit's own CI and deployment outcomes must be checked separately after it is committed.

## Release Checks

README.md's Checks section is the canonical local sequence. Run these commands in order from the project root, stopping on failure:

```sh
Rscript scripts/test-publication.R
Rscript scripts/test-tags.R
quarto render
Rscript scripts/check-render.R
Rscript scripts/check-redirects.R
```

Run rendered-output checks only after a successful render. GitHub Actions runs these checks before artifact uploads. Pull requests upload a downloadable preview without deployment; non-PR runs upload the Pages artifact and deploy. Inspect the run for the relevant commit rather than treating this document as a live build indicator. A successful commit is not proof of deployment.

Separately review the homepage, Ballot Guides index, and both election guides on desktop and mobile. Check white backgrounds, purple identity, reduced dividers, question separation, result labels and bars, source links, expandable wording, mobile wrapping, and visible keyboard focus. Automated disclosure counts do not compare quotations with source records or establish visual quality.

## Deferred Scope

The cleanup round is closed at the source/documentation level; visual review and the closeout commit's release outcome remain separate checkpoints. Filters and navigation changes remain intentionally deferred.

Render-scoped data reuse, shared-utility refactoring, and stronger dormant research validation are optional backlog items, not release blockers for the existing guides. Before using geographic, crosswalk, or spending data, revisit certification enforcement, geography references, coordinate validity, and cycle-to-guide consistency with fixtures. Precinct, boundary, spending, and implementation research remain separate workstreams, not unfinished backfill requirements. Do not delete intentional research tables, article templates, compatibility files, or theme overrides merely because they are currently quiet.
