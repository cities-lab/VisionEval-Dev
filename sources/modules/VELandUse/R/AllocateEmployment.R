# ================
# AllocateEmployment.R
# ================

#<doc>
#
## AllocateEmployment Module

# This module assigns employment targets (TotEmp, SvcEmp, and RetEmp), specified by Land Use Type, to Bzones.

# There are two steps for the allocation:
# 1. Allocation models predict Bzone employment by sector group based on LUType and other Bzone variables
# 2. An simplified IPF process based on the distribution of predict Bzone employment to meet the specified employment targets by LUType;

# The IPF process scales employment to Bzone based on the base/previous year employment by land use type and sector group (Svc, Ret, and Non-Svc-Ret) as well as the employment by type and sector group in current simulation year (an input). The former is used as the seed matrix for the IPF, while the latter matches the margin control totals.

#
### Model Parameter Estimation
#
# A OLS model is used to predict Bzone employment based on LUType and other Bzone varialbes. The model is estimated using data from Smart Location Database.
# data-raw/EmpAllocationModel_ls.R
# The summary statistics for this model are as follows:
#
#<txt:EmpAllocationModel_ls$Summary>
#

#
### How the Module Works
#
# The module carries out the following series of calculations to assign employment by sector group (e.g., Retail, Service, Other) to Bzones:

# 1) Predict Initial Bzone Employment by Sector: For each employment sector group (e.g., Retail - RetEmp, Service - SvcEmp, Non-Retail-Service/Other - OthEmp), an Ordinary Least Squares (OLS) regression model is applied. These models use Bzone characteristics (such as accessibility, existing development patterns) and the Bzone's assigned Land Use Type (LUType) as predictor variables to generate an initial forecast of the number of jobs within each Bzone for that sector. This initial forecast serves as the seed for the subsequent adjustment step.

# 2) Allocate Employment using Iterative Proportional Fitting (IPF): An IPF process is used to adjust the initial Bzone employment predictions (from Step 1) to match specified control totals.
#   The **seed matrix** for the IPF is the predicted Bzone employment by sector group (from Step 1).
#   The **margin control totals** are the employment targets by sector group (TotEmp, RetEmp, SvcEmp) by LUType reading from `lutype_employment.csv`.
#
#   The IPF algorithm iteratively scales the seed matrix until it converges with both the LUType-level and employment sector group targets. This ensures the final allocation respects both the spatial patterns from the OLS models and the aggregate targets.

# 3) Finalize Bzone Employment: The output of the IPF process is the final allocated number of jobs for each Bzone, broken down by each employment sector group (e.g., TotEmp, RetEmp, SvcEmp). These values are then stored in the datastore.
#
#</doc>

# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# This model allocates employment to block groups based on socioeconomic, land use, and accessibility variables.

# see data-raw/EmpAllocationModel_ls.R for details

# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
AllocateEmploymentSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  # Specify new tables to be created by Set if any
  # Specify input data
  Inp = items(
    item(
      NAME = items(
        "TotEmp",
        "SvcEmp",
        "RetEmp"
      ),
      FILE = "lutype_employment.csv",
      TABLE = "Lutype",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Total number of jobs by land use type and sector group",
        "Number of jobs in retail sector by land use type",
        "Number of jobs in service sector by land use type"
      )
    ),
    item(
      NAME = items(
        "AreaType",
        "DivType"
      ),
      FILE = "lutype_employment.csv",
      TABLE = "Lutype",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
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
      NAME = items("DistToCBD", "DistToRamp", "DistToFgwSta"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PctSteepSlope",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D4Lvl",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("1", "2", "3", "4", "5", "6", "7")
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      SIZE = 12,
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("AreaType", "DivType"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      SIZE = 12,
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  # Specify data to saved in the data store
  Set = items(
    item(
      NAME = items("TotEmp", "RetEmp", "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total number of jobs in zone",
        "Number of jobs in retail sector in zone",
        "Number of jobs in service sector in zone"
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
#' @source AllocateEmployment.R script.
"AllocateEmploymentSpecifications"
visioneval::savePackageDataset(AllocateEmploymentSpecifications, overwrite = TRUE)

# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================

# Main module function that assigns employment to Bzones
#---------------------------------------------------------------------------
#' Main module function that assigns employment to Bzones.
#'
#' \code{AllocateEmployment} assigns employment to Bzones.
#'
#' This function assigns employment to Bzones. The employment is assigned to a
#' Bzone based on the input:
#' 1) employment total by LUType and sector group
#' 2) base/previous year employment by sector group for each Bzone
#' 3) base/previous year Land use type for each Bzone
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AllocateEmploymentLUTTarget
#' @import visioneval stats
#' @import dplyr
#' @export
AllocateEmployment <- function(L) {
  Models_ls <- loadPackageDataset("EmpAllocationModel_ls", "VELandUse")

  # Get the Bzone data into a data.frame
  # Move STATEFP to Azone
  Bzone_df <- data.frame(L$Year[["Bzone"]]) |>
    mutate(
      OthEmp = TotEmp - RetEmp - SvcEmp,
      OthEmp = ifelse(OthEmp < 0, 0, OthEmp),
      STATEFP = "41",
      D4Lvl = factor(D4Lvl, levels = 1:7)
    )
  LUType_df <- data.frame(L$Year[["Lutype"]]) |>
    # non-retail and non-service employment
    mutate(
      OthEmp = TotEmp - RetEmp - SvcEmp,
      OthEmp = ifelse(OthEmp < 0, 0, OthEmp)
    )

  writeLog("Allocate employment to Bzones", Level = "info")

  EmpByLUType_df0 <- Bzone_df |>
    group_by(AreaType, DivType) |>
    summarise(
      RetEmp = sum(RetEmp, na.rm = TRUE),
      SvcEmp = sum(SvcEmp, na.rm = TRUE),
      OthEmp = sum(OthEmp, na.rm = TRUE),
      .groups = "drop"
    ) |>
    left_join(LUType_df, by = c("AreaType", "DivType"), suffix = c("", ".tgt")) |>
    mutate(
      RetEmp.delta = RetEmp.tgt - RetEmp,
      SvcEmp.delta = SvcEmp.tgt - SvcEmp,
      OthEmp.delta = OthEmp.tgt - OthEmp
    ) |>
    select(AreaType, DivType, ends_with(".delta"))
  
  for (SectorGrp in c("RetEmp", "SvcEmp", "OthEmp")) {
    model <- Models_ls[[SectorGrp]]
    Bzone_df[[paste0(SectorGrp, ".pred")]] <- predict(model, newdata = Bzone_df)
  }
  
  Bzone_df <- Bzone_df |>
    mutate(
      RetEmp.pred = ifelse(RetEmp.pred < 0, 0, RetEmp.pred),
      SvcEmp.pred = ifelse(SvcEmp.pred < 0, 0, SvcEmp.pred),
      OthEmp.pred = ifelse(OthEmp.pred < 0, 0, OthEmp.pred)
    )
  
  EmpByLUType_df1 <- Bzone_df |>
    group_by(AreaType, DivType) |>
    summarise(
      RetEmp.sum = sum(RetEmp.pred, na.rm = TRUE),
      SvcEmp.sum = sum(SvcEmp.pred, na.rm = TRUE),
      OthEmp.sum = sum(OthEmp.pred, na.rm = TRUE),
      .groups = "drop"
    )

  BzoneProp_df <- Bzone_df |>
    select(Bzone, AreaType, DivType, RetEmp, SvcEmp, OthEmp, RetEmp.pred, SvcEmp.pred, OthEmp.pred) |>
    left_join(EmpByLUType_df1, by = c("AreaType", "DivType")) |>
    mutate(
      PropRetEmp = ifelse(RetEmp.sum > 0, RetEmp.pred / RetEmp.sum, 1),
      PropSvcEmp = ifelse(SvcEmp.sum > 0, SvcEmp.pred / SvcEmp.sum, 1),
      PropOthEmp = ifelse(OthEmp.sum > 0, OthEmp.pred / OthEmp.sum, 1)
    )
  
  # IPF
  BzoneSamplePool_df <- BzoneProp_df |>
    group_by(AreaType, DivType) |>
    nest() |>
    left_join(EmpByLUType_df0, by = c("AreaType", "DivType")) |>
    mutate(PoolSize = map_dbl(data, ~ nrow(.x))) |>
    filter(PoolSize > 0) # we can only do sampling when there are Bzones with matched LUType

  RetEmpByBzone_df <- BzoneSamplePool_df |>
    mutate(
      sampled_data = map2(
        data, RetEmp.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropRetEmp, replace = TRUE)
      )
    ) |>
    select(sampled_data, RetEmp.delta) |>
    unnest(sampled_data) |>
    mutate(
      RetEmp_ = sign(RetEmp.delta) * 1
    ) |>
    group_by(Bzone) |>
    summarise(
      RetEmp_delta = sum(RetEmp_, na.rm = TRUE),
      RetEmp = first(RetEmp), # current RetEmp
      .groups = "drop"
    ) |>
    mutate(
      RetEmp_new = RetEmp + RetEmp_delta,
      RetEmp_new = ifelse(RetEmp_new < 0, 0, RetEmp_new)
    ) |>
    select(Bzone, RetEmp_new)

  SvcEmpByBzone_df <- BzoneSamplePool_df |>
    #filter(SvcEmp.delta != 0) |>
    mutate(
      sampled_data = map2(
        data, SvcEmp.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropSvcEmp, replace = TRUE)
      )
    ) |>
    select(sampled_data, SvcEmp.delta) |>
    unnest(sampled_data) |>
    mutate(
      SvcEmp_ = sign(SvcEmp.delta) * 1
    ) |>
    group_by(Bzone) |>
    summarise(
      SvcEmp_delta = sum(SvcEmp_, na.rm = TRUE),
      SvcEmp = first(SvcEmp), # current SvcEmp
      .groups = "drop"
    ) |>
    mutate(
      SvcEmp_new = SvcEmp + SvcEmp_delta,
      SvcEmp_new = ifelse(SvcEmp_new < 0, 0, SvcEmp_new)
    ) |>
    select(Bzone, SvcEmp_new)
  
  OthEmpByBzone_df <- BzoneSamplePool_df |>
    mutate(
      sampled_data = map2(
        data, OthEmp.delta,
        ~ slice_sample(.x, n = round(abs(.y), 0), weight_by = .x$PropOthEmp, replace = TRUE)
      )
    ) |>
    select(sampled_data, OthEmp.delta) |>
    unnest(sampled_data) |>
    mutate(
      OthEmp_ = sign(OthEmp.delta) * 1
    ) |>
    group_by(Bzone) |>
    summarise(
      OthEmp_delta = sum(OthEmp_, na.rm = TRUE),
      OthEmp = first(OthEmp), # current OthEmp
      .groups = "drop"
    ) |>
    mutate(
      OthEmp_new = OthEmp + OthEmp_delta,
      OthEmp_new = ifelse(OthEmp_new < 0, 0, OthEmp_new)
    ) |>
    select(Bzone, OthEmp_new)

  Bzone_df_ <- Bzone_df |>
    select(Bzone, AreaType, DivType, RetEmp, SvcEmp, OthEmp) |>
    left_join(RetEmpByBzone_df, by = "Bzone") |>
    left_join(SvcEmpByBzone_df, by = "Bzone") |>
    left_join(OthEmpByBzone_df, by = "Bzone") |>
    mutate(
      RetEmp = ifelse(is.na(RetEmp_new), RetEmp, RetEmp_new),
      SvcEmp = ifelse(is.na(SvcEmp_new), SvcEmp, SvcEmp_new),
      OthEmp = ifelse(is.na(OthEmp_new), OthEmp, OthEmp_new),
      TotEmp = RetEmp + SvcEmp + OthEmp
    ) |>
    select(Bzone, AreaType, DivType, RetEmp, SvcEmp, TotEmp) |>
    arrange(Bzone)

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()
  # Add the employment Bzone assignments to the list
  Out_ls$Year$Bzone$Bzone <- unname(Bzone_df_$Bzone)
  Out_ls$Year$Bzone$AreaType <- unname(Bzone_df_$AreaType)
  Out_ls$Year$Bzone$DivType <- unname(Bzone_df_$DivType)
  Out_ls$Year$Bzone$RetEmp <- as.integer(unname(Bzone_df_$RetEmp))
  Out_ls$Year$Bzone$SvcEmp <- as.integer(unname(Bzone_df_$SvcEmp))
  Out_ls$Year$Bzone$TotEmp <- as.integer(unname(Bzone_df_$TotEmp))
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
# documentModule("AllocateEmployment")

# Test code to check specifications, loading inputs, and whether datastore
# contains data needed to run module. Return input list (L) to use for developing
# module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# library(fields)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-CLMPO",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "veclmpo",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- PredictHousing(L)
#
# TestDat_ <- testModule(
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = TRUE
# )
