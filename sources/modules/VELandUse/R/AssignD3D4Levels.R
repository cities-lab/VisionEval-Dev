# ==========================
# AssignD3D4Levels.R
# ==========================
#
#<doc>
#
## AssignD3D4Levels Module
#
# This module assigns D3 and D4 levels to Bzones.
#
### Model Parameter Estimation
#
# The module uses two decision tree models to predict D3 (urban design) and D4 (transit) levels:
#
# 1) D3 Level Decision Tree (Urban Design):
#    - Predicts urban design level based on:
#      * D1D_hmbuf (activity density within half mile buffer of Bzone centroid)
#      * D2A_JPHH_hmbuf (Job per HH within half mile buffer of Bzone centroid)
#      * D3BPO4 (intersection density in terms of pedestrian-oriented intersections having three legs per square mile)
#    - Model parameters:
#      * minbucket = 1000 (minimum observations in terminal nodes)
#      * maxdepth = 3 (maximum tree depth)
#      * cp = 0.001 (complexity parameter)
#
# 2) D4 Level Decision Tree (Transit):
#    - Predicts transit level based on:
#      * D4A (distance from the population-weighted centroid to nearest transit stop)
#      * D4C (aggregate frequency of transit service within 0.25 miles of CBG boundary per hour during evening peak period)
#      * DistToStop (distance to nearest transit stop, miles)
#      * DistToFgwSta (distance to nearest fixed guideway station, miles)
#      * HasFgwTransit (indicator for whether the Marea has fixed guideway transit service)
#    - Model parameters:
#      * minbucket = 500 (minimum observations in terminal nodes)
#      * maxdepth = 3 (maximum tree depth)
#      * cp = 0.01 (complexity parameter)
#
### How the Module Works
#
# The module carries out the following steps to assign D3 (urban design) and D4 (transit) levels to Bzones:
#
# 1) Predict D3 Level (Urban Design): A decision tree model is used to predict the urban design level (D3) for each Bzone based on:
#    - D1D_hmbuf (activity density within half mile buffer of Bzone centroid)
#    - D2A_JPHH_hmbuf (Job per HH within half mile buffer of Bzone centroid)
#    - D3BPO4 (intersection density in terms of pedestrian-oriented intersections having three legs per square mile)
#    The model predicts one of four levels (1-4), where higher levels indicate better urban design supporting walkability.
#
# 2) Predict D4 Level (Transit): A separate decision tree model is used to predict the transit service level (D4) for each Bzone based on:
#    - D4A (distance from the population-weighted centroid to nearest transit stop)
#    - D4C (aggregate frequency of transit service within 0.25 miles of CBG boundary per hour during evening peak period)
#    - DistToStop (distance to nearest transit stop, miles)
#    - DistToFgwSta (distance to nearest fixed guideway station, miles)
#    - HasFgwTransit (indicator for whether the Marea has fixed guideway transit service)
#    The model predicts one of seven levels (1-7), where higher levels indicate better transit service quality.
#
# 3) Finalize Bzone Levels: The predicted D3 and D4 levels are stored in the datastore for each Bzone. These levels are used by other modules to model travel behavior and accessibility.
#
# The decision tree models were trained using data from the Smart Location Database (SLD) and transit and walking commuting shares from the American Community Survey (ACS) data.
#
#</doc>


# =============================================
# SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
# =============================================
# see data-raw/D3D4LevelDTree.R for details


# ================================================
# SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
# ================================================

