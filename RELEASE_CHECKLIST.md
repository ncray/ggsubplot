# Public release checklist

* The current bundled data, galleries, and snapshots use independently generated
  synthetic records. Do not push the existing local Git history, which still
  contains the original third-party datasets. Export the current source with
  `python3 tools/prepare-public-source.py /path/to/new-directory` and initialize
  a new repository there. Original authors, licensing, baseline revision, and
  source links remain documented in ATTRIBUTION.md.
* ncray is the fork maintainer, using
  `322031+ncray@users.noreply.github.com` to keep personal email private.
  Contact and support are through GitHub issues; the noreply address is not
  a support mailbox.
* Create the public repository under ncray from the clean source export.
  Describe it as an independent modernization with synthetic example data.
* Keep the original remote as upstream and direct pushes to the new fork.
  No remote configuration or publication has been performed by this review.
* Run the GitHub Actions matrix and inspect check artifacts before tagging
  v0.4.0. Local Linux results do not establish Windows/macOS compatibility.
* Inspect tracked files and history for secrets and accidental development
  artifacts. Do not publish credentials, private libraries, or check logs.
* State the exact tested R and ggplot2 versions and documented limitations.
  Installation targets ncray/ggsubplot; do not advertise this as a CRAN release.
