# ================
# PredictLandUseTypes.R
# ================

#<doc>
#
## PredictLocTypes Module

# This module predicts land use types for bzones for a future year.
# Land use types comprises of a combination of:
#- four area types: urban center, inner, outer, and fringe
#- three diversity types: residential, mixed-use, and employment
#- three location types: urban, town (urban cluster), and rural.

# This module supports land use scenario use case #3, in which users doesn't specify
# future year land use type for each bzone and relies on this module to predict
# land use types for each bzone.

### Model Parameter Estimation
#
# The location type transition model is used to predict the probability of a Bzone transitioning
# to different location types (Urban, Town, Rural) based on Bzone characteristics.
#
# The model is estimated using data from Smart Location Database and other sources.
#
### How the Module Works
#
# The module carries out the following series of calculations to predict location types for Bzones:
#
# 1) Predict Location Type Probabilities: For each Bzone, the module uses a location type transition
#   model to predict the probability of the Bzone being classified as Urban, Town, or Rural.
#
# 2) Convert Probabilities to Location Types: The probabilities are converted to location type
#   assignments using either:
#   - Maximum probability selection (if MaxProb = TRUE)
#   - Random sampling based on probabilities (if MaxProb = FALSE)
#
# 3) Enforce Transition Logic: The module enforces a hierarchical transition logic where:
#   - Transitions can only occur to the same level or a higher level
#   - The hierarchy is: Rural -> Town -> Urban
#   - If a predicted transition violates this logic, the original location type is retained
#
# 4) Store Results: The final location type assignments and their associated probabilities
#   are stored in the datastore.
#
#</doc>

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
PredictLocTypesSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  Inp = items(
    # Geographic attributes
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
        "Distance to nearest ramp",
        "Distance to CBD",
        "Distance to nearest transit stop",
        "Distance to nearest fixed guideway station"
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
          "DivType",
          "LocType"
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
    )
  ),
  # Independent variables needed by the models
  # Specify data to be saved in the data store
  # future year land use types
  Set = items(
    item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 6,
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Location Type of Bzone"
      )
    ),
    item(
      NAME = items(
        ".LocTypeProbTown",
        ".LocTypeProbUrban"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = "",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Probability of Bzone transitioning to Town LocType",
        "Probability of Bzone transitioning to Urban LocType"
      )
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for PredictLandUseTypes module
#'
#' A list containing specifications for the PredictLandUseTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source PredictLandUseTypes.R script.
"PredictLocTypesSpecifications"
visioneval::savePackageDataset(PredictLocTypesSpecifications, overwrite = TRUE)


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
    return(Choices_vc[apply(Prob_mx, 1, which.max)])
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
#' \code{PredictLandUseTypes} predicts land use types to each zone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name PredictLocTypes
#' @import visioneval
#' @import dplyr
#' @importFrom mlogit mlogit dfidx
#' @export
PredictLocTypes <- function(L) {
  Bzone_df <- data.frame(L$Year[["Bzone"]])

  LocTypeTransitionModel <- loadPackageDataset("LocTypeTransitionModel", "VELandUse")

  # predict.mlogit requires the dependent variable to exist
  LocType_mldf <- dfidx(
    Bzone_df |> mutate(LocType_v3 = LocType),
    shape = "wide",
    choice = "LocType_v3",
    idnames = "Bzone"
  )
  # Get probability matrix for LocType predictions
  LocTypeProb_mx <- predict(
    LocTypeTransitionModel,
    newdata = LocType_mldf,
    type = "prob"
  )

  # Convert probabilities to choices
  LocType.pred <- ProbToChoice(LocTypeProb_mx)

  # post-process LocType predictions, as it should be rare for transition in the
  # reverse direction: U -> C -> R
  # Define the ordered levels for LocType to enforce transition logic, i.e.,
  # a transition is only valid if it remains the same level or moves to a higher one
  LocTypeLevels <- c("Rural", "Town", "Urban")
  Bzone_df_ <- Bzone_df |>
    mutate(
      LocType = if_else(
        # Compare current and predicted AreaType as ordered factors
        factor(LocType.pred, levels = LocTypeLevels, ordered = TRUE) >=
          factor(LocType, levels = LocTypeLevels, ordered = TRUE),
        # Keep prediction if transition is valid
        LocType.pred,
        # Otherwise, revert to the original AreaType
        LocType
      ),
      .LocTypeProbTown = LocTypeProb_mx[, 2],
      .LocTypeProbUrban = LocTypeProb_mx[, 3]
    )

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  # Add LocType prediction
  Out_ls$Year$Bzone <- items(
    LocType = Bzone_df_$LocType,
    .LocTypeProbTown = Bzone_df_$.LocTypeProbTown,
    .LocTypeProbUrban = Bzone_df_$.LocTypeProbUrban
  )

  Out_ls$Year$Bzone$Bzone <- unname(Bzone_df$Bzone)
  attributes(Out_ls$Year$Bzone$LocType)$SIZE <- max(nchar(Out_ls$Year$Bzone$LocType))

  # Return the list
  return(Out_ls)
}

# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# documentModule("PredictLocTypes")

# ====================
# SECTION 5: TEST CODE
# ====================
# model test code is in tests/scripts/test.R
