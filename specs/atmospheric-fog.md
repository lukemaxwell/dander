# SPEC: Atmospheric fog — texture + edge glow

## Goal
- Transform the flat navy fog overlay into an atmospheric, mysterious visual layer using a subtle procedural noise texture and a glowing edge where fog meets revealed map.

## Non-goals
- Animated fog drift or breathing effects
- Particle/sparkle effects at boundary
- Distance rings or compass overlays
- Any gameplay or data model changes

## Users / scenario
- Every user sees the fog on the map screen at all times. The current flat fill looks clean but lifeless. Adding texture and edge glow makes unexplored territory feel mysterious and the explored boundary feel rewarding.

## Requirements (must)
- [ ] Fog layer renders a subtle procedural noise pattern over the solid navy fill
- [ ] Noise texture is generated once at runtime, cached as a `ui.Image`, and tiled via `ImageShader`
- [ ] Pattern opacity is low (~6%) — atmospheric, not distracting
- [ ] Fog-to-revealed boundary has a faint ambient glow fringe (amber `DanderColors.secondary`)
- [ ] Glow uses a two-pass technique: wide coloured blur minus interior punch-out, leaving only the fringe
- [ ] Glow is ~16px sigma wide at ~18% opacity
- [ ] No measurable FPS drop — texture is pre-rendered, glow reuses the same cell loop
- [ ] Existing blur mask on cell edges is preserved

## Nice-to-haves
- [ ] Glow colour adapts to zone level (amber L1-2, sky-blue L3+)

## Acceptance criteria (definition of done)
- [ ] Fog has visible fine-grain texture when zoomed in; blends to solid at distance
- [ ] Explored area boundary has a soft amber fringe visible against the fog
- [ ] All existing fog tests pass unchanged
- [ ] New tests cover texture generator output and painter configuration
- [ ] Manual test: fog renders correctly at various zoom levels and during walk

## Risks / constraints
- `ui.Image` generation requires async (`PictureRecorder`) — must be done in the widget layer, not the painter
- The fog painter uses `saveLayer` + `BlendMode.dstOut` — texture must be painted inside this compositing pass before hole-punching
- Glow pass is a separate `saveLayer` after the fog restore to avoid blend mode conflicts

## Issue breakdown

1. **Procedural fog noise texture generator**
   - Create `FogTextureGenerator` that produces a small tileable `ui.Image`
   - Acceptance: generates a 128×128 image with non-uniform pixel data
   - Test: output dimensions correct, image is non-null, can be called multiple times safely

2. **Integrate noise texture into FogPainter**
   - FogPainter accepts optional `ui.Image` texture, tiles it over fog fill at low opacity
   - FogLayer widget generates texture once on init, passes to painter
   - Acceptance: fog shows subtle grain when texture provided; unchanged when null
   - Test: shouldRepaint detects texture changes, painter constructs with texture param

3. **Edge glow at fog boundary**
   - Two-pass glow: draw all explored cells with wide amber blur, then punch interior with tighter white blur — leaves only the fringe
   - FogPainter accepts glow colour and sigma config
   - Acceptance: amber halo visible at fog/map boundary, interior map unaffected
   - Test: shouldRepaint detects glow config changes, painter constructs with glow params

## PR discipline
- All work on main (single developer)
- Run: `flutter test`
- Run: `flutter analyze`
