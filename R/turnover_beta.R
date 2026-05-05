#' turnover_beta
#'
#' Legacy monthly turnover routine retained for backward compatibility.
#'
#' This function updates FOM, HUM and ROM pools for one monthly timestep
#' using the historical C-TOOL workflow. It relies on objects defined in the
#' calling environment and is retained only for backward compatibility.
#'
#' @param i Integer index of the simulation timestep.
#'
#' @return A one-row data.frame containing updated pool sizes, carbon stocks,
#'   transport fluxes and CO2 emissions for the current timestep.
turnover_beta <- function(i) {

  result_pools <- result_pools[i - 1, ]
  result_pools <- as.data.frame(t(result_pools))

  current_month <- as.numeric(result_pools[, "mth"])
  current_year <- as.numeric(result_pools[, "yr"])

  if (current_month < 12) {
    m <- current_month + 1
    y <- current_year
  } else {
    m <- 1
    y <- current_year + 1
  }

  if (Crop[y] == "Grass") {
    month_prop <- month_prop_grass
  } else {
    month_prop <- month_prop_grain
  }

  # Use a single scalar historical amplitude when provided as such;
  # otherwise allow backward compatibility with time-indexed amplitude vectors.
  temperature_amplitude <- if (length(amplitude) == 1) {
    amplitude
  } else {
    amplitude[result_pools[, "step"]]
  }

  temperature_average <- T_ave[result_pools[, "step"]]

  # FOM topsoil ----
  FOM_top <-
    result_pools[, "FOM_top"] +
    C_input_top[y] * month_prop[m] +
    C_input_man[y] * (1 - fman) * month_man[m]

  FOM_after_decomp_top <-
    FOM_top +
    .decay(
      CO_t = FOM_top,
      k = kFOM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 25,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_FOM_decomp_top <- FOM_top - FOM_after_decomp_top
  FOM_tr <- substrate_FOM_decomp_top * ftr

  FOM_humified_top <-
    (substrate_FOM_decomp_top - FOM_tr) * .hum_coef(clay_top)

  CO2_FOM_top <-
    (substrate_FOM_decomp_top - FOM_tr) * (1 - .hum_coef(clay_top))

  FOM_top <- FOM_top - FOM_humified_top - CO2_FOM_top - FOM_tr

  # FOM subsoil ----
  FOM_sub <-
    result_pools[, "FOM_sub"] +
    C_input_sub[y] * month_prop[m] +
    FOM_tr

  FOM_after_decomp_sub <-
    FOM_sub +
    .decay(
      CO_t = FOM_sub,
      k = kFOM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 100,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_FOM_decomp_sub <- FOM_sub - FOM_after_decomp_sub

  FOM_humified_sub <-
    substrate_FOM_decomp_sub * .hum_coef(clay_sub)

  CO2_FOM_sub <-
    substrate_FOM_decomp_sub * (1 - .hum_coef(clay_sub))

  FOM_sub <- FOM_sub - FOM_humified_sub - CO2_FOM_sub

  # HUM topsoil ----
  HUM_top <-
    result_pools[, "HUM_top"] +
    C_input_man[y] * fman * month_man[m] +
    FOM_humified_top

  HUM_after_decomp_top <-
    HUM_top +
    .decay(
      CO_t = HUM_top,
      k = kHUM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 25,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_HUM_decomp_top <- HUM_top - HUM_after_decomp_top
  HUM_romified_top <- substrate_HUM_decomp_top * fromi
  CO2_HUM_top <- substrate_HUM_decomp_top * fco2
  HUM_tr <- substrate_HUM_decomp_top * (1 - fromi - fco2)

  HUM_top <- HUM_top - HUM_romified_top - CO2_HUM_top - HUM_tr

  # HUM subsoil ----
  HUM_sub <-
    result_pools[, "HUM_sub"] +
    HUM_tr +
    FOM_humified_sub

  HUM_after_decomp_sub <-
    HUM_sub +
    .decay(
      CO_t = HUM_sub,
      k = kHUM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 100,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_HUM_decomp_sub <- HUM_sub - HUM_after_decomp_sub
  HUM_romified_sub <- substrate_HUM_decomp_sub * fromi
  CO2_HUM_sub <- substrate_HUM_decomp_sub * fco2

  HUM_sub <- HUM_sub - HUM_romified_sub - CO2_HUM_sub

  # ROM topsoil ----
  ROM_top <-
    result_pools[, "ROM_top"] +
    HUM_romified_top

  ROM_after_decomp_top <-
    ROM_top +
    .decay(
      CO_t = ROM_top,
      k = kROM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 25,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_ROM_decomp_top <- ROM_top - ROM_after_decomp_top
  CO2_ROM_top <- substrate_ROM_decomp_top * fco2
  ROM_tr <- substrate_ROM_decomp_top * ftr

  ROM_top <- ROM_top - ROM_tr - CO2_ROM_top

  # ROM subsoil ----
  ROM_sub <-
    result_pools[, "ROM_sub"] +
    ROM_tr +
    HUM_romified_sub

  ROM_after_decomp_sub <-
    ROM_sub +
    .decay(
      CO_t = ROM_sub,
      k = kROM,
      tempCoefficient = .temp_coef(
        T_zt = .soil_temp(
          depth = 100,
          month = m,
          T_ave = temperature_average,
          Amplitude = temperature_amplitude,
          th_diff = temp_th_diff
        )
      )
    )

  substrate_ROM_decomp_sub <- ROM_sub - ROM_after_decomp_sub
  CO2_ROM_sub <- substrate_ROM_decomp_sub * fco2
  ROM_sub <- ROM_sub - CO2_ROM_sub

  result_pools <-
    cbind(
      "step" = result_pools[, "step"] + 1,
      "yr" = y,
      "mth" = m,
      "FOM_top" = FOM_top,
      "HUM_top" = HUM_top,
      "ROM_top" = ROM_top,
      "FOM_sub" = FOM_sub,
      "HUM_sub" = HUM_sub,
      "ROM_sub" = ROM_sub,
      "C_topsoil" = FOM_top + HUM_top + ROM_top,
      "C_subsoil" = FOM_sub + HUM_sub + ROM_sub,
      "FOM_tr" = FOM_tr,
      "HUM_tr" = HUM_tr,
      "ROM_tr" = ROM_tr,
      "CO2_FOM_top" = CO2_FOM_top,
      "CO2_HUM_top" = CO2_HUM_top,
      "CO2_ROM_top" = CO2_ROM_top,
      "CO2_FOM_sub" = CO2_FOM_sub,
      "CO2_HUM_sub" = CO2_HUM_sub,
      "CO2_ROM_sub" = CO2_ROM_sub,
      "C_CO2_top" = CO2_FOM_top + CO2_HUM_top + CO2_ROM_top,
      "C_CO2_sub" = CO2_FOM_sub + CO2_HUM_sub + CO2_ROM_sub
    )

  result_pools
}
