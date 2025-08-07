# ================
# UpdateLUTypes.R
# ================
# This module updates land use types for bzones for the base and/or future year.
# Land use types comprises of a combination of
# - four area types: urban core, close-in community, suburban, and fringe
# - three diversity types: residential, mixed-use, and employment
# - three location types: urban, town (urban cluster), and rural
# This modules updates land use types for bzones based on Bzone attributes used
# to define the land use types in data/AreaTypeModel.rda and data/DivTypeModel.rda.
# Running this module is optional - depending on whether it is desirable to update
# bzone land use types based on outputs of other modules (PredictHousing and
# PredictEmployment).

# library(visioneval)

# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# see data-raw/AreaTypeBySizeDT_ls.R and data-raw/DivTypeDT.R
#
# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
UpdateLUTypesSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  # Specify input data
  Inp = items(
    item(
      NAME = "Size",
      FILE = "marea_size.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 5,
      PROHIBIT = "",
      ISELEMENTOF = c("large", "small", ""),
      UNLIKELY = "",
      DESCRIPTION = "marea size category: large (>= 1,000,000 population) or small (< 1,000,000 population)"
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
    item(
      NAME =
        items(
          "TotEmp",
          "RetEmp",
          "SvcEmp"
        ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D2A_JPHH_hmbuf",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "JOB/HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of jobs to households in zone (Ref: EPA 2010 Smart Location Database) with half mile buffer"
    ),
    item(
      NAME = "D2A_JPHH_2mbuf",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "JOB/HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of jobs to households in zone (Ref: EPA 2010 Smart Location Database) with 2 mile buffer"
    ),
    item(
      NAME = "D5",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Destination accessibility of zone calculated as harmonic mean of jobs within 2 miles and population within 5 miles"
    )
  ),
  # Specify data to be saved in the data store
  Set = items(
    item(
      NAME = items(
        "AreaType",
        "DivType"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Area type",
        "Diversity type"
      )
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for UpdateLUTypes module
#'
#' A list containing specifications for the UpdateLUTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be updateed into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source UpdateLUTypes.R script.
"UpdateLUTypesSpecifications"
visioneval::savePackageDataset(UpdateLUTypesSpecifications, overwrite = TRUE)

# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================

# Main module function that updates land use types (Bzone)
#---------------------------------------------------------------------------
#' Main module function that updates the land use types (Bzone) for each zone
#'
#' \code{UpdateLUTypes} updates land use types for each zone based on Bzone attributes.
#'
#' This function uses trained models to predict area types (urban core, close-in community,
#' suburban, fringe) and diversity types (residential, mixed-use, employment) for each Bzone
#' based on built environment characteristics such as density, diversity, and design.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name UpdateLUTypes
#' @import visioneval
#' @import dplyr
#' @import sf
#' @importFrom rpart predict
#' @export
UpdateLUTypes <- function(L) {
  Marea_df <- data.frame(L$Year[["Marea"]])
  Bzone_df <- data.frame(L$Year[["Bzone"]])
  Bzone_df <- Bzone_df |> mutate(Area = UrbanArea + TownArea + RuralArea)

  AreaTypeBySizeDT_ls <- loadPackageDataset("AreaTypeBySizeDT_ls", "VELandUse")
  DivTypeDT <- loadPackageDataset("DivTypeDT", "VELandUse")

  DivType <- RpartPredClass(DivTypeDT, Bzone_df_, classes = c("emp", "mix", "res"))

  Bzone_df <- Bzone_df |>
    left_join(Marea_df, by = "Marea")

  AreaTypeResults <- NULL
  for (MareaSize in unique(Marea_df$Size)) {
    if (!is.na(MareaSize)) {
      AreaTypeTree <- AreaTypeBySizeDT_ls[[MareaSize]]
      Bzone_df_ <- Bzone_df |> filter(Size == MareaSize)
    } else {
      AreaTypeTree <- AreaTypeBySizeDT_ls[["NA"]]
      Bzone_df_ <- Bzone_df |> filter(is.na(Size))
    }

    PredClass <- RpartPredClass(
      AreaTypeTree,
      Bzone_df_,
      classes = c("center", "inner", "outer", "fringe")
    )
    Result_ <- data.frame(Bzone = Bzone_df_$Bzone, AreaType = PredClass)
    AreaTypeResults <- bind_rows(AreaTypeResults, Result_)
  }

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  AreaType <- Bzone_df |>
    left_join(AreaTypeResults, by = "Bzone") |>
    pull(AreaType)

  Out_ls$Year$Bzone <- items(
    AreaType = AreaType,
    DivType = DivType
  )
  Out_ls$Year$Bzone$Bzone <- unname(Bzone_df_$Bzone)
  attributes(Out_ls$Year$Bzone$AreaType)$SIZE <- max(nchar(Out_ls$Year$Bzone$AreaType))
  attributes(Out_ls$Year$Bzone$DivType)$SIZE <- max(nchar(Out_ls$Year$Bzone$DivType))

  # Return the list
  return(Out_ls)
}

#' Predict class labels using rpart tree model
#'
#' This function takes an rpart tree model and predicts class labels for new data.
#' It handles both classification and regression trees, mapping prediction values to class labels.
#'
#' @param rpart_tree An rpart tree model object
#' @param x_df A data frame containing the features for prediction
#' @param classes A vector of class labels that correspond to the ordered unique prediction values from lowest to highest
#' @return A vector of predicted class labels
#' @importFrom rpart predict
#' @importFrom dplyr left_join pull
#' @importFrom tibble tibble
#'
RpartPredClass <- function(
    rpart_tree,
    x_df,
    classes) {
  if (rpart_tree$method == "class") {
    # use [, 2] to get prob(y=TRUE) from prob[FALSE, TRUE]
    pred_val <- predict(rpart_tree, type = "prob")[, 2]
    x_df$.pred_val <- predict(rpart_tree, x_df, type = "prob")[, 2]
  } else {
    pred_val <- predict(rpart_tree)
    x_df$.pred_val <- predict(rpart_tree, x_df)
  }
  unique_vals <- unique(pred_val) |> sort()
  val_class_lut <- tibble(.pred_val = unique_vals, class = classes)

  # x_df$.pred_val <- predict(rpart_tree, x_df)
  results <- x_df %>%
    left_join(val_class_lut, by = ".pred_val") |>
    pull(class)

  return(results)
}

# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# visioneval::documentModule("UpdateLUTypes")

# ====================
# SECTION 5: TEST CODE
# ====================
# model test code is in tests/scripts/test.R
