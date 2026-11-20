# Guild Ball menu style — Codex handoff

Reference snapshot: `development/menu-polish`, commit `32f73150944dfa6b1e5b7b82c3d666c02644e3dc`; packaged 15 November 2026. Open **REFERENCES.html** for the labelled image gallery. PNGs are unchanged project captures, except **09**, the selected AI-generated Settings concept. Images demonstrate appearance; their example text, match data and dates are not requirements.

## Instruction to give the other agent

> Match these references using reusable components. Keep the normal-menu and Settings palettes separate. Reuse the supplied surfaces and fonts, preserve crisp corners, compact padding and native text/input. Show normal, hover, pressed, focus and disabled states. Check the result at 1280×720 and 1920×1080. Reproduce the visual language while adapting the content to the requested screen.

## Visual direction

**Normal menus and Profile:** a dark fantasy sports clubhouse: charcoal panels, raised blue controls, muted brass trim, chamfered corners and small asymmetric corner brackets. Ivory text and condensed headings provide hierarchy. Use the same treatment for contextual action dialogs.

**Settings only:** warm instrument/leather-like faces, fine inset seams, restrained bevels, cream text/grips and burnt-orange accents. Apply this skin to Controls, Display and Sound. Profile retains the ordinary stock style.

| Token | Normal menus / Profile | Settings |
|---|---|---|
| Panel | `#0B151E` | `#292624` |
| Control face | `#365569` | `#57514C` |
| Main accent | `#DFB36C` brass | `#C66B37` burnt orange |
| Text | `#F3ECDB` ivory | `#F0E5CE` cream |
| Focus | `#FFF0C4` | `#F0E5CE` |

Settings headings/active highlights also use `#E28C54`. Preserve guild colours on identity and game information.

## Components and sizing

- Use **Barlow Condensed** regular and semibold; supplied Phosphor supplies icons. Keep both font licences. Typical dialog sizes: 30px heading, 20px body/control text, 17–18px supporting text, measured in Godot logical pixels.
- Stock roles: **Essential** brass for final confirmations/submission/activation; **Primary** blue for ordinary actions; **Secondary** for navigation; **Danger** restrained oxblood for destructive or explicit skip choices. Tabs have a selected state. Focus is a separate outline.
- Buttons use **6px horizontal / 3px vertical content padding**. Stock panel content uses **8px / 6px**. Let text determine width. Ordinary dialog buttons are at least **38px** high; Settings buttons and slider hit areas at least **40px**. Use **8px** row gaps and **12px** section gaps.
- Use nine-slice surfaces: button corners stay **12px**, independent of content padding. Stock panel slices differ: use the included `.tres` or `manifest.json`. Scale the centre/edges while retaining corner geometry.
- Settings sliders: **6px rail**, **24×30px grip**, orange filled portion, grey remainder; live value and units beside the label. Keyboard focus and disabled state must remain distinct from hover.
- Keep headings/navigation and **Close** fixed; scroll only the body. Use one clear primary action and concise labels. Escape closes the current dialog and returns focus. Decorative layers ignore pointer input.
- Controls map: outline-only interiors for unassigned keys; assigned keys get warm-grey fill; linked hover/focus highlights the key and action. Numpad digits and their number-row equivalents are linked.

## Layout and background

Use grouped, compact content panels with a clear heading and restrained helper text. Normal-games pages use blurred newspaper drawing films behind a dark contrast layer: drawing, short hold, opaque page turn, clean random succession. Reduced motion shows a still. This effect is separate from the crisp foreground UI; the films themselves are not bundled here. Home keeps its captain-card layout.

## Included implementation material

`reusable/game/Content/` contains actual stock PNGs/Godot styles, Settings SVGs and fonts. Copy its contents to the equivalent `res://Content/` path, or update resource paths. Editable stock SVG masters are under `reusable/assets/ui-stock/svg/`.

`reference-code/` contains the existing `StockUiStyle`, `SettingsUiStyle` and `MenuDialogPresentation`. They show the component ownership and measurements; they depend on other game classes and are **not standalone scripts**. In the Guild Ball repository, extend these shared owners instead of copying them. In another engine, retain the same tokens, roles and state behaviour with that engine's native controls.

Image **08** is a component gallery; **10** is an in-game development fixture. **09** supplies art direction, while native screenshots and resources supply implementation geometry. Keep all labels, icons, values and interactive behaviour separate from surface artwork.
