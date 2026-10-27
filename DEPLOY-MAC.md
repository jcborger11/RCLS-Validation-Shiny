# Deploy to shinyapps.io (Mac)

After merging to `main`, run these in **Terminal** on your Mac:

```bash
cd ~/path/to/RCLS-Validation-Shiny   # your clone
git checkout main
git pull origin main
Rscript scripts/deploy-shinyapps.R
```

**First time only** — in R, connect your shinyapps account ([Tokens](https://www.shinyapps.io/admin/#/tokens)):

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(
  name   = "YOUR_ACCOUNT_NAME",
  token  = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
```

Then run `Rscript scripts/deploy-shinyapps.R` again.

**Check:** [https://john-borger.shinyapps.io/rcls-validator/](https://john-borger.shinyapps.io/rcls-validator/) — sidebar should include **Check completability (CP-SAT)?**

CP-SAT on shinyapps may show E0 unless the server has Python + ortools; the pink toggle UI still deploys.
