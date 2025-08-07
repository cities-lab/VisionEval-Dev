# ================
# LoadBaseYearData.R
# ================
# This module loads base year data for Bzones, including land use types, dwelling units, and employment.

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
LoadBaseYearDataSpecifications <- list(
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
    ),
    item(
        NAME = items("SFDU", "MFDU", "GQDU"),
        FILE = "bzone_dwelling_units.csv",
        TABLE = "Bzone",
        GROUP = "Year",
        TYPE = "integer",
        UNITS = "DU",
        NAVALUE = -1,
        PROHIBIT = c("NA", "< 0"),
        ISELEMENTOF = "",
        SIZE = 0,
        DESCRIPTION = items(
            "SF dwelling units in zone",
            "MF dwelling units in zone",
            "GQ dwelling units in zone"
        )
    ),
    item(
      NAME = items("TotEmp", "RetEmp", "SvcEmp"),
      FILE = "bzone_employment.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PctSteepSlope",
      FILE = "bzone_steep_slope.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
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
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D4Lvl",
      FILE = "bzone_transit_service.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
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
    ),
    item(
      NAME = items("SFDU", "MFDU", "GQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "SF dwelling units in zone",
        "MF dwelling units in zone",
        "GQ dwelling units in zone"
      )
    ),
    item(
      NAME = items("TotEmp", "RetEmp", "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PctSteepSlope",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "DistToRamp",
          "DistToCBD",
          "DistToStop",
          "DistToFgwSta"
        ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for LoadBaseYearData module
#'
#' A list containing specifications for the LoadBaseYearData module.
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
"LoadBaseYearDataSpecifications"
visioneval::savePackageDataset(LoadBaseYearDataSpecifications, overwrite = TRUE)


# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================

# Main module function that loads base year data for Bzones
#---------------------------------------------------------------------------
#' Main module function that loads the base year data for Bzones for each
#' zone.
#'
#' \code{LoadBaseYearData} loads base year data for Bzones for each zone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name LoadBaseYearData
#' @import visioneval
#' @export
LoadBaseYearData <- function(L) {
  Bzone_df <- data.frame(L$Year[["Bzone"]])

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  Out_ls$Year$Bzone <- items(
    AreaType = Bzone_df$AreaType,
    DivType = Bzone_df$DivType,
    LocType = Bzone_df$LocType,
    SFDU = Bzone_df$SFDU,
    MFDU = Bzone_df$MFDU,
    GQDU = Bzone_df$GQDU,
    TotEmp = Bzone_df$TotEmp,
    RetEmp = Bzone_df$RetEmp,
    SvcEmp = Bzone_df$SvcEmp,
    PctSteepSlope = Bzone_df$PctSteepSlope,
    DistToRamp = Bzone_df$DistToRamp,
    DistToCBD = Bzone_df$DistToCBD,
    DistToStop = Bzone_df$DistToStop,
    DistToFgwSta = Bzone_df$DistToFgwSta
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
