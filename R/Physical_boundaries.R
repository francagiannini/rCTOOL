
#' define_physical_boundaries
#'
#' @param value parameter value
#' @param min_limit min limit (usually 0)
#' @param max_limit max limit
#' 
#' @description
#' establishes minimum and physical boundaries for parameters
#' 
#' @return
#' @export
#'
#' @examples define_physical_boundaries(0.3, 0, 1)
define_physical_boundaries = function(value, min_limit, max_limit) {
  
  if (value<min_limit) { stop('Please ensure the parameter is above the min limit.') }
  if (value>max_limit) { stop('Please ensure the parameter is below the max limit.') }
  value
}

#' check_balance
#'
#' @param ctool_output output from turnover model
#' @param cin_config carbon input config
#' @param s_config soil config
#' 
#' @description
#' calculates mass balance for the simulation
#' Includes initial c soil, sum of inputs, SOC stocks and CO2 emissions
#' needs to be 0 or really close to 0
#' used in run_ctool (ctool.R)
#' @return
#' @export
#'
#' @examples
check_balance = function(ctool_output,
                         cin_config,
                         s_config) {
  
  
  initial = s_config$Csoil_init
  inputs = sum(cin_config$Cin_top) + sum(cin_config$Cin_sub) + sum(cin_config$Cin_man)
  stocks = ctool_output$C_topsoil[nrow(ctool_output)] + ctool_output$C_subsoil[nrow(ctool_output)]
  emissions = sum(ctool_output$em_CO2_top) + sum(ctool_output$em_CO2_sub)
  
  balance = initial + inputs - stocks - emissions
  
  if (balance != 0) {
    if (abs(balance)<0.0001) {
      return(balance)
    }
    print('Check balance does not added up; please check this')
  }
  else {
    return(balance)
  }
}



