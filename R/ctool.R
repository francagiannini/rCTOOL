#' turnover
#'
#' Perform one monthly turnover step of C-TOOL.
#'
#' Updates FOM, HUM and ROM pools for one monthly timestep using carbon
#' inputs, management allocations, monthly mean air temperature, soil
#' parameters, and the previous pool state.
#'
#' @param timestep Integer index of the simulation timestep.
#' @param time_config Time configuration object created by
#'   `define_timeperiod()`.
#' @param cin_config Carbon input configuration.
#' @param m_config Management configuration with monthly allocation patterns.
#' @param t_config Monthly temperature configuration containing at least
#'   `month` and `Tavg`.
#' @param s_config Soil parameter configuration.
#' @param out Data frame containing pool values from the previous timestep.
#' @param amplitude_hist Numeric. Historical annual air temperature amplitude
#'   calculated from the monthly climatology of `Tavg`.
#'
#' @return A data.frame containing updated monthly pool sizes, carbon stocks,
#'   transport fluxes and CO2 emissions for the current timestep.
#' @export
turnover <- function(timestep,
                     time_config,
                     cin_config,
                     m_config,
                     t_config,
                     s_config,
                     out,
                     amplitude_hist) {

  mon <- time_config$timeperiod[timestep, "mon"]
  yr <- time_config$timeperiod[timestep, "id"]

  t_avg <- t_config$Tavg[timestep]
  amplitude <- amplitude_hist

  # Read management config (allocations) and adapt it
  m_config <- .clean_monthly_allocations(m_config)

  # FOM ----
  FOM_top <- update_monthly_FOM_top(
    FOM_top_t1 = out$FOM_top,
    Cin_plant_top = cin_config$Cin_top[yr],
    Cin_manure = cin_config$Cin_man[yr],
    month = mon,
    m_config = m_config
  )

  FOM_top <- FOM_top_calculations(
    FOM_top_t = FOM_top,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  FOM_sub <- update_monthly_FOM_sub(
    FOM_sub_t1 = out$FOM_sub,
    FOM_transport = FOM_top$FOM_tr,
    C_in_plant_sub = cin_config$Cin_sub[yr],
    month = mon,
    m_config = m_config
  )

  FOM_sub <- FOM_sub_calculations(
    FOM_sub_t = FOM_sub,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  # HUM ----
  HUM_top <- update_monthly_HUM_top(
    HUM_top_t1 = out$HUM_top,
    C_in_man = cin_config$Cin_man[yr],
    FOM_humified_top = FOM_top$FOM_humified_top,
    month = mon,
    m_config = m_config
  )

  HUM_top <- HUM_top_calculations(
    HUM_top_t = HUM_top,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  HUM_sub <- update_monthly_HUM_sub(
    HUM_sub_t1 = out$HUM_sub,
    HUM_transport = HUM_top$HUM_tr,
    FOM_humified_sub = FOM_sub$FOM_humified_sub
  )

  HUM_sub <- HUM_sub_calculations(
    HUM_sub_t = HUM_sub,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  # ROM ----
  ROM_top <- update_monthly_ROM_top(
    ROM_top_t1 = out$ROM_top,
    HUM_romified_top = HUM_top$HUM_romified_top
  )

  ROM_top <- ROM_top_calculations(
    ROM_top_t = ROM_top,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  ROM_sub <- update_monthly_ROM_sub(
    ROM_sub_t1 = out$ROM_sub,
    HUM_romified_sub = HUM_sub$HUM_romified_sub,
    ROM_transport = ROM_top$ROM_tr
  )

  ROM_sub <- ROM_sub_calculations(
    ROM_sub_t = ROM_sub,
    month = mon,
    t_avg = t_avg,
    amplitude = amplitude,
    s_config = s_config
  )

  as.data.frame(list(
    FOM_top,
    FOM_sub,
    HUM_top,
    HUM_sub,
    ROM_top,
    ROM_sub,
    C_topsoil = FOM_top$FOM_top + HUM_top$HUM_top + ROM_top$ROM_top,
    C_subsoil = FOM_sub$FOM_sub + HUM_sub$HUM_sub + ROM_sub$ROM_sub,
    SOC_stock = FOM_top$FOM_top + HUM_top$HUM_top + ROM_top$ROM_top +
      FOM_sub$FOM_sub + HUM_sub$HUM_sub + ROM_sub$ROM_sub,
    C_transport = HUM_top$HUM_tr + ROM_top$ROM_tr + FOM_top$FOM_tr,
    em_CO2_top = FOM_top$em_CO2_FOM_top + HUM_top$em_CO2_HUM_top +
      ROM_top$em_CO2_ROM_top,
    em_CO2_sub = FOM_sub$em_CO2_FOM_sub + HUM_sub$em_CO2_HUM_sub +
      ROM_sub$em_CO2_ROM_sub,
    em_CO2_total = FOM_top$em_CO2_FOM_top + HUM_top$em_CO2_HUM_top +
      ROM_top$em_CO2_ROM_top + FOM_sub$em_CO2_FOM_sub +
      HUM_sub$em_CO2_HUM_sub + ROM_sub$em_CO2_ROM_sub
  ))
}


#' run_ctool
#'
#' Run C-TOOL over the full simulation period.
#'
#' Iteratively applies `turnover()` over all timesteps defined in
#' `time_config` and returns monthly carbon pool sizes, soil carbon stocks,
#' transport fluxes and CO2 emissions.
#'
#' The temperature configuration must provide monthly mean air temperature.
#' A single historical annual temperature amplitude is calculated internally
#' from the monthly climatology of `Tavg` and is used in the soil temperature
#' response function.
#'
#' @param time_config Time configuration object created by
#'   `define_timeperiod()`.
#' @param cin_config Carbon input configuration.
#' @param m_config Management configuration with monthly allocation patterns.
#' @param t_config Monthly temperature configuration containing at least
#'   `month` and `Tavg`.
#' @param s_config Soil parameter configuration.
#' @param soil_pools Initial soil pool configuration.
#' @param verbose Logical; if `TRUE`, run balance checking.
#'
#' @return A data.frame containing the monthly simulation output across the
#'   full simulation period.
#' @export
run_ctool <- function(time_config,
                      cin_config,
                      m_config,
                      t_config,
                      s_config,
                      soil_pools,
                      verbose = FALSE) {

  # Check temperature input ----
  required_temp_cols <- c("month", "Tavg")

  missing_temp_cols <- setdiff(required_temp_cols, names(t_config))

  if (length(missing_temp_cols) > 0) {
    stop(
      paste0(
        "'t_config' is missing required column(s): ",
        paste(missing_temp_cols, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (nrow(t_config) < time_config$steps) {
    stop(
      "'t_config' has fewer rows than the number of simulation timesteps.",
      call. = FALSE
    )
  }

  # Calculate one historical annual amplitude from monthly climatology ----
  monthly_tavg <- stats::aggregate(
    Tavg ~ month,
    data = t_config,
    FUN = mean,
    na.rm = TRUE
  )

  amplitude_hist <- (
    max(monthly_tavg$Tavg, na.rm = TRUE) -
      min(monthly_tavg$Tavg, na.rm = TRUE)
  ) / 2

  if (!is.finite(amplitude_hist)) {
    stop(
      "Historical temperature amplitude could not be calculated from 't_config$Tavg'.",
      call. = FALSE
    )
  }

  simul <- seq_len(time_config$steps)
  out_init <- as.data.frame(soil_pools)

  st <- vector("list", length = time_config$steps)

  for (i in simul) {
    if (i == 1) {
      st[[i]] <- turnover(
        timestep = i,
        time_config = time_config,
        cin_config = cin_config,
        m_config = m_config,
        t_config = t_config,
        s_config = s_config,
        out = out_init,
        amplitude_hist = amplitude_hist
      )
    } else {
      st[[i]] <- turnover(
        timestep = i,
        time_config = time_config,
        cin_config = cin_config,
        m_config = m_config,
        t_config = t_config,
        s_config = s_config,
        out = st[[i - 1]],
        amplitude_hist = amplitude_hist
      )
    }
  }

  ctool <- data.table::rbindlist(st)

  if (verbose) {
    ctool <- check_balance(
      ctool_output = ctool,
      cin_config = cin_config,
      s_config = s_config
    )
  }

  cbind(time_config$timeperiod[, c("mon", "yrs")], ctool)
}
