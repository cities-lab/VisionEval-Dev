#' Location Type Transition Model
#'
#' This script creates a multinomial logit model to predict the transition of area types
#' from 2010 to 2017. The model uses socioeconomic, land use, and accessibility variables
#' from 2010 block groups to predict their area types in 2017.
#'
#' The model includes the following predictors:
#' - Population (Pop)
#' - Total Employment (TotEmp)
#' - Number of Households (NumHh)
#' - Base/Current Area Type (AreaType)
#' - Base/Current Diversity Type (DivType)
#' - Base/Current Location Type (LocType)
#' - Activity density (D1D_hmcbuf)
#' - Accessibility measure (D5)
#' - Percent of steep slope (PctSteepSlope)
#' - Distance to highway ramp (DistToRamp)
#' - Distance to CBD (DistToCbd)
#' - Distance to fixed guideway transit station (DistToFgwSta)
#'
#' The model is saved to data/AreaTypeTransitionModel.rda for use in simulations.

library(mlogit)
library(targets)
library(dplyr)
library(butcher)
library(stargazer)

targets::tar_load(bg_all_df_2010)
targets::tar_load(bg_all_df_2017)

land_use_type_v3_df <- bg_all_df_2017 |>
    select(GEOID, LocType_v3 = LocType)

sld_v2_v3_df <- bg_all_df_2010 |>
    select(
        GEOID,
        Pop,
        TotEmp,
        NumHh,
        D1D_hmbuf,
        D5,
        PctSteepSlope,
        DistToRamp,
        DistToCBD,
        DistToFgwSta,
        STATEFP,
        AreaType,
        DivType,
        LocType
    ) |>
    left_join(land_use_type_v3_df, by = "GEOID")

mldf_loc_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "LocType_v3",
    idnames = "GEOID"
)

(LocTypeTransitionModel <- mlogit(
    LocType_v3 ~
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
    data = mldf_area_type,
    reflevel = "Rural"
)) |>
    stargazer(
        type = "text",
        single.row = T,
        no.space = T,
        out.header = F
    )

AreaTypeTransitionModel <- butcher(AreaTypeTransitionModel, verbose = TRUE)

save(
    AreaTypeTransitionModel,
    file = "data/AreaTypeTransitionModel.rda"
)
