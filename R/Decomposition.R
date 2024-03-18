
.temp_coef =  function(T_zt) {
  
    return(7.24 * exp(-3.432 + 0.168 * T_zt * (1 - 0.5 * T_zt / 36.9)))
}

.soil_temp = function(depth,
                      month,
                      T_ave ,
                      A_0 ,
                      th_diff) {

    # depth in meters#
    z = depth / 2 * 0.01
    
    #temporal position in daily bases setted as the last day of each month
    t = month
    
    #angular frequency
    # here the cycle is daily, for secondly cycles (365 * 24 * 3600)
    rho = pi * 2 / 365 #as.numeric(j["daysinmonth"]) #/30#
    
    # Damping depth here in m
    D = sqrt(2 * th_diff / rho)
    
    # Soil temperature at t days and z depth in m Montein and Unsworth
    return(T_ave + A_0 * exp(-z / D) * sin(rho * t - z / D))
    rm(list=c('z','t','rho','D'))
}



#' decay
#'Decay of carbon function'
#'The decay of carbon in each pool is described by first-order reaction kinetics
#'where we have an specific decay rate coefficient in each pool that affects the
#'actual C content in it (MgC/ha).The turnover is simulated in monthly time steps,
#'where th decay rate is modify by the temp_coef() function.
#' @param CO_t description
#' @param k description
#' @param tempCoefficient description
#' @return T
#' @export
#' @examples

.decay = function(CO_t, k, tempCoefficient ){
  return(CO_t * (-k * tempCoefficient))
}

#' soil_pool_decomposition
#'
#' @param soil_pool 
#' @param k 
#' @param soil_depth 
#' @param month 
#' @param t_avg 
#' @param t_range 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
soil_pool_decomposition = function(soil_pool = c('FOM_top','FOM_sub','HUM_top','HUM_sub','ROM_top','ROM_sub'),
                                    k,
                                    soil_depth = c(25,100),
                                    month,
                                    t_avg,
                                    t_range,
                                    s_config) {
  
  temp_coefficient = .temp_coef(T_zt=.soil_temp(depth=soil_depth, month = month, T_ave = t_avg, A_0 = t_range, th_diff = s_config[['phi']]))
  
  return(.decay(CO_t = soil_pool, k = k, tempCoefficient = temp_coefficient))
  rm(list='temp_coefficient')
}
