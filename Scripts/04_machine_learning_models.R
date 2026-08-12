# ============================================================
# CO2 MACHINE LEARNING MODELS
# ============================================================
#
# MODEL 1:
# Random Forest Regression
# Predict continuous CO2 "value"
#
# MODEL 2:
# Logistic Regression
# Predict whether H2 CO2 values increase or decrease
# compared with H1
#
# ============================================================


# ============================================================
# 1. LOAD REQUIRED LIBRARIES
# ============================================================

library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(randomForest)
library(pROC)
library(scales)

# NOTE:
# caret is intentionally NOT used in this project.
# Train/test splitting and confusion-matrix metrics are
# calculated directly with base R to reduce package dependencies.


# ============================================================
# 2. LOAD DATA
# ============================================================

# Original observation-level dataset
raw_data <- read.csv(
  file.path("data", "raw", "CO2_Analysis.csv"),
  stringsAsFactors = FALSE
)

# Bi-yearly statistical summary
sector_summary <- read.csv(
  file.path("data", "processed", "CO2_BiYearly_Sector_Summary.csv"),
  stringsAsFactors = FALSE
)


# ============================================================
# 3. CREATE OUTPUT DIRECTORY
# ============================================================

output_directory <- file.path("outputs", "machine_learning")

dir.create(
  output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!file.exists(file.path("data", "raw", "CO2_Analysis.csv"))) {
  stop("Raw dataset missing. Place it at data/raw/CO2_Analysis.csv.")
}

if (!file.exists(file.path("data", "processed", "CO2_BiYearly_Sector_Summary.csv"))) {
  stop("Summary dataset missing. Run scripts/02_biyearly_statistical_summary.R first.")
}


# ============================================================
# 4. SET RANDOM SEED
# ============================================================
#
# Setting a seed makes the train/test split reproducible.
# ============================================================

set.seed(123)


# ============================================================
# ============================================================
#
# MODEL 1
#
# RANDOM FOREST REGRESSION
#
# ============================================================
# ============================================================


# ============================================================
# 5. PREPARE RAW DATA FOR RANDOM FOREST
# ============================================================
#
# The Unix timestamp is used as the authoritative date because
# the text date field contains mixed MM/DD/YYYY and DD/MM/YYYY
# formatting.
#
# Prediction Target:
#
#   value
#
# Predictor Variables:
#
#   country
#   sector
#   year
#   month
#   reporting_half
#
# ============================================================

rf_data <- raw_data %>%
  
  mutate(
    
    value = as.numeric(value),
    
    timestamp = as.numeric(timestamp),
    
    canonical_date = as.Date(
      as.POSIXct(
        timestamp,
        origin = "1970-01-01",
        tz = "UTC"
      )
    ),
    
    year = year(canonical_date),
    
    month = month(canonical_date),
    
    reporting_half = if_else(
      month < 6,
      "H1",
      "H2"
    ),
    
    country = as.factor(country),
    
    sector = as.factor(sector),
    
    reporting_half = as.factor(reporting_half)
    
  ) %>%
  
  select(
    value,
    country,
    sector,
    year,
    month,
    reporting_half
  ) %>%
  
  filter(
    complete.cases(.)
  )


# ============================================================
# 6. INSPECT RANDOM FOREST DATA
# ============================================================

print("RANDOM FOREST DATA:")

print(
  dim(rf_data)
)

head(rf_data)

summary(rf_data)


# ============================================================
# 7. CREATE RANDOM FOREST TRAIN / TEST SPLIT
# ============================================================
#
# 80% = training data
# 20% = testing data
#
# Base R sampling is used here so the project does not depend
# on the caret package.
#
# ============================================================

set.seed(123)

rf_training_rows <- sample(
  seq_len(nrow(rf_data)),
  size = floor(0.80 * nrow(rf_data))
)

rf_train <- rf_data[
  rf_training_rows,
]

rf_test <- rf_data[
  -rf_training_rows,
]


cat(
  "\nRandom Forest Training Rows:",
  nrow(rf_train),
  "\n"
)

cat(
  "Random Forest Testing Rows:",
  nrow(rf_test),
  "\n"
)


