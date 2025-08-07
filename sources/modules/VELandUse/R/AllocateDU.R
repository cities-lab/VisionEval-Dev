# ================
# AllocateDU.R
# ================

#<doc>
#
## AllocateDU Module

# This module assigns dwelling unit targets specified by Housing Type (SF, MF, GQ) and Land Use Type to Bzones.
#
# The module carries out the following series of calculations to assign dwelling units by type (SFDU, MFDU, GQDU) to Bzones:
#
# 1) Predict Initial Bzone Dwelling Units by Type: For each dwelling unit type (SFDU - Single Family Dwelling Units, MFDU - Multi-Family Dwelling Units, GQDU - Group Quarters Dwelling Units), an Ordinary Least Squares (OLS) regression model is applied. These models use Bzone characteristics (such as accessibility, existing development patterns) and the Bzone's assigned Land Use Type (LUType) as predictor variables to generate an initial forecast of the number of dwelling units of that type within each Bzone. This initial forecast serves as the seed for the subsequent adjustment step.
#
# 2) Allocate Dwelling Units using Iterative Proportional Fitting (IPF): An simplified IPF process is used to adjust the initial Bzone dwelling unit predictions (from Step 1) to match specified control totals.
#   The **seed matrix** for the IPF is the predicted Bzone dwelling units by type (SFDU, MFDU, GQDU) from Step 1.
#   The **margin control totals** are the target dwelling unit numbers by type (SFDU, MFDU, GQDU) for each LUType, read from the `lutype_dwelling_units.csv` input file.
#   The IPF algorithm iteratively samples from the seed matrix until the sum of dwelling units in Bzones, grouped by their LUType, matches the LUType-level targets for each dwelling unit type. This ensures the final allocation respects both the spatial patterns suggested by the OLS models and the aggregate targets specified by LUType.
#
### Model Parameter Estimation
#
# An OLS model is used to predict Bzone dwelling units for each housing type (SFDU, MFDU, GQDU) based on LUType and other Bzone varialbes. The model is estimated using data from Smart Location Database.

# The summary statistics for this model are as follows:
#
#<txt:DUAllocationModel_ls$Summary>
#
### How the Module Works
#
# The module carries out the following series of calculations to assign dwelling units by type (SFDU, MFDU, GQDU) to Bzones:
#
# 1) Predict Initial Bzone Dwelling Units by Type: For each dwelling unit type (SFDU - Single Family Dwelling Units, MFDU - Multi-Family Dwelling Units, GQDU - Group Quarters Dwelling Units), an Ordinary Least Squares (OLS) regression model is applied. These models use Bzone characteristics (such as accessibility, existing development patterns) and the Bzone's assigned Land Use Type (LUType) as predictor variables to generate an initial forecast of the number of dwelling units of that type within each Bzone. This initial forecast serves as the seed for the subsequent adjustment step.
#
# 2) Allocate Dwelling Units using Iterative Proportional Fitting (IPF): An IPF process is used to adjust the initial Bzone dwelling unit predictions (from Step 1) to match specified control totals.
#   The **seed matrix** for the IPF is the predicted Bzone dwelling units by type (SFDU, MFDU, GQDU) from Step 1.
#   The **margin control totals** are the target dwelling unit numbers by type (SFDU, MFDU, GQDU) for each LUType, read from the `lutype_dwelling_units.csv` input file.
#   The IPF algorithm iteratively scales the seed matrix until the sum of dwelling units in Bzones, grouped by their LUType, matches the LUType-level targets for each dwelling unit type. This ensures the final allocation respects both the spatial patterns suggested by the OLS models and the aggregate targets specified by LUType.
#
# 3) Finalize Bzone Dwelling Units: The output of the IPF process is the final allocated number of dwelling units (SFDU, MFDU, GQDU) for each Bzone. These values are then stored in the datastore.
#
#</doc>

# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# This model allocates dwelling units to block groups based on socioeconomic, land use, and accessibility variables.

# see data-raw/DUAllocationModel_ls.R

# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
AllocateDUSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  # Specify new tables to be created by Set if any
  # Specify input data
  Inp = items(
    item(
      NAME = items(
        "SFDU",
        "MFDU",
        "GQDU"
      ),
      FILE = "lutype_dwelling_units.csv",
      TABLE = "Lutype",
      GROUP = "Year",      
      TYPE = "double",
      UNITS = "DU",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "SF dwelling units by land use type",
        "MF dwelling units by land use type",
        "GQ dwelling units by land use type"
      )
    ),
    item(
      NAME = items(
        "AreaType",
        "DivType"
      ),
      FILE = "lutype_dwelling_units.csv",
      TABLE = "Lutype",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 6,
      PROHIBIT = "",
      DESCRIPTION = items(
        "Area type",
        "Diversity type"
      )
    )
  ),

  # Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "D4Lvl",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("1", "2", "3", "4", "5", "6", "7"),
      DESCRIPTION = "D4Lvl"
    ),
    item(
      NAME = items("SFDU", "MFDU", "GQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("Bzone", "AreaType", "DivType"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      SIZE = 12,
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  # Specify data to saved in the data store
  Set = items(
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
    )
  )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for AllocateEmployment module
#'
#' A list containing specifications for the AllocateEmployment module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AllocateDU.R script.
"AllocateDUSpecifications"
visioneval::savePackageDataset(AllocateDUSpecifications, overwrite = TRUE)

# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================

# Main module function that assigns dwelling units to Bzones
#---------------------------------------------------------------------------
#' Main module function that assigns dwelling units to Bzones.
#'
#' \code{AllocateDU} assigns dwelling units to Bzones.
#'
#' This function assigns dwelling units to Bzones. The dwelling units
#' are assigned to a Bzone based on the input:
#' 1) dwelling units total by LUType and sector group
#' 2) base/previous year dwelling units by sector group for each Bzone
#' 3) base/previous year Land use type for each Bzone
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AllocateDU
#' @import visioneval stats
#' @import dplyr
#' @importFrom tidyr nest unnest
#' @importFrom purrr map2
#'
#' @export
AllocateDU <- function(L) {
  Models_ls <- loadPackageDataset("DUAllocationModel_ls", "VELandUse")

  # Get the Bzone data into a data.frame
  Bzone_df <- data.frame(L$Year[["Bzone"]])
  LUType_df <- data.frame(L$Year[["Lutype"]])

  writeLog("Allocate dwelling units to Bzones", Level = "info")

  Bzone_df <- Bzone_df |>
    mutate(
      STATEFP = "41",
      D4Lvl = factor(D4Lvl, levels = 1:7)
    )

  DUByLUType_df0 <- Bzone_df |>
    group_by(AreaType, DivType) |>
    summarise(
      SFDU = sum(SFDU, na.rm = TRUE),
      MFDU = sum(MFDU, na.rm = TRUE),
      GQDU = sum(GQDU, na.rm = TRUE),
      .groups = "drop"
    ) |>
    left_join(LUType_df, by = c("AreaType", "DivType"), suffix = c("", ".tgt")) |>
    mutate(
      SFDU.delta = SFDU.tgt - SFDU,
      MFDU.delta = MFDU.tgt - MFDU,
      GQDU.delta = GQDU.tgt - GQDU
    ) |>
    select(AreaType, DivType, ends_with(".delta"))

  for (DUType in c("SFDU", "MFDU", "GQDU")) {
    model <- Models_ls[[DUType]]
    Bzone_df[[paste0(DUType, ".pred")]] <- predict(model, newdata = Bzone_df)
  }

  Bzone_df <- Bzone_df |>
    mutate(
      SFDU.pred = ifelse(SFDU.pred < 0, 0, SFDU.pred),
      MFDU.pred = ifelse(MFDU.pred < 0, 0, MFDU.pred),
      GQDU.pred = ifelse(GQDU.pred < 0, 0, GQDU.pred)
    )

  # IPF
  DUByLUType_df1 <- Bzone_df |>
    group_by(AreaType, DivType) |>
    summarise(
      SFDU.sum = sum(SFDU.pred, na.rm = TRUE),
      MFDU.sum = sum(MFDU.pred, na.rm = TRUE),
      GQDU.sum = sum(GQDU.pred, na.rm = TRUE),
      .groups = "drop"
    )

  BzoneProp_df <- Bzone_df |>
    select(Bzone, AreaType, DivType, SFDU, MFDU, GQDU, SFDU.pred, MFDU.pred, GQDU.pred) |>
    left_join(DUByLUType_df1, by = c("AreaType", "DivType")) |>
    mutate(
      PropSFDU = ifelse(SFDU.sum > 0, SFDU.pred / SFDU.sum, 1),
      PropMFDU = ifelse(MFDU.sum > 0, MFDU.pred / MFDU.sum, 1),
      PropGQDU = ifelse(GQDU.sum > 0, GQDU.pred / GQDU.sum, 1)
    )

  # LUTypeProp_df <- BzoneProp_df |>
  #   # when the weights are all 0, we set each bzone to have equal weight
  #   group_by(AreaType, DivType) |>
  #   summarise(
  #     PropSFDU.lut = sum(PropSFDU),
  #     PropMFDU.lut = sum(PropMFDU),
  #     PropGQDU.lut = sum(PropGQDU),
  #     .groups = "drop"
  #   )
  
  # BzoneProp_df <- BzoneProp_df |>
  #   left_join(LUTypeProp_df, by = c("AreaType", "DivType")) |>
  #   mutate(
  #     PropSFDU = ifelse(PropSFDU.lut == 0, 1, PropSFDU),
  #     PropMFDU = ifelse(PropMFDU.lut == 0, 1, PropMFDU),
  #     PropGQDU = ifelse(PropGQDU.lut == 0, 1, PropGQDU)
  #   )

  BzoneSamplePool_df <- BzoneProp_df |>
    group_by(AreaType, DivType) |>
    nest() |>
    left_join(DUByLUType_df0, by = c("AreaType", "DivType")) |>
    mutate(PoolSize = map_dbl(data, ~ nrow(.x))) |>
    filter(PoolSize > 0) # we can only do sampling when there are Bzones with matched LUType
  
  SFDUByBzone_df <- BzoneSamplePool_df |>
    mutate(
      sampled_data = map2(
        data, SFDU.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropSFDU, replace = TRUE)
      )
    ) |>
    select(sampled_data, SFDU.delta) |>
    unnest(sampled_data) |>
    mutate(
      SFDU_ = sign(SFDU.delta) * 1
    ) |>
    group_by(Bzone) |>
    summarise(
      SFDU_delta = sum(SFDU_, na.rm = TRUE),
      SFDU = first(SFDU), # current SFDU
      .groups = "drop"
    ) |>
    mutate(
      SFDU_new = SFDU + SFDU_delta,
      SFDU_new = ifelse(SFDU_new < 0, 0, SFDU_new)
    ) |>
    select(Bzone, SFDU_new)

  MFDUByBzone_df <- BzoneSamplePool_df |>
    #filter(MFDU.delta != 0) |>
    mutate(
      sampled_data = map2(
        data, MFDU.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropMFDU, replace = TRUE)
      )
    ) |>
    select(sampled_data, MFDU.delta) |>
    unnest(sampled_data) |> 
    mutate(
        MFDU_ = sign(MFDU.delta) * 1
      ) |>
      group_by(Bzone) |>
      summarise(
        MFDU_delta = sum(MFDU_, na.rm = TRUE),
        MFDU = first(MFDU), # current MFDU
        .groups = "drop"
      ) |>
      mutate(
        MFDU_new = MFDU + MFDU_delta,
        MFDU_new = ifelse(MFDU_new < 0, 0, MFDU_new)
      ) |>
      select(Bzone, MFDU_new)

  GQDUByBzone_df <- BzoneSamplePool_df |>
    mutate(
      sampled_data = map2(
        data, GQDU.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropGQDU, replace = TRUE)
      )
    ) |>
    select(sampled_data, GQDU.delta) |>
    unnest(sampled_data) |>
    mutate(
      GQDU_ = sign(GQDU.delta) * 1
    ) |>
    group_by(Bzone) |>
    summarise(
      GQDU_delta = sum(GQDU_, na.rm = TRUE),
      GQDU = first(GQDU), # current GQDU
      .groups = "drop"
    ) |>
    mutate(
      GQDU_new = GQDU + GQDU_delta,
      GQDU_new = ifelse(GQDU_new < 0, 0, GQDU_new)
    ) |>
    select(Bzone, GQDU_new)
  
  Bzone_df_ <- Bzone_df |>
    left_join(SFDUByBzone_df, by = "Bzone") |>
    left_join(MFDUByBzone_df, by = "Bzone") |>
    left_join(GQDUByBzone_df, by = "Bzone") |>
    mutate(
      SFDU = ifelse(is.na(SFDU_new), SFDU, SFDU_new),
      MFDU = ifelse(is.na(MFDU_new), MFDU, MFDU_new),
      GQDU = ifelse(is.na(GQDU_new), GQDU, GQDU_new)
    ) |>
    select(Bzone, AreaType, DivType, SFDU, MFDU, GQDU) |>
    arrange(Bzone)

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()
  # Add the employment Bzone assignments to the list
  Out_ls$Year$Bzone$Bzone <- unname(Bzone_df_$Bzone)
  #Out_ls$Year$Bzone$AreaType <- unname(Bzone_df_$AreaType)
  #Out_ls$Year$Bzone$DivType <- unname(Bzone_df_$DivType)
  Out_ls$Year$Bzone$SFDU <- as.integer(unname(Bzone_df_$SFDU))
  Out_ls$Year$Bzone$MFDU <- as.integer(unname(Bzone_df_$MFDU))
  Out_ls$Year$Bzone$GQDU <- as.integer(unname(Bzone_df_$GQDU))
  # Add SIZE attribute for the employment Bzone assignments
  attributes(Out_ls$Year$Bzone$Bzone)$SIZE <- max(nchar(Bzone_df_$Bzone))

  # Return the outputs list
  Out_ls
}


# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# documentModule("AllocateDU")
