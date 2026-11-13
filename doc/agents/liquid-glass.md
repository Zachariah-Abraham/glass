# Liquid glass internals

Moved out of AGENTS.md (read it when you touch the liquid path).

- `LiquidGlass` holds the settings; `LiquidGlass.clear` and `LiquidGlass.regular` are presets fitted
  to native iOS 26 `Glass.clear` / `Glass.regular` screenshots. Explicit `blurX`, `blurY`, `tintColor`
  and `frosted` override the preset. `liquid: null` (default) renders exactly as plain glass.
- The live path needs `ImageFilter.isShaderFilterSupported` (Impeller: iOS, Android, macOS). Web
  and Skia fall back to a plain `BackdropFilter` with the preset's blur and tint.
- `_GlassBackdropState._loadProgram()` loads the shader once (shared static future `_program`) and
  caches it in `_loadedProgram`; glass built after that uses the shader from its first frame. Until then
  liquid glass shows the plain blur. The public `LiquidGlass.precache()` starts the same load early.
  `_RenderLiquidBackdrop` pushes a `_LiquidBackdropLayer` (a `BackdropFilterLayer` with
  `alwaysNeedsAddToScene`). It pushes the blur as its own backdrop filter (pushed and popped with no
  children), then the shader filter, which reads the blurred backdrop. Don't compose them
  (`ImageFilter.compose` makes Impeller blur far beyond the clip: a small blur got about 3x slower) and
  don't nest them (inside the blur's save layer the shader's coordinates are no longer global). It computes
  the uniforms right before every push from `getTransformTo(null)`, and builds a new filter only when
  they change. This is required because ancestors (scroll views) move the glass without repainting it,
  and the engine copies a shader filter's uniforms the first time it is pushed, so `setFloat` on an
  existing filter does nothing. `asGlass(grouped: true)` passes the nearest `BackdropGroup`'s
  `backdropKey` to the blur only (plain glass uses `BackdropFilter.grouped`): the shader must read the
  blurred result, not the shared unblurred backdrop. The blur is a child `BackdropFilterLayer`, added
  in `addToScene`, because `BackdropKey`'s id is private. Grouping took a list of liquid cards on an
  Adreno phone at 90 Hz from 14 ms to 4.5 ms raster per frame: the cost is per backdrop read, not per
  pixel. The shader works in the glass's local space through two 3x3 matrices,
  so rotation, skew and perspective work. The shape is the clip `RRect` (`_GlassShape`: `clipper`, else
  `clipBorderRadius`, with `scaleRadii()`), sent as its local rect plus per-corner x and y radii; the
  shader's `shapeSdf` is a rounded-rect SDF with elliptical corners. `_RenderLiquidGlassLayers` paints the optional `shadow`
  outside the shape.
- Native model the shader follows: it samples **inward** only, along the inward normal,
  `source = p + d(t)*n_in` with `W = min(20 pt, 0.69*min(w,h)/2)`, `A = 3W` and
  `d(t) = A*(1 - sqrt(1 - (1 - t/W)^2))` for depth `t < W`. Blur comes before refraction. The rim is a
  3 physical px white mix that takes on the backdrop's colour. `FlutterFragCoord()` in a backdrop
  shader is global physical px, y down, on Metal, Vulkan and GLES.
