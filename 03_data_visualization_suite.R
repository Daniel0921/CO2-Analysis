# ============================================================
# CO2 SECTOR ANALYTICS
# DATA VISUALIZATION SUITE
# ============================================================
#
# Creates eight visualizations:
#   1. Bi-Yearly Sector Trend
#   2. H1 vs H2 Comparison
#   3. H1-to-H2 Percentage Change
#   4. Sector Heatmap
#   5. Raw Value Distribution
#   6. Mean vs Volatility
#   7. Quartile / Range Analysis
#   8. Faceted Sector Trends
# ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(scales)

raw_file <- file.path("data", "raw", "CO2_Analysis.csv")
summary_file <- file.path("data", "processed", "CO2_BiYearly_Sector_Summary.csv")
output_directory <- file.path("outputs", "visualizations")

dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(raw_file)) {
  stop("Raw dataset missing. Place it at data/raw/CO2_Analysis.csv.")
}
if (!file.exists(summary_file)) {
  stop("Summary dataset missing. Run scripts/02_biyearly_statistical_summary.R first.")
}

raw_data <- read.csv(raw_file, stringsAsFactors = FALSE)
sector_summary <- read.csv(summary_file, stringsAsFactors = FALSE)

sector_summary <- sector_summary %>%
  mutate(
    year = as.numeric(year),
    half = case_when(
      grepl("Batch 1", batch, ignore.case = TRUE) ~ "H1",
      grepl("Batch 2", batch, ignore.case = TRUE) ~ "H2",
      TRUE ~ NA_character_
    ),
    reporting_period = paste(year, half)
  )

reporting_period_order <- sector_summary %>%
  distinct(year, half, reporting_period) %>%
  mutate(half_number = if_else(half == "H1", 1, 2)) %>%
  arrange(year, half_number) %>%
  pull(reporting_period)

sector_summary <- sector_summary %>%
  mutate(
    reporting_period = factor(reporting_period, levels = reporting_period_order)
  )

raw_data_clean <- raw_data %>%
  mutate(
    value = as.numeric(value),
    timestamp = as.numeric(timestamp),
    canonical_date = as.Date(
      as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC")
    ),
    year = year(canonical_date),
    half = if_else(month(canonical_date) < 6, "H1", "H2")
  ) %>%
  filter(!is.na(value), !is.na(sector), !is.na(canonical_date))

# 1. Bi-Yearly Mean CO2 Trend by Sector
plot_1 <- ggplot(
  sector_summary,
  aes(x = reporting_period, y = mean_value, group = sector, color = sector)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  labs(
    title = "Bi-Yearly Mean CO2 Value by Sector",
    subtitle = "Average sector values across first-half and second-half reporting periods",
    x = "Reporting Period", y = "Mean CO2 Value", color = "Sector",
    caption = "H1 = January-May | H2 = June-December"
  ) +
  scale_y_continuous(labels = label_number()) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "01_BiYearly_Sector_Trend.png"), plot_1,
       width = 12, height = 7, dpi = 300)

# 2. H1 vs H2 Comparison
plot_2 <- ggplot(
  sector_summary,
  aes(x = sector, y = mean_value, fill = half)
) +
  geom_col(position = position_dodge(width = 0.8)) +
  facet_wrap(~ year) +
  labs(
    title = "First-Half vs Second-Half CO2 Values",
    subtitle = "Comparison of mean sector values within each calendar year",
    x = "Sector", y = "Mean CO2 Value", fill = "Reporting Half",
    caption = "H1 = January-May | H2 = June-December"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "02_H1_vs_H2_Comparison.png"), plot_2,
       width = 14, height = 8, dpi = 300)

# 3. H1-to-H2 Percentage Change
half_change <- sector_summary %>%
  select(year, sector, half, mean_value) %>%
  pivot_wider(names_from = half, values_from = mean_value) %>%
  filter(!is.na(H1), !is.na(H2), H1 != 0) %>%
  mutate(percent_change = ((H2 - H1) / H1) * 100)

