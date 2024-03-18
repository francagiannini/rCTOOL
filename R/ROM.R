#' ROM_top_calculations
#'
#' @param ROM_top_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
ROM_top_calculations = function(ROM_top_t,
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  ROM_decomposition = soil_pool_decomposition(soil_pool=ROM_top_t, k=s_config[['k_rom']], soil_depth=25, month=month, t_avg=t_avg, t_range=t_range, s_config)
  substrate_ROM_decomp_top =  ROM_top_t - (ROM_top_t + ROM_decomposition)
  em_CO2_ROM_top = substrate_ROM_decomp_top * s_config[['f_co2']]
  ROM_transport = substrate_ROM_decomp_top * s_config[['ftr']] 
  ROM_top = ROM_top_t - em_CO2_ROM_top - ROM_transport 
  
  return(list(
    ROM_top = ROM_top,
    ROM_top_decomposition = ROM_decomposition,
    substrate_ROM_decomp_top = substrate_ROM_decomp_top,
    em_CO2_ROM_top = em_CO2_ROM_top,
    ROM_tr = ROM_transport
  ))
}

#' ROM_sub_calculations
#'
#' @param ROM_sub_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
ROM_sub_calculations = function(ROM_sub_t, # here what I do not get is how we add to the previous ROM_sub what it comes from the transport of ROM_top
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  ROM_decomposition = soil_pool_decomposition(soil_pool=ROM_sub_t, k=s_config[['k_rom']], soil_depth=100, month=month, t_avg=t_avg, t_range=t_range, s_config = s_config)
  substrate_ROM_decomp_sub = ROM_sub_t - (ROM_sub_t + ROM_decomposition) # ROM_sub_t - ROM_decomposition
  em_CO2_ROM_sub = substrate_ROM_decomp_sub * s_config[['f_co2']] 
  ROM_sub = ROM_sub_t - em_CO2_ROM_sub
  
  return(list(
    ROM_sub = ROM_sub,
    ROM_sub_decomposition = ROM_decomposition,
    substrate_ROM_decomp_sub = substrate_ROM_decomp_sub,
    em_CO2_ROM_sub = em_CO2_ROM_sub
  ))
}
