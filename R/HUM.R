#' HUM_top_calculations
#'
#' @param HUM_top_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
HUM_top_calculations = function(HUM_top_t,
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  HUM_decomposition = soil_pool_decomposition(soil_pool=HUM_top_t, k=s_config[['k_hum']], soil_depth=25, month=month, t_avg=t_avg, t_range=t_range, s_config)
  substrate_HUM_decomp_top = HUM_top_t - (HUM_top_t + HUM_decomposition) 
  HUM_romified_top  = substrate_HUM_decomp_top * s_config[['f_romi']]
  em_CO2_HUM_top = substrate_HUM_decomp_top * s_config[['f_co2']]
  HUM_transport = (HUM_top_t+HUM_decomposition)  *(1-s_config[['f_romi']]-s_config[['f_co2']])
  HUM_top = HUM_top_t - HUM_romified_top - em_CO2_HUM_top - HUM_transport
  
  return(list(
    HUM_top = HUM_top,
    HUM_top_decomposition = HUM_decomposition,
    substrate_HUM_decomp_top = substrate_HUM_decomp_top,
    HUM_romified_top = HUM_romified_top,
    em_CO2_HUM_top = em_CO2_HUM_top,
    HUM_tr = HUM_transport
  ))
}


#' HUM_sub_calculations
#'
#' @param HUM_sub_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
HUM_sub_calculations = function(HUM_sub_t,
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  HUM_decomposition = soil_pool_decomposition(soil_pool=HUM_sub_t, k=s_config[['k_hum']], soil_depth=100, month=month, t_avg=t_avg, t_range=t_range, s_config)
  substrate_HUM_decomp_sub = HUM_sub_t - (HUM_sub_t + HUM_decomposition) 
  HUM_romified_sub  = substrate_HUM_decomp_sub * s_config[['f_romi']]
  em_CO2_HUM_sub = substrate_HUM_decomp_sub * s_config[['f_co2']]
  HUM_sub = HUM_sub_t - HUM_romified_sub - em_CO2_HUM_sub
  
  return(list(
    HUM_sub = HUM_sub,
    HUM_sub_decomposition = HUM_decomposition,
    substrate_HUM_decomp_sub = substrate_HUM_decomp_sub,
    HUM_romified_sub = HUM_romified_sub,
    em_CO2_HUM_sub = em_CO2_HUM_sub
  ))
}

