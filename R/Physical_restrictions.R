
#' .soil_pool_physical_restriction
#'
#' @param soil_pool 
#'
#' @return
#'
#' @examples
.soil_pool_physical_restriction = function(soil_pool) {
  
  soil_pool = ifelse(soil_pool<0, 0, soil_pool)
  return(soil_pool)
}


#' check_monthly_allocation
#' check whether user input (from vector; default for all timeperiod) monthly allocation fractions add up to 1 
#' @param month_alloc_manag 
#'
#' @return
#'
#' @examples
.check_monthly_allocation_vector = function(month_alloc_manag) {
  
  if (sum(month_alloc_manag)!=1) { stop(paste0('Annual sum of monthly fractions must be 1; currently, it is ', sum(month_alloc_manag))) }
  return(month_alloc_manag)
}


#' .check_monthly_allocation_df
#' check whether user input (from csv) monthly allocation fractions add up to 1 per year
#' @param manag_df 
#'
#' @return
#' @export
#'
#' @examples
.check_monthly_allocation_df = function(manag_df) {
  
  man_check = aggregate(manure_monthly_allocation~yrs, FUN=sum, data=manag_df)
  id_man_check = which(man_check$manure_monthly_allocation!=1)
  
  plant_check = aggregate(plant_monthly_allocation~yrs, FUN=sum, data=manag_df)
  id_plant_check = which(plant_check$plant_monthly_allocation!=1)
  
  if (length(id_man_check)!=0 | length(id_plant_check)!=0) {
    if (length(id_man_check)!=0 & length(id_plant_check)!=0) {stop('Manure allocation monthly fraction for the Year(s) No. ', id_man_check, ' and plant fractions for the Year(s) No. ', id_plant_check, ' are wrong.') }
    if (length(id_man_check)!=0) {stop('Manure allocation monthly fraction for the Year(s) No. ', id_man_check, ' are wrong.') }
    if (length(id_plant_check)!=0) {stop('Plant allocation monthly fraction for the Year(s) No. ', id_plant_check, ' are wrong.') }
  }
  return(manag_df)
}


.decay_physical_boundary = function(decomposition) {
  
  if (decomposition>0) { stop('Decomposition cannot be positive; check decay parametrization of FOM, ROM, HUM') }
  return(decomposition)
}
