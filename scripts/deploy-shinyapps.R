#!/usr/bin/env Rscript
# Deploy RCLS Validator to shinyapps.io from repo root.
# Usage (Terminal on your Mac):
#   cd /path/to/RCLS-Validation-Shiny
#   git pull origin main
#   Rscript scripts/deploy-shinyapps.R

if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

root <- normalizePath(getwd(), winslash = "/")
if (!file.exists(file.path(root, "app.R"))) {
  stop(
    "Run this from the repo root (folder containing app.R).\n",
    "Example: cd ~/RCLS-Validation-Shiny && Rscript scripts/deploy-shinyapps.R"
  )
}

message("Deploying from: ", root)
message("Target app: rcls-validator (updates https://<account>.shinyapps.io/rcls-validator/)")

rsconnect::deployApp(
  appDir = ".",
  appName = "rcls-validator",
  forceUpdate = TRUE
)

message("Done. Open your shinyapps URL and hard-refresh (Cmd+Shift+R).")
