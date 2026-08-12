# Machine Learning Results

## Model 1 — Random Forest Regression

The Random Forest Regression model was built to predict the continuous CO2 `value` using country, sector, year, month, and reporting half.

### Test metrics

| Metric | Result |
|---|---:|
| RMSE | 3.2693 |
| MAE | 1.8054 |
| R-squared | 0.8864 |

The model captured approximately **88.6% of the variation in the test-set CO2 values**. The actual-versus-predicted plot shows that it learned the broad structure of the data and separated low-, medium-, and high-value observations reasonably well.

Feature importance indicates that **country was the dominant predictor**, followed by **sector**. Month, year, and the H1/H2 reporting indicator contributed much less to prediction. This suggests that geography and economic sector carried substantially more predictive information for CO2 magnitude than the simple reporting-period split.

The residual plot also identifies an important limitation: errors become larger for some high-value observations, especially within higher-emission sector clusters. The model therefore performs well as an exploratory predictive model but should not be presented as a production forecasting system.

## Model 2 — Logistic Regression

The Logistic Regression model was designed to classify whether a sector's H2 mean CO2 value would **Increase** or **Decrease** relative to H1 based on H1 summary statistics.

### Test metrics

| Metric | Result |
|---|---:|
| Accuracy | 71.43% |
| Precision | 71.43% |
| Recall | 100.00% |
| Specificity | 0.00% |
| F1 Score | 83.33% |

The confusion matrix provides the most important interpretation. The test set contained five actual increases and two actual decreases, while the model predicted **Increase for all seven observations**. It therefore detected every increase but failed to identify either decrease.

The 71.43% accuracy is consequently not evidence of a strong balanced classifier. Instead, the model exposed a limitation of the small, imbalanced aggregated dataset. It identified the dominant upward pattern but did not learn a reliable boundary for declining periods.

## Combined interpretation

The two models answer different questions:

- **Random Forest:** What CO2 magnitude should be expected?
- **Logistic Regression:** Is H2 more likely to increase or decrease relative to H1?

The results suggest that **CO2 magnitude was considerably more predictable from geography and sector characteristics than H1-to-H2 directional change was from H1 summary statistics alone**. The regression model produced strong exploratory predictive performance, while the classification experiment highlighted the importance of class balance and sample size when evaluating machine-learning results.
