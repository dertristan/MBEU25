# Copy figures preserving the subfolder structure expected by preview HTML files.
# _freeze/code/<notebook>/figure-html/*.png
#   -> _manuscript/code/<notebook>_files/figure-html/*.png

notebooks <- list.dirs("_freeze/code", full.names = FALSE, recursive = FALSE)

for (nb in notebooks) {
  src_dir  <- file.path("_freeze/code", nb, "figure-html")
  dest_dir <- file.path("_manuscript/code", paste0(nb, "_files"), "figure-html")

  if (!dir.exists(src_dir)) next

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  figs <- list.files(src_dir, pattern = "\\.png$", full.names = TRUE)
  file.copy(figs, dest_dir, overwrite = TRUE)
}