# Define the data specifications
#------------------------------
AssignD3D4LevelsSpecifications <- list(
    # Level of geography module is applied at
    RunBy = "Bzone",
    # Specify new tables to be created by Inp if any
    # Specify input data
    Inp = items(
        item(
            NAME = "D4A",
            FILE = "bzone_transit_service.csv",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "distance",
            UNITS = "M",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = "Distance from the population-weighted centroid to nearest transit stop (meters)"
        ),
        item(
            NAME = "D4C",
            FILE = "bzone_transit_service.csv",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "double",
            UNITS = "aggregate peak period transit service",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = "Aggregate frequency of transit service within 0.25 miles of CBG boundary per hour during evening peak period"
        ),
        item(
            NAME = items("DistToStop", "DistToFgwSta"),
            FILE = "bzone_distances.csv",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "distance",
            UNITS = "MI",
            NAVALUE = "NA",
            SIZE = 2,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = items("Distances to nearest transit stop", "Distance to nearest fixed guideway station (meters)")
        ),
        item(
            NAME = "HasFgwTransit",
            FILE = "marea_fgw_transit.csv",
            TABLE = "Marea",
            GROUP = "Year",
            TYPE = "integer",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = "Indicator for whether the Marea has fixed guideway transit service (1 = yes, 0 = no)"
        ),
        item(
            NAME = "D3bpo4",
            FILE = "bzone_network_design.csv",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "double",
            UNITS = "pedestrian-oriented intersections per square mile",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = "Intersection density in terms of pedestrian-oriented intersections having three legs per square mile"
        )
    ),
    # Specify data to be loaded from data store
    Get = items(
        item(
            NAME = "D1D_hmbuf",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "compound",
            UNITS = "HHJOB/ACRE",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            UNLIKELY = "",
            TOTAL = "",
            DESCRIPTION = "Activity density within half mile buffer of Bzone centroid"
        ),
        item(
            NAME = "D2A_JPHH_hmbuf",
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "compound",
            UNITS = "JOB/HH",
            NAVALUE = -1,
            PROHIBIT = "",
            ISELEMENTOF = "",
            DESCRIPTION = "Job per HH within half mile buffer of Bzone centroid"
        )
    ),
    # Specify data to saved in the data store
    Set = items(
        item(
            NAME = items(
                "D3Lvl",
                "D4Lvl"
            ),
            TABLE = "Bzone",
            GROUP = "Year",
            TYPE = "character",
            UNITS = "category",
            NAVALUE = "NA",
            SIZE = 1,
            PROHIBIT = "",
            ISELEMENTOF = "",
            DESCRIPTION = items(
                "Level of urban density (D3) quality supporting walkability, from 1 (lowest) to 4 (highest)",
                "Level of transit service quality, from 1 (lowest) to 7 (highest)"
            )
        )
    )
)

# Save the data specifications list
#---------------------------------
#' Specifications list for AssignD3D4Levels module
#'
#' A list containing specifications for the AssignD3D4Levels module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignD3D4Levels.R script.
"AssignD3D4LevelsSpecifications"
visioneval::savePackageDataset(AssignD3D4LevelsSpecifications, overwrite = TRUE)


# =======================================================
# SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
# =======================================================
# This function assigns the D3 and D4 levels to Bzones.

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
    classes = NULL) {
    if (rpart_tree$method == "class") {
        # use [, 2] to get prob(y=TRUE) from prob[FALSE, TRUE]
        pred_val <- predict(rpart_tree, type = "prob")[, 2]
        x_df$.pred_val <- predict(rpart_tree, x_df, type = "prob")[, 2]
    } else {
        pred_val <- predict(rpart_tree)
        x_df$.pred_val <- predict(rpart_tree, x_df)
    }
    unique_vals <- unique(pred_val) |> sort()
    classes <- ifelse(is.null(classes), 1:length(unique_vals), classes)
    val_class_lut <- tibble(.pred_val = unique_vals, class = classes)

    # x_df$.pred_val <- predict(rpart_tree, x_df)
    results <- x_df %>%
        left_join(val_class_lut, by = ".pred_val") |>
        pull(class)

    return(results)
}

# Main module function that assigns D3 and D4 levels to Bzones
#---------------------------------------------------------------------
#' Main module function to assign D3 and D4 levels to Bzones.
#'
#' \code{AssignD3D4Levels} assigns the D3 and D4 levels to Bzones using decision trees
#' trained on D-variables from the Smart Location Database (SLD) data using transit
#' and walking commuting shares from the ACS data as the "ground truth" outcome.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignD3D4Levels
#' @import visioneval stats
#' @export
AssignD3D4Levels <- function(L) {
    # Assign car service level to each household
    #------------------------------------------
    # Match index vector of Bzone to Households
    Bzone_df <- data.frame(L$Year$Bzone)
    D3LevelDTree <- loadPackageDataset("D3LevelDTree", "VELandUse")
    D4LevelDTree <- loadPackageDataset("D4LevelDTree", "VELandUse")
    D3Lvl_ <- RpartPredClass(D3LevelDTree, Bzone_df, c(1:4))
    D4Lvl_ <- RpartPredClass(D4LevelDTree, Bzone_df, c(1:7))

    # Return list of results
    #----------------------
    Out_ls <- initDataList()
    Out_ls$Year$Bzone <- list(
        D3Lvl = D3Lvl_,
        D4Lvl = D4Lvl_
    )
    Out_ls
}

# ===============================================================
# SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
# ===============================================================
# Run module automatic documentation
#----------------------------------
# documentModule("AssignD3D4Levels")

# Test code to check specifications, loading inputs, and whether datastore
# contains data needed to run module. Return input list (L) to use for developing
# module functions
#-------------------------------------------------------------------------------