# ============================================================
# 8. TRAIN RANDOM FOREST REGRESSION MODEL
# ============================================================
#
# ntree:
# Number of decision trees in the forest
#
# importance = TRUE:
# Allows variable importance to be calculated later
#
# ============================================================

rf_model <- randomForest(
  
  value ~
    country +
    sector +
    year +
    month +
    reporting_half,
  
  data = rf_train,
  
  ntree = 500,
  
  importance = TRUE
)


# ============================================================
# 9. VIEW RANDOM FOREST MODEL
# ============================================================

print(rf_model)


# ============================================================
# 10. CREATE RANDOM FOREST PREDICTIONS
# ============================================================

rf_predictions <- predict(
  rf_model,
  newdata = rf_test
)


rf_results <- rf_test %>%
  mutate(
    
    predicted_value = rf_predictions,
    
    residual = value - predicted_value
    
  )


# ============================================================
# 11. RANDOM FOREST EVALUATION METRICS
# ============================================================
#
# RMSE:
# Root Mean Squared Error
#
# MAE:
# Mean Absolute Error
#
# R-Squared:
# Proportion of observed variation explained by the model
#
# ============================================================

rf_rmse <- sqrt(
  mean(
    (
      rf_results$value -
        rf_results$predicted_value
    )^2
  )
)


rf_mae <- mean(
  abs(
    rf_results$value -
      rf_results$predicted_value
  )
)


rf_r_squared <- cor(
  rf_results$value,
  rf_results$predicted_value
)^2


rf_metrics <- data.frame(
  
  Metric = c(
    "RMSE",
    "MAE",
    "R-Squared"
  ),
  
  Value = c(
    rf_rmse,
    rf_mae,
    rf_r_squared
  )
)


print(
  rf_metrics
)


# ============================================================
# 12. EXPORT RANDOM FOREST METRICS
# ============================================================

