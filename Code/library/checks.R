# Title: ICE QA Checks
# Author: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 25 February 2026
# Purpose: Check ICE data for QA purposes.

library(glue)
library(here)
library(purrr)
library(rlang)
library(logr)

source(here::here("Code/library/logging.R"))

#' Run QA checks on data.
#'
#' @param data The data to check.
#' @param qa_config A config object for the dataset.
#' @returns The data, if no errors found.
#' @export
run_qa <- function(data, data_config) {
  force(data)
  qa_config <- data_config$qa
  if (is.null(qa_config)) {
    log_me_maybe("No QA checks to run!")
    return(data)
  }
  log_me_maybe("Running QA checks...")
  data |>
    check_required_columns(qa_config$required_columns, qa_config$strict) |>
    check_suspect_values(qa_config$suspect_checks)
}

#' Check that columns don't contain any missing values.
#'
#' @param data A data.frame or tibble.
#' @param required_columns Columns that shouldn't have missing values.
#' @param strict Whether to fail if the check is violated.
#' @return The original df.
#' @export
check_required_columns <- function(data, required_columns, strict = TRUE) {
  force(data)
  log_me_maybe("Checking for required columns...")
  missing_values <- purrr::map_lgl(required_columns, function(x) {
    any(is.na(data[x]))
  })
  missing_columns <- required_columns[missing_values]
  any_missing <- any(missing_values)
  if (any_missing) {
    msg <- glue::glue(
      "Missing values in {paste(missing_columns, collapse=', ')}"
    )
    log_me_maybe(msg, "error")
    if (!is.null(strict) && strict) {
      stop(msg)
    }
  } else if (any_missing) {
    log_me_maybe(
      glue::glue(
        "Missing values in {paste(missing_columns, collapse=', ')}"
      ),
      "error"
    )
  }
  data
}

#' Check that values don't raise any suspicions.
#'
#' @param data A data.frame or tibble.
#' @param suspect_checks List of (condition, value_col, index_col, strict).
#' @return The original df.
#' @export
check_suspect_values <- function(data, suspect_checks) {
  force(data)
  log_me_maybe("Checking for suspect values...")
  for (check in suspect_checks) {
    condition <- rlang::eval_tidy(
      rlang::parse_expr(check$condition),
      data = data
    )
    if (any(condition)) {
      log_suspect(data, condition, check$value_col, check$index_col)
      if (!is.null(check$strict) && check$strict) {
        stop(glue::glue("Suspect values found in column {check$value_col}."))
      }
    }
  }
  data
}
