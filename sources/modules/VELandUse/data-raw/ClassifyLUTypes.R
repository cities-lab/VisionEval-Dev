# Overview
# This script creates decision tree models that classify Bzones into different 
# area types and diversity types based on Bzone attributes. The models are created using the 
# 2017 National Household Travel Survey (NHTS) data merged with Smart Location 
# Database (SLD) measures.
#
# Dependencies:
# - targets - For loading prepared datasets
# - rpart - For decision tree modeling
# - rpart.plot - For decision tree visualization
# - dplyr - For data manipulation
# - butcher - For reducing model object size
# - yardstick - For the rmse_vec function
#
# Input Data:
# - nhts_sld_df_2017: A dataset combining NHTS household travel data with Smart Location Database variables. 
# See _targets.R and code/data-pipeline for the process generating this input.
#
# Key Variables:
# - DVMT: Household Daily Vehicle Miles Traveled (NHTS)
# - D2A_JPHH_2mcbuf: Activity density D2A_JPHH within 2 mile buffer (Jobs per Household, SLD)
# - hhwtg: Household weight from NHTS survey
#
# Process:
# 1. Loads the combined NHTS and SLD dataset
# 2. Configures decision tree parameters
# 3. Fits a decision tree model predicting DVMT from D1D_2mcbuf
# 4. Uses the butcher package to reduce model object size
# 5. Saves the resulting dataframe with models to "data/DivTypeDT.rda"

library(dplyr)
library(tidyr)
library(rpart)
library(rpart.plot)
library(yardstick)
library(butcher)
library(purrr)
library(ggplot2)
library(knitr)

targets::tar_load(nhts_sld_df_2017)

rpart_control <- rpart.control(minbucket = 1000, maxdepth = 2, cp = 0.001)
area_tree_by_size <- nhts_sld_df_2017 |>
    group_by(uza_size) |>
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
        rmse = map2_dbl(
            data,
            .pred,
            ~ rmse_vec(.x$DVMT, .y, case_weights = as.numeric(.x$hhwtg))
        ),
    )

area_tree_by_size

AreaTypeBySizeDTrees_ls <- area_tree_by_size$area_tree
names(AreaTypeBySizeDTrees_ls) <- area_tree_by_size$uza_size
purrr::walk(AreaTypeBySizeDTrees_ls, ~ butcher(.x, verbose = TRUE))

# diversity type
div_tree <- rpart(
    DVMT ~ D2A_JPHH_2mcbuf,
    data = nhts_sld_df_2017,
    weights = as.numeric(nhts_sld_df_2017$hhwtg),
    control = rpart.control(minbucket = 1000, maxdepth = 2, cp = 0.001),
    method = "anova"
)
.pred <- predict(div_tree, nhts_sld_df_2017) # ^(1/pwr)
DVMT <- nhts_sld_df_2017$DVMT # ^(1/pwr)
rmse_vec(DVMT, .pred, case_weights = as.numeric(nhts_sld_df_2017$hhwtg))

pwalk(
    area_tree_by_size %>% select(area_tree, uza_size, rmse),
    ~ rpart.plot(
        ..1,
        roundint = FALSE,
        main = str_glue("Area Type - {..2} (rmse={round(..3, 2)})")
    )
)
div_tree %>% rpart.plot(roundint = F, main = "Div Type")

DivTypeDTree <- div_tree %>% butcher(verbose = TRUE)
save(DivTypeDTree, file = "data/DivTypeDTree.rda")
