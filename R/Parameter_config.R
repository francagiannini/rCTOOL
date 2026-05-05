#' define_timeperiod
#'
#' Create the monthly simulation time structure.
#'
#' @param yr_start Initial simulation year.
#' @param yr_end Final nd simulation year.
#'
#'
#' @returns A list with two elements: `timeperiod`, a data.frame containing
#' monthly timesteps, years and annual timestep identifiers; and `steps`,
#' the total number of simulated months.
#' @export
#'
#' @examples
#'  define_timeperiod(yr_start=2006, yr_end=2010)
define_timeperiod  <- function(yr_start,
                             yr_end) {
  timeperiod <- expand.grid( mon=1:12,
                            yrs=yr_start:yr_end)
  timeperiod$id = timeperiod$yrs-(yr_start-1)

  list(
    timeperiod = timeperiod,
    steps = nrow(timeperiod)
  )
}



#' export_management_template
#'
#' Exports a template that can be used to provide management inputs for the
#' model. The exported file includes monthly allocation variables and carbon
#' input columns initialized with zeros, so they can be filled by the user
#' before being read by the model.
#'
#' Users should keep only the columns relevant to their workflow and avoid
#' double accounting among allocation variables. For example, when
#' `plant_monthly_allocation` is used, grain and grass allocation columns
#' should not be used simultaneously.
#'
#' If monthly carbon inputs are provided directly, additional allocation
#' columns may not be needed. These consistency checks are not enforced
#' automatically and must be handled by the user when preparing the input file.
#'
#' @param yr_start Initial simulation year.
#' @param yr_end Final simulation year.
#' @param filepath Filepath where management template will be exported.
#'
#' @return The exported template as a data.frame.
#' @export
#'
#' @examples
#' path <- tempfile(fileext = ".csv")
#' export_management_template(2006, 2010, path)
export_management_template <- function(yr_start,
                                      yr_end,
                                      filepath) {

  df <- define_timeperiod(yr_start, yr_end)$timeperiod
  cols_add <- c(
    'plant_monthly_allocation',
    'grain_monthly_allocation',
    'grass_monthly_allocation',
    'manure_monthly_allocation',
    'Cin_top',
    'Cin_sub',
    'Cin_man')
  df[, cols_add] <- 0
  write.csv(df, filepath, row.names = FALSE)
}

#' define_Cinputs
#'
#' Prepare annual carbon input (from plants and/or manure) configuration.
#'
#' @param management_filepath Either a filepath to a management template or
#'   a data.frame containing `Cin_top`, `Cin_sub` and `Cin_man`.
#' @param Cin_top Annual carbon input from plant residues in the topsoil.
#' @param Cin_sub Annual carbon input from plant residues in the subsoil.
#' @param Cin_man Annual carbon input from manure.
#' @param time_config Time configuration object returned by `define_timeperiod()`
#'
#' @return A list containing `Cin_top`, `Cin_sub` and `Cin_man`.
#' @export
#'
#' @examples
#' time_config <- define_timeperiod(yr_start = 2006, yr_end = 2008)
#' define_Cinputs(
#'   Cin_top = c(2, 2, 2),
#'   Cin_sub = c(0.5, 0.5, 0.5),
#'   Cin_man = c(1, 1, 1),
#'   time_config = time_config
#' )

define_Cinputs <- function(management_filepath = NULL,
                          Cin_top=NULL,
                          Cin_sub=NULL,
                          Cin_man=NULL,
                          time_config=NULL) {


  if (!missing(management_filepath) && !is.null(management_filepath)) {

    if (is.data.frame(management_filepath)) {
      df <- management_filepath
    }
    else {
      df <- read.csv(management_filepath)
    }

    if (!all(c("Cin_top", "Cin_sub", "Cin_man") %in% names(df))) { stop('Ensure Cin_top, Cin_sub and Cin_man are provided.')
      }
    list(
      Cin_top = df$Cin_top,
      Cin_sub = df$Cin_sub,
      Cin_man = df$Cin_man
    )
  } else {

    n <- length(unique(time_config$timeperiod$yrs))

    if (length(Cin_top) != n || length(Cin_sub) != n || length(Cin_man) != n) {
      stop('Number of annual carbon inputs must be equal to the number of simulated years.') }

    list(
      Cin_top = Cin_top,
      Cin_sub = Cin_sub,
      Cin_man = Cin_man
    )
  }
}


