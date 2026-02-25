# Title: ICE Pipeline Validation
# Author: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 25 February 2026
# Purpose: Library functions for validating ICE data against other sources.

library(dplyr)
library(purrr)
library(rlang)

#' Validate whether rows in one data frame match a corresponding row in another.
#'
#' @param unvalidated_df The data frame to validate.
#' @param comparison_df The data frame against which to validate.
#' @param validation_source The name of the comparison data source.
#'
#' @returns The original data frame with `validated` and `validation_source`
#'   columns added.
#' @export
validate_data <- function(
  unvalidated_df,
  comparison_df,
  validation_source,
  ...
) {
  keys <- rlang::enquos(...)

  unvalidated_df |>
    dplyr::left_join(
      comparison_df |>
        dplyr::select(!!!keys) |>
        dplyr::mutate(validated = TRUE, validation_source = validation_source),
      by = purrr::map_chr(keys, as_name),
    ) |>
    dplyr::mutate(validated = !is.na(validated))
}
