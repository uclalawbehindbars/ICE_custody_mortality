# Title: ICE Mortality Validation
# Authors: Hena Vadher, Annette Dekker, and Ethan Corey for BBDP
# Date (Last Updated): 26 February 2026
# Date (Last Ran): 6 April 2026
# Purpose: Clean and validate ICE mortality data.

library(common)
library(here)
library(lubridate)
library(yaml)

common::source.all(here("Code/library"), isolate = FALSE)

options("logr.notes" = FALSE)
options("logr.autolog" = TRUE)


# Data Import -----------------------------------------------------------------
config <- read_yaml(here("Code", "pipeline_config.yml"))
log_file <- glue("ice_mortality_validation_{now()}.log")
data <- with_logging(log_file, load_df, "bbdp_ice_deaths", config)

# Validate against FOIA -------------------------------------------------------
check_foia <- load_df("foia2003-2017", config) # foia confirmed deaths 2003-Oct 2017 here: https://www.ice.gov/doclib/foia/reports/detaineedeaths-2003-2017.pdf

data_validated_foia <- validate_data(data, check_foia, "foia", name, dod)

unmatched_foia <- check_foia |>
  anti_join(
    data_validated_foia,
    by = c("name", "dod", "dob", "death_location_validation", "gender")
  ) # now returns none - great

if (nrow(unmatched_foia) != 0) {
  unmatched_foia |>
    write_csv(here("Data/Processed/ice_deaths_unmatched_foia.csv"))
  stop("Some rows don't match for the FOIA dataset!")
}

unvalidated_foia <- data_validated_foia |>
  filter(validated == FALSE)

validated_foia <- data_validated_foia |>
  filter(validated == TRUE)

# Validate against HRW Code Red report ----------------------------------------
check_code_red <- load_df("code_red", config)
data_validated_code_red <- validate_data(
  data,
  check_code_red,
  "code_red",
  name,
  dod
)

unmatched_code_red <- check_code_red |>
  anti_join(data_validated_code_red, by = c("name", "dod", "age"))

if (nrow(unmatched_code_red) != 0) {
  unmatched_code_red |>
    write_csv(here("Data/Processed/ice_deaths_unmatched_code_red.csv"))
  stop("Some rows don't match for Code Red!")
}

unvalidated_code_red <- data_validated_code_red |>
  filter(validated == FALSE)

validated_code_red <- data_validated_code_red |>
  filter(validated == TRUE)

# Separate validated and unvalidated deaths -----------------------------------
double_plus_unvalidated <- inner_join(
  unvalidated_foia,
  unvalidated_code_red |> select(name, dod),
  by = c("name", "dod")
)
citations_needed <- double_plus_unvalidated |>
  filter(is.na(ice_press_release) & is.na(ice_death_report))
data_validated <- data |>
  select(-ends_with("_validation")) |>
  mutate(
    additional_source = if_else(
      data_validated_code_red$validated,
      "Human Rights Watch Code Red",
      NA_character_
    )
  ) |>
  mutate(
    additional_source = if_else(
      data_validated_foia$validated,
      "ICE FOIA Death Log",
      additional_source
    )
  ) |>
  anti_join(citations_needed, by = c("name", "dod"))

# Trimmed fully-validated death data ------------------------------------------

trimmed <- data_validated |>
  mutate(
    detention_center_type = classify_detention_type(
      detention_center_contractor_type
    )
  ) |>
  select(
    name,
    dod,
    calendar_year,
    fiscal_year,
    gender,
    age,
    dob,
    listed_citizenship,
    death_location,
    death_city,
    death_state,
    detention_center_id,
    detention_center_name,
    detention_center_state,
    detention_center_city,
    detention_center_aor,
    detention_center_type,
    ice_press_release,
    ice_death_report,
    latitude,
    longitude,
    last_updated,
    additional_source
  )

# Output QA artifacts ---------------------------------------------------------
validated_foia |>
  write_csv(here("Data/Processed/ice_deaths_validated_foia.csv"))
validated_code_red |>
  write_csv(here("Data/Processed/ice_deaths_validated_code_red.csv"))
unvalidated_foia |>
  write_csv(here("Data/Processed/ice_deaths_unvalidated_foia.csv"))
unvalidated_code_red |>
  write_csv(here("Data/Processed/ice_deaths_unvalidated_code_red.csv"))
double_plus_unvalidated |>
  write_csv(here("Data/Processed/ice_deaths_double_unvalidated.csv"))
citations_needed |>
  write_csv(here("Data/Processed/ice_deaths_citations_needed.csv"))
data_validated |>
  write_csv(here("Data/Processed/processed_ice_deaths_unvalidated.csv"))
trimmed |>
  write_csv(here("Data/Processed/ice_deaths_validated.csv"))
