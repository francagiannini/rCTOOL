

#' FOM_top_calculations
#'
#' @param FOM_top_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
FOM_top_calculations = function(FOM_top_t,
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  FOM_decomposition = soil_pool_decomposition(soil_pool=FOM_top_t, k=s_config[['k_fom']], soil_depth=25, month=month, t_avg=t_avg, t_range=t_range, s_config)
  substrate_FOM_decomp_top = FOM_top_t - (FOM_top_t + FOM_decomposition) 
  FOM_transport= substrate_FOM_decomp_top* s_config[['ftr']]
  FOM_humified_top  = (substrate_FOM_decomp_top - FOM_transport) * .hum_coef(s_config[['clay_top']])
  em_CO2_FOM_top = (substrate_FOM_decomp_top - FOM_transport) * (1-.hum_coef(s_config[['clay_top']]))
 
  FOM_top = FOM_top_t - FOM_humified_top - em_CO2_FOM_top - FOM_transport
  
  return(list(
    FOM_top = FOM_top,
    FOM_top_decomposition = FOM_decomposition,
    substrate_FOM_decomp_top = substrate_FOM_decomp_top,
    FOM_humified_top = FOM_humified_top,
    em_CO2_FOM_top = em_CO2_FOM_top,
    FOM_tr = FOM_transport
  ))
}

#' FOM_sub_calculations
#'
#' @param FOM_sub_t 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
FOM_sub_calculations = function(FOM_sub_t,
                                month,
                                t_avg = t_avg,
                                t_range = t_range,
                                s_config) {
  
  FOM_decomposition = soil_pool_decomposition(soil_pool=FOM_sub_t, k=s_config[['k_fom']], soil_depth=100, month=month, t_avg=t_avg, t_range=t_range, s_config)
  substrate_FOM_decomp_sub = FOM_sub_t - (FOM_sub_t + FOM_decomposition) 
  FOM_humified_sub  = substrate_FOM_decomp_sub * .hum_coef(s_config[['clay_top']])
  em_CO2_FOM_sub = substrate_FOM_decomp_sub * (1-.hum_coef(s_config[['clay_top']]))
  FOM_sub = FOM_sub_t - FOM_humified_sub - em_CO2_FOM_sub
  
  return(list(
    FOM_sub = FOM_sub,
    FOM_sub_decomposition = FOM_decomposition,
    substrate_FOM_decomp_sub = substrate_FOM_decomp_sub,
    FOM_humified_sub = FOM_humified_sub,
    em_CO2_FOM_sub = em_CO2_FOM_sub
  ))
}





