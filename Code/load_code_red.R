library(dplyr)
library(here)
library(readr)
library(rvest)

code_red_url <- paste0(
  "https://www.hrw.org/report/2018/06/20/code-red/",
  "fatal-consequences-dangerously-substandard-medical-care-immigration"
)

html <- read_html(code_red_url)

html %>%
  html_element(".WordSection3 table") %>%
  html_table() %>%
  rename(
    Name = X2,
    Gender = X3,
    Age.Death = X4,
    Country.Birth = X5,
    Death.Date = X6,
    Detention.Center = X7,
    Death.Review.Published = X8,
    Poor.Care.Contributed = X9,
    Dangerous.Practices = X10
  ) %>%
  select(-X1) %>%
  filter(
    Name != "Gender",
    Name != "Name"
  ) %>%
  write_csv(here("Data", "Raw", "CodeRed.csv"), )
