#' turnover
#'
#' @param timestep timestep of the ith month
#' @param time_config timeperiod configuration
#' @param cin_config C input configuration
#' @param m_config management configuration
#' @param t_config temperature configuration
#' @param s_config soil configuration
#' @param out output (ie, from initialized soil pools or simulated timestep-1 for timestep>1)
#' @return
#' @export
#'
#' @examples
turnover = function(timestep,
                    time_config,
                    cin_config,
                    m_config,
                    t_config,
                    s_config,
                    out) {
  
  mon = time_config$timeperiod[timestep,'mon']
  yr = time_config$timeperiod[timestep,'id']
  m_ctr = ifelse(cin_config$class=='csv', timestep, mon) # counter for management iteration 
  c_ctr = ifelse(cin_config$class=='csv', timestep, yr) #counter for C inputs iteration
  
  # FOM ----
  FOM_top = update_monthly_FOM_top(FOM_top_t1 = out$FOM_top, Cin_plant_top = cin_config$Cin_top[c_ctr] , Cin_manure = cin_config$Cin_man[c_ctr], timestep = m_ctr, m_config = m_config)
  FOM_top = FOM_top_calculations(FOM_top_t=FOM_top, month=mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config)
  
  FOM_sub = update_monthly_FOM_sub(FOM_sub_t1 = out$FOM_sub, FOM_transport = FOM_top$FOM_tr, C_in_plant_sub = cin_config$Cin_sub[c_ctr], timestep = m_ctr, m_config = m_config)
  FOM_sub = FOM_sub_calculations(FOM_sub_t=FOM_sub, month=mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config = s_config)
  
  # HUM ----
  HUM_top = update_monthly_HUM_top(HUM_top_t1 = out$HUM_top, C_in_man = cin_config$Cin_man[c_ctr], FOM_humified_top = FOM_top$FOM_humified_top, timestep = m_ctr, m_config = m_config)
  HUM_top = HUM_top_calculations(HUM_top_t = HUM_top, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config = s_config)
  
  HUM_sub = update_monthly_HUM_sub(HUM_sub_t1 =out$HUM_sub, HUM_transport = HUM_top$HUM_tr, FOM_humified_sub = FOM_sub$FOM_humified_sub)
  HUM_sub = HUM_sub_calculations(HUM_sub_t = HUM_sub, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config = s_config)
  
  # ROM ----
  ROM_top = update_monthly_ROM_top(ROM_top_t1 = out$ROM_top, HUM_romified_top = HUM_top$HUM_romified_top)
  ROM_top = ROM_top_calculations(ROM_top_t = ROM_top, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config = s_config)
  
  ROM_sub = update_monthly_ROM_sub(ROM_sub_t1 = out$ROM_sub, HUM_romified_sub = HUM_sub$HUM_romified_sub, ROM_transport = ROM_top$ROM_tr)
  ROM_sub = ROM_sub_calculations(ROM_sub_t = ROM_sub, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config = s_config)
  
  # CO2 emissions ----
  em_CO2_top = FOM_top$em_CO2_FOM_top + HUM_top$em_CO2_HUM_top + ROM_top$em_CO2_ROM_top
  em_CO2_sub = FOM_sub$em_CO2_FOM_sub + HUM_sub$em_CO2_HUM_sub + ROM_sub$em_CO2_ROM_sub
  em_CO2_total = em_CO2_sub + em_CO2_top
  
  # SOC stock ----
  C_topsoil = FOM_top$FOM_top + HUM_top$HUM_top + ROM_top$ROM_top
  C_subsoil = FOM_sub$FOM_sub + HUM_sub$HUM_sub + ROM_sub$ROM_sub
  SOC_stock = C_subsoil + C_topsoil
  
  return(as.data.frame(list(
    FOM_top,
    FOM_sub,
    HUM_top,
    HUM_sub,
    ROM_top,
    ROM_sub,
    C_topsoil = C_topsoil,
    C_subsoil = C_subsoil,
    SOC_stock = SOC_stock,
    C_transport = HUM_top$HUM_tr + ROM_top$ROM_tr,
    em_CO2_top = em_CO2_top,
    em_CO2_sub = em_CO2_sub,
    em_CO2_total = em_CO2_total
  )))
}
