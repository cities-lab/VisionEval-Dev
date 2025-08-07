# ================
# PredictLUTypes.R
# ================
#<doc>
#
## PredictLUTypes Module
#
# This module predicts future year land use types (AreaType and DivType) for Bzones. It is designed for scenarios where future Bzone-level land use types are not explicitly provided by the user (use case #3).
#
# The land use type for a Bzone is composed of two main components predicted by this module:
# 1.  **AreaType**: Categorizes Bzones: urban center, inner, outer, or fringe based on their development intensity and D5 characteristics.
# 2.  **DivType**: Categorizes Bzones by their mix of activities: residential, mixed-use, or employment-focused.
#
# The module uses predictive models to determine the most probable AreaType and DivType for each Bzone in the target year, based on various Bzone attributes from the current/base year.
#
### Model Parameter Estimation
#
# Two separate models are used for predicting land use type components:
#
# 1.  **AreaType Transition Model**: This model predicts the future AreaType of a Bzone. Details of this model's estimation can be found in the `data-raw/AreaTypeTransitionModel.R` script.
#   <txt:AreaTypeTransitionModel$Summary>
#
# 2.  **DivType Transition Model**: This model predicts the future DivType of a Bzone. Details of this model's estimation can be found in the `data-raw/DivTypeTransitionModel.R` script.
#   <txt:DivTypeTransitionModel$Summary>
#
# These models are typically estimated using historical data and Bzone characteristics to learn patterns of land use change.
#
### How the Module Works
#
# The module performs the following steps to predict future land use types for each Bzone:
#
# 1)  **Load Bzone Data**: The module retrieves current/base year data for all Bzones. This includes existing AreaType, DivType, population, employment, household numbers, density measures (D1D_hmcbuf, D5), and geographic attributes (PctSteepSlope, DistToRamp, DistToCBD, DistToFgwSta).
#
# 2)  **Load Prediction Models**: The pre-estimated `AreaTypeTransitionModel` and `DivTypeTransitionModel` are loaded from the package datasets.
#
# 3)  **Predict Future AreaType**: For each Bzone, the `AreaTypeTransitionModel` is applied using the Bzone's characteristics as input variables. This yields a predicted AreaType for the future year.
#
# 4)  **Predict Future DivType**: Similarly, for each Bzone, the `DivTypeTransitionModel` is applied using the Bzone's characteristics as input variables. This yields a predicted DivType for the future year.
#
# 5)  **Store Predicted LUTypes**: The predicted AreaTypes and DivTypes for each Bzone are then stored in the datastore for the target year.
#
#</doc>

# library(visioneval)

# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# #See:
# data-raw/AreaTypeTransitionModel.R
# data-raw/DivTypeTransitionModel.R
#
# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
PredictLUTypesSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  Inp = items(
    item(
      NAME = "D4Lvl",
      FILE = "bzone_transit_service.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("1", "2", "3", "4", "5", "6", "7"),
      DESCRIPTION = "D4Lvl"
    ),
    item(
      NAME = "PctSteepSlope",
      FILE = "bzone_steep_slope.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION = "Percentage of Bzone area with steep slope"
    ),
    item(
      NAME =
        items(
          "DistToRamp",
          "DistToCBD",
          "DistToStop",
          "DistToFgwSta"
        ),
      FILE = "bzone_distances.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Distance to ramp",
        "Distance to CBD",
        "Distance to stop",
        "Distance to FGW station"
      )
    )
  ),
  # Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    # base/current year land use types
    item(
      NAME =
        items(
          "AreaType",
          "DivType"
        ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 6,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION =
        items(
          "Area type",
          "Diversity type"
        )
    ),
    # Population, Employment, and Household attributes
    item(
      NAME = "Pop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    # Density and 5D measures
    item(
      NAME = "D1D_hmbuf",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D5",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )#,
    # Geographic attributes
    # item(
    #   NAME = "PctSteepSlope",
    #   TABLE = "Bzone",
    #   GROUP = "Year",
    #   TYPE = "double",
    #   UNITS = "proportion",
    #   PROHIBIT = "< 0",
    #   ISELEMENTOF = ""
    # ),
    # item(
    #   NAME =
    #     items(
    #       "DistToRamp",
    #       "DistToCBD",
    #       "DistToFgwSta"
    #     ),
    #   TABLE = "Bzone",
    #   GROUP = "Year",
    #   TYPE = "distance",
    #   UNITS = "MI",
    #   PROHIBIT = "< 0",
    #   ISELEMENTOF = ""
    # )
  ),
  # Independent variables needed by the models
  # Specify data to be saved in the data store
  # future year land use types
  Set = items(
    item(
      NAME = items(
        "AreaType",
        "DivType"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 6,
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Area type",
        "Diversity type"
      )
    ),
    item(
      NAME = items(
        ".AreaTypeProbCenter",
        ".AreaTypeProbInner",
        ".AreaTypeProbOuter",
        ".DivTypeProbEmp",
        ".DivTypeProbMix"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = "",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Probability of Bzone transitioning to center AreaType",
        "Probability of Bzone transitioning to inner AreaType",
        "Probability of Bzone transitioning to outer AreaType",
        "Probability of Bzone transitioning to emp DivType",
        "Probability of Bzone transitioning to mix DivType"
      )
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for PredictLUTypes module
#'
#' A list containing specifications for the PredictLUTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source PredictLUTypes.R script.
"PredictLUTypesSpecifications"
visioneval::savePackageDataset(PredictLUTypesSpecifications, overwrite = TRUE)

# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================
#' Convert probability matrix to choice values
#'
#' @param Prob_mx Matrix of probabilities where each row represents an observation and
#'   each column represents the probability of a choice
#' @param Choices_vc Vector of choice values corresponding to the columns of Prob_mx
#' @param MaxProb Logical, if TRUE returns the choice with highest probability,
#'   if FALSE (default) samples from the choices based on probabilities
#' @return Vector of selected choices, one for each row in Prob_mx
ProbToChoice <- function(Prob_mx, Choices_vc = NULL, MaxProb = FALSE) {
  if (is.null(Choices_vc)) {
    Choices_vc <- colnames(Prob_mx)
  }

  if (MaxProb) {
    return(Choice_vc[apply(Prob_mx, 1, which.max)])
  }

  apply(Prob_mx, 1, \(.x) {
    sample(
      Choices_vc, # ordered alphabetically
      size = 1,
      prob = .x
    )
  })
}
# Main module function that predicts land use types (Bzone)
#---------------------------------------------------------------------------
#' Main module function that predicts the land use types (Bzone) to each
#' zone.
#'
#' \code{PredictLUTypes} predicts land use types to each zone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name PredictLUTypes
#' @import visioneval
#' @import dplyr
#' @importFrom mlogit mlogit dfidx
#' @export
PredictLUTypes <- function(L) {
  Bzone_df <- data.frame(L$Year[["Bzone"]])

  AreaTypeTransitionModel <- loadPackageDataset("AreaTypeTransitionModel", "VELandUse")
  DivTypeTransitionModel <- loadPackageDataset("DivTypeTransitionModel", "VELandUse")

  # predict.mlogit requires the dependent variable to exist
  AreaType_mldf <- dfidx(
    Bzone_df |> mutate(AreaType_v3 = AreaType),
    shape = "wide",
    choice = "AreaType_v3",
    idnames = "Bzone"
  )

  AreaTypeProb_mx <- predict(
    AreaTypeTransitionModel,
    newdata = AreaType_mldf,
    type = "prob"
  )
  AreaType.pred <- ProbToChoice(AreaTypeProb_mx)
  
  #est_df <- DivTypeTransitionModel$model
  #XNames <- names(DivTypeTransitionModel$model)
  DivType_mldf <- dfidx(
    Bzone_df |> 
      mutate(DivType_v3 = DivType, D4Lvl = factor(D4Lvl, levels = 1:7)),
    shape = "wide",
    choice = "DivType_v3",
    idnames = "Bzone"
  )

  DivTypeProb_mx <- predict(
    DivTypeTransitionModel,
    newdata = DivType_mldf,
    type = "prob"
  )
  DivType.pred <- ProbToChoice(DivTypeProb_mx)

  # post-process AreaType predictions, as it should be rare for transition in the
  # reverse direction: center -> inner -> outer -> fringe
  # Define the ordered levels for AreaType to enforce transition logic.
  # A transition is only valid if it moves to a higher or remains at thesame level
  # (e.g., 'outer' to 'inner' is okay, 'inner' to 'outer' is not).
  # TODO: make this controlled by a model parameter
  AreaTypeLevels <- c("fringe", "outer", "inner", "center")
  Bzone_df_ <- Bzone_df |>
    mutate(
      AreaType = if_else(
        # Compare current and predicted AreaType as ordered factors
        factor(AreaType.pred, levels = AreaTypeLevels, ordered = TRUE) >=
          factor(AreaType, levels = AreaTypeLevels, ordered = TRUE),
        # Keep prediction if transition is valid
        AreaType.pred,
        # Otherwise, revert to the original AreaType
        AreaType
      ),

      # Append the transition probability for potential "high leverage point" analysis
      .AreaTypeProbCenter = AreaTypeProb_mx[, 1],
      .AreaTypeProbInner = AreaTypeProb_mx[, 3],
      .AreaTypeProbOuter = AreaTypeProb_mx[, 4],
      .DivTypeProbEmp = DivTypeProb_mx[, 1],
      .DivTypeProbMix = DivTypeProb_mx[, 2]
    )

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  Out_ls$Year$Bzone <- items(
    AreaType = Bzone_df_$AreaType,
    DivType = DivType.pred,
    .AreaTypeProbCenter = Bzone_df_$.AreaTypeProbCenter,
    .AreaTypeProbInner = Bzone_df_$.AreaTypeProbInner,
    .AreaTypeProbOuter = Bzone_df_$.AreaTypeProbOuter,
    .DivTypeProbEmp = Bzone_df_$.DivTypeProbEmp,
    .DivTypeProbMix = Bzone_df_$.DivTypeProbMix
  )

  # Set SIZE attributes for Bzone table columns
  attributes(Out_ls$Year$Bzone$AreaType)$SIZE <- max(nchar(Out_ls$Year$Bzone$AreaType))
  attributes(Out_ls$Year$Bzone$DivType)$SIZE <- max(nchar(Out_ls$Year$Bzone$DivType))

  # Return the list
  return(Out_ls)
}

# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# documentModule("PredictLUTypes")

# ====================
# SECTION 5: TEST CODE
# ====================
# model test code is in tests/scripts/test.R
