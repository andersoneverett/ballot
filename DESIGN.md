# Design Direction

Baltimore Ballot uses a user-selected purple-led palette on a clean white background. It is not restricted to an official city brand palette and uses no city seal, government lockup, or team logo.

## Palette

- Purple: #241773, requested as Ravens purple. Use for identity, major headings, actions, active navigation, and Charter Change accents.
- White: #FFFFFF. Use for the page background and navigation. Warm-paper page backgrounds are retired.
- Gold: #FCB826. Use sparingly, primarily for Bond badges rather than navigation divider lines.
- Teal: #0B5963. Use for links and For vote bars.
- Forest Green: #256047. Use for explicit Passed labels, not decorative result borders.
- Brick Red: #A33D32. Use for explicit Failed labels, not decorative result borders.
- Ink: #20272B. Use for primary text.
- Slate: #52616B. Use for supporting text and Against vote bars.
- Quiet Result Surface: #F8F7FC. Use to group result information without outlining each block.
- Soft Rule: #D8DEDC. Reserved for separators that carry a real structural purpose; do not add repeated rules to every section.
- Pale Gold #FFF0C7 and Pale Purple #EEEAF8 support compact type badges.

## Layout And Hierarchy

Use whitespace, typography, and consistent alignment as the primary section separators. Remove automatic heading rules, guide-list rules, article-list rules, the featured-guide top rule, decision-column rails, official-wording rules, result-card outlines, and the footer rule. Override the theme's h2 underline as well as project-defined h3 rules.

A restrained purple line at the top of navigation may remain as an identity accent. Active navigation, keyboard focus outlines, type-badge outlines, and the active table-of-contents indicator remain functional cues rather than decorative section dividers.

Measure type is a compact badge. Topics are unboxed text separated by dots. Ballot origin is a linked attribution line. Election outcome is a larger word grouped with its source status and vote information on a quiet surface. These are distinct information roles, not variations of the same pill.

## Accessibility And Review

Always retain explicit Passed/Failed and For/Against labels. Do not make color the only carrier of meaning or use red to imply that an Against vote is wrong. Preserve keyboard focus, native details disclosure, mobile wrapping, and readable source links.

Validate contrast against the actual white and result-surface backgrounds when reviewing visual changes. Previously documented paper-background ratios are not evidence of review for this direction. R tests, Quarto rendering, contrast checks, and desktop/mobile browser review must be reported separately from source inspection.
