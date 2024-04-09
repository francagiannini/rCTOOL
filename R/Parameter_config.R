#' define_timeperiod
#'
#' @param yr_start initial simulation year
#' @param yr_end end simulation year
#'
#' @description
#' creates a dataframe template with the months, yrs and annual timesteps
#'
#' @returns list with 2 indexes; index 1 is a dataframe teplate (cols month, yr and annual timestep) and index 2 is the number of months
#' @export
#'
#' @examples define_timeperiod(yr_start=2006, yr_end=2010)
define_timeperiod = function(yr_start,
                             yr_end) {
  timeperiod = expand.grid( mon=1:12,
                            yrs=yr_start:yr_end)
  timeperiod$id = timeperiod$yrs-(yr_start-1)

  return(list(
    timeperiod = timeperiod,
    steps = nrow(timeperiod))
  )
}



#' export_management_template
#'
#' @param yr_start initial simulation year
#' @param yr_end end simulation year
#' @param filepath filepath where management template is to be exported
#'
#' @description
#' if user wants to specify monthly (or annual) C inputs and allocation fraction, it can export a template later to be read by the model
#' note that all relevant columns are exported as 0, to be later populated by the user
#' user needs to deleted columns that are not being used
#' please ensure no double accounting in columns, for instance, by populating "plant_monthly_allocation" the user should not distinguish grass nor grain crops
#' Furthermore, if user provides monthly C inputs, there is no need to populate allocation columns
#' these conditions are not provided in the code and must be manually done with commmon sense
#'
#' @return
#' @export
#'
#' @examples export_management_template(2006, 2010, './Management_config.csv')
export_management_template = function(yr_start,
                                      yr_end,
                                      filepath) {

  df = define_timeperiod(yr_start, yr_end)$timeperiod
  cols_add = c('plant_monthly_allocation','grain_monthly_allocation','grass_monthly_allocation','manure_monthly_allocation','Cin_top','Cin_sub','Cin_man')
  df[, cols_add] = 0
  write.csv(df, filepath, row.names = F)
}

#' define_Cinputs
#'
#' @param management_filepath filepath (or file!) for the management template (see export_management_template())
#' @param df_Cin dataframe with the following cols: Cin_top (residues topsoil), Cin_sub (residues subsoil), Cin_man (Manure)
#' @param Cin_top C input from residues on topsoil
#' @param Cin_sub C input from residues on subsoil
#' @param Cin_man C input from manure
#' @param time_config config of timeperiod
#'
#' @description
#' explicits C inputs from plants and manure
#'
#' @return
#' @export
#'
#' @examples
define_Cinputs = function(management_filepath = NULL,
                          Cin_top=NULL,
                          Cin_sub=NULL,
                          Cin_man=NULL,
                          time_config=NULL) {


  if (missing(management_filepath)==F) {

    if (class(management_filepath)=='data.frame') {
      df = management_filepath
    }
    else {
      df = read.csv(management_filepath)
    }

    if (length(which(names(df) %in% c('Cin_top','Cin_sub','Cin_man')))!=3) { stop('Ensure Cin_top, Cin_sub and Cin_man are populated!') }
    return(list(
      Cin_top = df$Cin_top,
      Cin_sub = df$Cin_sub,
      Cin_man = dfCin_man
    ))
  }
  else {

    n = length(unique(time_config$timeperiod$yrs))
    if (length(Cin_top) != n | length(Cin_sub) != n | length(Cin_man) != n) { stop('Number of C inputs must be equal to the number of simulated years') }
    return(list(
      Cin_top = Cin_top,
      Cin_sub = Cin_sub,
      Cin_man = Cin_man
    ))
  }
}


