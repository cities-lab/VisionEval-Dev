#' Land Use Type Transition Models
#'
#' This script creates a multinomial logit models to predict the transition of AreaType, DivType, and LocType
#' from 2010 to 2017. The models use socioeconomic, land use, and accessibility variables from 2010 block groups
#' to predict their area types, diversity types, and location types in 2017.
#'
#' The model includes the following predictors:
#' - Population (Pop)
#' - Total Employment (TotEmp)
#' - Number of Households (NumHh)
#' - Base/Current Area Type (AreaType)
#' - Base/Current Diversity Type (DivType)
#' - Base/Current Location Type (LocType)
#' - Activity density (D1D_hmbuf)
#' - Accessibility measure (D5)
#' - D4 Level (D4Lvl)
#' - Percent of steep slope (PctSteepSlope)
#' - Distance to highway ramp (DistToRamp)
#' - Distance to CBD (DistToCBD)
#' - Distance to fixed guideway transit station (DistToFgwSta)
#'
#' The models are saved to separate rda file in data/ for use in simulations.

library(mlogit)
library(targets)
library(dplyr)

my.dir <- dirname(sys.frame(1)$ofile)
source(file.path(my.dir, "TrimModel.R"))

tar_load(bg_all_df_2010)
tar_load(bg_all_df_2017)

land_use_type_v3_df <- bg_all_df_2017 |>
    select(GEOID, AreaType_v3 = AreaType, DivType_v3 = DivType, LocType_v3 = LocType)

sld_v2_v3_df <- bg_all_df_2010 |>
    select(
        GEOID,
        TotEmp,
        Pop,
        NumHh,
        D1D_hmbuf,
        D4Lvl,
        D5,
        PctSteepSlope,
        DistToRamp,
        DistToCBD,
        DistToFgwSta,
        AreaType,
        DivType,
        LocType
    ) |>
    left_join(land_use_type_v3_df, by = "GEOID")

mldf_area_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "AreaType_v3",
    idnames = "GEOID"
)

AreaTypeTransitionModel_full <- mlogit(
    AreaType_v3 ~
        1 |
            TotEmp +
                NumHh +
                Pop +
                AreaType + DivType +
                D1D_hmbuf +
                # D4Lvl + # causing singular matrix
                D5 +
                PctSteepSlope +
                DistToRamp +
                DistToCBD +
                DistToFgwSta,
    data = mldf_area_type,
    reflevel = "fringe"
)

AreaTypeTransitionModel_full |>
    summary()

# AreaTypeTransitionModel <- butcher(AreaTypeTransitionModel, verbose = TRUE)

AreaTypeTransitionModel <- TrimModel(AreaTypeTransitionModel_full)
pred_s <- predict(AreaTypeTransitionModel, newdata = mldf_area_type)
pred_f <- predict(AreaTypeTransitionModel_full, newdata = mldf_area_type)
stopifnot(identical(pred_s, pred_f))

save(
    AreaTypeTransitionModel,
    file = file.path(my.dir, "..", "data/AreaTypeTransitionModel.rda")
)

mldf_div_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "DivType_v3",
    idnames = "GEOID"
)

DivTypeTransitionModel_full <- mlogit(
    DivType_v3 ~
        1 |
            TotEmp +
                NumHh +
                Pop +
                AreaType + 
                DivType +
                D1D_hmbuf +
                # D4Lvl + # causing singular matrix
                D5 +
                PctSteepSlope +
                DistToRamp +
                DistToCBD +
                DistToFgwSta,
    data = mldf_div_type,
    reflevel = "res"
)

DivTypeTransitionModel_full |>
    summary()

#DivTypeTransitionModel <- butcher(DivTypeTransitionModel, verbose = TRUE)

DivTypeTransitionModel <- TrimModel(DivTypeTransitionModel_full)
pred_s <- predict(DivTypeTransitionModel, newdata = mldf_div_type)
pred_f <- predict(DivTypeTransitionModel_full, newdata = mldf_div_type)
stopifnot(identical(pred_s, pred_f))

save(
    DivTypeTransitionModel,
    file = file.path(my.dir, "..", "data/DivTypeTransitionModel.rda")
)

mldf_loc_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "LocType_v3",
    idnames = "GEOID"
)

LocTypeTransitionModel_full <- mlogit(
    LocType_v3 ~
        1 |
            TotEmp +
                Pop +
                NumHh +
                D1D_hmbuf +
                D5 +
                PctSteepSlope +
                DistToRamp +
                DistToCBD +
                DistToFgwSta +
                LocType,
    data = mldf_loc_type
)

LocTypeTransitionModel_full |>
    summary()

LocTypeTransitionModel <- TrimModel(LocTypeTransitionModel_full)
pred_s <- predict(LocTypeTransitionModel, newdata = mldf_loc_type)
pred_f <- predict(LocTypeTransitionModel_full, newdata = mldf_loc_type)
stopifnot(identical(pred_s, pred_f))

save(
    LocTypeTransitionModel,
    file = file.path(my.dir, "..", "data/LocTypeTransitionModel.rda")
)
