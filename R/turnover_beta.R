#' Turnover core function

#' @return The arguments are:
#' @export
#' @examples
#'

# i refers to the time step

turnoverkl <- function(i) {

  result_pools <- result_pools[i - 1, ]
  result_pools <- as.data.frame(t(result_pools))

  #browser()

  m = ifelse(as.numeric(result_pools[, "mth"]) < 12,
             as.numeric(result_pools[, "mth"]) + 1,
             1)
  y = ifelse(as.numeric(result_pools[, "mth"]) < 12,
             as.numeric(result_pools[, "yr"]),
             as.numeric(result_pools[, "yr"]) + 1)

  #if_else(c())
  # month_prop <- c()

  if (Crop[y] == 'Grass') {
    month_prop = month_prop_grass
  } else {
    month_prop = month_prop_grain
  }

  # FOM topsoil ----

  FOM_top <-
    result_pools[, "FOM_top"] +
    C_input_top[y] * month_prop[m] +
    C_input_man[y] * (1 - fman) * month_man[m]

  FOM_after_decomp_top <- FOM_top +
    decay(
      C0_t = FOM_top,
      k = kFOM,
      tempCoefficient = temp_coef(
        T_zt =
          soil_temp(
            depth = 25,
            month = m,
            T_ave = T_ave[y - 1 + m],
            A_0 = T_range[y - 1 + m],
            th_diff = phi
          )
      )
    )

  substrate_FOM_decomp_top <- FOM_top - FOM_after_decomp_top

  FOM_tr <- substrate_FOM_decomp_top * ftr

  FOM_humified_top <-
    (substrate_FOM_decomp_top-FOM_tr) * hum_coef(clayfrac = clay_top)

  CO2_FOM_top <-
    (substrate_FOM_decomp_top-FOM_tr) * (1 - hum_coef(clayfrac = clay_top))

  FOM_top <- FOM_top - FOM_humified_top - CO2_FOM_top - FOM_tr

  # FOM subsoil ----

  FOM_sub <-
    result_pools[, "FOM_sub"] +
    C_input_sub[y] * month_prop[m]+
    FOM_tr

  FOM_after_decomp_sub <-
    FOM_sub +
    decay(
      C0_t = FOM_sub,
      k = kFOM,
      tempCoefficient =  temp_coef(
        T_zt = soil_temp(
          depth = 100,
          month = m,
          T_ave = T_ave[y - 1 + m],
          A_0 = T_range[y - 1 + m],
          th_diff = phi
        )
      )
    )

  substrate_FOM_decomp_sub <- FOM_sub - FOM_after_decomp_sub

  FOM_humified_sub <-
    substrate_FOM_decomp_sub * hum_coef(clayfrac = clay_sub)

  CO2_FOM_sub <-
    substrate_FOM_decomp_sub * (1 - hum_coef(clayfrac = clay_sub))

  FOM_sub <- FOM_sub - FOM_humified_sub - CO2_FOM_sub

  # HUM topsoil ----

  HUM_top <-
    result_pools[, "HUM_top"] +
    C_input_man[y] * fman * month_man[m] +
    FOM_humified_top

  HUM_after_decomp_top <-
    HUM_top +
    decay(
      C0_t = HUM_top,
      k = kHUM,
      tempCoefficient = temp_coef(
        T_zt = soil_temp(
          depth = 25,
          month = m,
          T_ave = T_ave[y - 1 + m],
          A_0 = T_range[y - 1 + m],
          th_diff = phi
        )
      )
    )

  substrate_HUM_decomp_top <- HUM_top - HUM_after_decomp_top

  HUM_romified_top <- substrate_HUM_decomp_top * fromi

  CO2_HUM_top <- substrate_HUM_decomp_top * fco2

  HUM_tr <- substrate_HUM_decomp_top * (1-fromi-fco2)

  HUM_top <- HUM_top - HUM_romified_top - CO2_HUM_top - HUM_tr

  # HUM subsoil ----

  HUM_sub <-
    result_pools[, "HUM_sub"] +
    HUM_tr +
    FOM_humified_sub

  HUM_after_decomp_sub <-
    HUM_sub +
    decay(
      C0_t = HUM_sub,
      k = kHUM,
      tempCoefficient = temp_coef(
        T_zt = soil_temp(
          depth = 100,
          month = m,
          T_ave = T_ave[y - 1 + m],
          A_0 = T_range[y - 1 + m],
          th_diff = phi
        )
      )
    )

  substrate_HUM_decomp_sub <- HUM_sub - HUM_after_decomp_sub

  HUM_romified_sub <- substrate_HUM_decomp_sub * fromi

  CO2_HUM_sub <-
    substrate_HUM_decomp_sub * fco2

  HUM_sub <- HUM_sub - HUM_romified_sub - CO2_HUM_sub

  # ROM topsoil ----

  ROM_top <-
    result_pools[, "ROM_top"] +
    HUM_romified_top

  ROM_after_decomp_top <-
    ROM_top +
    decay(
      C0_t = ROM_top,
      k = kROM,
      tempCoefficient =  temp_coef(
        T_zt = soil_temp(
          depth = 25,
          month = m,
          T_ave = T_ave[y - 1 + m],
          A_0 = T_range[y - 1 + m],
          th_diff = phi
        )
      )
    )

  substrate_ROM_decomp_top <- ROM_top - ROM_after_decomp_top

  CO2_ROM_top <-
    substrate_ROM_decomp_top * fco2

  # ROM_not_respirated <-
  #   substrate_ROM_decomp_top*(1-fco2)

  ROM_tr <-
    substrate_ROM_decomp_top * ftr

  ROM_top <- ROM_top - ROM_tr - CO2_ROM_top

  # ROM subsoil ----

  ROM_sub <-
    result_pools[, "ROM_sub"] +
    ROM_tr +
    HUM_romified_sub

  ROM_after_decomp_sub <-
    ROM_sub +
    decay(
      C0_t = ROM_sub,
      k = kHUM,
      tempCoefficient =  temp_coef(
        T_zt = soil_temp(
          depth = 100,
          month = m,
          T_ave = T_ave[y - 1 + m],
          A_0 = T_range[y - 1 + m],
          th_diff = phi
        )
      )
    )

  substrate_ROM_decomp_sub <- ROM_sub - ROM_after_decomp_sub

  CO2_ROM_sub <-
    substrate_ROM_decomp_top * fco2

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

      "FOM_tr" = NA,
      "HUM_tr" = HUM_tr,
      "ROM_tr" = ROM_tr,

      "C_tr" =  HUM_tr + ROM_tr,

      "CO2_FOM_top" = CO2_FOM_top,
      "CO2_HUM_top" = CO2_HUM_top,
      "CO2_ROM_top" = CO2_ROM_top,

      "CO2_FOM_sub" = CO2_FOM_sub,
      "CO2_HUM_sub" = CO2_HUM_sub,
      "CO2_ROM_sub" = CO2_ROM_sub,

      "C_CO2_top" = CO2_FOM_top + CO2_HUM_top + CO2_ROM_top,
      "C_CO2_sub" = CO2_FOM_sub + CO2_HUM_sub + CO2_ROM_sub
    )

  return(result_pools)
}
