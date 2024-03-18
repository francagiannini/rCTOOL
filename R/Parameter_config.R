# time period configuration ----

#' define_timeperiod
#'
#' @param yr_start initial simulation year
#' @param yr_end end simulation year
#' @description creates a 
#' @return
#' @export
#'
#' @examples
define_timeperiod = function(yr_start=2006,
                             yr_end=2010) {
  timeperiod = expand.grid( mon=1:12,
                            yrs=yr_start:yr_end)
  timeperiod$id = timeperiod$yrs-(yr_start-1)
  
  return(list(
    timeperiod = timeperiod,
    steps = nrow(timeperiod)))
}


#' write_Cinput_management
#' Function used to write the management config (incl months and years) for manure and plant C inputs for user to populate either by month or year
#' @param yr_start 
#' @param yr_end 
#' @param filepath 
#'
#' @return
#' @export
#'
#' @examples
write_Cinput_management = function(yr_start=2006,
                                   yr_end=2010,
                                   filepath) {
  
  config_df = define_timeperiod(yr_start, yr_end)$timeperiod
  config_df$Cin_man = NA
  config_df$manure_monthly_allocation = NA
  config_df$Cin_plant_top = NA
  config_df$Cin_plant_sub = NA
  config_df$plant_monthly_allocation = NA
  write.csv(config_df, filepath, row.names=F)
  rm(list='config_df')
}



# C inputs configuration ----

#' .read_Cinputs
#'
#' @param df_Cin dataframe with the following cols: Cin_top (residues topsoil), Cin_sub (residues subsoil), Cin_man (Manure)
#' @param n number of simulated years
#' @description
#' helper function to read a dataframe and return Cin_top, Cin_sub, Cin_man
#' 
#' @return
#' @export
#'
#' @examples
.read_Cinputs = function(cin_filepath,
                         n) {
  
  df_Cin = read.csv(cin_filepath)
  
  if (nrow(df_Cin) != n) { stop('Number of annual C inputs must be equal to the number of simulated years.') }
  return(list(
    Cin_top = df_Cin$Cin_plant_top,
    Cin_sub = df_Cin$Cin_plant_sub,
    Cin_man = df_Cin$Cin_man,
    class = 'csv'
  ))
}

#' define_Cinputs
#' User defined C inputs
#' if directly read from a csv file, can be monthly and/or annual (length equivalent to simulated months)
#' if directly input through a vector, default is for annual C inputs
#' @param cin_filepath filepath of management csv expored with write_Cinput_management
#' @param Cin_top C input from residues on topsoil
#' @param Cin_sub C input from residues on subsoil
#' @param Cin_man C input from manure
#' @param time_config config of timeperiod
#' @description
#' explicits C inputs from plants and manure
#' 
#' @return
#' @export
#'
#' @examples
#' TODO: create different OOP classes for C inputs read from a csv AND directly inputed through a vector
define_Cinputs = function(cin_filepath = NULL,
                          Cin_top=NULL,
                          Cin_sub=NULL,
                          Cin_man=NULL,
                          time_config) {

  n = time_config$steps
  if (missing(cin_filepath)==T) {
    if (length(Cin_top) != n | length(Cin_sub) != n | length(Cin_man) != n) { stop('Number of C inputs must be equal to the number of simulated years') }
    
    return(list(
      Cin_top = Cin_top,
      Cin_sub = Cin_sub,
      Cin_man = Cin_man,
      class='vector'
    ))
  }
  else {
    return(.read_Cinputs(cin_filepath, n))
  }
}

# management configuration ----


#' .read_management
#'
#' @param df_Cin dataframe with the following cols: Cin_top (residues topsoil), Cin_sub (residues subsoil), Cin_man (Manure)
#' @param n number of simulated years
#' @description
#' helper function to read a dataframe and return Cin_top, Cin_sub, Cin_man
#' 
#' @return
#' @export
#'
#' @examples
.read_management = function(manag_filepath,
                            n,
                            f_man_humification) {
  
  df_management = read.csv(manag_filepath)
  
  if (nrow(df_management) != n) {
    stop('Number of monthly allocation  must be equal to the number of simulated years.')
  }
  df_management = .check_monthly_allocation_df(df_management)
  
  return(list(
    f_man_humification = f_man_humification,
    manure_monthly_allocation = df_management$manure_monthly_allocation,
    plant_monthly_allocation = df_management$plant_monthly_allocation,
    class = 'csv'
  ))
}


#' management_config
#' @param manag_filepath description
#' @param f_man_humification fraction of manure already humidified
#' @param plant_monthly_allocation monthly distribution of plant C inputs e.g., c(0,0,0,.08,.12,.16,.64,0,0,0,0,0)
#' @param manure_monthly_allocation monthly distribution of manure C input e.g., c(0,0,1,0,0,0,0,0,0,0,0,0)
#' @param time_config description
#' @return
#' @export
#'
#' @examples
management_config = function(manag_filepath=NULL,
                             f_man_humification=0.192,
                             plant_monthly_allocation = NULL,
                             manure_monthly_allocation = NULL,
                             time_config = NULL) {
  
  if (missing(manag_filepath)==T) {
    if (missing(time_config)==T) { stop('Needs to specify time_config!') }
    if (missing(plant_monthly_allocation)==T | missing(manure_monthly_allocation)==T) { stop('Needs to specify monthly allocation of plants and manure') }
  
    n = time_config$steps
    if (length(plant_monthly_allocation)!=12 | length(manure_monthly_allocation)!=12) { stop('Vector must be of length 12 (1 for each month).') }
    
    plant_monthly_allocation = .check_monthly_allocation(plant_monthly_allocation)
    manure_monthly_allocation = .check_monthly_allocation(manure_monthly_allocation)
    
    return(list(
      f_man_humification = f_man_humification,
      plant_monthly_allocation = plant_monthly_allocation,
      manure_monthly_allocation = manure_monthly_allocation,
      class='vector'
    ))
  }
  else {
    if (missing(time_config)==T) { stop('Needs to specify time_config!') }
    n = time_config$steps
    
    return(.read_management(manag_filepath = manag_filepath, n = n, f_man_humification = f_man_humification))
  }
}

