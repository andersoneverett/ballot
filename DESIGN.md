# Design Direction

Baltimore Ballot uses a user-selected purple-led palette. It is not restricted to an official city brand palette and uses no city seal, government lockup, or team logo.

## Palette

- Purple: #241773, specifically requested by Everett as Ravens purple. Use for identity, major headings, actions, and Charter Change accents.
- Gold: #FCB826. Use for limited civic accents and Bond badges.
- Teal: #0B5963. Use for links and For vote bars.
- Forest Green: #256047. Use for Passed labels and result borders.
- Brick Red: #A33D32. Use for Failed labels and result borders.
- Warm Paper: #F7F4ED. Use for the page background.
- Ink: #20272B. Use for primary text.
- Slate: #52616B. Use for supporting text and Against vote bars.
- Soft Rule: #D8DEDC. Use for separators; white #FFFFFF for result surfaces.
- Pale Gold #FFF0C7 and Pale Purple #EEEAF8 support readable type badges.

## Visual Hierarchy

Measure type is a compact badge. Topics are unboxed text separated by dots. Ballot origin is a linked attribution line. Election outcome is a larger word in its own result block. These are distinct information roles, not variations of the same pill.

Always retain explicit Passed/Failed and For/Against labels. Do not make color the only carrier of meaning or use red to imply that an Against vote is wrong. Preserve keyboard focus outlines and wrapping at narrow widths.

Calculated contrast ratios include white on purple 14.53:1, teal on paper 7.29:1, slate on paper 5.83:1, and purple on the badge backgrounds above 12:1. These checks do not replace rendered-page or accessibility review. R tests, Quarto rendering, and browser review must be reported separately from source inspection.
