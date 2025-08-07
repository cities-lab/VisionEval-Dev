# Overview
# This script creates decision tree models that classify Bzones into different 
# diversity types based on Bzone attributes. The models are created using the 
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

library(rpart)
library(dplyr)
library(tidyr)
library(ggplot2)
library(yardstick)
library(butcher)

# load dataset joined from NHTS and sld
targets::tar_load(nhts_sld_df_2017)

rpart_control <- rpart.control(minbucket = 1000, maxdepth = 2, cp = 0.001)
DivTypeDT <- rpart(
    DVMT ~ D2A_JPHH_2mcbuf,
    data = nhts_sld_df_2017,
    weights = as.numeric(nhts_sld_df_2017$hhwtg),
    control = rpart_control,
    method = "anova"
)

.pred <- predict(DivTypeDT, nhts_sld_df_2017) # ^(1/pwr)
DVMT <- nhts_sld_df_2017$DVMT
rmse_vec(DVMT, .pred, case_weights = as.numeric(nhts_sld_df_2017$hhwtg))

rpart.plot(DivTypeDT)

DivTypeDT <- butcher(DivTypeDT, verbose = TRUE)

save(
    DivTypeDT,
    file = "data/DivTypeDT.rda"
)