# Soil configuration ----

#' soil_config
#'
#' @param Csoil_init initial C stock at depth 1m (t/ha)
#' @param f_hum_top initial hum fraction top layer
#' @param f_rom_top initial rom fraction top layer
#' @param f_hum_sub initial hum fraction bottom layer
#' @param f_rom_sub initial rom fraction bottom layer
#' @param Cproptop Proportion of the total C allocated in topsoil
#' @param clay_top clay fraction top soil
#' @param clay_sub clay fraction subsoil
#' @param phi Diffusion index 
#' @param f_co2 respiration fraction
#' @param f_romi romification fraction
#' @param k_fom fom decomposition rate
#' @param k_hum hum decomposition rate
#' @param k_rom rom decomposition rate
#' @param ftr transport rate
#' @param cn soil Carbon:Nitrogen ratio
#' @param ini_Cin_top initial C inputs topsoil 
#' @param ini_Cin_sub initial C inputs subsoil 
#' @description soil configuration params
#' @return 
#' @export
#'
#' @examples
soil_config = function(Csoil_init = 100,
                       f_hum_top = 0.4803,
                       f_rom_top = 0.4881,
                       f_hum_sub = 0.3123,
                       f_rom_sub = 0.6847,
                       Cproptop = 0.47,
                       clay_top = 0.1,
                       clay_sub = 0.15,
                       phi = 0.035,
                       f_co2 = 0.628,
                       f_romi = 0.012,
                       k_fom  = 0.12,
                       k_hum = 0.0028, 
                       k_rom = 3.85e-5,
                       ftr = 0,
                       cn = 10) {
  
  return(list(
    Csoil_init = Csoil_init,
    f_hum_top = f_hum_top,
    f_rom_top = f_rom_top,
    f_hum_sub = f_hum_sub,
    f_rom_sub = f_rom_sub,
    Cproptop = Cproptop,
    clay_top = clay_top,
    clay_sub = clay_sub,
    phi = phi,
    f_co2 = f_co2,
    f_romi = f_romi,
    k_fom = k_fom,
    k_hum = k_hum,
    k_rom = k_rom,
    ftr = ftr,
    cn = cn,
    ini_Cin_top = Csoil_init * Cproptop,
    ini_Cin_sub = Csoil_init * (1 - Cproptop)
  ))
}



#' Initial pool distribution parametrization
#'
#' This function helps to modify the parametrization of the initial pool distribution
#' according thesoil  C/N ratio.
#' When the C/N ratio is above the threshold of 10.8, the initial content of C in ROM is adjusted upwards, so that the relative turnover
#'rate is adjusted to the level determined by the function. The use of this procedure has a significant
#'influence for national simulations, as there is a significant proportion of coarse sandy soils in
#'Denmark with a high C/N ratio. If such a function is not used, the simulation of Danish sandy soils
#'will exhibit clear declines in SOC, in contrast to the general build-up of SOC on these soils reported
#'by Heidmann et al. (2001).
#' @param cn soil CN
#' @param f_hum_top initial hum fraction top layer
#' @param f_rom_top initial rom fraction top layer
#' @param ini_Cin_top initial C inputs topsoil 
#' @export
#' @examples pool_cn(cn=12,HUM_frac = 0.33, C_0=75)
.pool_cn = function(cn,
                    f_hum_top,
                    f_rom_top,
                    ini_Cin_top,
                    soil_surf=c('top','sub')) {
  
  CNfraction = min(56.2 * cn ^ (-1.69), 1)
  
  #fom = 1-f_hum_top-f_rom_top
  fom = 0
  hum = ini_Cin_top * f_hum_top * CNfraction
  rom = ini_Cin_top -hum-fom
  
  if (soil_surf=='top') { return(list(FOM_top=fom,HUM_top=hum,ROM_top=rom)) }
  else { return(list(FOM_sub=fom,HUM_sub=hum,ROM_sub=rom)) } 
}


#' initialize_soil_pools
#'
#' @param soil_config soil configuration file (list)
#' @description initializes top and bottom soil pools
#' @return list with the initialized top and bottom soil pool
#' @export
#'
#' @examples
initialize_soil_pools = function(soil_config) {
  
  ini_pool_top = .pool_cn(cn=soil_config$cn,
                         f_hum_top = soil_config$f_hum_top,
                         f_rom_top = soil_config$f_rom_top,
                         ini_Cin_top = soil_config$ini_Cin_top,
                         'top')
  ini_pool_sub = .pool_cn(cn=soil_config$cn,
                         f_hum_top = soil_config$f_hum_sub,
                         f_rom_top = soil_config$f_rom_sub,
                         ini_Cin_top = soil_config$ini_Cin_sub,
                         'sub')
  
  return(list(
    ini_pool_top,
    ini_pool_sub
  ))
}