#' management_config
#'
#' Prepares management configuration for monthly carbon input allocation.
#'
#' This function can be used in two ways:
#' 1. from a management template file or data.frame, such as one exported with
#'    `export_management_template()`
#' 2. by directly providing fixed monthly allocation vectors of length 12.
#'
#' In the first approach, the user can specify monthly allocation fractions
#' directly in the input file. When no crop rotation is considered,
#' `plant_monthly_allocation` should be used. When crop rotation is considered,
#' grain and grass allocation fractions can be specified separately.
#'
#' In the second approach, the user can directly provide monthly allocation
#' vectors of length 12.
#'
#' @param management_filepath Either a filepath to a management template or
#'   a data.frame containing management allocation variables.
#' @param plant_monthly_allocation Monthly distribution of plant carbon inputs.
#' @param grain_monthly_allocation Monthly distribution of grain carbon inputs.
#' @param grass_monthly_allocation Monthly distribution of grass carbon inputs.
#' @param manure_monthly_allocation Monthly distribution of manure carbon inputs.
#' @param f_man_humification Fraction of manure already humidified.
#'
#' @return A list containing management allocation settings.
#' @export
#'
#' @examples management_config(
#' f_man_humification=0.192,
#' plant_monthly_allocation = c(0,0,0,.08,.12,.16,.64,0,0,0,0,0),
#'  manure_monthly_allocation = c(0,0,1,0,0,0,0,0,0,0,0,0)
#'  )

management_config = function(management_filepath = NULL,
                             plant_monthly_allocation=NULL,
                             grain_monthly_allocation=NULL,
                             grass_monthly_allocation=NULL,
                             manure_monthly_allocation=NULL,
                             f_man_humification=0.12) {

  if (!missing(management_filepath) && !is.null(management_filepath)) {

    if (is.data.frame(management_filepath)) {
      df <- management_filepath
    } else {
      df <- read.csv(management_filepath)
    }
   list(
      f_man_humification = f_man_humification,
      plant_monthly_allocation = df$plant_monthly_allocation,
      grain_monthly_allocation = df$grain_monthly_allocation,
      grass_monthly_allocation = df$grass_monthly_allocation,
      manure_monthly_allocation = df$manure_monthly_allocation
    )
  } else {

    if ( (missing(plant_monthly_allocation)==F & length(plant_monthly_allocation)!=12) |
         (missing(manure_monthly_allocation)==F & length(manure_monthly_allocation)!=12) |
         (missing(grain_monthly_allocation)==F & length(grain_monthly_allocation)!=12) |
         (missing(grass_monthly_allocation)==F & length(grass_monthly_allocation)!=12) ){
      stop('Allocation vectors must have length 12 (one value for each month).')
    }
    list(
        f_man_humification = f_man_humification,
        plant_monthly_allocation = plant_monthly_allocation,
        grain_monthly_allocation = grain_monthly_allocation,
        grass_monthly_allocation = grass_monthly_allocation,
        manure_monthly_allocation = manure_monthly_allocation
      )
  }
}