plot_3 <- ggplot(
  half_change,
  aes(x = sector, y = percent_change, fill = sector)
) +
  geom_col(show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  facet_wrap(~ year) +
  labs(
    title = "H1-to-H2 Percentage Change by Sector",
    subtitle = "Positive values indicate increases; negative values indicate decreases",
    x = "Sector", y = "Percent Change",
    caption = "Percentage change calculated from bi-yearly mean values"
  ) +
  scale_y_continuous(labels = label_number(suffix = "%")) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "03_H1_to_H2_Percent_Change.png"), plot_3,
       width = 14, height = 8, dpi = 300)

write.csv(
  half_change,
  file.path("data", "processed", "H1_H2_Percentage_Change_Data.csv"),
  row.names = FALSE
)

# 4. Sector Heatmap
plot_4 <- ggplot(
  sector_summary,
  aes(x = reporting_period, y = sector, fill = mean_value)
) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(mean_value, 2)), size = 3) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(
    title = "CO2 Sector Heatmap",
    subtitle = "Mean CO2 values across reporting periods",
    x = "Reporting Period", y = "Sector", fill = "Mean Value",
    caption = "Darker cells represent higher mean values"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "04_Sector_Heatmap.png"), plot_4,
       width = 12, height = 7, dpi = 300)

# 5. Raw Value Distribution by Sector
plot_5 <- ggplot(
  raw_data_clean,
  aes(x = sector, y = value, fill = sector)
) +
  geom_boxplot(show.legend = FALSE, outlier.alpha = 0.35) +
  labs(
    title = "Distribution of CO2 Values by Sector",
    subtitle = "Observation-level distribution, quartiles, and potential outliers",
    x = "Sector", y = "CO2 Value",
    caption = "Based on the original observation-level dataset"
  ) +
  scale_y_continuous(labels = label_number()) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "05_Sector_Value_Distributions.png"), plot_5,
       width = 12, height = 7, dpi = 300)

# 6. Mean vs Volatility
plot_6 <- ggplot(
  sector_summary,
  aes(x = mean_value, y = standard_deviation, color = sector)
) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title = "Mean CO2 Value vs Statistical Volatility",
    subtitle = "Relationship between average values and standard deviation",
    x = "Mean CO2 Value", y = "Standard Deviation", color = "Sector",
    caption = "Each point represents one sector and reporting period"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "06_Mean_vs_Volatility.png"), plot_6,
       width = 11, height = 7, dpi = 300)

# 7. Quartile and Range Analysis
plot_7 <- ggplot(sector_summary, aes(x = reporting_period)) +
  geom_linerange(aes(ymin = minimum, ymax = maximum), linewidth = 0.5, alpha = 0.6) +
  geom_linerange(aes(ymin = q1, ymax = q3), linewidth = 3) +
  geom_point(aes(y = median_value), size = 2.5) +
  facet_wrap(~ sector, scales = "free_y") +
  labs(
    title = "CO2 Quartile and Range Analysis",
    subtitle = "Minimum, maximum, interquartile range, and median by reporting period",
    x = "Reporting Period", y = "CO2 Value",
    caption = "Thin line = Min-Max | Thick line = Q1-Q3 | Point = Median"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "07_Quartile_Range_Analysis.png"), plot_7,
       width = 14, height = 10, dpi = 300)

# 8. Faceted Sector Trends
plot_8 <- ggplot(
  sector_summary,
  aes(x = reporting_period, y = mean_value, group = 1)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  facet_wrap(~ sector, scales = "free_y") +
  labs(
    title = "Individual CO2 Sector Trends",
    subtitle = "Bi-yearly mean values displayed independently for each sector",
    x = "Reporting Period", y = "Mean CO2 Value",
    caption = "Free y-axis scales highlight each sector's individual trend"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(output_directory, "08_Faceted_Sector_Trends.png"), plot_8,
       width = 14, height = 10, dpi = 300)

cat("\nCO2 VISUALIZATION SUITE COMPLETE\n")
cat("Output directory:", output_directory, "\n")
