#' Install R Packages from Local Source Directories
#'
#' @description
#' This script installs one or more R packages from specified local source directories
#' into the library path defined by the VE_LIB environment variable.
#' It uses `devtools::install` for the installation.
#' Necessary dependencies (`withr`, `devtools`) are installed if missing.
#'
#' @details
#' The script accepts zero or more command-line arguments, each being a path
#' to a directory containing an R package source.
#' If no arguments are provided, it defaults to installing the package in the
#' current working directory (`.`).
#' Errors during the installation of one package do not stop the script; it will
#' report the error and continue with the next specified directory.
#'
#' @param ... Paths to package source directories passed as command-line arguments.
#'
#' @examples
#' # Install package from the current directory
#' # Rscript install_pkg.R
#'
#' # Install packages from two specific directories
#' # Rscript install_pkg.R ../MyPackage1 ./MyPackage2
#'
#' # Show help message
#' # Rscript install_pkg.R --help
#'
#' @keywords internal

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check for help flag
if ("-h" %in% args || "--help" %in% args) {
    cat("Usage: Rscript install_pkgs.R [package_dir1] [package_dir2] ...\n")
    cat("\n")
    cat(
        "Installs R packages from the specified source directories into the VE_LIB environment.\n"
    )
    cat(
        "If no directories are provided, it installs the package from the current directory ('.').\n"
    )
    cat("\n")
    cat("Arguments:\n")
    cat(
        "  package_dir  Path to the source directory of the R package to install.\n"
    )
    cat("               Multiple directories can be specified.\n")
    cat("\n")
    cat("Options:\n")
    cat("  -h, --help   Show this help message and exit.\n")
    quit(save = "no", status = 0)
}

# Default to current directory if no arguments are provided
if (length(args) == 0) {
    args <- c(".")
}

repos <- c("https://cran.rstudio.com", "https://cloud.r-project.org")
ve_lib <- Sys.getenv("VE_LIB")
ve_lib <- ifelse(ve_lib == "", .libPaths()[1], ve_lib)

# Ensure necessary packages are installed
if (!requireNamespace("withr", quietly = TRUE)) {
    install.packages("withr", lib = ve_lib, repos = repos)
}
if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools", lib = ve_lib, repos = repos)
}

# Loop through each package directory and install
for (pkg_dir in args) {
    cat("\nInstalling package from directory:", pkg_dir, "\n")
    tryCatch(
        {
            withr::with_libpaths(ve_lib, {
                devtools::install(
                    pkg_dir,
                    dependencies = TRUE,
                    repos = repos,
                    upgrade = "never"
                ) # Added upgrade='never' to potentially speed up installs if deps are met
            })
            cat("Successfully installed package from:", pkg_dir, "\n")
        },
        error = function(e) {
            cat(
                "ERROR installing package from:",
                pkg_dir,
                "\n",
                conditionMessage(e),
                "\n"
            )
        }
    )
}