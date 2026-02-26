# Title: ICE Logging
# Author: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 26 February 2026
# Purpose: Logging functions for ICE pipeline

library(glue)
library(logr)

#' Run a function with logging.
#'
#' @param log_file The path to the log file.
#' @param func The function to run
#' @param ... The function parameters
#'
#' @return The result of `func(...)`.
#' @export
with_logging <- function(log_file, func, ...) {
  log_buffer <- logr::log_open(log_file)
  called_with <- match.call()
  func_name <- called_with[3]
  func_args <- called_with[4:length(called_with)]
  logr::log_info(glue::glue(
    "Started running {func_name} with {paste(func_args, collapse = ', ')}!"
  ))
  result <- func(...)
  logr::log_info(glue::glue("Finished running {func_name}!"))
  logr::log_close()
  result
}

#' Log a statement if there's a log buffer open, otherwise print it.
#'
#' @param msg The log message.
#' @param level The log level (print, info, warning, or error).
#' @export
log_me_maybe <- function(msg, level = "print") {
  if (log_status() == "open") {
    switch(
      level,
      "print" = logr::log_print(msg),
      "info" = logr::log_info(msg),
      "warning" = logr::log_warning(msg),
      "error" = logr::log_error(msg)
    )
  } else {
    message(msg)
  }
}

#' Flag and log suspect values
#'
#' @param data The data to review.
#' @param condition The criterion for flagging values.
#' @param value_col The column containing the values to flag.
#' @param index_col The column to use to identify rows.
#' @export
log_suspect <- function(data, condition, value_col, index_col) {
  sus_values <- which(condition)
  for (idx in sus_values) {
    index_value <- data[index_col][[1]][idx]
    sus_value <- data[value_col][[1]][idx]
    log_me_maybe(
      glue::glue(
        "Suspect value for column {value_col} at row {idx}, {index_value}: {sus_value}"
      ),
      "warning"
    )
  }
}