write.csv(
  rf_metrics,
  file.path(
    output_directory,
    "Random_Forest_Model_Metrics.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 13. EXPORT RANDOM FOREST PREDICTIONS
# ============================================================

write.csv(
  rf_results,
  file.path(
    output_directory,
    "Random_Forest_Predictions.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 14. RANDOM FOREST VISUALIZATION 1
#
# ACTUAL VS PREDICTED
# ============================================================
#
# A strong model should place points close to the diagonal
# reference line.
#
# ============================================================

rf_plot_1 <- ggplot(
  rf_results,
  aes(
    x = value,
    y = predicted_value,
    color = sector
  )
) +
  
  geom_point(
    alpha = 0.65,
    size = 2
  ) +
  
  geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    color = "black"
  ) +
  
  labs(
    title = "Random Forest: Actual vs Predicted CO2 Values",
    subtitle = "Observed CO2 values compared with Random Forest predictions",
    x = "Actual CO2 Value",
    y = "Predicted CO2 Value",
    color = "Sector",
    caption = "Points closer to the dashed line indicate more accurate predictions"
  ) +
  
  theme_minimal() +
  
  theme(
    legend.position = "bottom",
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  rf_plot_1
)


ggsave(
  filename = file.path(
    output_directory,
    "10_Random_Forest_Actual_vs_Predicted.png"
  ),
  plot = rf_plot_1,
  width = 11,
  height = 7,
  dpi = 300
)


# ============================================================
# 15. RANDOM FOREST VISUALIZATION 2
#
# FEATURE IMPORTANCE
# ============================================================
#
# IncNodePurity measures how much each variable contributed
# to reducing prediction error across the decision trees.
#
# ============================================================

rf_importance <- importance(
  rf_model
)


rf_importance_data <- data.frame(
  
  Feature = rownames(
    rf_importance
  ),
  
  Importance = rf_importance[
    ,
    "IncNodePurity"
  ],
  
  row.names = NULL
) %>%
  
  arrange(
    Importance
  )


rf_plot_2 <- ggplot(
  rf_importance_data,
  aes(
    x = reorder(
      Feature,
      Importance
    ),
    y = Importance
  )
) +
  
  geom_col(
    fill = "steelblue"
  ) +
  
  coord_flip() +
  
  labs(
    title = "Random Forest Feature Importance",
    subtitle = "Relative contribution of predictors to CO2 value prediction",
    x = "Predictor",
    y = "Increase in Node Purity",
    caption = "Higher values indicate greater influence within the Random Forest"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  rf_plot_2
)


ggsave(
  filename = file.path(
    output_directory,
    "11_Random_Forest_Feature_Importance.png"
  ),
  plot = rf_plot_2,
  width = 10,
  height = 7,
  dpi = 300
)


# ============================================================
# 16. RANDOM FOREST VISUALIZATION 3
#
# RESIDUAL ANALYSIS
# ============================================================
#
# Residual:
#
# Actual Value - Predicted Value
#
# Ideally residuals should be centered around zero without
# a strong systematic pattern.
#
# ============================================================

rf_plot_3 <- ggplot(
  rf_results,
  aes(
    x = predicted_value,
    y = residual,
    color = sector
  )
) +
  
  geom_point(
    alpha = 0.65
  ) +
  
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    color = "black"
  ) +
  
  labs(
    title = "Random Forest Residual Analysis",
    subtitle = "Prediction error across fitted CO2 values",
    x = "Predicted CO2 Value",
    y = "Residual",
    color = "Sector",
    caption = "Residual = Actual CO2 Value - Predicted CO2 Value"
  ) +
  
  theme_minimal() +
  
  theme(
    legend.position = "bottom",
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  rf_plot_3
)


ggsave(
  filename = file.path(
    output_directory,
    "12_Random_Forest_Residuals.png"
  ),
  plot = rf_plot_3,
  width = 11,
  height = 7,
  dpi = 300
)


# ============================================================
# ============================================================
#
# MODEL 2
#
# LOGISTIC REGRESSION
#
# ============================================================
# ============================================================


# ============================================================
# 17. PREPARE BI-YEARLY DATA
# ============================================================
#
# Logistic Regression will answer:
#
# Based on H1 characteristics, is the sector's H2 mean
# expected to INCREASE or DECREASE?
#
# The H1 and H2 summary values are converted into a single
# row per:
#
#   year
#   sector
#
# ============================================================

logistic_source <- sector_summary %>%
  
  mutate(
    
    half = case_when(
      
      grepl(
        "Batch 1",
        batch,
        ignore.case = TRUE
      ) ~ "H1",
      
      grepl(
        "Batch 2",
        batch,
        ignore.case = TRUE
      ) ~ "H2",
      
      TRUE ~ NA_character_
      
    )
    
  )


# ============================================================
# 18. BUILD H1/H2 MODELING TABLE
# ============================================================

logistic_data <- logistic_source %>%
  
  select(
    year,
    sector,
    half,
    mean_value,
    median_value,
    standard_deviation,
    variance,
    minimum,
    q1,
    q3,
    maximum,
    range
  ) %>%
  
  pivot_wider(
    
    names_from = half,
    
    values_from = c(
      mean_value,
      median_value,
      standard_deviation,
      variance,
      minimum,
      q1,
      q3,
      maximum,
      range
    )
  ) %>%
  
  filter(
    !is.na(mean_value_H1),
    !is.na(mean_value_H2)
  ) %>%
  
  mutate(
    
    direction = if_else(
      mean_value_H2 > mean_value_H1,
      "Increase",
      "Decrease"
    ),
    
    direction = factor(
      direction,
      levels = c(
        "Decrease",
        "Increase"
      )
    ),
    
    percent_change = (
      (
        mean_value_H2 -
          mean_value_H1
      ) /
        mean_value_H1
    ) * 100,
    
    sector = as.factor(
      sector
    )
    
  )


# ============================================================
# 19. INSPECT LOGISTIC REGRESSION DATA
# ============================================================

print(
  logistic_data
)

table(
  logistic_data$direction
)


# ============================================================
# 20. IMPORTANT SAMPLE-SIZE NOTE
# ============================================================
#
# This dataset only contains a small number of complete
# sector/year H1-H2 combinations.
#
# Therefore, this classification model should be treated as
# an exploratory / proof-of-concept machine learning model.
#
# It is not intended to represent a production-ready
# forecasting system.
#
# ============================================================

cat(
  "\nComplete H1/H2 observations available for logistic regression:",
  nrow(logistic_data),
  "\n"
)


# ============================================================
# 21. CREATE LOGISTIC TRAIN / TEST SPLIT
# ============================================================
#
# Because the dataset is small, use a 75/25 split.
#
# Base R sampling is used here so the project does not depend
# on the caret package.
#
# NOTE:
# Because this modeling table is small, the test set may contain
# only a few examples of each class. Results should therefore be
# treated as exploratory.
#
# ============================================================

set.seed(123)

# Create a base-R stratified split so both Increase and
# Decrease observations are represented as consistently as
# possible in the training and testing sets.

increase_rows <- which(
  logistic_data$direction == "Increase"
)

decrease_rows <- which(
  logistic_data$direction == "Decrease"
)


increase_train_rows <- sample(
  increase_rows,
  size = max(
    1,
    floor(
      0.75 * length(increase_rows)
    )
  )
)

decrease_train_rows <- sample(
  decrease_rows,
  size = max(
    1,
    floor(
      0.75 * length(decrease_rows)
    )
  )
)


logistic_training_rows <- sort(
  c(
    increase_train_rows,
    decrease_train_rows
  )
)


logistic_train <- logistic_data[
  logistic_training_rows,
]

logistic_test <- logistic_data[
  -logistic_training_rows,
]


cat(
  "\nLogistic Training Rows:",
  nrow(logistic_train),
  "\n"
)

cat(
  "Logistic Testing Rows:",
  nrow(logistic_test),
  "\n"
)


# ============================================================
# 22. TRAIN LOGISTIC REGRESSION MODEL
# ============================================================
#
# Because the dataset is very small, we intentionally avoid
# throwing every available variable into the model.
#
# Predictors:
#
#   H1 Mean
#   H1 Standard Deviation
#   H1 Median
#
# Target:
#
#   Increase vs Decrease
#
# ============================================================

logistic_model <- glm(
  
  direction ~
    mean_value_H1 +
    standard_deviation_H1 +
    median_value_H1,
  
  data = logistic_train,
  
  family = binomial(
    link = "logit"
  )
)


# ============================================================
# 23. VIEW LOGISTIC MODEL SUMMARY
# ============================================================

summary(
  logistic_model
)


# ============================================================
# 24. CREATE LOGISTIC PROBABILITY PREDICTIONS
# ============================================================

logistic_probability <- predict(
  
  logistic_model,
  
  newdata = logistic_test,
  
  type = "response"
)


# ============================================================
# 25. CONVERT PROBABILITY TO CLASSIFICATION
# ============================================================
#
# Threshold:
#
# >= 0.50 = Increase
#
# < 0.50 = Decrease
#
# ============================================================

logistic_prediction <- ifelse(
  
  logistic_probability >= 0.50,
  
  "Increase",
  
  "Decrease"
)


logistic_prediction <- factor(
  
  logistic_prediction,
  
  levels = c(
    "Decrease",
    "Increase"
  )
)


# ============================================================
# 26. CREATE LOGISTIC RESULTS TABLE
# ============================================================

logistic_results <- logistic_test %>%
  
  mutate(
    
    predicted_probability_increase =
      logistic_probability,
    
    predicted_direction =
      logistic_prediction,
    
    correct_prediction =
      direction == predicted_direction
    
  )


print(
  logistic_results
)


# ============================================================
# 27. CONFUSION MATRIX
# ============================================================

confusion_matrix <- table(
  Predicted = logistic_prediction,
  Actual = logistic_test$direction
)

print(confusion_matrix)


# ============================================================
# 28. EXTRACT LOGISTIC MODEL METRICS
# ============================================================

# Extract the four confusion-matrix outcomes.
#
# Because both the Actual and Predicted variables are factors
# with the same two levels, the table remains 2 x 2 even if a
# particular outcome has a count of zero.
#
# Positive class = "Increase"

true_positive <- confusion_matrix[
  "Increase",
  "Increase"
]

true_negative <- confusion_matrix[
  "Decrease",
  "Decrease"
]

false_positive <- confusion_matrix[
  "Increase",
  "Decrease"
]

false_negative <- confusion_matrix[
  "Decrease",
  "Increase"
]


# Safe division helper.
#
# If a metric has a denominator of zero, return NA instead of
# stopping the script or producing Inf/NaN.

safe_divide <- function(
    numerator,
    denominator
) {
  
  if (
    is.na(denominator) ||
    !is.finite(denominator) ||
    denominator == 0
  ) {
    
    return(
      NA_real_
    )
    
  }
  
  numerator / denominator
}


logistic_accuracy <- safe_divide(
  
  true_positive +
    true_negative,
  
  true_positive +
    true_negative +
    false_positive +
    false_negative
)


logistic_precision <- safe_divide(
  
  true_positive,
  
  true_positive +
    false_positive
)


logistic_recall <- safe_divide(
  
  true_positive,
  
  true_positive +
    false_negative
)


logistic_specificity <- safe_divide(
  
  true_negative,
  
  true_negative +
    false_positive
)


logistic_f1 <- safe_divide(
  
  2 *
    logistic_precision *
    logistic_recall,
  
  logistic_precision +
    logistic_recall
)


logistic_metrics <- data.frame(
  
  Metric = c(
    "Accuracy",
    "Precision",
    "Recall",
    "Specificity",
    "F1 Score"
  ),
  
  Value = c(
    logistic_accuracy,
    logistic_precision,
    logistic_recall,
    logistic_specificity,
    logistic_f1
  )
)


print(
  logistic_metrics
)


# ============================================================
# 29. EXPORT LOGISTIC METRICS
# ============================================================

write.csv(
  
  logistic_metrics,
  
  file.path(
    output_directory,
    "Logistic_Regression_Model_Metrics.csv"
  ),
  
  row.names = FALSE
)


# ============================================================
# 30. EXPORT LOGISTIC PREDICTIONS
# ============================================================

write.csv(
  
  logistic_results,
  
  file.path(
    output_directory,
    "Logistic_Regression_Predictions.csv"
  ),
  
  row.names = FALSE
)


# ============================================================
# 31. LOGISTIC VISUALIZATION 1
#
# PREDICTED PROBABILITY OF H2 INCREASE
# ============================================================

logistic_results <- logistic_results %>%
  
  mutate(
    
    observation = paste(
      year,
      sector,
      sep = " - "
    )
    
  )


logistic_plot_1 <- ggplot(
  
  logistic_results,
  
  aes(
    x = reorder(
      observation,
      predicted_probability_increase
    ),
    y = predicted_probability_increase,
    fill = direction
  )
) +
  
  geom_col() +
  
  geom_hline(
    yintercept = 0.50,
    linetype = "dashed"
  ) +
  
  coord_flip() +
  
  scale_y_continuous(
    labels = percent_format(
      accuracy = 1
    ),
    limits = c(
      0,
      1
    )
  ) +
  
  labs(
    title = "Logistic Regression: Probability of H2 Increase",
    subtitle = "Predicted probability that second-half mean CO2 exceeds first-half mean CO2",
    x = "Sector-Year",
    y = "Predicted Probability",
    fill = "Actual Direction",
    caption = "Dashed line represents the 50% classification threshold"
  ) +
  
  theme_minimal() +
  
  theme(
    legend.position = "bottom",
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  logistic_plot_1
)


ggsave(
  
  filename = file.path(
    output_directory,
    "13_Logistic_Classification_Probability.png"
  ),
  
  plot = logistic_plot_1,
  
  width = 11,
  
  height = 7,
  
  dpi = 300
)


# ============================================================
# 32. LOGISTIC VISUALIZATION 2
#
# CONFUSION MATRIX HEATMAP
# ============================================================

confusion_table <- as.data.frame(
  confusion_matrix
)


names(
  confusion_table
) <- c(
  "Predicted",
  "Actual",
  "Count"
)


logistic_plot_2 <- ggplot(
  
  confusion_table,
  
  aes(
    x = Actual,
    y = Predicted,
    fill = Count
  )
) +
  
  geom_tile(
    color = "white"
  ) +
  
  geom_text(
    aes(
      label = Count
    ),
    size = 6
  ) +
  
  scale_fill_gradient(
    low = "white",
    high = "steelblue"
  ) +
  
  labs(
    title = "Logistic Regression Confusion Matrix",
    subtitle = "Comparison of actual and predicted H2 direction",
    x = "Actual Direction",
    y = "Predicted Direction",
    fill = "Count"
  ) +
  
  theme_minimal() +
  
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  logistic_plot_2
)


ggsave(
  
  filename = file.path(
    output_directory,
    "14_Logistic_Confusion_Matrix.png"
  ),
  
  plot = logistic_plot_2,
  
  width = 8,
  
  height = 7,
  
  dpi = 300
)


# ============================================================
# 33. LOGISTIC VISUALIZATION 3
#
# ACTUAL VS PREDICTED DIRECTION
# ============================================================

logistic_plot_3 <- logistic_results %>%
  
  select(
    observation,
    direction,
    predicted_direction
  ) %>%
  
  pivot_longer(
    
    cols = c(
      direction,
      predicted_direction
    ),
    
    names_to = "Prediction_Type",
    
    values_to = "Direction"
  ) %>%
  
  mutate(
    
    Prediction_Type = recode(
      
      Prediction_Type,
      
      direction = "Actual",
      
      predicted_direction = "Predicted"
    )
    
  ) %>%
  
  ggplot(
    
    aes(
      x = observation,
      y = Prediction_Type,
      color = Direction
    )
    
  ) +
  
  geom_point(
    size = 4
  ) +
  
  labs(
    title = "Actual vs Predicted H2 Direction",
    subtitle = "Logistic Regression classification results by sector-year",
    x = "Sector-Year",
    y = "",
    color = "Direction"
  ) +
  
  theme_minimal() +
  
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    ),
    
    legend.position = "bottom",
    
    plot.title = element_text(
      face = "bold"
    )
  )


