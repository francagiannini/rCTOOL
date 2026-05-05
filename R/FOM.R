#' FOM_top_calculations
#'
#' Calculate FOM decomposition and carbon fluxes in the topsoil layer.
#'
#' @param FOM_top_t Numeric. Carbon content in FOM top pool (Mg C ha-1).
#' @param month Integer. Month index (1–12).
#' @param t_avg Numeric. Monthly mean air temperature (°C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters.
#'
#' @return A list with updated pool values and fluxes for FOM topsoil layer.
#' @export
#'
#' @examples
#' FOM_top_calculations(
#'   FOM_top_t = 10,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )
#'

FOM_top_calculations <- function(FOM_top_t,
                                month,
                                t_avg = t_avg,
                                amplitude = amplitude,
                                s_config) {

  FOM_decomposition <- soil_pool_decomposition(
    soil_pool = FOM_top_t,
    k = s_config[['k_fom']],
    soil_depth = 25,
    month = month,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  substrate_FOM_decomp_top <- FOM_top_t - (FOM_top_t + FOM_decomposition)
  FOM_transport <- substrate_FOM_decomp_top* s_config[['ftr']]
  FOM_humified_top  <- (substrate_FOM_decomp_top - FOM_transport) * .hum_coef(s_config[['clay_top']])
  em_CO2_FOM_top <- (substrate_FOM_decomp_top - FOM_transport) * (1-.hum_coef(s_config[['clay_top']]))

  FOM_top <- FOM_top_t - FOM_humified_top - em_CO2_FOM_top - FOM_transport

  list(
    FOM_top = FOM_top,
    FOM_top_decomposition = FOM_decomposition,
    substrate_FOM_decomp_top = substrate_FOM_decomp_top,
    FOM_humified_top = FOM_humified_top,
    em_CO2_FOM_top = em_CO2_FOM_top,
    FOM_tr = FOM_transport
  )
}

#' FOM_sub_calculations
#'
#' Calculate FOM decomposition and carbon fluxes in the subsoil layer.
#'
#' @param FOM_sub_t Numeric. Carbon content in FOM subsoil pool (Mg C ha-1).
#' @param month Integer. Month index (1–12).
#' @param t_avg Numeric. Monthly mean air temperature (°C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters
#'
#' @return A list with updated pool values and fluxes for FOM subsoil layer.
#' @export
#'
#' @examples
#' FOM_sub_calculations(
#'   FOM_sub_t = 10,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )

FOM_sub_calculations <- function(FOM_sub_t,
                                month,
                                t_avg,
                                amplitude,
                                s_config) {

  FOM_decomposition <- soil_pool_decomposition(
    soil_pool = FOM_sub_t,
    k = s_config[['k_fom']],
    soil_depth = 100,
    month = month,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  substrate_FOM_decomp_sub <- FOM_sub_t - (FOM_sub_t + FOM_decomposition)
  FOM_humified_sub  <- substrate_FOM_decomp_sub *
    .hum_coef(s_config[['clay_sub']])
  em_CO2_FOM_sub <- substrate_FOM_decomp_sub *
    (1-.hum_coef(s_config[['clay_sub']]))
  FOM_sub <- FOM_sub_t - FOM_humified_sub - em_CO2_FOM_sub

 list(
    FOM_sub = FOM_sub,
    FOM_sub_decomposition = FOM_decomposition,
    substrate_FOM_decomp_sub = substrate_FOM_decomp_sub,
    FOM_humified_sub = FOM_humified_sub,
    em_CO2_FOM_sub = em_CO2_FOM_sub
  )
}





