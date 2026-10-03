pkgload::load_all(); library(ggplot2)
source('tests/testthat/helper-data.R')
source('tests/testthat/helper-gallery.R')
plots <- gallery_plots()
for (name in names(plots)) {
  file <- paste0('docs/gallery/',gallery_prefix(),name,'.png')
  ggsave(file, plots[[name]], width = 8, height = 6, dpi = 120)
  cat(file, '\n')
}
