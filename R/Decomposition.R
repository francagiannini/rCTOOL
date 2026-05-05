#' .temp_coef
#'
#' Calculate the temperature response coefficient for carbon decomposition.
#'
#' @param T_zt Soil temperature at depth z and time t.
#'
#' @return Temperature response coefficient for carbon decomposition.
.temp_coef <- function(T_zt) {
  return(7.24 * exp(-3.432 + 0.168 * T_zt * (1 - 0.5 * T_zt / 36.9)))
}

# Previous soil temperature implementation was removed because it used
# monthly indices directly in a formulation requiring annual physical time scaling.

#' .soil_temp
#'
#' @param depth Soil layer reference depth in cm. In the default C-TOOL
#' configuration, the model operates with two fixed layers:
#' topsoil (25 cm) and subsoil (100 cm).
#' @param month Month index (1 to 12).
#' @param T_ave Monthly mean air temperature.
#' @param Amplitude Annual temperature amplitude used in the soil temperature equation.
#' @param th_diff Thermal diffusivity.
#'
#' @return Soil temperature at the midpoint of the soil layer for the
#' specified monthly timestep.
.soil_temp <- function(depth,
                       month,
                       T_ave,
                       Amplitude,
                       th_diff) {

  z <- depth / 2 * 0.01

  month_mid_day <- c(15, 45, 74, 105, 135, 166, 196, 227, 258, 288, 319, 349)

  if (!month %in% 1:12) {
    stop("month must be between 1 and 12")
  }

  t_day <- month_mid_day[month]
  rho <- 2 * pi / (365 * 24 * 3600)
  D <- sqrt(2 * th_diff / rho)
  t_sec <- t_day * 24 * 3600

  T_ave + Amplitude * exp(-z / D) * sin(rho * t_sec - z / D)
}

#' .decay
#'
#' Calculate soil carbon loss by first-order decomposition.
#'
#' @param CO_t Carbon amount in the pool at time t.
#' @param k First-order decomposition rate constant.
#' @param tempCoefficient Temperature response coefficient.
#'
#' @return Carbon change due to decomposition during the timestep.
.decay <- function(CO_t, k, tempCoefficient) {
  return(CO_t * (-k * tempCoefficient))
}

#' soil_pool_decomposition
#'
#' Calculate temperature-modified decomposition of a soil carbon pool.
#'
#' @param soil_pool Carbon amount in the soil pool.
#' @param k First-order decomposition rate constant.
#' @param soil_depth Soil layer thickness in cm. In the default C-TOOL
#' configuration, the model operates with two fixed layers: topsoil
#' (25 cm) and subsoil (100 cm).
#' @param month Month index from 1 to 12.
#' @param t_avg Monthly mean air temperature.
#' @param amplitude Historical annual temperature amplitude previously
#' calculate from the monthly temperature series.
#' @param s_config Soil parameter configuration.
#'
#' @return Carbon change in the pool due to temperature-modified
#' first-order decomposition.
soil_pool_decomposition <- function(soil_pool,
                                    k,
                                    soil_depth,
                                    month,
                                    t_avg,
                                    amplitude,
                                    s_config) {

  temp_coefficient <- .temp_coef(
    T_zt = .soil_temp(
      depth = soil_depth,
      month = month,
      T_ave = t_avg,
      Amplitude = amplitude,
      th_diff = s_config[["temp_th_diff"]]
    )
  )

  .decay(CO_t = soil_pool, k = k, tempCoefficient = temp_coefficient)
}
