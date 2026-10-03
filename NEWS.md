# ggsubplot 0.4.0

* **Breaking:** replaced the bundled NASA and Afghan War Diary datasets with
  independently generated synthetic examples. Historical object and column names
  remain, but values and row counts differ. Examples, galleries, and snapshots
  are regenerated and labeled synthetic. The generator reads no original data.

* Independent modernization fork maintained by ncray (2026-10-03).
  Retains attribution to Garrett Grolemund, Hadley Wickham, and RStudio,
  and the original GPL-2.0-or-later code license. Added provenance,
  installation/contribution guidance, and a cross-platform CI workflow.

* Rebuilt subplot layers for ggplot2 3.5.2 and 4.0.x, including S7 plots.
  Removed proto, plyr, S4 plot/layer classes, custom build and print methods.
  `ggsubplot(plot)` is now a deprecated identity function.
* `subplot = geom_*()` is accepted as a top-level argument. The historical
  `aes(subplot = geom_*())` syntax remains supported.
* Minor aesthetics evaluate per subplot by default. **Breaking:** `I()` now
  has ggplot2's identity-aesthetic meaning. Use `ply.aes = FALSE` or a vector
  of aesthetic names to control grouped evaluation. `ply_aes()` supports
  ordinary ggplot2 layers and column names via `.vars`.
* Non-position scales and legends are shared with ordinary layers. Staged
  mappings use `after_stat()`, `after_scale()`, or `stage()`, replacing old
  `..count..` examples.
* **Breaking:** minor scaling accepts only `identity` (fixed) and `free`.
  Arbitrary rescaler functions are no longer supported. Discrete major
  coordinates become numeric positions on continuous outer axes.
* Relative dimensions use the smallest positive spacing between centres,
  falling back to one unit. Grid references and glyphs share cell centres;
  unequal breaks give unequal box sizes. Grid rows outside breaks are omitted.
  Overlap merging includes transitive overlaps.
* Reimplemented stars, frequency stars, and coxcombs as ggproto polygon geoms.
  Coxcomb radii use square roots for area-correct stacking. **Breaking:** the
  default frequency-star and coxcomb stat is `count`, suitable for categorical
  angles; use `stat = "bin"` for continuous histograms. Glyph outlines use
  `linewidth`, with ggplot2's compatibility support for `size`.
* **Breaking:** internal `.ref`, `sp_layer`, exported S4 classes, and internal
  `layer_clone` methods are removed. Reference factories are intended only
  for the `reference` argument. Subplot-specific data belongs on the major
  layer; data on the supplied minor layer is ignored.
* Outer facetting and nested subplots produce explicit errors. Reference
  boxes and lines, mixed ordinary layers, map coordinates, and `ggsave()` work.
* Replaced the empty Sweave manual with a fast R Markdown vignette, added
  runnable examples, geometric tests, and reviewed visual snapshots.
