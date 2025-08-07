# ================
# LoadLUTypes.R
# ================
# This module loads land use types for bzones for the base and/or future year.
# Land use types comprises of a combination of
# - four area types: urban center, inner, outer, and fringe
# - three diversity types: residential, mixed-use, and employment
# - three location types: urban, town (urban cluster), and rural
# this module supports land use scenario use case #2, in which users specifies
# base/future year land use type for each bzone

# library(visioneval)

# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# This module has no parameters.
#
# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
LoadLUTypesSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  # Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "AreaType",
          "DivType",
          "LocType"
        ),
      FILE = "bzone_lutypes.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      SIZE = 6,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION =
        items(
          "Area type",
          "Diversity type",
          "Location type"
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
    )
  ),
  # Specify data to be saved in the data store
  Set = items(
    item(
      NAME = items(
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
      DESCRIPTION = items(
        "Area type",
        "Diversity type",
        "Location type"
      )
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for LoadLandUseTypes module
#'
#' A list containing specifications for the LoadLandUseTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source LoadLandUseTypes.R script.
"LoadLUTypesSpecifications"
visioneval::savePackageDataset(LoadLUTypesSpecifications, overwrite = TRUE)


# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================

# Main module function that loads land use types (Bzone)
#---------------------------------------------------------------------------
#' Main module function that loads the land use types (Bzone) for each
#' zone.
#'
#' \code{LoadLUTypes} loads land use types for each zone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name LoadLUTypes
#' @import visioneval
#' @export
LoadLUTypes <- function(L) {
  Bzone_df <- data.frame(L$Year[["Bzone"]])

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  Out_ls$Year$Bzone <- items(
    AreaType = Bzone_df$AreaType,
    DivType = Bzone_df$DivType,
    LocType = Bzone_df$LocType
  )

  attributes(Out_ls$Year$Bzone$AreaType)$SIZE <- max(nchar(Out_ls$Year$Bzone$AreaType))
  attributes(Out_ls$Year$Bzone$DivType)$SIZE <- max(nchar(Out_ls$Year$Bzone$DivType))
  attributes(Out_ls$Year$Bzone$LocType)$SIZE <- max(nchar(Out_ls$Year$Bzone$LocType))

  # Return the list
  return(Out_ls)
}

# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# documentModule("LoadLandUseTypes")

# ====================
# SECTION 5: TEST CODE
# ====================
# model test code is in tests/scripts/test.R
