# ICE Custody Mortality Repository

## Description

This repository collects, cleans, analyzes, and publishes data on deaths in ICE detention facilities in the United States to enable meaningful oversight, empirical research, and informed policy decision-making.

## Repository Structure

The `ICE_custody_mortality` repository includes the following:

* `/bin` : Contains quality assurance script using lintr.

* `/Code` : Includes all code used to process and validate Andrew Free's raw ICE data files. This includes subsetting into BBDP-validated .csvs and their analysis, available in the `/Data` folder.
  * `ice_mortality_validation.R` : The main data processing script, loading, cleaning, and validating Andrew Free's ICE Deaths in Detention dataset.
  * `ice_mortality_analysis.R` : Uses the BBDP-validated dataset to produce death counts by fiscal year, calendar year, state, detention facility, and detention facility type (public or private). Outputs are saved to `Data/Output/`.
  * `pipeline_config.yml` : Defines the data pipeline configuration, specifying sources, corrections, mutations, renamings, filters, joins, and output columns for each dataset used in the pipeline.
  *   * `/library` : Contains helper functions used throughout the data processing, cleaning, and validation pipeline.
    * `checks.R` : QA functions checking for missing values and flagging suspect values.
    * `logging.R` : Logging functions recording pipeline activity and printing warnings for suspect values.
    * `pipeline.R` : Core pipeline functions for loading, cleaning, and transforming datasets according to the config. This includes applying dataset corrections (e.g. renamings), mutations, filters, joins, and trimming our output column selections to reflect validated data.
    * `utils.R` : Utility functions for data cleaning and transformation, including name standardization, abbreviations processing, location parsing, and facility type classification.
    * `validation.R` : Cross-references the master dataset against external sources to validate death records.
  *`load_code_red.R` : Scrapes Human Rights Watch's Code Red report webpage to extract documented deaths, saving the file as a CSV in the `Data/Processed/` folder. This script is embedded into the data cleaning and validation pipeline.

* `/Data` : All data can be found within this folder or its subfolders.

  * `/Raw` : Includes raw data used to process or validate Andrew Free's ICE Death's in Custody dataset.

    * `facilities.csv` : Contains facility metadata largely sourced from the Vera Institute of Justice's ICE Detention Trends facilities [data](https://github.com/vera-institute/ice-detention-trends/tree/main/facilities) with some revisions to incorporate missing facilities where deaths occurred.
    * `facility-crosswalk.csv` : Standardizes facility names used in Andrew Free's dataset to IDs in `facilities.csv`.
    * `foia2003-2017.csv` : FOIA data scraped from ICE List of Death's in ICE Custody [FOIA release](https://www.ice.gov/doclib/foia/reports/detaineedeaths-2003-2017.pdf)
    * `population_data/`: Contains ICE-reported detention population data by fiscal year.

  * `/Processed` : Includes intermediate and final datasets produced by `ice_mortality_validation.R`.

    * `ice_deaths_validated.csv` : BBDP's final validated ICE Detention Deaths dataset.
    * `processed_ice_deaths_unvalidated.csv` : Full cleaned and processed dataset with only validated deaths, but containing additional unvalidated data from Andrew Free's ICE Death's in Detention data. BBDP cannot ensure the veracity of variables included in this file, but is included here for those interested in further exploring Andrew Free's data.
    * `ice_deaths_validated_foia.csv` : Contains deaths that were matched against our FOIA validation sources.
    * `ice_deaths_unvalidated_foia.csv` : Contains deaths that were not matched against our FOIA validation sources.
    * `ice_deaths_validated_code_red.csv` : Contains deaths that were matched against Human Rights Watch's Code Red report.
    * `ice_deaths_unvalidated_code_red.csv` : Contains deaths that were not matched against Human Rights Watch's Code Red report.
    * `ice_deaths_double_unvalidated.csv` : Contains deaths that could not be validated against either FOIA validation sources or the Code Red report.
    * `ice_deaths_citations_needed.csv` : Contains deaths that are both double unvalidated (by FOIA or Code Red sources) and lack ICE Press Release or Death Report links. These records required additional sourcing before they were included in the final BBDP dataset.
    * `CodeRed.csv` : Raw data scraped from Human Rights Watch's Code Red report in `load_code_red.R`. This is used as a deaths validation source.

  * `/Output` : Includes validated aggregated death count tables produced by `ice_mortality_analysis.R`.

    * Overall
      * `ice_deaths_by_fy.csv` : Total deaths by fiscal year
      * `ice_deaths_by_year.csv` : Total deaths by calendar year
    * By detention facility
      * `ice_deaths_by_facility.csv` : Total deaths by detention facility across all years
      * `ice_deaths_by_fy_facility.csv` : Total deaths by detention facility and fiscal year
      *  `ice_deaths_by_calyr_facility.csv` : Total deaths by detention facility and calendar year
    * By detention facility type (public/private)
      * `ice_deaths_by_facility_type.csv` : Total deaths by facility type across all years
      * `ice_deaths_by_fy_state.csv` : Total deaths by detention facility type and fiscal year
      * `ice_deaths_by_year_facility_type.csv` : Reported deaths by detention facility type and calendar year
    * By state
      * `ice_deaths_by_state.csv` : Total deaths by detention facility state across all years
      * `ice_deaths_by_fy_state.csv` : Total deaths by detention facility state and fiscal year
      * `ice_deaths_by_year_state.csv` : Total deaths by detention facility state and calendar year

