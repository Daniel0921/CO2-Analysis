# Publishing Guide

## GitHub

Create a new repository, for example:

```text
co2-sector-analytics-r
```

Upload the contents of this package so that `README.md` is at the repository root.

If using Git from a terminal:

```bash
git init
git add .
git commit -m "Initial CO2 sector analytics portfolio release"
git branch -M main
git remote add origin <YOUR_REPOSITORY_REMOTE>
git push -u origin main
```

Do not commit the raw source CSV unless you have confirmed that redistribution is allowed.

## Upwork

Use `docs/UPWORK_PROJECT_DESCRIPTION.txt` as the basis for the project description. For the visual portfolio, prioritize a small number of high-information images rather than all outputs at once. Suggested showcase images:

1. `04_Sector_Heatmap.png`
2. `08_Faceted_Sector_Trends.png`
3. `10_Random_Forest_Actual_vs_Predicted.png`
4. `11_Random_Forest_Feature_Importance.png`
5. `14_Logistic_Confusion_Matrix.png`

Link the GitHub repository from the Upwork project when appropriate so technical reviewers can inspect the complete code and methodology.
