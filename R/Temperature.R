#' set_monthly_temperature_data
#'
#' Prepare monthly temperature input data for rCTOOL.
#'
#' Monthly temperature data can be provided in two ways:
#' 1. directly through the argument `file`, as a filepath or data.frame
#'    containing monthly temperature data
#' 2. directly through the argument `Tavg`, as a numeric vector of average
#'    monthly temperature values
#'
#' @param file Either a filepath to a csv file or a data.frame containing
#'   monthly temperature data.
#' @param Tavg Numeric vector of average monthly temperature values.
#'
#' @return A data.frame containing monthly temperature input data.
#'   The output always contains `Tavg`.
#' @export
#'
#' @examples
#' df_temp <- data.frame(Tavg = c(5, 6, 7, 8, 9, 15, 14, 11, 10, 9, 5, 1))
#' set_monthly_temperature_data(file = df_temp)
#'
#' @examples
#' set_monthly_temperature_data(
#'   Tavg = c(5, 6, 7, 8, 9, 15, 14, 11, 10, 9, 5, 1)
#' )
set_monthly_temperature_data <- function(file = NULL, Tavg = NULL) {

  if (missing(file) || is.null(file)) {

    if (!is.null(Tavg)) {
      temp_df <- data.frame(Tavg = Tavg)
    } else {
      stop("Provide monthly temperature data through 'file' or through a Tavg vector.")
    }

  } else {

    if (is.character(file)) {

      if (!grepl("\\.csv$", file, ignore.case = TRUE)) {
        stop("Please use a csv file.")
      }

      temp_df <- read.csv(file)

    } else if (is.data.frame(file)) {

      temp_df <- as.data.frame(file)

    } else {

      stop(
        'Argument "file" can be either a filepath to the temperature csv ',
        'or it can directly be the temperature data.frame'
      )
    }
  }

  if (!("Tavg" %in% names(temp_df))) {
    stop("Monthly temperature data must contain a Tavg column.")
  }

  if (!is.numeric(temp_df$Tavg)) {
    stop("Column 'Tavg' must be numeric.")
  }

  if (length(temp_df$Tavg) == 0) {
    stop("Column 'Tavg' must not be empty.")
  }

  if (all(is.na(temp_df$Tavg))) {
    stop("Column 'Tavg' contains only missing values.")
  }

  as.data.frame(temp_df)
}

#' set_monthly_temperature_data_historical_amplitude
#'
#' Prepare monthly temperature input with a single historical amplitude.
#'
#' Monthly `Tavg` data can be provided either as a filepath/data.frame
#' through `file` or directly as a numeric vector through `Tavg`.
#'
#' A single historical amplitude is calculated from the full monthly
#' `Tavg` series as:
#' \deqn{(max(Tavg) - min(Tavg)) / 2}
#'
#' This historical amplitude is then assigned to the full series in the
#' `Amplitude` column.
#'
#' @param file Either a filepath to a csv file or a data.frame containing
#'   monthly temperature data.
#' @param Tavg Numeric vector of average monthly temperature values.
#'
#' @return A data.frame containing `Tavg` and a single historical
#'   `Amplitude` repeated over the full series.
#' @export
#'
#' @examples
#' set_monthly_temperature_data_historical_amplitude(
#'   Tavg = c(1, 2, 4, 7, 11, 15, 17, 16, 13, 9, 5, 2)
#' )
set_monthly_temperature_data_historical_amplitude <- function(file = NULL,
                                                              Tavg = NULL) {

  if (missing(file) || is.null(file)) {

    if (!is.null(Tavg)) {
      temp_df <- data.frame(Tavg = Tavg)
    } else {
      stop("Provide monthly temperature data through 'file' or through a Tavg vector.")
    }

  } else {

    if (is.character(file)) {

      if (!grepl("\\.csv$", file, ignore.case = TRUE)) {
        stop("Please use a csv file.")
      }

      temp_df <- read.csv(file)

    } else if (is.data.frame(file)) {

      temp_df <- as.data.frame(file)

    } else {

      stop(
        'Argument "file" can be either a filepath to the temperature csv ',
        'or it can directly be the temperature data.frame'
      )
    }
  }

  if (!("Tavg" %in% names(temp_df))) {
    stop("Monthly temperature data must contain a Tavg column.")
  }

  if (!is.numeric(temp_df$Tavg)) {
    stop("Column 'Tavg' must be numeric.")
  }

  if (length(temp_df$Tavg) == 0) {
    stop("Column 'Tavg' must not be empty.")
  }

  if (all(is.na(temp_df$Tavg))) {
    stop("Column 'Tavg' contains only missing values.")
  }

  A0_hist <- (max(temp_df$Tavg, na.rm = TRUE) - min(temp_df$Tavg, na.rm = TRUE)) / 2

  temp_df$Amplitude <- A0_hist

  as.data.frame(temp_df)
}
