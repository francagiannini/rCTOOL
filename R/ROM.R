#' ROM_top_calculations
#'
#' Calculate ROM decomposition and carbon fluxes in the topsoil layer.
#'
#' @param ROM_top_t Numeric. Carbon content in the ROM topsoil pool
#'   (Mg C ha-1).
#' @param month Integer. Month index (1-12).
#' @param t_avg Numeric. Monthly mean air temperature (degrees C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters.
#'
#' @return A list with updated ROM topsoil pool values and associated fluxes.
#' @export
#'
#' @examples
#' \dontrun{
#' ROM_top_calculations(
#'   ROM_top_t = 10,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )
#' }
ROM_top_calculations <- function(ROM_top_t,
                                 month,
                                 t_avg,
                                 amplitude,
                                 s_config) {

  ROM_decomposition <- soil_pool_decomposition(
    soil_pool = ROM_top_t,
    k = s_config[["k_rom"]],
    soil_depth = 25,
    month = month,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  substrate_ROM_decomp_top <- ROM_top_t - (ROM_top_t + ROM_decomposition)
  em_CO2_ROM_top <- substrate_ROM_decomp_top * s_config[["f_co2"]]
  ROM_transport <- substrate_ROM_decomp_top * s_config[["ftr"]]
  ROM_top <- ROM_top_t - em_CO2_ROM_top - ROM_transport

  list(
    ROM_top = ROM_top,
    ROM_top_decomposition = ROM_decomposition,
    substrate_ROM_decomp_top = substrate_ROM_decomp_top,
    em_CO2_ROM_top = em_CO2_ROM_top,
    ROM_tr = ROM_transport
  )
}

#' ROM_sub_calculations
#'
#' Calculate ROM decomposition and carbon fluxes in the subsoil layer.
#'
#' @param ROM_sub_t Numeric. Carbon content in the ROM subsoil pool
#'   (Mg C ha-1).
#' @param month Integer. Month index (1-12).
#' @param t_avg Numeric. Monthly mean air temperature (degrees C).
#' @param amplitude Numeric. Annual historical temperature amplitude
#'   used in the soil temperature function.
#' @param s_config List. Soil configuration parameters.
#'
#' @return A list with updated ROM subsoil pool values and associated fluxes.
#' @export
#'
#' @examples
#' \dontrun{
#' ROM_sub_calculations(
#'   ROM_sub_t = 10,
#'   month = 7,
#'   t_avg = 15,
#'   amplitude = 10,
#'   s_config = soil_config()
#' )
#' }
ROM_sub_calculations <- function(ROM_sub_t,
                                 month,
                                 t_avg,
                                 amplitude,
                                 s_config) {

  ROM_decomposition <- soil_pool_decomposition(
    soil_pool = ROM_sub_t,
    k = s_config[["k_rom"]],
    soil_depth = 100,
    month = month,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  substrate_ROM_decomp_sub <- ROM_sub_t - (ROM_sub_t + ROM_decomposition)
  em_CO2_ROM_sub <- substrate_ROM_decomp_sub * s_config[["f_co2"]]
  ROM_sub <- ROM_sub_t - em_CO2_ROM_sub

  list(
    ROM_sub = ROM_sub,
    ROM_sub_decomposition = ROM_decomposition,
    substrate_ROM_decomp_sub = substrate_ROM_decomp_sub,
    em_CO2_ROM_sub = em_CO2_ROM_sub
  )
}
