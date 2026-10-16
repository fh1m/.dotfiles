# Zondo asset provenance

Generated with the built-in imagegen tool on 17 October 2026. Reference images were this repository’s existing original fh1m character art. No API credentials or external paid asset pack is required. Raster assets live beside the QML that consumes them.

## Production atlas — zondo-life-v2.png

Initial prompt:

> Create a NEW production sprite atlas of Zondo, same cute chibi engineer character as reference: messy black hair, warm brown eyes, black hoodie with hot pink circuit details, hot pink headphones, sneakers. Exactly 4 columns by 4 rows equally sized square cells on transparent background, each character centered and fully contained within its own cell with generous padding, no grid, no text. Row 1 four consecutive dance frames: stepping left, arms up, stepping right, playful spin. Row 2 four relaxed different poses: reading a book, sipping mug, stretching arms, sitting gazing at a tiny star. Row 3 four playful different poses: juggling tiny gears, holding small underwater robot, paper airplane, sketching on pad. Row 4 four different explorer poses: looking through binoculars, watering tiny plant, air guitar, sleeping curled up. Crisp polished illustrated game sprite style matching reference. No laptop in any pose. Equal scale across all 16 cells. True transparent background.

Padding revision, using the initial atlas as reference:

> Edit this sprite sheet for production use. Preserve all sixteen characters, exact identities, colors and individual actions. Critical correction: place each complete figure into a STRICT mathematically uniform 4x4 grid of square cells, center each inside its cell, make every figure SMALLER so there is at least 15% transparent padding on every side of every cell, including accessories, stars, airplane, gears and music notes. No part of a sprite may touch its cell boundary or cross into neighboring cells. Each sprite full body, no cutoff hair or feet. Preserve genuinely transparent background, no grid lines, no text. All 16 cells exactly equal. Crisp game-ready artwork.

The generated image’s gutters are slightly uneven despite the prompt. Alpha inspection found transparent seams at x=313/627/945 and y=323/627/931 in the 1254px image. Native QML clip rectangles use those actual seams, rather than assuming perfect 313.5px cells. The bitmap is preserved; no synthetic redraw or background-removal script was used. The first atlas remains recoverable in Git history.

## Arrival scene — den-welcome-v1.png

> Use case illustration-story. Asset type widescreen welcome-card background for fh1m's Digital Den, used on Linux desktop at login/docking. Create a beautiful restrained 16:9 night engineering sanctuary, no text or logos: obsidian-black electronics workbench, subtle hot-pink circuit traces and tiny warm lights, underwater robotics prototype with two small thrusters, a rocket fin and sensor board on desk, multiple monitors with abstract dark geometry not legible UI. Cozy and optimistic, refined anime environment painting, left third mostly quiet dark negative space for code-rendered welcome text, right half detailed desk. No people. No frame or watermark. High craftsmanship, palette near-black warm ivory and raspberry pink, low brightness suitable for night use.

The welcome text is rendered by QML, not baked into the image. GTK/Qt controls remain native widgets and CSS/palette rules; bitmap art is not used as fake buttons.
