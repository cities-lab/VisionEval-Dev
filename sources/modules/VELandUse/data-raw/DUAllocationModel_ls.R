#' Estimate dwelling unit allocation models
#'
#' This script builds linear regression models to predict dwelling unit allocation
#' across different types (single-family, multi-family, and group quarters) at the block
#' group level. The models use 2010 data to predict 2017 dwelling unit patterns.
#'
#' @details
#' The script:
#' 1. Loads block group data from 2010 and 2017
#' 2. Joins and processes the data to create features for modeling
#' 3. Builds separate linear regression models for each dwelling unit type:
#'    - Single-Family Dwelling Units (SFDU)
#'    - Multi-Family Dwelling Units (MFDU)
#'    - Group Quarters Dwelling Units (GQDU)
#' 4. Saves the models as a list object for use in the VELandUse module
#'
#' @note
#' The models exclude Alaska (02), Hawaii (15), and territories
#' (60, 66, 69, 72) from the analysis.
#'
#' @inputs
#' - bg_all_df_2010: Block group data from 2010 (loaded from targets)
#' - bg_all_df_2017: Block group data from 2017 (loaded from targets)
#'
#' @outputs
#' - models_ls: A list containing three linear regression models
#' - DUAllocationModel_ls.rda: Saved R data file with the models
#'
#' @dependencies
#' - dplyr: For data manipulation
#' - targets: For data loading
#'
#' @model_features
#' Models use predictors including:
#' - Area and diversity types (AreaType:DivType)
#' - Total employment (TotEmp)
#' - Single-family dwelling units (SFDU)
#' - Multi-family dwelling units (MFDU)
#' - Retail employment (RetEmp)
#' - Service employment (SvcEmp)
#' - State FIPS code (STATEFP)
#' - Percent steep slope (PctSteepSlope)
#' - Distance to highway ramp (DistToRamp)
#' - Distance to CBD (DistToCBD)
#' - Distance to fixed guideway station (DistToFgwSta)
#'

library(dplyr)
library(targets)
library(butcher)
my.dir <- dirname(sys.frame(1)$ofile)
source(file.path(my.dir, "TrimModel.R"))

tar_load(bg_all_df_2010)
tar_load(bg_all_df_2017)

du_emp_df <- bg_all_df_2017 |>
    dplyr::select(
        GEOID,
        SFDU_v3 = SFDU,
        MFDU_v3 = MFDU,
        GQDU_v3 = GQDU,
        AreaType,
        DivType,
        LocType
    ) |>
    mutate(
        LUType = paste(AreaType, DivType, sep = "_")
    ) |>
    left_join(
        bg_all_df_2010 |>
            select(
                GEOID,
                NumHh,
                TotEmp,
                RetEmp,
                SvcEmp,
                PctSteepSlope,
                DistToCBD,
                DistToRamp,
                DistToFgwSta,
                D4Lvl,
                ST,
                SFDU,
                MFDU,
                GQDU,
                D5
            ),
        by = "GEOID",
        suffix = c("_v3", "")
    ) |>
    na.exclude()

sfdu_lm <- lm(
    SFDU_v3 ~
        LUType +
        LocType +
        SFDU +
        MFDU +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = du_emp_df
)
summary(sfdu_lm) |> print()

mfdu_lm <- lm(
    MFDU_v3 ~
        LUType +
        LocType +
        SFDU +
        MFDU +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = du_emp_df
)
summary(mfdu_lm) |> print()

gqdu_lm <- lm(
    GQDU_v3 ~
        LUType +
        LocType +
        SFDU +
        MFDU +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = du_emp_df
)
summary(gqdu_lm) |> print()

sfdu_slm <- TrimModel(sfdu_lm)
mfdu_slm <- TrimModel(mfdu_lm)
gqdu_slm <- TrimModel(gqdu_lm)

DUAllocationModel_ls <- list(
    SFDU = sfdu_slm,
    MFDU = mfdu_slm,
    GQDU = gqdu_slm
)

save(DUAllocationModel_ls, file = file.path(my.dir, "..", "data", "DUAllocationModel_ls.rda"))