* `renv.lock` : This project uses renv for package management. To restore the project library and install all required packages, you can run renv::restore() in the console.

* `/renv` : Contains renv activation and configuration files enabling package management. This folder does not contain the packages themselves.

## Data and Validation Sources

* Raw data is sourced from Andrew Free's ICE Deaths in Custody [dataset](https://docs.google.com/spreadsheets/d/1Zwpt9Uk2xJDX91rJ9f_s4zlSab4i8CaYW1E3FrogWjI/edit?gid=0#gid=0)

* To validate Andrew's dataset, we leverage data from the following:
  * ICE List of Deaths in ICE Custody [FOIA release](https://www.ice.gov/doclib/foia/reports/detaineedeaths-2003-2017.pdf)
  * Human Rights Watch's [Code Red Report](https://www.hrw.org/report/2018/06/20/code-red/fatal-consequences-dangerously-substandard-medical-care-immigration)
  * ICE [Detainee Death Reports](https://www.ice.gov/detain/detainee-death-reporting)
  * ICE [Press Releases](https://www.ice.gov/newsroom)
  * Vera Institute of Justice ICE Detention facilities [data](https://github.com/vera-institute/ice-detention-trends/tree/main)
  * Journalistic Reporting: In rare instances, news sources were used to clarify conflicts between sources (for example, how a name is spelled).

* *A Note on Edge Cases:* Our inclusion criteria reflect the limitations of available data. BBDP recognizes that there is no criteria that would include every death that could be linked to ICE detention. This repository includes all deaths occurring from the moment someone was booked into ICE custody through book out and the process of removal. Edge cases, including where someone died in ICE custody before being formally booked, or shortly after they were released, were individually considered but do not appear in this dataset. BBDP welcomes additional context that may help refine how edge cases are considered--whether they reflect deaths that are currently included in the final dataset or not.

## Data Dictionary

This section is under construction. You may note missing elements under revision.

### All files are within `/Data`

#### `/Raw` files

* `facilities.csv`: Data on ICE facilities, largely sourced from the Vera Institute of Justice's ICE Detention Trends [dataset](https://github.com/vera-institute/ice-detention-trends/tree/main/metadata)

  * `detention_facility_code` : Standardized unique identifier for each detention facility
  * `detention_facility_name_vera` : Facility name used by the Vera Institute of Justice
  * `detention_facility_name_bbdp` : Facility name used in the Beyond Bars Data Project's published dataset
  * `address` : Street address of detention facility
  * `city` : City location of detention facility
  * `county` : County location of detention facility
  * `state` : Abbreviated state location of detention facility
  * `zip` : Zip code of detention facility
  * `aor` : ICE Area of Responsibility, or the regional ICE field office with jurisdiction over the specified detention facility
  * `latitude` : Geographic latitude coordinate of detention facility
  * `longitude` : Geographic longitudinal coordinate of detention facility
  * `type_detailed` : Detailed classification of the detention facility type. Acronyms defined below.
    * BOP: Federal Bureau of Prisons facility
    * CDF: Contract Detention Facility
    * DIGSA: Dedicated Intergovernmental Services Agreement
    * Family: A facility certified to hold children and families
    * Hold: A temporary holding facility
    * Hospital: A hospital
    * IGSA: Intergovernmental Services Agreement
    * SPC: Service Processing Facility
    * Unknown: An unknown facility type
    * USMS IGSA: U.S. Marshals Intergovernmental Services Agreement
  * `type_grouped` : Grouped facility type, including:
    * Dedicated: A facility dedicated to immigrant detention
    * Family/Youth: A facility certified to hold children and families
    * Federal: A facility under the responsibility of the Federal Bureau of Prisons or the U.S. Marshals Service
    * Holding/Staging: A temporary holding or staging facility
    * Medical: A medical facility
    * Non-Dedicated: A facility that holds non-immigrants as well as immigrants
    * Other/Unknown: An other or unknown facility type
  * `contractor` : The name of the most recent facility contractor
  * `data_source` : Whether the data source came from the Vera Institute of Justice

* `facility-crosswalk.csv` : Standardizes facility names used in Andrew Free's dataset to IDs in `facilities.csv`.

  * `detention_center_raw` : The detention facility name as it appears in Andrew Free's dataset.
  * `state` : the state where the detention facility is located (disambiguates between facilities with identical names in different states)
  * `detention_facility_code` : The standardized facility unique identifing code

* `foia2003-2017.csv` : FOIA data scraped from ICE List of Death's in ICE Custody [FOIA release](https://www.ice.gov/doclib/foia/reports/detaineedeaths-2003-2017.pdf). Please see ICE documentation for variable descriptions.

* `population_data/`: Contains ICE-reported detention population data by fiscal year. Please see ICE documentation for variable descriptions.

* `CodeRed.csv` : Raw data scraped from Human Rights Watch's Code Red report in `load_code_red.R`. This is used as a deaths validation source. Please see the Code Red Report for variable details.

#### `/Processed` files

* `ice_deaths_validated.csv`: Behind Bars Data Projected full validated dataset, including only variables that were verified by BBDP. All detention center details are for the last detention center associated with the person who died before their death.

  * `name`: Name of the deceased person
  * `dod`: Date of death
  * `calendar_year`: Calendar year when death occurred
  * `fiscal_year`: Fiscal year (October-September) when death occurred
  * `gender`: The gender identity of the deceased person, or listed sex where gender isn't known
  * `age`: Age of the deceased person at time of death
  * `dob`: Deceased person's date of birth
  * `death_location`: Location where the person died
  * `death_city`: City where the person died
  * `death_state`: State where the person died
  * `detention_center_id`: Standardized detention center unique identifier
  * `detention_center_name`: Name of the detention center
  * `detention_center_state`: State where last detention center is located
  * `detention_center_city`: City where last detention center is located
  * `detention_center_aor`: ICE Area of Responsibility, or the regional ICE field office with jurisdiction over the detention center
  * `detention_center_type`: Detention center type, see `facilities.csv` data dictionary for type definitions
  * `detention_center_contractor_type`: Binary contractor type (public or private) of the detention centetr at time of death
  * `latitude` : Geographic latitude coordinate of the detention center
  * `longitude` : Geographic longitude coordinate of the detention center
  * `last_updated` : The last date the dataset was updated
  * `ice_press_release`: Link to the ICE press release announcing the person's death, if available
  * `ice_death_report`: Link to the ICE Detainee Death Report, if available
  * `additional_source`: Additional source used to validate data, if any

* `processed_ice_deaths_unvalidated.csv` : In addition to the variables above, this file includes:

  * `detention_center_contractor`: The most recent contractor affiliated with the detention center
  * `detention_center_contractor_type`: Categorical detention center contractor type (federal, state, county, municipal, or private)
  * `detention_center_type_detailed`: Detailed detention center type, see `facilities.csv` data dictionary entry for definitions

#### `/Output` files

Output file variable names mirror Processed variables, with the addition that `deaths_n` indicates the number of total deaths.

## How to Run Code

To generate the processed data files, run `Code/ice_mortality_validation.R` in your local environment. To generate analysis data files, run `Code/ice_mortality_analysis.R` in your local environment.

## Contact

Please contact Hena Vadher with any questions or suggestions at vadher@law.ucla.edu

## Acknowledgements

All data was initially collated by [Andrew Free](https://theintercept.com/staff/r-andrew-free/).
