# Title: ICE Utils
# Author: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 25 February 2026
# Purpose: Utility functions for ICE pipeline

library(dplyr)
library(stringr)
library(usdata)

#' Clean names so that they're in <First> <Middle> <Last> format
#'
#' > clean_name("SMITH, JOHN F")
#' "John F Smith"
#'
#' @param name The name to clean.
#' @returns The cleaned name.
#'
#' @export
clean_name <- function(name) {
  stringr::str_to_title(stringr::str_replace_all(name, "\\n", " ")) |>
    stringr::str_split(",\\s*", n = 2, simplify = TRUE) |>
    (\(x) paste(x[, 2], x[, 1]))() |>
    stringr::str_replace_all("\\s+", " ") |>
    stringr::str_replace_all("‐", "-") |> # replace weird Unicode hyphen with regular hyphen
    stringr::str_replace_all("\\s*-\\s*", " ") |> # replace hyphens with spaces
    trimws()
}

#' Expand state abbreviations within a death location.
#'
#' > expand_state("Philadelphia, PA")
#' "Philadelphia, Pennsylvania"
#'
#' @param location The location to expand.
#' @returns The expanded location.
#'
#' @export
expand_state <- function(location) {
  state_abbr <- stringr::str_extract(location, "[A-Z][A-Z]$")
  dplyr::if_else(
    state_abbr %in% usdata::state_stats$abbr,
    state_abbr |>
      usdata::abbr2state() |>
      str_replace(location, "[A-Z][A-Z]$", replacement = _),
    expand_territory(location)
  )
}

#' Expand territory abbreviations.
#'
#' @param location The location to expand.
#' @returns The expanded territory name.
#'
#' @export
expand_territory <- function(location) {
  territories <- c(
    PR = "Puerto Rico",
    GU = "Guam",
    MP = "Northern Marianas",
    VI = "Virgin Islands",
    AS = "American Samoa"
  )

  # Avoid NA values causing errors in str_replace
  abbr <- dplyr::if_else(
    stringr::str_detect(location, "[A-Z]{2}"),
    stringr::str_extract(location, "[A-Z]{2}$"),
    " ",
  )
  expanded <- territories[abbr]

  dplyr::if_else(
    !is.na(expanded) & !is.null(expanded),
    stringr::str_replace(location, abbr, expanded %||% abbr),
    location
  )
}

#' Classify detention center contractor type as Public or Private.
#'
#' Federal, State, County, and City facilities are classified as Public;
#' Private facilities are classified as Private.
#'
#' @param contractor_type The contractor type to classify.
#' @returns "Public", "Private", or NA.
#'
#' @export
classify_detention_type <- function(contractor_type) {
  dplyr::case_when(
    contractor_type %in% c("Federal", "State", "County", "City") ~ "Public",
    contractor_type == "Private" ~ "Private",
    .default = NA_character_
  )
}

#' Get death counts by one or more groups.
#'
#' @param data The deaths to count.
#' @param ... The groups for counting.
get_death_counts <- function(data, ...) {
  data |>
    dplyr::group_by(...) |>
    dplyr::count() |>
    dplyr::rename(deaths_n = n)
}

#' Get the city from the death location field.
#'
#' Assumes that field has a newline character splitting city/state from the
#' specific location name (e.g., "Memorial Hospital\nAnytown, Anystate"). Also
#' assumes state name is spelled out (e.g., "Maryland" instead of "MD").
#'
#'@param location The location from which to extract the city
#'
#'@returns The extracted city
get_location_city <- function(location) {
  # some "states" aren't technically states
  state_allow_list = c("Egypt", "Puerto Rico") # Should additional states of interest arise, this will need to be revised
  city_state <- stringr::str_split_i(location, "\n", -1)
  state <- stringr::str_split_i(city_state, ",", -1)
  city <- stringr::str_split_i(city_state, ",", 1)
  dplyr::if_else(
    stringr::str_trim(state) %in%
      c(
        as.character(usdata::state_stats$state),
        state_allow_list
      ),
    stringr::str_trim(city),
    NA_character_
  )
}

#' Get the state from the death location field.
#'
#' Assumes that field has a newline character splitting city/state from the
#' specific location name (e.g., "Memorial Hospital\nAnytown, Anystate"). Also
#' assumes state name is spelled out (e.g., "Maryland" instead of "MD").
#'
#'@param location The location from which to extract the state.
#'
#'@returns The extracted state.
get_location_state <- function(location) {
  # some "states" aren't technically states
  state_allow_list = c("Egypt", "Puerto Rico") # Should additional states of interest arise, this will need to be revised
  city_state <- stringr::str_split_i(location, "\n", -1)
  state <- stringr::str_split_i(city_state, ",", -1)
  dplyr::if_else(
    stringr::str_trim(state) %in%
      c(
        as.character(usdata::state_stats$state),
        state_allow_list
      ),
    stringr::str_trim(state),
    NA_character_
  )
}

#' Ensure relative paths are resolved from project directory.
#'
#' @param path The relative path.
#' @returns The resolved path.
#'
#' @export
resolve_path <- function(path) {
  if (is.null(path) || is.na(path) || !nzchar(path)) {
    return(path)
  }
  if (grepl("^(/|[A-Za-z]+:[\\\\/])", path)) {
    return(path)
  }
  here::here(path)
}
