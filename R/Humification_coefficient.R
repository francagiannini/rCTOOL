#' Internal humification coefficient
#'
#' Calculate the humification coefficient as a function of clay fraction.
#'
#' @param f_clay Fraction of clay in soil.
#'
#' @return Numeric humification coefficient.
#'
#' @noRd
.hum_coef <- function(f_clay) {
  if (any(f_clay < 0 | f_clay > 1, na.rm = TRUE)) {
    stop("'f_clay' must be between 0 and 1.")
  }
  R <- 1.67 * (1.85 + 1.6 * exp(-7.86 * f_clay))
  return(1/(R+1))
}
