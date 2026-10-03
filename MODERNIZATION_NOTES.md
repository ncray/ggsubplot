# ggsubplot 0.4.0 modernization

All five milestones in PLAN.md are implemented, in order, on branch `modernize`.
Each milestone has its own local commit. No upstream history was rewritten and
nothing was pushed.

## What changed

* Replaced obsolete proto/plyr/S4 infrastructure with ordinary ggplot2 layers.
  Subplots compose through `+`, `layer_data()`, themes, coordinates, and
  `ggsave()`. The original datasets and public rescaling helpers remain.
* Added grouped and grid assignment, numeric positions for discrete majors,
  shared/free minor limits, relative dimensions, unequal grid cells, aligned
  reference boxes/lines, and connected-component overlap merging.
* Implemented tidy per-subplot aesthetics, opt-outs, staged mappings, ordinary
  `ply_aes()` layers, shared non-position palettes and legends. Hidden raw
  aesthetic columns allow final palette mapping after all outer layers train.
  Factor levels survive this mapping, including unions of levels from
  group-specific factor expressions; explicit manual and transformed scales
  are covered by tests.
* Rebuilt stars, frequency stars, and coxcombs as polygon ggproto geoms. Geometry
  is prepared before position training/embedding, with invisible symmetric
  bounds to keep glyphs centred. Coxcomb sectors stack in area using square-root
  radii. Glyphs work standalone and as subplots with map coordinates.
* Replaced the empty Sweave vignette with a fast, offline R Markdown manual.
  Regenerated NAMESPACE and Rd documentation with roxygen2 8.1.0, added runnable
  examples, migration notes in NEWS.md, and a README with a rendered map example.
* Added geometric, grouping, scale, composition, error, and visual tests.
  `tools/render-gallery.R` reproduces the gallery without network access.
  `.dev/`, PLAN.md, development tools, galleries, and these notes are excluded
  from package builds. Development binaries, private libraries, and check
  outputs are ignored by git. The pre-existing Dockerfile edit was left alone.

## Design adjustments to the plan

* ggplot2's Layer prototype is obtained through
  `ggplot2::geom_blank()$super()` instead of a direct `ggplot2:::Layer` reference.
  It is the same prototype in both tested versions. This avoids an unexported
  namespace dependency diagnostic while preserving the planned subclass design.
  The package still necessarily depends on ggplot2's layer extension pipeline.
* Non-position scale mapping is deferred until `compute_geom_2()` so several
  subplot layers and ordinary layers share a final palette. Simply carrying
  the first inner build's mapped colours, as in the initial plan, would produce
  inconsistent colours when later layers introduce new categories or ranges.
  Legend keys receive geom defaults, and `after_scale()` runs against the final
  palette. One small compatibility branch handles the extra parameters/theme
  accepted by `Layer$compute_geom_2()` in ggplot2 4.0.
* Fixed minor position parameters are converted to mapping constants so the
  inner position scales train on them. They must not overwrite the embedded
  coordinates when final geom defaults are applied.
* Coxcomb/frequency-star defaults use `stat = "count"` for categorical angles;
  continuous histograms explicitly request `stat = "bin"` and bins/binwidth.
  The old bin default did not provide sensible categorical behavior with modern
  ggplot2. This change is documented in NEWS.md.
* Nine visual cases rather than roughly eight include an additional standalone
  glyph comparison. Separate gg4/gg35 snapshot variants avoid incidental theme
  and guide differences and prevent one version deleting the other's snapshots.
  Every case has a corresponding PNG in docs/gallery: 18 files for two versions.
  All were opened and reviewed before accepting the snapshots. Review confirmed
  point containment, geographic borders, star outlines and coxcomb sectors.
* Imports are smaller than the allowed list: unused direct scales/stats imports
  were omitted. No extra CRAN packages were installed; EXTRA_PACKAGES.txt was
  therefore unnecessary. roxygen2 8.1.0 records its version in
  Config/roxygen2/version; RoxygenNote is also retained for the requested metadata.

## Known limitations

* Outer facets and nested subplot layers are deliberately rejected. Ordinary
  `ply_aes()` and standalone glyph layers can be facetted.
* One minor layer is supported per subplot call. Put subplot data on the major
  layer; any data on the supplied minor layer is ignored. Custom layer subclasses
  with their own computation methods are not preserved by the inner layer wrapper.
* Major discrete/date-time coordinates become numeric positions. Continuous
  outer axes are expected; supply explicit labels for discrete positions.
  A major group must have one centre, or use summary expressions such as mean().
* Minor scaling supports fixed (`identity`) and `free`, rather than arbitrary
  rescaler functions. Only `identity` and `merge` subplot positions are supported.
* References draw one row per occupied subplot: use summary expressions for
  reference aesthetics that vary across rows. Rowwise reference mappings use
  the first row after grouped evaluation. Missing/out-of-break major rows are
  omitted. Merging uses mean constituent centres and maximum original dimensions,
  not a bounding box of the entire overlapping cluster.
