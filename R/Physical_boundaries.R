
#' define_physical_boundaries
#'
#' Check whether a parameter value lies within specified physical bounds.
#'
#' @param value parameter value
#' @param min_limit Minimum allowed value.
#' @param max_limit Maximum allowed value.
#'
#'
#' @return The input value if it lies within the specified physical bounds.
#' @export
#'
#' @examples define_physical_boundaries(0.3, 0, 1)
define_physical_boundaries <- function(value, min_limit, max_limit) {

  if (min_limit > max_limit) {
    stop("'min_limit' must be smaller than or equal to 'max_limit'.")
  }

  if (value < min_limit) {
    stop("Please ensure the parameter is above the minimum limit.")
  }

  if (value > max_limit) {
    stop("Please ensure the parameter is below the maximum limit.")
  }

  value
}

#' check_balance
#'
#'Check carbon balance consistency of a  simulation.
#'
#' Computes the balance between initial soil carbon, cumulative carbon inputs,
#' final carbon stocks and cumulative CO2 emissions. The balance should be
#' zero or very close to zero.
#'
#' @param ctool_output Output from turnover model.
#' @param cin_config Carbon input configuration.
#' @param s_config Soil configuration.
#'
#' @return The input `ctool_output` data.frame, returned unchanged after
#' checking carbon balance consistency.
#'
#' @export

check_balance <- function(ctool_output,
                         cin_config,
                         s_config) {
  # TODO: if C inputs are given in a monthly data frame, do not sum the full vector directly;
  # monthly allocation must be accounted for.

  initial <- s_config$Csoil_init

  inputs <- sum(cin_config$Cin_top) +
    sum(cin_config$Cin_sub) +
    sum(cin_config$Cin_man)

  stocks <- ctool_output$C_topsoil[nrow(ctool_output)] +
    ctool_output$C_subsoil[nrow(ctool_output)]

  emissions <- sum(ctool_output$em_CO2_top) +
    sum(ctool_output$em_CO2_sub)

  balance <- initial + inputs - stocks - emissions

     if (abs(balance) >= 0.001) {
       warning("Carbon balance does not close. Balance error = ",
              signif(balance, 6))
     }

      ctool_output
}
