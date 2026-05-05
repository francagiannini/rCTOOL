#' HUM_top_calculations
#'
#' Calculate HUM decomposition and carbon fluxes in the topsoil layer.
#'
#' @param HUM_top_t Numeric. Carbon content in the HUM topsoil pool
#'   (Mg C ha-1).
#' @param month Integer. Month index (1-12).
#' @param t_avg Numeric. Monthly mean air temperature (degrees C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters.
#'
#' @return A list with updated HUM topsoil pool values and associated fluxes.
#' @export
#'
#' @examples
#' \dontrun{
#' HUM_top_calculations(
#'   HUM_top_t = 20,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )
#' }

HUM_top_calculations <- function(HUM_top_t,
                                month,
                                t_avg = t_avg,
                                amplitude = amplitude,
                                s_config) {

  HUM_decomposition <- soil_pool_decomposition(
    soil_pool=HUM_top_t,
    k=s_config[['k_hum']],
    soil_depth = 25,
    month=month,
    t_avg=t_avg,
    amplitude = amplitude,
    s_config
    )

  substrate_HUM_decomp_top <- HUM_top_t - (HUM_top_t + HUM_decomposition)
  HUM_romified_top  <- substrate_HUM_decomp_top * s_config[['f_romi']]
  em_CO2_HUM_top <- substrate_HUM_decomp_top * s_config[['f_co2']]
  HUM_transport <- substrate_HUM_decomp_top  *(1-s_config[['f_romi']]-s_config[['f_co2']])
  HUM_top <- HUM_top_t - HUM_romified_top - em_CO2_HUM_top - HUM_transport

  list(
    HUM_top = HUM_top,
    HUM_top_decomposition = HUM_decomposition,
    substrate_HUM_decomp_top = substrate_HUM_decomp_top,
    HUM_romified_top = HUM_romified_top,
    em_CO2_HUM_top = em_CO2_HUM_top,
    HUM_tr = HUM_transport
  )
}


#' HUM_sub_calculations
#'
#' Calculate HUM decomposition and carbon fluxes in the subsoil layer.
#'
#' @param HUM_sub_t Numeric. Carbon content in the HUM subsoil pool
#'   (Mg C ha-1).
#' @param month Integer. Month index (1-12).
#' @param t_avg Numeric. Monthly mean air temperature (degrees C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters.
#'
#' @return A list with updated HUM subsoil pool values and associated fluxes.
#' @export
#'
#' @examples
#' \dontrun{
#' HUM_sub_calculations(
#'   HUM_sub_t = 20,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )
#' }
HUM_sub_calculations <- function(HUM_sub_t,
                                month,
                                t_avg,
                                amplitude,
                                s_config) {

  HUM_decomposition <- soil_pool_decomposition(
    soil_pool = HUM_sub_t,
    k = s_config[['k_hum']],
    soil_depth = 100,
    month = month,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
    )

  substrate_HUM_decomp_sub <- HUM_sub_t - (HUM_sub_t + HUM_decomposition)
  HUM_romified_sub <- substrate_HUM_decomp_sub * s_config[['f_romi']]
  em_CO2_HUM_sub <- substrate_HUM_decomp_sub * s_config[['f_co2']]
  HUM_sub <- HUM_sub_t - HUM_romified_sub - em_CO2_HUM_sub

  list(
    HUM_sub = HUM_sub,
    HUM_sub_decomposition = HUM_decomposition,
    substrate_HUM_decomp_sub = substrate_HUM_decomp_sub,
    HUM_romified_sub = HUM_romified_sub,
    em_CO2_HUM_sub = em_CO2_HUM_sub
  )
}