#' soil_config
#'
#' Prepare soil configuration parameters.
#'
#' Exports a template that can be used to provide management inputs for the model.
#' The exported file includes monthly allocation variables and carbon input
#' columns initialized with zeros, so they can be filled by the user before
#' being read by the model.
#'
#' Users should keep only the columns relevant to their workflow and avoid
#' double accounting among allocation variables. For example, when
#' `plant_monthly_allocation` is used, grain and grass allocation columns
#' should not be used simultaneously.
#'
#' If monthly carbon inputs are provided directly, additional allocation
#' columns may not be needed. These consistency checks are not enforced
#' automatically and must be handled by the user when preparing the input file.
#'
#' @param Csoil_init Initial carbon stock at depth 1m (Mg C ha-1).
#' @param f_hum_top Initial HUM fraction in the topsoil layer.
#' @param f_rom_top Initial ROM fraction in the topsoil layer.
#' @param f_hum_sub Initial HUM fraction in the bottom layer.
#' @param f_rom_sub initial ROM fraction in the bottom layer.
#' @param Cproptop Proportion of the total carbon allocated to the topsoil.
#' @param clay_top Clay fraction in the top soil.
#' @param clay_sub Clay fraction in the subsoil.
#' @param phi Legacy diffusion parameter used in the original rCTOOL
#' temperature formulation.
#' @param f_co2 Respiration fraction.
#' @param f_romi Romification fraction.
#' @param k_fom FOM decomposition rate constant.
#' @param k_hum HUM decomposition rate constant.
#' @param k_rom ROM decomposition rate constant.
#' @param ftr Vertical transport rate.
#' @param temp_method Temperature method identifier.
#' @param temp_amplitude_hist Optional historical annual amplitude to be used
#'   in the soil temperature calculation.
#' @param temp_offset Phase offset used in the soil temperature calculation.
#' @param temp_th_diff Thermal diffusivity used in the physical soil
#'   temperature formulation.
#'
#' @return A list containing soil configuration parameters.
#' @export
#'
#' @examples soil_config(Csoil_init=72, f_hum_top=0.5, clay_sub = 0.35, clay_top=0.25)
soil_config <- function(Csoil_init = 70.4,
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
                        k_fom = 0.12,
                        k_hum = 0.0028,
                        k_rom = 3.85e-05,
                        ftr = 0.0025,
                        temp_method = "rctool",
                        temp_amplitude_hist = NA_real_,
                        temp_offset = 0,
                        temp_th_diff = 0.35e-6) {

 list(
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
    ini_Cin_sub = Csoil_init * (1 - Cproptop),
    temp_method = temp_method,
    temp_amplitude_hist = temp_amplitude_hist,
    temp_offset = temp_offset,
    temp_th_diff = temp_th_diff
  )
}


#' Internal pool C:N initialization
#'
#' Calculates initial pool carbon using the initial C:N ratio, HUM fraction,
#' and initial carbon stock. This helper is used internally by
#' `initialize_soil_pools()`.
#'
#' @param cn Numeric. Initial C:N ratio.
#' @param HUM_frac Numeric. HUM fraction.
#' @param C_0 Numeric. Initial carbon stock.
#'
#' @return Numeric initial pool carbon.
#'
#' @noRd
.pool_cn <- function(cn,
                    f_hum,
                    f_rom,
                    ini_Cin,
                    soil_surf=c('top','sub')) {

  soil_surf <- match.arg(soil_surf)

  CNfraction = min(56.2 * cn ^ (-1.69), 1)


  hum <- (ini_Cin * f_hum) * CNfraction
  fom <- ini_Cin *(1-f_hum-f_rom) # Modified after Ozan observation
  rom <- ini_Cin-hum-fom

  if (soil_surf=='top') {
   list(
        FOM_top = fom,
        HUM_top = hum,
        ROM_top = rom
    )
  } else {
   list(
        FOM_sub = fom,
        HUM_sub = hum,
        ROM_sub = rom
    )
  }
}


#' initialize_soil_pools
#'
#'Initialize topsoil and subsoil carbon pools.
#'
#' @param cn Soil carbon:nitrogen ratio.
#' @param soil_config Soil configuration list.
#'
#' @return A list containing initialized topsoil and subsoil pools.
#' @export
#'
#' @examples
#' s_config <- soil_config()
#' initialize_soil_pools(cn=15, soil_config = s_config)
initialize_soil_pools <- function(cn,
                                 soil_config) {

  ini_pool_top <- .pool_cn(
                         cn=cn,
                         f_hum = soil_config$f_hum_top,
                         f_rom = soil_config$f_rom_top,
                         ini_Cin = soil_config$ini_Cin_top,
                         soil_surf = 'top'
                         )
  ini_pool_sub <- .pool_cn(
                         cn=cn,
                         f_hum = soil_config$f_hum_sub,
                         f_rom = soil_config$f_rom_sub,
                         ini_Cin = soil_config$ini_Cin_sub,
                         'sub'
                         )

  list(
    ini_pool_top,
    ini_pool_sub
  )
}

