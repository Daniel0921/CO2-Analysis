# Methodology

## 1. Data-quality investigation

The source dataset contained `country`, `date`, `sector`, `value`, and Unix `timestamp` fields. During analysis, the text date field was found to contain mixed regional date formats. Dates such as `05/04/2019` are inherently ambiguous when the format is unknown.

The workflow therefore treats the Unix timestamp as the canonical temporal field and uses the text date only for quality auditing. This prevents ambiguous date parsing from changing reporting-period assignments.

## 2. Bi-yearly reporting rule

Each calendar year is divided at June 1:

- **H1 / Batch 1:** January 1 through May 31
- **H2 / Batch 2:** June 1 through December 31

For every sector and reporting period, the project calculates observation count, mean, median, standard deviation, variance, minimum, first quartile, third quartile, maximum, and range from the `value` field.

## 3. Visualization strategy

The visualization suite addresses different analytical questions rather than repeating the same metric in multiple forms. It includes time trends, H1/H2 comparisons, percentage changes, a heatmap, raw-value distributions, mean-versus-volatility analysis, quartile/range analysis, and sector-level small multiples.

## 4. Random Forest Regression

The Random Forest model predicts continuous CO2 values from country, sector, year, month, and reporting half. The observation-level dataset is split into 80% training and 20% testing data using a reproducible random seed. Model evaluation uses RMSE, MAE, and R-squared.

This is an exploratory predictive model rather than a production forecasting system. A random observation-level split can share historical patterns between the training and test sets, so the reported accuracy should not be interpreted as a forward-looking time-series backtest.

## 5. Logistic Regression

The Logistic Regression model predicts whether H2 mean CO2 values increase or decrease relative to H1. The modeling table contains one complete H1/H2 observation per sector-year. H1 mean, median, and standard deviation are used as predictors.

Because the aggregated classification dataset is small, the classifier is explicitly treated as a proof of concept. Accuracy alone is not sufficient; the project also reports precision, recall, specificity, F1 score, and the confusion matrix.
