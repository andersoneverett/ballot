# Design Direction

Baltimore Ballot uses black and Baltimore gold as the dominant identity, purple as a selective accent, and white page backgrounds. This replaces the earlier purple-led direction at the user's request. No city seals, government lockups, or team logos.

## Palette Roles

- Black/Ink #20272B: masthead and footer surfaces, headings, and primary text.
- Gold #FCB826: wordmark, restrained header/footer accents, primary guide action, active navigation on dark backgrounds, and Bond badge accents. Gold is not the default color for every link, heading, or marker; do not use it as small text on white.
- Purple #241773: selected hover states, Charter Change accents, table-of-contents selection, and focus on light backgrounds. It supplements rather than replaces the dominant identity.
- White #FFFFFF: page background and text on dark surfaces.
- Teal #0B5963: readable content links and For vote bars.
- Slate #52616B: supporting text and Against vote bars.
- Green #256047 and Brick #A33D32: explicit Passed and Failed labels.
- Pale gold #FFF0C7 and pale purple #EEEAF8: compact type badges. The subtle result surface remains #F8F7FC.

## Shared Structure

Home, Ballot Guides, and About use page-layout: article, body-classes: top-level, and Quarto's standard title/subtitle block. Keep their content left-aligned within the same article layout. Home is not a separate full-width hero system. Maintain consistent title placement, introductory text, spacing, and left edges.

Home explains the publication, directs readers to the current and historical guides, briefly explains ballot origins with evidence, and motivates follow-through. About holds ownership, independence, scope, sources, result terminology, corrections, limitations, and the meaning of we. The guide index is an election archive, not a second homepage.

The shared footer identifies the publication and provides Home, Ballot Guides, and About links. Do not restore an editorial-standards footer link. Formal standards live within About.

## Election Guides And Accessibility

Preserve the election guides' question structure, cycle URLs, anchors, result blocks, vote bars, type/topic/origin hierarchy, and native official-wording disclosures. Shared identity may change without rebuilding those components. No ballot data or official quotations change as part of a visual pass.

Use whitespace, typography, and alignment rather than repeated rules, boxes, or pills. Always retain explicit Passed/Failed and For/Against labels. Preserve mobile wrapping and visible keyboard focus; use gold focus outlines on dark header/footer surfaces and purple on white.

Inspect actual rendered desktop/mobile pages, keyboard interactions, and contrast before claiming visual verification. Source inspection and successful CI do not establish appearance or accessibility.
