# Project Status

## Publication

Baltimore City guides cover 2024 Questions A–H and 2026 Questions A–I. The backfill is complete. Results remain Certified for 2024 and Unofficial for the 2026 snapshot; implementation remains Not assessed. No election data or official quotations change in the visual update.

## Legacy Retirement

The forwarding system is removed: e60f67f retired the hook, workflow check, test requirements, and documentation policy; fe8ef85, 90bf350, and 650d5c6 deleted the generator, dedicated checker, and URL mapping. Old URLs may return Not Found. Current guide URLs and anchors remain. CI clears generated docs/ before rendering.

## Coordinated Visual Update

Home, Ballot Guides, and About now share the article layout and standard title/subtitle treatment. The homepage introduces the publication, links to guides, explains ballot origins using the City election board's records, and frames follow-through as work to investigate rather than completed reporting. About holds the formal information.

Shared styling uses black and gold as the dominant identity, with purple accents on white pages. The footer provides publication identity and Home, Ballot Guides, and About links; its editorial-standards link is removed. Election-guide question structure, result components, metadata, and official-wording disclosures are retained. DESIGN.md records this direction.

## Verification

README.md remains the canonical local verification guide. This visual change requires its own CI/deployment check and desktop/mobile browser review. No local R/Quarto execution, rendered-browser review, or contrast-test pass is claimed from this chat environment. Prior user-reported passes apply to their own checkpoints, not automatically to this update.

## Deferred

Filters, new coverage, implementation research, data-reuse refactoring, and dormant research-validation enhancements remain outside this update. Do not reopen completed ballot research or restore retired routes.