print(
  logistic_plot_3
)


ggsave(
  
  filename = file.path(
    output_directory,
    "15_H2_Direction_Predictions.png"
  ),
  
  plot = logistic_plot_3,
  
  width = 12,
  
  height = 7,
  
  dpi = 300
)


# ============================================================
# 34. OPTIONAL ROC CURVE
# ============================================================
#
# ROC analysis evaluates classification performance across
# multiple probability thresholds rather than only 0.50.
#
# Because this test sample is small, interpret the ROC/AUC
# result cautiously.
#
# ============================================================

if (
  length(
    unique(
      logistic_test$direction
    )
  ) == 2
) {
  
  logistic_roc <- roc(
    
    response =
      logistic_test$direction,
    
    predictor =
      logistic_probability,
    
    levels = c(
      "Decrease",
      "Increase"
    ),
    
    direction = "<"
  )
  
  
  logistic_auc <- auc(
    logistic_roc
  )
  
  
  cat(
    "\nLogistic Regression AUC:",
    as.numeric(
      logistic_auc
    ),
    "\n"
  )
  
}


# ============================================================
# 35. MODEL COMPARISON SUMMARY
# ============================================================

cat(
  "\n",
  "============================================================\n",
  "CO2 MACHINE LEARNING ANALYSIS COMPLETE\n",
  "============================================================\n",
  "\n",
  "MODEL 1: RANDOM FOREST REGRESSION\n",
  "\n",
  "Target: Continuous CO2 Value\n",
  "\n",
  "RMSE:",
  round(
    rf_rmse,
    4
  ),
  "\n",
  "MAE:",
  round(
    rf_mae,
    4
  ),
  "\n",
  "R-Squared:",
  round(
    rf_r_squared,
    4
  ),
  "\n",
  "\n",
  "MODEL 2: LOGISTIC REGRESSION\n",
  "\n",
  "Target: H2 Increase / Decrease\n",
  "\n",
  "Accuracy:",
  round(
    logistic_accuracy,
    4
  ),
  "\n",
  "Precision:",
  round(
    logistic_precision,
    4
  ),
  "\n",
  "Recall:",
  round(
    logistic_recall,
    4
  ),
  "\n",
  "F1 Score:",
  round(
    logistic_f1,
    4
  ),
  "\n",
  "\n",
  "Output Directory:\n",
  output_directory,
  "\n",
  "\n",
  "============================================================\n"
)
