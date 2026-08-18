# Title: ICE Pipeline
# Author: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 26 February 2026
# Purpose: Library functions for ICE pipeline

library(dplyr)
library(glue)
library(googlesheets4)
library(here)
library(janitor)
library(purrr)
library(readr)
library(readxl)
library(rlang)
library(tidyselect)
library(tools)

source(here("Code/library/logging.R"))
source(here("Code/library/utils.R"))

#' Manually correct cells in a data frame using a provided config
#'
#' The function loads corrections using the config's `corrections`
#' key to load corrections, and the `corrections_index` key to generate
#' an index column to use for finding rows that require corrections. It then
#' joins the uncorrected data with the corrections and replaces values wherever
#' a correction exists.
#'
#' @param uncorrected_df The data frame to corrrect.
#' @param config A named list with a `corrections` key that
#'   lists rows and columns needing corrections and a `corrections_index` key
#'   that generates the row index when passed as an expression to `mutate`.
#' @param `id_col` The name of the column to use as a row index. Default is
#'   `id`.
#'
#' @returns The corrected data frame.
#' @export
apply_corrections <- function(
  uncorrected_df,
  config,
  id_col = "id"
) {
  force(uncorrected_df)
  if (is.null(config$corrections)) {
    log_me_maybe("No corrections to apply!")
    return(uncorrected_df)
  }
  corrections <- load_corrections(config$corrections)
  log_me_maybe(glue::glue("Applying {length(corrections)} corrections..."))
  uncorrected_df |>
    dplyr::mutate(
      {{ id_col }} := !!parse_expr(config$corrections_index)
    ) |>
    dplyr::left_join(corrections, by = id_col, suffix = c("", ".new")) |>
    purrr::reduce(
      dplyr::setdiff(
        dplyr::intersect(names(uncorrected_df), names(corrections)),
        id_col
      ),
      function(df, col) {
        new_col <- str_c(col, ".new")

        df |>
          dplyr::mutate(
            {{ col }} := dplyr::coalesce(.data[[new_col]], .data[[col]])
          )
      },
      .init = _
    ) |>
    dplyr::select(-tidyselect::ends_with(".new")) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        ~ dplyr::if_else(.x == "", NA_character_, .x)
      )
    )
}

#' Apply filters to data frame
#'
#' No-op if no filters provided.
#'
#' @param data The dataframe to mutate.
#' @param data_config The data config object.
#'
#' @returns The mutated dataframe.
#' @export
apply_filters <- function(data, data_config) {
  force(data)
  filter_map <- data_config$filters
  if (length(filter_map)) {
    log_me_maybe("Filtering rows...")
    dplyr::filter(data, !!!parse_exprs(filter_map))
  } else {
    log_me_maybe("No filters to apply!")
    data
  }
}

#' Apply a join to data frame
#'
#'
#' @param data The lefthand dataframe to join.
#' @param join_config The join config object.
#'
#' @returns The joined dataframe.
#' @export
apply_join <- function(data, join_config, main_config) {
  force(data)
  log_me_maybe(glue::glue("Joining to table {join_config$right}..."))
  switch(
    join_config$how,
    "left" = exec(
      dplyr::left_join,
      x = data,
      y = load_df(join_config$right, main_config),
      by = join_by(!!rlang::parse_expr(join_config$by))
    ),
    "right" = exec(
      dplyr::right_join,
      x = data,
      y = load_df(join_config$right, main_config),
      by = join_by(!!rlang::parse_expr(join_config$by))
    ),
    "full" = exec(
      dplyr::full_join,
      x = data,
      y = load_df(join_config$right, main_config),
      by = join_by(!!rlang::parse_expr(join_config$by))
    ),
    "inner" = exec(
      dplyr::inner_join,
      x = data,
      y = load_df(join_config$right, main_config),
      by = join_by(!!rlang::parse_expr(join_config$by))
    ),
  )
}

#' Join the df to other dfs.
#'
#' No-op if no joins provided.
#'
#' @param data The dataframe to join.
#' @param data_config The data config object.
#' @param main_config The main config object.
#'
#' @returns The joined dataframe.
#' @export
apply_joins <- function(data, data_config, main_config) {
  force(data)
  joins <- data_config$joins
  if (length(joins)) {
    log_me_maybe("Applying table joins...")
    purrr::reduce(joins, .init = data, ~ apply_join(.x, .y, main_config))
  } else {
    log_me_maybe("No tables to join!")
    data
  }
}

#' Apply mutations to data frame
#'
#' No-op if no mutations provided.
#'
#' @param data The dataframe to mutate.
#' @param data_config The data config object.
#'
#' @returns The mutated dataframe.
#' @export
apply_mutations <- function(data, data_config) {
  force(data)
  mutate_map <- rlang::set_names(
    purrr::map_chr(data_config$mutations, as.character),
    names(data_config$mutations)
  )
  if (length(mutate_map)) {
    log_me_maybe("Applying column mutations...")
    dplyr::mutate(data, !!!parse_exprs(mutate_map))
  } else {
    log_me_maybe("No mutations to apply!")
    data
  }
}

#' Apply renamings to data frame
#'
#' No-op if no renamings provided.
#'
#' @param data The dataframe to rename.
#' @param data_config The data config object.
#'
#' @returns The renamed dataframe
#' @export
apply_renamings <- function(data, data_config) {
  force(data)
  renaming_map <- data_config$renamings
  if (length(renaming_map)) {
    log_me_maybe("Renaming columns...")
    dplyr::rename(data, !!!renaming_map)
  } else {
    log_me_maybe("No columns to rename!")
    data
  }
}

