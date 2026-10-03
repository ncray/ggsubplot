# Modified for the ncray modernization fork, 2026-10-03.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.

#' Synthetic monthly atmospheric measurements
#'
#' Entirely simulated measurements on a regular geographic grid, with seasonal
#' patterns suitable for subplot examples. These are not NASA observations.
#' The historical name `nasa` and column names are retained for compatibility
#' with examples from the original ggsubplot package; the original data have
#' been replaced, and numerical results will differ.
#'
#' @format A data frame with 8640 rows and 17 columns: grid indices `x`, `y`;
#'   monthly index `time`; `lat`, `long`; UTC `date`; cloud percentages
#'   `cloudhigh`, `cloudlow`, `cloudmid`; simulated `ozone`, `pressure`,
#'   `surftemp` and `temperature` (temperatures in kelvin); location `id`;
#'   and numeric `day`, `month`, `year`.
#' @source Generated independently by `tools/generate-synthetic-data.R` in the
#'   source repository. No original dataset is read or transformed.
"nasa"

#' Synthetic fictional event records
#'
#' Entirely fictional events for geographic count and glyph examples. These do
#' not describe real people, casualties, or the Afghan War Diary. The historical
#' name `casualties` and column names are retained for example compatibility;
#' the original data have been replaced, and numerical results will differ.
#' Victim categories are fictional labels retained from the historical schema.
#'
#' @format A data frame with 2400 rows and 12 columns: UTC `date`; numeric `year`;
#'   ordered factors `month` and `day`; coordinates `lon`, `lat`; logical
#'   `fatal`, `harmful`; character `type`, `category`; factor `victim`;
#'   and character `casualty`. Coordinates are simulated, not event locations.
#' @source Generated independently by `tools/generate-synthetic-data.R` in the
#'   source repository. No original dataset is read or transformed.
"casualties"
