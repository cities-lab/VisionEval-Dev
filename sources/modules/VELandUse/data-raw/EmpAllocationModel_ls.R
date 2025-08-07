#' Employment Allocation Models
#'
#' This script builds linear regression models to predict employment allocation
#' across different sectors (retail, service, and non-retail/service) at the block
#' group level. The models use 2010 data to predict 2017 employment patterns.
#'
#' @details
#' The script:
#' 1. Loads block group data from 2010 and 2017
#' 2. Joins and processes the data to create features for modeling
#' 3. Builds separate linear regression models for each employment sector:
#'    - Retail Employment (RetEmp)
#'    - Service Employment (SvcEmp)
#'    - Non-Retail/Service Employment (OthEmp)
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
#' - EmpAllocationModel_ls.rda: Saved R data file with the models
#'
#' @dependencies
#' - dplyr: For data manipulation
#' - targets: For data loading
#'
#' @model_features
#' Models use predictors including:
#' - Area and diversity types (AreaType:DivType)
#' - Number of households (NumHh)
#' - Total employment (TotEmp)
#' - Retail employment (RetEmp)
#' - Service employment (SvcEmp)
#' - State (STATEFP)
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

hh_emp_diff_df <- bg_all_df_2017 |>
    dplyr::select(
        GEOID,
        TotEmp_v3 = TotEmp,
        RetEmp_v3 = RetEmp,
        SvcEmp_v3 = SvcEmp,
        AreaType,
        DivType,
        LocType
    ) |>
    left_join(
        bg_all_df_2010 |>
            select(
                GEOID,
                ST,
                NumHh,
                TotEmp,
                RetEmp,
                SvcEmp,
                AreaType,
                DivType,
                PctSteepSlope,
                DistToCBD,
                DistToRamp,
                DistToFgwSta,
                D4Lvl,
                D5
            ),
        by = "GEOID",
        suffix = c("_v3", "")
    ) |>
    mutate(
        LUType = paste(AreaType, DivType, sep = "_"),
        OthEmp = TotEmp - RetEmp - SvcEmp,
        OthEmp_v3 = TotEmp_v3 - RetEmp_v3 - SvcEmp_v3
    ) |>
    na.exclude()

ret_emp_lm <- lm(
    RetEmp_v3 ~
        LUType +
        LocType +
        NumHh +
        TotEmp +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = hh_emp_diff_df
)
summary(ret_emp_lm) |> print()

svc_emp_lm <- lm(
    SvcEmp_v3 ~
        LUType +
        LocType +
        NumHh +
        TotEmp +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = hh_emp_diff_df
)
summary(svc_emp_lm) |> print()

oth_emp_lm <- lm(
    OthEmp_v3 ~
        LUType +
        LocType +
        NumHh +
        TotEmp +
        RetEmp +
        SvcEmp +
        ST +
        PctSteepSlope +
        DistToRamp +
        DistToCBD +
        DistToFgwSta +
        D4Lvl +
        D5,
    data = hh_emp_diff_df
)
summary(oth_emp_lm) |> print()

ret_emp_slm <- TrimModel(ret_emp_lm)
svc_emp_slm <- TrimModel(svc_emp_lm)
oth_emp_slm <- TrimModel(oth_emp_lm)

EmpAllocationModel_ls <- list(
    RetEmp = ret_emp_slm,
    SvcEmp = svc_emp_slm,
    OthEmp = oth_emp_slm
)

save(EmpAllocationModel_ls, file = file.path(my.dir, "..", "data", "EmpAllocationModel_ls.rda"))