#' Load manual corrections from a YAML config
#'
#' The YAML corrections should have the following schema:
#'
#' ```
#' <row ID>:
#'   <column to fix>: <replacement value>
#'   <another column to fix>: <another replacement value>
#'   ...
#' ```
#'
#' The function outputs corrections as a tibble in which each row corresponds to
#' a unique row ID, and each column contains the corrected values for the column
#' of the same name, with NA values if a row has no correction for a given
#' column.
#'
#' @param corrections YAML-formatted corrections.
#' @param id_col The name of the column to use for row IDs. Default is `id`.
#'
#' @returns
#' @export
load_corrections <- function(corrections, id_col = "id") {
  purrr::map2(corrections, names(corrections), function(vals, key) {
    tibble::as_tibble(c(setNames(list(key), id_col), vals)) |>
      # Coerce non-NA values to strings to avoid type conflicts
      dplyr::mutate(dplyr::across(dplyr::where(~ !is.na(.x)), as.character))
  }) |>
    purrr::list_rbind()
}

#' Load a dataframe and pass it through configured pipeline
#'
#' Each dataframe record uses the following schema:
#'
#' ```
#' <dataframe name>
#'   src:
#'     path: <path to dataframe>
#'     generator: <optional shell expression called to generate source data>
#'     args:
#'       - <optional arguments to pass to `read_any`
#'       - ...
#'   index_column: <column to use for finding rows to apply substitutions>
#'   corrections_index: <R expression to create manual correction index>
#'   corrections:
#'     <index value>:
#'       <column name>: <updated value>
#'       <column name>: <updated value>
#'    <index value>:
#'      <column name>: <updated value>
#'    ...
#'   mutations:
#'     <name of column to mutate>: <R expression for mutation>
#'   filters:
#'     - <R expression to use for filter>
#'     - ...
#'   renamings:
#'     <new column name>: <old column name>
#'     ...
#'   joins:
#'     - how: <left | right | inner | full>
#'       right: <name of df to join>
#'       by: <join condition expression>
#'     ...
#'   output_columns:
#'     - <column 1>
#'     - <column 2>
#'     ...
#'   qa:
#'     required_columns:
#'       - <column 1>
#'       - <column 2>
#'       ...
#'     suspect_checks:
#'       - condition: <logical expression to evaluate>
#'         value_col: <name of column with values to inspect>
#'         index_col: <name of index column to use when reporting suspect values>
#'         strict: <true | false>
#'       ...
#'
#' ```
#' All keys are optional except for `src.path`.
#'
#' @param df_name The key name to use to load the dataframe
#' @param config A list loaded from a YAML file matching the schema above.
#' @returns The processed data
#' @export
load_df <- function(df_name, config) {
  log_me_maybe(glue::glue("Loading {df_name}..."))
  if (is.null(config)) {
    stop("No config found for dataset: ", df_name, call. = FALSE)
  }
  data <- read_any(config[[df_name]]) |>
    janitor::clean_names() |>
    apply_corrections(config[[df_name]]) |>
    apply_mutations(config[[df_name]]) |>
    apply_renamings(config[[df_name]]) |>
    apply_filters(config[[df_name]]) |>
    apply_joins(config[[df_name]], config) |>
    run_qa(config[[df_name]]) |>
    output_columns(config[[df_name]])
  log_me_maybe(glue::glue("{df_name} loaded!"))
  data
}

#' Output columns based on config
#'
#' @param df The dataframe to output.
#' @param config The config mapping for the dataframe.
#'
#' @returns The selected output columns.
#' @export
output_columns <- function(df, config) {
  log_me_maybe("Selecting output columns...")
  if (length(config$output_columns)) {
    df |> select(!!!rlang::parse_exprs(config$output_columns))
  } else {
    df
  }
}

#' Uniform API for reading source data.
#'
#' @param source_config A source config.
#' @returns A tibble.
#'
#' @export
read_any <- function(source_config, ...) {
  src_path <- resolve_path(source_config$src$path)
  if (
    stringr::str_detect(
      src_path,
      "^https://docs.google.com/spreadsheets"
    )
  ) {
    googlesheets4::gs4_deauth()
    df <- exec(
      googlesheets4::read_sheet,
      ss = src_path,
      !!!source_config$src$args,
      ...
    ) |>
      dplyr::select(where(~ !all(is.na(.))))
    return(df)
  }
  if (!file.exists(src_path)) {
    message("\n[Step 1/2] Generating source file...\n")
    if (!is.null(source_config$src$generator)) {
      generator <- paste(
        "cd",
        shQuote(here::here()),
        "&&",
        source_config$src$generator
      )
      system(generator)
    }
    if (!file.exists(src_path)) {
      stop(glue::glue("File generation failed for `{src_path}`."))
    }
    message(
      "\n[Step 2/2] Extraction complete. Proceeding to data cleaning...\n"
    )
  }
  ext <- tolower(tools::file_ext(src_path))
  switch(
    ext,
    "csv" = exec(
      readr::read_csv,
      file = src_path,
      !!!source_config$src$args,
      ...
    ),
    "tsv" = exec(
      readr::read_tsv,
      file = src_path,
      !!!source_config$src$args,
      ...
    ),
    "xlsx" = exec(
      readxl::read_excel,
      path = src_path,
      !!!source_config$src$args,
      ...
    ),
    "xls" = exec(
      readxl::read_excel,
      path = src_path,
      !!!source_config$src$args,
      ...
    ),
    stop("Unsupported file type: ", ext)
  ) |>
    dplyr::select(where(~ !all(is.na(.)))) # drop empty columns
}
