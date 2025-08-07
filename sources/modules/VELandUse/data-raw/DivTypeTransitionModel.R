# Overview
# This script creates a multinomial logit model that predicts transitions between 
# diversity types based on block group attributes. The model is created using 
# block group data from 2010 and 2017.
#
# Dependencies:
# - mlogit - For multinomial logit modeling
# - targets - For loading prepared datasets
# - dplyr - For data manipulation
# - butcher - For reducing model object size
# - stargazer - For model summary output
#
# Input Data:
# - bg_all_df_2010: Block group data from 2010
# - bg_all_df_2017: Block group data from 2017
#
# Key Variables:
# - DivType_v3: Diversity type in 2017 (target variable)
# - Pop: Total population
# - TotEmp: Total employment
# - NumHh: Number of households
# - AreaType: Area type classification
# - DivType: Diversity type in 2010
# - D1D_hmcbuf: Activity density within buffer
# - D5: Destination accessibility
# - PctSteepSlope: Percent steep slope
# - DistToRamp: Distance to highway ramp
# - DistToCbd: Distance to central business district
# - DistToFgwSta: Distance to fixed guideway station
#
# Process:
# 1. Loads the 2010 and 2017 block group datasets
# 2. Prepares data for multinomial logit modeling
# 3. Fits a multinomial logit model predicting diversity type transitions
# 4. Displays model summary statistics
# 5. Reduces model size using butcher
# 6. Saves the resulting model to "data/DivTypeTransitionModel.rda"

library(mlogit)
library(targets)
library(dplyr)
library(butcher)

targets::tar_load(bg_all_df_2010)
targets::tar_load(bg_all_df_2017)

land_use_type_v3_df <- bg_all_df_2017 |>
    select(GEOID, AreaType = area_type, DivType = diversity_type)

sld_v2_v3_df <- bg_all_df_2010 |>
    select(
        GEOID,
        Pop = TOTPOP,
        TotEmp = TOTEMP,
        NumHh = HH,
        D1D_hmcbuf,
        D5,
        PctSteepSlope = pct_steep_slope,
        DistToRamp = dist_to_ramp,
        DistToCbd = dist_to_cbd,
        DistToFgwSta = dist_to_fgw_sta,
        AreaType = area_type,
        DivType = diversity_type
    ) |>
    left_join(land_use_type_v3_df, by = "GEOID", suffix = c("", "_v3"))

mldf_div_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "DivType_v3",
    idnames = "GEOID"
)

(DivTypeTransitionModel <- mlogit(
    DivType_v3 ~
        1 |
            Pop +
                TotEmp +
                NumHh +
                AreaType +
                DivType +
                D1D_hmcbuf +
                D5 +
                PctSteepSlope +
                DistToRamp +
                DistToCbd +
                DistToFgwSta,
    data = mldf_div_type
)) |>
    stargazer(
        type = "text",
        single.row = T,
        no.space = T,
        out.header = F
    )

DivTypeTransitionModel <- butcher(DivTypeTransitionModel, verbose = TRUE)

save(
    DivTypeTransitionModel,
    file = "data/DivTypeTransitionModel.rda"
)