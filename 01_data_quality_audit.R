# ============================================================
# CO2 SECTOR ANALYTICS
# DATA QUALITY AUDIT
# ============================================================
#
# Purpose:
# Audit the source dataset for missing, invalid, or ambiguous
# text dates and compare them with the Unix timestamp field.
#
# Expected input:
#   data/raw/CO2_Analysis.csv
#
# Expected columns:
#   country, date, sector, value, timestamp
#
# The timestamp is treated as the canonical date because the
# source text date field contains mixed regional formats.
# ============================================================

library(dplyr)
library(lubridate)

input_file <- file.path("data", "raw", "CO2_Analysis.csv")
output_dir <- file.path("data", "processed")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop(
    paste0(
      "Raw dataset not found at: ", input_file,
      "\nPlace the source CSV in data/raw/CO2_Analysis.csv and rerun."
    )
  )
}

raw_data <- read.csv(input_file, stringsAsFactors = FALSE)

required_columns <- c("country", "date", "sector", "value", "timestamp")
missing_columns <- setdiff(required_columns, names(raw_data))

if (length(missing_columns) > 0) {
  stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
}

# Create multiple parsed versions of the text date for auditing.
date_audit <- raw_data %>%
  mutate(
    original_date = date,
    parsed_mdy = suppressWarnings(mdy(original_date)),
    parsed_dmy = suppressWarnings(dmy(original_date)),
    timestamp = as.numeric(timestamp),
    canonical_date = as.Date(
      as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC")
    ),
    missing_text_date = is.na(original_date) | trimws(original_date) == "",
    invalid_text_date = !missing_text_date & is.na(parsed_mdy) & is.na(parsed_dmy),
    ambiguous_text_date = !is.na(parsed_mdy) & !is.na(parsed_dmy) & parsed_mdy != parsed_dmy,
    mdy_matches_timestamp = !is.na(parsed_mdy) & parsed_mdy == canonical_date,
    dmy_matches_timestamp = !is.na(parsed_dmy) & parsed_dmy == canonical_date,
    date_quality_status = case_when(
      is.na(canonical_date) ~ "Missing/Invalid Timestamp",
      missing_text_date ~ "Missing Text Date",
      invalid_text_date ~ "Unparseable Text Date",
      mdy_matches_timestamp & !dmy_matches_timestamp ~ "MM/DD/YYYY",
      dmy_matches_timestamp & !mdy_matches_timestamp ~ "DD/MM/YYYY",
      mdy_matches_timestamp & dmy_matches_timestamp ~ "Unambiguous Same Date",
      ambiguous_text_date ~ "Ambiguous / Does Not Match Timestamp",
      TRUE ~ "Date Does Not Match Timestamp"
    )
  )

problem_records <- date_audit %>%
  filter(
    date_quality_status %in% c(
      "Missing/Invalid Timestamp",
      "Missing Text Date",
      "Unparseable Text Date",
      "Ambiguous / Does Not Match Timestamp",
      "Date Does Not Match Timestamp"
    )
  ) %>%
  select(
    country,
    sector,
    value,
    original_date,
    canonical_date,
    date_quality_status,
    timestamp
  )

sector_quality_summary <- date_audit %>%
  count(sector, date_quality_status, name = "record_count") %>%
  arrange(sector, desc(record_count))

write.csv(
  problem_records,
  file.path(output_dir, "CO2_Date_Quality_Exceptions.csv"),
  row.names = FALSE
)

write.csv(
  sector_quality_summary,
  file.path(output_dir, "CO2_Date_Quality_Summary.csv"),
  row.names = FALSE
)

cat("\nCO2 DATE QUALITY AUDIT COMPLETE\n")
cat("Total source rows:", nrow(raw_data), "\n")
cat("Problem records:", nrow(problem_records), "\n")
cat("Canonical date source: Unix timestamp\n")
