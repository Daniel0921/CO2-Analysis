# CO2 Sector Analytics in R

An end-to-end R portfolio project covering **data quality, statistical analysis, data visualization, and machine learning**.

The project investigates CO2 values across economic sectors and reporting periods, beginning with a mixed-date-format data-quality problem and progressing through bi-yearly statistical summaries, eight visualizations, Random Forest regression, and Logistic Regression classification.

## Project workflow

```text
Raw CO2 Data
    ↓
Date Quality Audit
    ↓
Unix Timestamp Normalization
    ↓
Bi-Yearly Sector Statistical Summary
    ↓
8 Data Visualizations
    ↓
Random Forest Regression
    ↓
Logistic Regression Classification
    ↓
Model Evaluation & Interpretation
```

## Key analytical design

The source text date field contained a mixture of `MM/DD/YYYY` and `DD/MM/YYYY` formatting. Because ambiguous dates can be interpreted incorrectly, the project uses the Unix `timestamp` field as the canonical date and retains the text field for quality auditing.

Each year is split on June 1:

- **H1:** January 1 through May 31
- **H2:** June 1 through December 31

Sector-level statistics are calculated from the `value` column.

## Visualizations

The visualization suite includes:

1. Bi-Yearly Mean CO2 Trend by Sector
2. H1 vs H2 Comparison
3. H1-to-H2 Percentage Change
4. Sector Heatmap
5. Raw Value Distribution by Sector
6. Mean CO2 Value vs Statistical Volatility
7. Quartile and Range Analysis
8. Faceted Sector Trends

## Machine learning

### Random Forest Regression

The Random Forest predicts continuous CO2 values using country, sector, year, month, and reporting half.

| Metric | Test Result |
|---|---:|
| RMSE | 3.2693 |
| MAE | 1.8054 |
| R-squared | **0.8864** |

Country and sector emerged as the dominant predictive features. The model captured the broad structure of the observation-level data, although residual error increased for some high-value observations.

### Logistic Regression

The Logistic Regression model classifies whether a sector's H2 mean increases or decreases relative to H1.

| Metric | Test Result |
|---|---:|
| Accuracy | 71.43% |
| Precision | 71.43% |
| Recall | 100.00% |
| Specificity | 0.00% |
| F1 Score | 83.33% |

The confusion matrix shows why accuracy alone is insufficient: the small test set contained five increases and two decreases, and the model classified all seven observations as increases. The model, therefore, identified the dominant upward class but did not reliably identify declines.

This classifier is intentionally presented as an **exploratory proof of concept**, not a production forecasting model.

## Repository structure

```text
co2-sector-analytics-portfolio/
├── README.md
├── run_all.R
├── .gitignore
├── data/
│   ├── README.md
│   ├── raw/
│   │   └── CO2_Analysis.csv        # add source data here
│   └── processed/
│       ├── CO2_BiYearly_Sector_Summary.csv
│       └── H1_H2_Percentage_Change_Data.csv
├── scripts/
│   ├── 00_install_packages.R
│   ├── 01_data_quality_audit.R
│   ├── 02_biyearly_statistical_summary.R
│   ├── 03_data_visualization_suite.R
│   └── 04_machine_learning_models.R
├── outputs/
│   ├── visualizations/
│   └── machine_learning/
└── docs/
    ├── METHODOLOGY.md
    ├── MODEL_RESULTS.md
    └── UPWORK_PROJECT_DESCRIPTION.txt
```

## Requirements

R packages used:

- dplyr
- tidyr
- lubridate
- ggplot2
- randomForest
- pROC
- scales

Install them with:

```r
source("scripts/00_install_packages.R")
```

## Running the project

1. Clone or download the repository.
2. Place the source CSV at:

```text
data/raw/CO2_Analysis.csv
```

3. Open R or RStudio with the repository root as the working directory.
4. Install dependencies if necessary.
5. Run:

```r
source("run_all.R")
```

The project will regenerate processed analytical tables, visualizations, and machine-learning outputs.

## Notes on interpretation

This project is a portfolio analysis and learning exercise. The Random Forest uses a reproducible random observation-level train/test split rather than a temporal holdout, and the Logistic Regression uses a small aggregated H1/H2 dataset. Results are therefore interpreted as exploratory analytical evidence rather than production forecasting performance.

