#' aggregate_inputs
#'
#' @param cin_config 
#' @param s_config 
#'
#' @return
#' @export
#'
#' @examples
aggregate_inputs = function(cin_config,
                            s_config) {
  
  c_ini = s_config$Csoil_init
  C_inputs = cin_config$Cin_top + cin_config$Cin_sub + cin_config$Cin_man
  c_in_totals = c_ini + C_inputs
  
  return(list(
    c_ini = c_ini,
    C_inputs = C_inputs,
    C_in_totals = c_in_totals
  ))
}

#' aggregate_outputs
#'
#' @param CO2_em 
#' @param SOC_stock 
#'
#' @return
#' @export
#'
#' @examples
aggregate_outputs = function(CO2_em,
                             SOC_stock) {
  
  return(list(
    c_out_totals = SOC_stock + CO2_em
  ))
}


#' check_output
#'
#' @param cin_config 
#' @param s_config 
#' @param CO2_em 
#' @param SOC_stock 
#'
#' @return
#' @export
#'
#' @examples
check_output = function(cin_config,
                        s_config,
                        CO2_em,
                        SOC_stock) {
  
  c_in_totals = aggregate_inputs(cin_config, s_config)$C_in_totals
  c_out_totals = aggregate_outputs(CO2_em, SOC_stock)$c_out_totals
  balance = c_in_totals - c_out_totals
  
  if (sum(balance)!=0) { stop('Balance must be 0; needs debugging')}
  return(balance)
}
