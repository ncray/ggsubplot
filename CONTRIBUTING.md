# Contributing

Open issues and pull requests against this fork, rather than asking the original
maintainers to support the modernization. Include a small reproducible example,
`sessionInfo()`, and expected versus actual behavior.

Run `Rscript -e 'testthat::test_local()'` from the repository root. Check the
package with `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'`.
The full vignette requires knitr and rmarkdown. Visual tests require vdiffr and
maps. Review rendered output before accepting changed snapshots. The snapshots
have separate ggplot2 3.5 and 4.x variants; newer versions may need review.

CI checks R release on Linux, macOS, and Windows, R oldrel on Linux, and a
Linux job pinned to ggplot2 3.5.2. CI status is evidence only after those jobs
actually run. Local development container instructions and prior results are in
MODERNIZATION_NOTES.md; the existing image has the needed tools installed.

Keep changes focused, document compatibility changes in NEWS.md, retain source
attribution, and include meaningful regression tests for behavior changes.
Submit code only when you have the right to distribute it under the package's
GPL-2.0-or-later license. Identify external sources and their licenses.
