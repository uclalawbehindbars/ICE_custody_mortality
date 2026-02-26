#!/usr/bin/env Rscript
options(warn = 2)

suppressMessages(library(purrr))

config <- if (file.exists(".lintr")) ".lintr" else NULL


targets <- c(
  "Code"
)

lints <- map(targets, function(target) {
  lintr::lint_dir(
    path = target,
    linters = NULL,
    relative_path = TRUE,
    exclusions = config
  )
})

lints <- do.call(c, lints)

if (length(lints) > 0) {
  print(lints)
  quit(status = 1, save = "no")
} else {
  cat("lintr: no issues found.\n")
  quit(status = 0, save = "no")
}
