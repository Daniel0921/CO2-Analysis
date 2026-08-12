# GitHub Upload Checklist

- [ ] Confirm you have the right to redistribute the original raw dataset before adding it to the repository.
- [ ] If redistribution is not permitted or is uncertain, keep `data/raw/CO2_Analysis.csv` local. The `.gitignore` already excludes raw CSV files.
- [ ] Review `README.md` in GitHub preview mode.
- [ ] Confirm all image links render correctly.
- [ ] Confirm no local Windows, OneDrive, username, email, API key, token, or private path appears in tracked files.
- [ ] Run `source("scripts/00_install_packages.R")` if dependencies are missing.
- [ ] Run `source("run_all.R")` from the repository root with the raw CSV present locally.
- [ ] Review regenerated outputs before committing.
- [ ] Add a license only if you intentionally choose one.
