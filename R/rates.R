#'Decay of carbon function'
#'
#'The decay of carbon in each pool is described by first-order reaction kinetics
#'where we have an specific decay rate coefficient in each pool that affects the
#'actual C content in it (MgC/ha).The turnover is simulated in monthly time steps,
#'where th decay rate is modify by the temp_coef() function.

#' @return The arguments are:
#' @export
#' @examples

decay <- function(amount_t, k, tempCoefficient ){
  amount = amount_t * (-k * tempCoefficient)
  amount
}

decay

#' Humification coefficient
#'

#' @return The arguments are:
#' @export
#' @examples

hum_coef <- function(clayfrac) {

  R= 1.67 * (1.85 + 1.6 * exp(-7.86 * clayfrac))

  h= 1/(R+1)

  h
}

hum_coef
