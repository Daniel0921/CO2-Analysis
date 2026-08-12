# ============================================================
# CO2 SECTOR ANALYTICS
# BI-YEARLY STATISTICAL SUMMARY BY SECTOR
# ============================================================
#
# Reporting rule:
#   H1 / Batch 1 = January 1 through May 31
#   H2 / Batch 2 = June 1 through December 31
#
# Statistics are calculated from the "value" column.
# The Unix timestamp is used as the canonical date.
# ============================================================

library(dplyr)
library(lubridate)

input_file <- file.path("data", "raw", "CO2_Analysis.csv")
output_file <- file.path("data", "processed", "CO2_BiYearly_Sector_Summary.csv")

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop(
    paste0(
      "Raw dataset not found at: ", input_file,
      "\nPlace the source CSV in data/raw/CO2_Analysis.csv and rerun."
    )
  )
}

data <- read.csv(input_file, stringsAsFactors = FALSE)

required_columns <- c("sector", "value", "timestamp")
missing_columns <- setdiff(required_columns, names(data))
if (length(missing_columns) > 0) {
  stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
}

data_clean <- data %>%
  mutate(
    value = as.numeric(value),
    timestamp = as.numeric(timestamp),
    canonical_date = as.Date(
      as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC")
    ),
    year = year(canonical_date),
    batch = if_else(
      month(canonical_date) < 6,
      "Batch 1: Jan-May",
      "Batch 2: Jun-Dec"
    )
  ) %>%
  filter(!is.na(canonical_date), !is.na(value), !is.na(sector), sector != "")

sector_summary <- data_clean %>%
  group_by(year, sector, batch) %>%
  summarise(
    observations = n(),
    mean_value = mean(value, na.rm = TRUE),
    median_value = median(value, na.rm = TRUE),
    standard_deviation = sd(value, na.rm = TRUE),
    variance = var(value, na.rm = TRUE),
    minimum = min(value, na.rm = TRUE),
    q1 = quantile(value, 0.25, na.rm = TRUE),
    q3 = quantile(value, 0.75, na.rm = TRUE),
    maximum = max(value, na.rm = TRUE),
    range = maximum - minimum,
    .groups = "drop"
  ) %>%
  arrange(year, sector, batch)

write.csv(sector_summary, output_file, row.names = FALSE)

print(sector_summary)
cat("\nBi-yearly sector summary written to:", output_file, "\n")
