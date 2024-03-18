#' update_FOM_top
#'
#' @param FOM_top_t1 
#' @param Cin_plant 
#' @param Cin_manure 
#' @param month 
#' @param m_config management configuration list
#'
#' @return
#' @export
#'
#' @examples
update_monthly_FOM_top = function(FOM_top_t1,
                                  Cin_plant_top,
                                  Cin_manure,
                                  timestep,
                                  m_config) {
  FOM_top = FOM_top_t1 +
    Cin_plant_top * m_config[['plant_monthly_allocation']][timestep] +
    Cin_manure * (1-m_config[['f_man_humification']])*m_config[['manure_monthly_allocation']][timestep] 
  FOM_top = .soil_pool_physical_restriction(FOM_top)
  return(FOM_top)
}


#' updated_monthly_FOM_sub
#'
#' @param FOM_sub_t1 
#' @param FOM_transport 
#' @param C_in_plant_sub 
#' @param month 
#' @param m_config 
#'
#' @return
#' @export
#'
#' @examples
update_monthly_FOM_sub = function(FOM_sub_t1,
                                  FOM_transport,
                                  C_in_plant_sub,
                                  timestep,
                                  m_config) {
  FOM_sub = FOM_sub_t1 +
    C_in_plant_sub * m_config[['plant_monthly_allocation']][timestep]
  FOM_sub = .soil_pool_physical_restriction(FOM_sub)
  return(FOM_sub)
}

#' update_monthly_HUM_top
#'
#' @param HUM_top_t1 
#' @param C_in_man 
#' @param FOM_humified_top 
#' @param month 
#' @param m_config 
#'
#' @return
#' @export
#'
#' @examples
update_monthly_HUM_top = function(HUM_top_t1,
                                  C_in_man,
                                  FOM_humified_top,
                                  timestep,
                                  m_config) {
  HUM_top = HUM_top_t1 +
    FOM_humified_top + 
    C_in_man * m_config[['f_man_humification']] * m_config[['manure_monthly_allocation']][timestep]
  HUM_top = .soil_pool_physical_restriction(HUM_top)
  return(HUM_top)
}

#' update_monthly_HUM_sub
#'
#' @param HUM_sub_t1 
#' @param HUM_transport 
#' @param FOM_humified_sub 
#'
#' @return
#' @export
#'
#' @examples
update_monthly_HUM_sub = function(HUM_sub_t1,
                                  HUM_transport,
                                  FOM_humified_sub) {
  HUM_sub = HUM_sub_t1 + HUM_transport + FOM_humified_sub
  HUM_sub = .soil_pool_physical_restriction(HUM_sub)
  return(HUM_sub)
}

#' update_monthly_ROM_top
#'
#' @param ROM_top_t1 
#' @param HUM_romified_top 
#'
#' @return
#' @export
#'
#' @examples
update_monthly_ROM_top = function(ROM_top_t1,
                                  HUM_romified_top) {
  ROM_top = ROM_top_t1 + HUM_romified_top
  ROM_top = .soil_pool_physical_restriction(ROM_top)
  return(ROM_top)
}

#' update_monthly_ROM_sub
#'
#' @param ROM_sub_t1 
#' @param HUM_romified_sub 
#' @param ROM_transport 
#'
#' @return
#' @export
#'
#' @examples
update_monthly_ROM_sub = function(ROM_sub_t1,
                                  HUM_romified_sub,
                                  ROM_transport) {
  
  ROM_sub = ROM_sub_t1 + HUM_romified_sub + ROM_transport
  ROM_sub = .soil_pool_physical_restriction(ROM_sub)
  return(ROM_sub)
}