#' management_config
#'
#' @param management_filepath filepath (or file!) for the management template (see export_management_template())
#' @param plant_monthly_allocation monthly distribution of plant C inputs; default c(0,0,0,.08,.12,.16,.64,0,0,0,0,0)
#' @param grain_monthly_allocation monthly distribution of grain C input; default c(0,0,1,0,0,0,0,0,0,0,0,0)
#' @param grass_monthly_allocation monthly distribution of grass C input; default c(0,0,1,0,0,0,0,0,0,0,0,0)
#' @param manure_monthly_allocation monthly distribution of manure C input; default c(0,0,1,0,0,0,0,0,0,0,0,0)
#' @param f_man_humification fraction of manure already humidified; default 0.192
#'
#' @description
#' prepares management configuration
#' Can be used in two ways: from the management template (csv file exported using export_management_template()) or using fixed monthly values
#' In the first approach the user can specify directly in the csv file the monthly allocation fractions - please note plant is used if there are no crop rotations or otherwise use grain and crop allocation fractions
#' In the second approach, the user can specify, using a vector of length 12 the different allocations
#'
#' @return
#' @export
#'
#' @examples management_config(f_man_humification=0.192, plant_monthly_allocation=c(0,0,0,.08,.12,.16,.64,0,0,0,0,0), manure_monthly_allocation = c(0,0,1,0,0,0,0,0,0,0,0,0))
#' @examples management_config(management_filepath='./management_template.csv, f_man_humification=0.192)
management_config = function(management_filepath = NULL,
                             plant_monthly_allocation=NULL,
                             grain_monthly_allocation=NULL,
                             grass_monthly_allocation=NULL,
                             manure_monthly_allocation=NULL,
                             f_man_humification=0.192) {

  if (missing(management_filepath)==F) {

    if (class(management_filepath)=='data.frame') {
      df = management_filepath
    }
    else {
      df = read.csv(management_filepath) # note: there is an unneeded overhead here (read.csv twice from management and Cin!)
    }

    # apply some conditions, these are not implement ad nauseam, needs common sense
    if (length(which(names(df) %in% c('plant_monthly_allocation','grain_monthly_allocation','grass_monthly_allocation')))!=3) { stop('Please either use plant allocation or grain/grass rotation!') }
    if (length(which(names(df) %in% 'manure_monthly_allocation'))!=3) { stop('Even if no manure is used, make sure this column exists all all is set to 0') }

    return(list(
      f_man_humification = df$f_man_humification,
      plant_monthly_allocation = df$plant_monthly_allocation,
      grain_monthly_allocation = df$grain_monthly_allocation,
      grass_monthly_allocation = df$grass_monthly_allocation,
      manure_monthly_allocation = df$manure_monthly_allocation
    ))
  }
  else {
    # if no management template is given, prepare vectorization
    # note this is set to fixed monthly values
    if (length(plant_monthly_allocation)!=12 | length(manure_monthly_allocation)!=12 | length(grain_monthly_allocation)!=12 | length(grass_monthly_allocation)!=12) {
      stop('Vector must be of length 12 (1 for each month).')
    }
    else {
      return(list(
        f_man_humification = f_man_humification,
        plant_monthly_allocation = plant_monthly_allocation,
        grain_monthly_allocation = grain_monthly_allocation,
        grass_monthly_allocation = grass_monthly_allocation,
        manure_monthly_allocation = manure_monthly_allocation
      ))
    }

  }
}

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
#' @param ini_Cin_top initial C inputs topsoil
#' @param ini_Cin_sub initial C inputs subsoil
#'
#' @description
#'  sets soil configuration parameters
#'
#' @return
#' @export
#'
#' @examples soil_config(Csoil_init=72, f_hum_top=0.5)
#' @examples soil_config()
#' @examples soil_config(Csoil_init=72, f_hum_top=0.5, clay_sub = 0.35, clay_top=0.25, Cproptop=0.6)
soil_config = function(Csoil_init = 70.4,
                       f_hum_top = 0.48,
                       f_rom_top = 0.49,
                       f_hum_sub = 0.312,
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
                       ftr = 0.0025) {


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
#'
#' @param cn soil CN
#' @param f_hum initial hum fraction
#' @param f_rom initial rom fraction
#' @param ini_Cin initial C inputs
#'
#' @description
#' A short description...
#'
#' @examples pool_cn(cn=12,HUM_frac = 0.33, C_0=75)
.pool_cn = function(cn,
                    f_hum,
                    f_rom,
                    ini_Cin,
                    soil_surf=c('top','sub')) {

  CNfraction = min(56.2 * cn ^ (-1.69), 1)


  hum = (ini_Cin * f_hum) * CNfraction
  fom = ini_Cin *(1-f_hum-f_rom) # Modified after Ozan observation
  rom = ini_Cin-hum-fom

  if (soil_surf=='top') {
    return(list(FOM_top=fom,
                HUM_top=hum,
                ROM_top=rom))
  }
  else {
    return(list(FOM_sub=fom,
                HUM_sub=hum,
                ROM_sub=rom))
  }
}


#' initialize_soil_pools
#'
#' @param cn soil carbon:nitrogen ratio
#' @param soil_config soil configuration file (list)
#'
#' @description
#' initializes top and bottom soil pools
#'
#' @return list with the initialized top and bottom soil pool
#' @export
#'
#' @examples initialize_soil_pools(cn=15, soil_config = s_config)
initialize_soil_pools = function(cn,
                                 soil_config) {

  ini_pool_top = .pool_cn(cn=cn,
                         f_hum = soil_config$f_hum_top,
                         f_rom = soil_config$f_rom_top,
                         ini_Cin = soil_config$ini_Cin_top,
                         'top')
  ini_pool_sub = .pool_cn(cn=cn,
                         f_hum = soil_config$f_hum_sub,
                         f_rom = soil_config$f_rom_sub,
                         ini_Cin = soil_config$ini_Cin_sub,
                         'sub')

  return(list(
    ini_pool_top,
    ini_pool_sub
  ))
}

