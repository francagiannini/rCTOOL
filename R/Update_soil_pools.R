
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
                                  month,
                                  m_config) {
  
  
  
  return(
    FOM_top_t1 +
      Cin_plant_top * m_config[['plant_monthly_allocation']][month] +
      Cin_manure * (1-m_config[['f_man_humification']])*m_config[['manure_monthly_allocation']][month] 
  )
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
                                  month,
                                  m_config) {
  
  return(FOM_sub_t1 + FOM_transport + 
           C_in_plant_sub * m_config[['plant_monthly_allocation']][month])
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
                                  month,
                                  m_config) {
  
  return(HUM_top_t1 +
           FOM_humified_top + 
           C_in_man * m_config[['f_man_humification']] * m_config[['manure_monthly_allocation']][month])
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
  
  return(HUM_sub_t1 + HUM_transport + FOM_humified_sub)
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
  
  return(ROM_top_t1 + HUM_romified_top)
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
  
  return(ROM_sub_t1 + HUM_romified_sub + ROM_transport)
}


