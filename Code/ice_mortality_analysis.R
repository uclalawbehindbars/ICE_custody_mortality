# Title: ICE Mortality Analysis
# Authors: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 5 February 2026
# Purpose: Analyze ICE mortality data.

library(common)
library(here)
library(lubridate)
library(yaml)
library(common)

common::source.all(here("Code/library"), isolate = FALSE)

# Data Import -----------------------------------------------------------------
config <- read_yaml(here("Code", "pipeline_config.yml"))
data_validated <- load_df("bbdp_data_clean", config)

# Analysis --------------------------------------------------------------------

## Overall counts

overall_fy <- data_validated |>
  get_death_counts(fiscal_year) |>
  arrange(fiscal_year)

overall_calyr <- data_validated |>
  get_death_counts(calendar_year) |>
  arrange(calendar_year)

overall_facility <- data_validated |>
  get_death_counts(detention_center_name) |>
  arrange(desc(deaths_n))


overall_state <- data_validated |>
  get_death_counts(detention_center_state) |>
  arrange(desc(deaths_n))

overall_facility_type <- data_validated |>
  get_death_counts(detention_center_type) |>
  arrange(desc(deaths_n))

### State-level counts
deaths_by_fy_state <- data_validated |>
  get_death_counts(fiscal_year, detention_center_state) |>
  arrange(fiscal_year, detention_center_state)

deaths_by_calyr_state <- data_validated |>
  get_death_counts(calendar_year, detention_center_state) |>
  arrange(calendar_year, detention_center_state)

### Facility-level counts

deaths_by_fy_facility <- data_validated |>
  get_death_counts(fiscal_year, detention_center_name) |>
  arrange(fiscal_year, detention_center_name)

deaths_by_calyr_facility <- data_validated |>
  get_death_counts(calendar_year, detention_center_name) |>
  arrange(calendar_year, detention_center_name)

### Contractor-level (public/private) counts
deaths_by_fy_detention_center_type <- data_validated |>
  get_death_counts(fiscal_year, detention_center_type) |>
  arrange(fiscal_year, detention_center_type)

deaths_by_calyr_detention_center_type <- data_validated |>
  get_death_counts(calendar_year, detention_center_type) |>
  arrange(calendar_year, detention_center_type)

# Save analysis artifacts -----------------------------------------------------
overall_fy |> write_csv(here("Data/Output/ice_deaths_by_fy.csv"))
overall_calyr |> write_csv(here("Data/Output/ice_deaths_by_year.csv"))
overall_state |> write_csv(here("Data/Output/ice_deaths_by_state.csv"))
overall_facility |> write_csv(here("Data/Output/ice_deaths_by_facility.csv"))
overall_facility_type |>
  write_csv(here("Data/Output/ice_deaths_by_facility_type.csv"))

deaths_by_fy_state |> write_csv(here("Data/Output/ice_deaths_by_fy_state.csv"))
deaths_by_calyr_state |>
  write_csv(here("Data/Output/ice_deaths_by_year_state.csv"))

deaths_by_fy_facility |>
  write_csv(here("Data/Output/ice_deaths_by_fy_facility.csv"))
deaths_by_calyr_facility |>
  write_csv(here("Data/Output/ice_deaths_by_year_facility.csv"))

deaths_by_fy_detention_center_type |>
  write_csv(here("Data/Output/ice_deaths_by_fy_facility_type.csv"))
deaths_by_calyr_detention_center_type |>
  write_csv(here("Data/Output/ice_deaths_by_calyr_facility_type.csv"))

