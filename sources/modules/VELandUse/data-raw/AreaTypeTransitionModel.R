#' Area Type Transition Model
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

tar_load(bg_all_df_2010)
tar_load(bg_all_df_2017)

land_use_type_v3_df <- bg_all_df_2017 |>
    select(GEOID, AreaType_v3 = AreaType, DivType_v3 = DivType)

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
        AreaType,
        DivType
    ) |>
    left_join(land_use_type_v3_df, by = "GEOID", suffix = c("", "_v3"))

mldf_area_type <- dfidx(
    sld_v2_v3_df,
    shape = "wide",
    choice = "AreaType_v3",
    idnames = "GEOID"
)

(AreaTypeTransitionModel <- mlogit(
    AreaType_v3 ~
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
    data = mldf_area_type
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