* Glyph angle positions cover the observed cycle. Sparse numeric angles use the
  smallest observed step to close it; specify a consistent complete angular
  domain when comparing sparse series. At least three distinct rays are needed
  for a non-degenerate star polygon. Star fill/outline use the first ray's
  aesthetics. Coxcomb/frequency glyphs are centred at zero when used standalone.
* The checked target versions are ggplot2 4.0.3 and 3.5.2 on R 4.6.1. Future
  changes to ggplot2's layer pipeline may require adaptation. There is no special
  handling for arbitrary custom geoms, non-Cartesian minor coordinates, or
  advanced inner layouts; the inner build uses a Cartesian facet_wrap layout.

## Final validation

Commands (from /work):

```sh
Rscript -e 'testthat::test_local()'
R_LIBS=/opt/gg35 Rscript -e 'testthat::test_local()'
Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'
R_LIBS=/opt/gg35 Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'
```

| Environment | Local tests (including visual snapshots) | R CMD check --as-cran --no-manual |
|---|---|---|
| R 4.6.1 / ggplot2 4.0.3 | 120 passed, 0 failed, 0 warnings, 0 skips | 0 errors, 0 warnings, 1 NOTE |
| R 4.6.1 / ggplot2 3.5.2 | 120 passed, 0 failed, 0 warnings, 0 skips | 0 errors, 0 warnings, 1 NOTE |

Examples, vignette builds/rebuilds, package installation/loading, dependency
checks, and installed-package tests passed in both checks. vdiffr runs in local
tests; it follows its standard skip-on-CRAN policy during --as-cran checking.
Additional rendered smoke checks of coord_map() and patchwork composition passed.

The sole NOTE in each check is CRAN incoming feasibility: it identifies the
original maintainer, treats this as a new submission, and reports the historical
CRAN archive entry (2016-01-11, at the maintainer's request). This is submission
metadata, not a code, example, test, or vignette issue. Local check logs are under
.dev/ and are not committed. No milestone is left incomplete.

## Public repository review (2026-10-03)

Re-ran all 120 local tests, including nine visual snapshots, on the existing
R 4.6.1 development image with ggplot2 4.0.3 and 3.5.2. Both suites passed with
zero failures, warnings, or skips. Source data files match the upstream baseline.
Added fork attribution, GPL text, installation and contribution instructions,
dataset provenance, modification notices, and a GitHub Actions check matrix.
No code behavior changes were required by this review. Windows/macOS and remote
CI have not been run locally. No GitHub repository has been created or pushed.

The initial no-email maintainer metadata failed R CMD build in both environments:
R requires a named maintainer with a valid email address. This is separate from
the passing functional tests and must be resolved before installable releases.
Dataset redistribution permissions remain unresolved; see ATTRIBUTION.md and
RELEASE_CHECKLIST.md. Earlier successful checks above predate the fork metadata
changes and do not establish that the current source is release-ready.

## Synthetic example replacement (2026-10-03)

At the user's request, replaced both original bundled datasets with independently
generated synthetic examples. tools/generate-synthetic-data.R reads no original
records and uses deterministic formulas. Historical object/column names are
retained, but values and row counts differ: nasa has 8640 rows and casualties
has 2400 fictional events. Documentation and plot titles explicitly state this.
The original records remain only in local Git history and ignored check outputs.
A clean current-source export avoids redistributing those historical objects.
This supersedes the earlier statement that current data files match upstream;
original dataset permissions no longer apply to the new synthetic examples.

Synthetic data validation: 133 assertions pass with zero failures, warnings,
or skips in both ggplot2 4.0.3 and 3.5.2 on R 4.6.1, including regenerated
visual snapshots. Reviewed the eight changed PNGs across the two versions.
The generator reproduces both .rda files byte-for-byte in a fresh temporary
directory. At this stage, no-email maintainer metadata still blocked R CMD
build; it was subsequently resolved with the GitHub noreply address below.

All runnable Rd examples also passed and the R Markdown vignette rendered
successfully with the replacement data. The verified public source export is
`.dev/public-source-synthetic/`; it contains no .git or .dev directory.

## Maintainer contact resolved (2026-10-03)

Applied the verified GitHub noreply address
`322031+ncray@users.noreply.github.com` to the fork maintainer in DESCRIPTION.
This resolves the earlier no-email build failure without exposing personal email.
Support remains through GitHub issues.

R CMD build and standard R CMD check --no-manual passed on R 4.6.1 with both
ggplot2 4.0.3 and 3.5.2: zero errors, warnings, or notes. Installation, examples,
installed-package tests, and vignette rebuilds passed. These checks ran offline
with CRAN incoming checks disabled. Initial --as-cran attempts built successfully
but stopped during incoming feasibility because network access was disabled;
those incomplete checks are not counted as passes. Logs are under .dev/.
The clean public source export has been refreshed with the corrected metadata.
