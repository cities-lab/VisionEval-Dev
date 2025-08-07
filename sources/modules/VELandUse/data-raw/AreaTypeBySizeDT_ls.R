# Overview
# This script creates decision tree models that classify Bzones into different
# area types based on Bzone attributes. The models are created for different
# urban area size categories using the 2017 National Household Travel Survey (NHTS) data
# merged with Smart Location Database (SLD) measures.
#
# Dependencies:
# - targets - For loading prepared datasets
# - rpart - For decision tree modeling
# - rpart.plot - For decision tree visualization
# - dplyr - For data manipulation
# - purrr - For functional programming operations
# - butcher - For reducing model object size
# - yardstick - For the rmse_vec function
#
# Input Data:
# - nhts_sld_df_2017: A dataset combining NHTS household travel data with Smart Location Database variables.
# See _targets.R and code/data-pipeline for the process generating this input.
#
# Key Variables:
# - marea_size: Urban area size category based on TTI classification - large (>= 1,000,000 population) and small (< 1,000,000 population)
# - DVMT: Household Daily Vehicle Miles Traveled (NHTS)
# - D1D_hmcbuf: Activity density D1D within half mile buffer (D variable from SLD)
# - D5: Destination accessibility D5 (harmonic mean accessibility measure)
# - hhwtg: Household weight from NHTS survey
#
# Process:
# 1. Loads the combined NHTS and SLD dataset
# 2. Configures decision tree parameters
# 3. Groups data by urban area size categories
# 4. For each size category:
#    - Creates a nested dataframe
#    - Fits a decision tree model predicting DVMT from D1D_hmcbuf and D5
#    - Applies household weights to the model
#    - Makes predictions for each observation
#    - Calculates weighted RMSE to evaluate model performance
# 5. Uses the butcher package to reduce model object size
# 6. Saves the resulting dataframe with models to "data/AreaTypeBySizeDT_df.rda"

library(rpart)
library(rpart.plot)
library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)
library(yardstick)
library(butcher)

# load dataset joined from NHTS and sld
targets::tar_load(nhts_sld_df_2017)

rpart_control <- rpart.control(minbucket = 1000, maxdepth = 2, cp = 0.001)
AreaTypeBySizeDT_df <- nhts_sld_df_2017 |>
    group_by(marea_size) |>
    nest() |>
    mutate(
        area_tree = map(
            data,
            ~ rpart(
                DVMT ~ D1D_hmcbuf + D5,
                data = .,
                weights = as.numeric(.$hhwtg),
                control = rpart_control,
                method = "anova"
            )
        ),
        .pred = map2(area_tree, data, ~ predict(.x, .y)),
        # in sample rmse
        rmse = map2_dbl(
            data,
            .pred,
            ~ rmse_vec(.x$DVMT, .y, case_weights = as.numeric(.x$hhwtg))
        ),
    )

AreaTypeBySizeDT_df |> knitr::kable()

# plot the decision trees
pwalk(
    AreaTypeBySizeDT_df %>% select(area_tree, marea_size, rmse),
    ~ rpart.plot(
        ..1,
        roundint = FALSE,
        main = str_glue("Area Type - {..2} (rmse={round(..3, 2)})")
    )
)

AreaTypeBySizeDT_df <- AreaTypeBySizeDT_df |>
    select(.pred, rmse) |>
    mutate(area_type = map(area_tree, ~ butcher(.x, verbose = TRUE)))

save(
    AreaTypeBySizeDT_df,
    file = "data/AreaTypeBySizeDT_df.rda"
)