# Install required packages only when they are not already available.
required_packages <- c(
  "dplyr",
  "tidyr",
  "lubridate",
  "ggplot2",
  "randomForest",
  "pROC",
  "scales"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, dependencies = TRUE)
} else {
  message("All required packages are already installed.")
}
