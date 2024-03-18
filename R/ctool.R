#' turnover-rCTOOL
#'
#' @param timestep 
#' @param timeperiod 
#' @param cin_config 
#' @param m_config 
#' @param t_config 
#' @param s_config 
#' @param out 
#'
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
  #print(paste0('Yr No. ',yr,' Month no ',mon))
  
  # FOM ----
  FOM_top = update_monthly_FOM_top(FOM_top_t1 = out$FOM_top, Cin_plant_top = cin_config$Cin_top[yr] , Cin_manure = cin_config$Cin_man[yr], month = mon, m_config = m_config)
  FOM_top = FOM_top_calculations(FOM_top_t=FOM_top, month=mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[timestep], s_config)
  
  FOM_sub = update_monthly_FOM_sub(FOM_sub_t1 = out$FOM_sub, FOM_transport = FOM_top$FOM_tr, C_in_plant_sub = cin_config$Cin_sub[yr], month = mon, m_config = m_config)
  FOM_sub = FOM_sub_calculations(FOM_sub_t=FOM_sub, month=mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[mon], s_config = s_config)
  
  # HUM ----
  HUM_top = update_monthly_HUM_top(HUM_top_t1 = out$HUM_top, C_in_man = cin_config$Cin_man[yr], FOM_humified_top = FOM_top$FOM_humified_top, month = mon, m_config = m_config)
  HUM_top = HUM_top_calculations(HUM_top_t = HUM_top, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[mon], s_config = s_config)
  
  HUM_sub = update_monthly_HUM_sub(HUM_sub_t1 =out$HUM_sub, HUM_transport = HUM_top$HUM_tr, FOM_humified_sub = FOM_sub$FOM_humified_sub)
  HUM_sub = HUM_sub_calculations(HUM_sub_t = HUM_sub, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[mon], s_config = s_config)
  
  # ROM ----
  ROM_top = update_monthly_ROM_top(ROM_top_t1 = out$ROM_top, HUM_romified_top = HUM_top$HUM_romified_top)
  ROM_top = ROM_top_calculations(ROM_top_t = ROM_top, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[mon], s_config = s_config)
  
  ROM_sub = update_monthly_ROM_sub(ROM_sub_t1 = out$ROM_sub, HUM_romified_sub = HUM_sub$HUM_romified_sub, ROM_transport = ROM_top$ROM_tr)
  ROM_sub = ROM_sub_calculations(ROM_sub_t = ROM_sub, month = mon, t_avg = t_config$Tavg[timestep], t_range=t_config$Trange_col[mon], s_config = s_config)
  
  return(as.data.frame(list(
    FOM_top,
    FOM_sub,
    HUM_top,
    HUM_sub,
    ROM_top,
    ROM_sub,
    C_topsoil = FOM_top$FOM_top + HUM_top$HUM_top + ROM_top$ROM_top,
    C_subsoil = FOM_sub$FOM_sub + HUM_sub$HUM_sub + ROM_sub$ROM_sub,
    SOC_stock = FOM_top$FOM_top + HUM_top$HUM_top + ROM_top$ROM_top + FOM_sub$FOM_sub + HUM_sub$HUM_sub + ROM_sub$ROM_sub,
    C_transport = HUM_top$HUM_tr + ROM_top$ROM_tr + FOM_top$FOM_tr,
    em_CO2_top = FOM_top$em_CO2_FOM_top + HUM_top$em_CO2_HUM_top + ROM_top$em_CO2_ROM_top,
    em_CO2_sub = FOM_sub$em_CO2_FOM_sub + HUM_sub$em_CO2_HUM_sub + ROM_sub$em_CO2_ROM_sub,
    em_CO2_total = FOM_top$em_CO2_FOM_top + HUM_top$em_CO2_HUM_top + ROM_top$em_CO2_ROM_top + FOM_sub$em_CO2_FOM_sub + HUM_sub$em_CO2_HUM_sub + ROM_sub$em_CO2_ROM_sub
  )))
}


#' run_ctool
#'
#' @param time_config 
#' @param cin_config 
#' @param m_config 
#' @param t_config 
#' @param s_config 
#' @param soil_pools 
#'
#' @return
#' @export
#'
#' @examples
run_ctool = function(time_config,
                     cin_config,
                     m_config,
                     t_config,
                     s_config,
                     soil_pools) {
  
  simul=1:time_config$steps
  out_init = as.data.frame(soil_pools)
  
  # test simulation loop code
  st = list(length=time_config$steps) 
  for (i in simul) {
    if (i==1) {  st[[i]] = turnover(timestep = i, time_config = time_config, cin_config = cin_config, m_config = m_config, t_config = t_config, s_config = s_config, out = out_init) }
    else { 
      st[[i]] = turnover(timestep = i, time_config = time_config, cin_config = cin_config, m_config = m_config, t_config = t_config, s_config = s_config, out = st[[i-1]])
    }
  }
  # lapply is better here but out is not stored properly
#  ctool = lapply(simul, function(tstp) {
 #   out = turnover(timestep = tstp, time_config = time_config, cin_config = cin_config, m_config = m_config, t_config = t_config, s_config = s_config, out = out)
  #  return(out)
  #})
  ctool = data.table::rbindlist(st)
  return(cbind(time_config$timeperiod[,c('mon','yrs')], ctool))
}
