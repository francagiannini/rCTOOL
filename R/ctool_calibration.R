#' Calibrate C-TOOL using observed topsoil SOC
#'
#' Calibrates two C-TOOL parameters against observed SOC stocks:
#' `f_hum_top` and `k_hum`.
#'
#' This function assumes that all C-TOOL simulation inputs have already been
#' prepared using the standard rCTOOL workflow. The only additional data
#' required for calibration is a two-column data frame containing observed SOC
#' stocks by year.
#'
#' The observed data frame must contain, by default:
#'
#' - `Year`: observation year.
#' - `SOC_obs`: observed SOC stock.
#'
#' For each tested value of `f_hum_top`, `f_rom_top` is calculated internally as:
#'
#' `f_rom_top = 1 - f_hum_top - f_fom_top`
#'
#' Invalid combinations where `f_rom_top <= 0` are removed before model runs.
#'
#' The function first evaluates the current C-TOOL parameter set supplied through
#' `soil_config`. It then evaluates the tested calibration grid. If the current
#' C-TOOL parameter set performs as well as or better than the best tested
#' calibration, the function recommends keeping the current parameters.
#'
#' The main goodness-of-fit statistics returned by the function are RMSE, MAE,
#' mean bias, R2, and the Willmott index of agreement, here reported as
#' `d_index`.
#'
#' @param time_config A C-TOOL time configuration object returned by
#'   [define_timeperiod()].
#' @param cinput_config A C-TOOL carbon input configuration object returned by
#'   [define_Cinputs()].
#' @param temperature_config A C-TOOL compatible temperature configuration used
#'   by [run_ctool()]. It must contain at least `month` and `Tavg`.
#'   A single historical annual temperature amplitude is calculated internally
#'   from the monthly climatology of `Tavg`.
#' @param management_config A C-TOOL management configuration object returned by
#'   [management_config()].
#' @param soil_config A C-TOOL soil configuration object returned by
#'   [soil_config()]. All parameters are preserved, except `f_hum_top`, `k_hum`,
#'   and the internally recalculated `f_rom_top`.
#' @param observed A data frame with observed SOC values. By default, it must
#'   contain columns `Year` and `SOC_obs`.
#' @param f_hum_top Named numeric vector defining the calibration range for
#'   `f_hum_top`, with names `min`, `max`, and `by`.
#' @param k_hum Named numeric vector defining the calibration range for `k_hum`,
#'   with names `min`, `max`, and `by`.
#' @param cn_init Initial C:N ratio used by [initialize_soil_pools()].
#'   Default is `10`.
#' @param years_col Name of the year column in `observed`.
#'   Default is `"Year"`.
#' @param obs_col Name of the observed SOC column in `observed`.
#'   Default is `"SOC_obs"`.
#' @param f_fom_top Fixed topsoil FOM transfer fraction used to calculate
#'   `f_rom_top`. Default is `0.003`.
#' @param metric Character. Metric used to select the best tested parameter set.
#'   Options are `"d_index"`, `"RMSE"`, `"R2"`, `"MAE"`, and `"Bias"`.
#'   Default is `"d_index"`. The legacy value `"d"` is also accepted and
#'   internally converted to `"d_index"`.
#' @param minimize Logical. Should the selected metric be minimized? If `NULL`,
#'   sensible defaults are used: `FALSE` for `"d_index"` and `"R2"`, and `TRUE`
#'   for `"RMSE"`, `"MAE"`, and absolute `"Bias"`.
#' @param keep_simulations Logical. If `TRUE`, stores all calibrated simulation
#'   time series. Default is `FALSE`.
#' @param verbose Logical. If `TRUE`, prints progress messages.
#'
#' @return An object of class `"ctool_calibration"`, a list containing:
#' \describe{
#'   \item{best_params}{Best tested calibration parameter set and its metrics.}
#'   \item{recommended_params}{Recommended parameter set. This may be either the current C-TOOL parameter set or the best tested calibration.}
#'   \item{recommendation}{Text explaining whether to keep current parameters or use the best tested calibration.}
#'   \item{metrics}{Metrics for the current C-TOOL parameters and best tested calibration.}
#'   \item{all_results}{Metrics for all tested parameter combinations.}
#'   \item{observed}{Observed SOC data used for calibration.}
#'   \item{default_simulation}{Simulation using the supplied soil configuration.}
#'   \item{best_simulation}{Simulation using the best tested calibration.}
#'   \item{recommended_simulation}{Simulation using the recommended parameter set.}
#'   \item{parameter_grid}{Parameter grid used for calibration.}
#'   \item{all_simulations}{Optional list of all tested calibrated simulations.}
#'   \item{settings}{Calibration settings.}
#' }
#'
#' @references
#' Willmott, C. J. (1981). On the validation of models. Physical Geography,
#' 2(2), 184-194.
#'
#' @examples
#' \dontrun{
#' observed <- data.frame(
#'   Year = c(1923, 1932, 1942, 1950),
#'   SOC_obs = c(54.2, 53.8, 52.1, 51.4)
#' )
#'
#' calib <- ctool_calibrate(
#'   time_config = time_cfg,
#'   cinput_config = cin_cfg,
#'   temperature_config = t_cfg,
#'   management_config = m_cfg,
#'   soil_config = soil_cfg,
#'   observed = observed,
#'   f_hum_top = c(min = 0.20, max = 0.60, by = 0.05),
#'   k_hum = c(min = 0.0020, max = 0.0040, by = 0.0005)
#' )
#'
#' summary(calib)
#' }
#'
#' @export
ctool_calibrate <- function(
    time_config,
    cinput_config,
    temperature_config,
    management_config,
    soil_config,
    observed,
    f_hum_top = c(min = 0.20, max = 0.60, by = 0.05),
    k_hum = c(min = 0.0020, max = 0.0040, by = 0.0005),
    cn_init = 10,
    years_col = "Year",
    obs_col = "SOC_obs",
    f_fom_top = 0.003,
    metric = "d_index",
    minimize = NULL,
    keep_simulations = FALSE,
    verbose = TRUE
) {

  if (identical(metric, "d")) {
    metric <- "d_index"
  }

  metric <- match.arg(metric, c("d_index", "RMSE", "R2", "MAE", "Bias"))

  if (is.null(minimize)) {
    minimize <- metric %in% c("RMSE", "MAE", "Bias")
  }

  .ctool_calibration_check_numeric_scalar(cn_init, "cn_init")
  .ctool_calibration_check_numeric_scalar(f_fom_top, "f_fom_top")

  if (!is.logical(keep_simulations) ||
      length(keep_simulations) != 1L ||
      is.na(keep_simulations)) {
    stop("'keep_simulations' must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.logical(verbose) ||
      length(verbose) != 1L ||
      is.na(verbose)) {
    stop("'verbose' must be TRUE or FALSE.", call. = FALSE)
  }

  .ctool_calibration_check_soil_config(soil_config)
  .ctool_calibration_check_temperature_config(temperature_config)

  observed_df <- .ctool_calibration_prepare_observed(
    observed = observed,
    years_col = years_col,
    obs_col = obs_col
  )

  f_hum_top_values <- .ctool_calibration_make_parameter_sequence(
    x = f_hum_top,
    name = "f_hum_top"
  )

  k_hum_values <- .ctool_calibration_make_parameter_sequence(
    x = k_hum,
    name = "k_hum"
  )

  parameter_grid <- expand.grid(
    f_hum_top = f_hum_top_values,
    k_hum = k_hum_values,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )

  parameter_grid$f_rom_top <- 1 - parameter_grid$f_hum_top - f_fom_top

  parameter_grid <- parameter_grid[
    parameter_grid$f_rom_top > 0,
    ,
    drop = FALSE
  ]

  if (nrow(parameter_grid) == 0L) {
    stop(
      "No valid parameter combinations. ",
      "All combinations produced 'f_rom_top <= 0'. ",
      "Check 'f_hum_top' and 'f_fom_top'.",
      call. = FALSE
    )
  }

  if (isTRUE(verbose)) {
    message("Running C-TOOL with current parameters.")
  }

  sim_default <- .ctool_calibration_run_simulation(
    time_config = time_config,
    cinput_config = cinput_config,
    temperature_config = temperature_config,
    management_config = management_config,
    soil_config = soil_config,
    cn_init = cn_init
  )

  cmp_default <- merge(
    observed_df,
    sim_default,
    by = "Year",
    all = FALSE
  )

  if (nrow(cmp_default) < 2L) {
    stop(
      "Current C-TOOL simulation and observed data have fewer than two matching years.",
      call. = FALSE
    )
  }

  metrics_default <- ctool_calibration_metrics(
    observed = cmp_default$SOC_obs,
    simulated = cmp_default$SOC
  )

  metrics_default$Type <- "Current C-TOOL parameters"
  metrics_default$f_hum_top <- soil_config$f_hum_top
  metrics_default$k_hum <- soil_config$k_hum
  metrics_default$f_rom_top <- soil_config$f_rom_top

  if (isTRUE(verbose)) {
    message(
      "Running calibration grid with ",
      nrow(parameter_grid),
      " parameter combinations."
    )
  }

  all_results <- vector("list", nrow(parameter_grid))

  if (isTRUE(keep_simulations)) {
    all_simulations <- vector("list", nrow(parameter_grid))
  } else {
    all_simulations <- NULL
  }

  for (i in seq_len(nrow(parameter_grid))) {

    pars <- parameter_grid[i, , drop = FALSE]

    soil_i <- .ctool_calibration_update_soil(
      soil_config = soil_config,
      f_hum_top = pars$f_hum_top,
      k_hum = pars$k_hum,
      f_fom_top = f_fom_top
    )

    sim_i <- .ctool_calibration_run_simulation(
      time_config = time_config,
      cinput_config = cinput_config,
      temperature_config = temperature_config,
      management_config = management_config,
      soil_config = soil_i,
      cn_init = cn_init
    )

    cmp_i <- merge(
      observed_df,
      sim_i,
      by = "Year",
      all = FALSE
    )

    if (nrow(cmp_i) < 2L) {
      metrics_i <- data.frame(
        d_index = NA_real_,
        RMSE = NA_real_,
        R2 = NA_real_,
        Bias = NA_real_,
        MAE = NA_real_,
        n = nrow(cmp_i),
        stringsAsFactors = FALSE
      )
    } else {
      metrics_i <- ctool_calibration_metrics(
        observed = cmp_i$SOC_obs,
        simulated = cmp_i$SOC
      )
    }

    all_results[[i]] <- data.frame(
      f_hum_top = pars$f_hum_top,
      k_hum = pars$k_hum,
      f_rom_top = pars$f_rom_top,
      metrics_i,
      stringsAsFactors = FALSE
    )

    if (isTRUE(keep_simulations)) {
      sim_i$f_hum_top <- pars$f_hum_top
      sim_i$k_hum <- pars$k_hum
      sim_i$f_rom_top <- pars$f_rom_top
      all_simulations[[i]] <- sim_i
    }

    if (isTRUE(verbose) && (i %% 25L == 0L || i == nrow(parameter_grid))) {
      message("  Completed ", i, " / ", nrow(parameter_grid), " runs.")
    }
  }

  all_results <- do.call(rbind, all_results)
  rownames(all_results) <- NULL

  complete_metric <- !is.na(all_results[[metric]])

  if (!any(complete_metric)) {
    stop(
      "No valid calibration metrics were calculated. ",
      "Check whether observed years match simulated years.",
      call. = FALSE
    )
  }

  ranking_values <- all_results[[metric]]

  if (metric == "Bias") {
    ranking_values <- abs(ranking_values)
  }

  ranking_values[!complete_metric] <- if (isTRUE(minimize)) Inf else -Inf

  if (isTRUE(minimize)) {
    best_index <- order(
      ranking_values,
      all_results$RMSE,
      -all_results$d_index,
      -all_results$R2,
      na.last = TRUE
    )[1L]
  } else {
    best_index <- order(
      -ranking_values,
      all_results$RMSE,
      -all_results$d_index,
      -all_results$R2,
      na.last = TRUE
    )[1L]
  }

  best_params <- all_results[best_index, , drop = FALSE]

  soil_best <- .ctool_calibration_update_soil(
    soil_config = soil_config,
    f_hum_top = best_params$f_hum_top,
    k_hum = best_params$k_hum,
    f_fom_top = f_fom_top
  )

  sim_best <- .ctool_calibration_run_simulation(
    time_config = time_config,
    cinput_config = cinput_config,
    temperature_config = temperature_config,
    management_config = management_config,
    soil_config = soil_best,
    cn_init = cn_init
  )

  metrics_best <- best_params
  metrics_best$Type <- "Best tested calibration"

  metrics <- rbind(
    metrics_default[, c(
      "Type", "d_index", "RMSE", "R2", "Bias", "MAE", "n",
      "f_hum_top", "k_hum", "f_rom_top"
    )],
    metrics_best[, c(
      "Type", "d_index", "RMSE", "R2", "Bias", "MAE", "n",
      "f_hum_top", "k_hum", "f_rom_top"
    )]
  )

  rownames(metrics) <- NULL

  default_row <- metrics[metrics$Type == "Current C-TOOL parameters", , drop = FALSE]
  calibrated_row <- metrics[metrics$Type == "Best tested calibration", , drop = FALSE]

  default_score <- default_row[[metric]]
  calibrated_score <- calibrated_row[[metric]]

  if (metric == "Bias") {
    default_score <- abs(default_score)
    calibrated_score <- abs(calibrated_score)
  }

  if (isTRUE(minimize)) {
    calibration_improved <- calibrated_score < default_score
  } else {
    calibration_improved <- calibrated_score > default_score
  }

  if (isTRUE(calibration_improved)) {

    recommended_params <- data.frame(
      Source = "Best tested calibration",
      f_hum_top = calibrated_row$f_hum_top,
      k_hum = calibrated_row$k_hum,
      f_rom_top = calibrated_row$f_rom_top,
      d_index = calibrated_row$d_index,
      RMSE = calibrated_row$RMSE,
      R2 = calibrated_row$R2,
      Bias = calibrated_row$Bias,
      MAE = calibrated_row$MAE,
      n = calibrated_row$n,
      stringsAsFactors = FALSE
    )

    recommended_simulation <- sim_best

    recommendation <- paste(
      "Use the best tested calibration because it improved the selected",
      "performance metric compared with the current C-TOOL parameters."
    )

  } else {

    recommended_params <- data.frame(
      Source = "Current C-TOOL parameters",
      f_hum_top = default_row$f_hum_top,
      k_hum = default_row$k_hum,
      f_rom_top = default_row$f_rom_top,
      d_index = default_row$d_index,
      RMSE = default_row$RMSE,
      R2 = default_row$R2,
      Bias = default_row$Bias,
      MAE = default_row$MAE,
      n = default_row$n,
      stringsAsFactors = FALSE
    )

    recommended_simulation <- sim_default

    recommendation <- paste(
      "Keep the current C-TOOL parameters because they performed as well as",
      "or better than the tested calibration grid."
    )
  }

  if (isTRUE(verbose)) {
    message(
      "Best tested calibration: ",
      "f_hum_top = ", signif(best_params$f_hum_top, 5),
      "; k_hum = ", signif(best_params$k_hum, 5),
      "; f_rom_top = ", signif(best_params$f_rom_top, 5),
      "; d-index = ", signif(best_params$d_index, 5),
      "; RMSE = ", signif(best_params$RMSE, 5),
      "."
    )

    message(
      "Recommended parameter set: ",
      recommended_params$Source,
      " | f_hum_top = ", signif(recommended_params$f_hum_top, 5),
      "; k_hum = ", signif(recommended_params$k_hum, 5),
      "; f_rom_top = ", signif(recommended_params$f_rom_top, 5),
      "."
    )
  }

  out <- list(
    best_params = best_params,
    recommended_params = recommended_params,
    recommendation = recommendation,
    metrics = metrics,
    all_results = all_results,
    observed = observed_df,
    default_simulation = sim_default,
    best_simulation = sim_best,
    recommended_simulation = recommended_simulation,
    parameter_grid = parameter_grid,
    all_simulations = all_simulations,
    settings = list(
      f_hum_top = f_hum_top,
      k_hum = k_hum,
      f_hum_top_values = f_hum_top_values,
      k_hum_values = k_hum_values,
      f_fom_top = f_fom_top,
      cn_init = cn_init,
      metric = metric,
      minimize = minimize,
      keep_simulations = keep_simulations
    )
  )

  class(out) <- "ctool_calibration"

  out
}


#' Calculate C-TOOL calibration metrics
#'
#' Calculates performance metrics between observed and simulated SOC values.
#'
#' The returned `d_index` is the Willmott index of agreement.
#'
#' @param observed Numeric vector with observed values.
#' @param simulated Numeric vector with simulated values.
#'
#' @return A data frame with `d_index`, `RMSE`, `R2`, `Bias`, `MAE`, and `n`.
#'
#' @references
#' Willmott, C. J. (1981). On the validation of models. Physical Geography,
#' 2(2), 184-194.
#'
#' @examples
#' ctool_calibration_metrics(
#'   observed = c(50, 52, 55),
#'   simulated = c(49, 53, 54)
#' )
#'
#' @export
ctool_calibration_metrics <- function(observed, simulated) {

  if (!is.numeric(observed)) {
    stop("'observed' must be numeric.", call. = FALSE)
  }

  if (!is.numeric(simulated)) {
    stop("'simulated' must be numeric.", call. = FALSE)
  }

  if (length(observed) != length(simulated)) {
    stop(
      "'observed' and 'simulated' must have the same length.",
      call. = FALSE
    )
  }

  ok <- stats::complete.cases(observed, simulated)

  observed <- observed[ok]
  simulated <- simulated[ok]

  n <- length(observed)

  if (n < 2L) {
    stop(
      "At least two paired observed-simulated values are required.",
      call. = FALSE
    )
  }

  obs_mean <- mean(observed)

  rmse <- sqrt(mean((simulated - observed)^2))
  mae <- mean(abs(simulated - observed))
  bias <- mean(simulated - observed)

  r_value <- suppressWarnings(stats::cor(observed, simulated))

  r2 <- if (is.na(r_value)) {
    NA_real_
  } else {
    r_value^2
  }

  denominator <- sum(
    (abs(simulated - obs_mean) + abs(observed - obs_mean))^2
  )

  d_index <- if (isTRUE(all.equal(denominator, 0))) {
    NA_real_
  } else {
    1 - sum((simulated - observed)^2) / denominator
  }

  data.frame(
    d_index = d_index,
    RMSE = rmse,
    R2 = r2,
    Bias = bias,
    MAE = mae,
    n = n,
    stringsAsFactors = FALSE
  )
}


#' @export
print.ctool_calibration <- function(x, ...) {

  cat("C-TOOL calibration\n")
  cat("=================\n\n")

  cat("Calibrated parameters:\n")
  cat("  - f_hum_top\n")
  cat("  - k_hum\n\n")

  cat("Parameter ranges:\n")
  cat(
    "  f_hum_top: ",
    x$settings$f_hum_top[["min"]], " to ",
    x$settings$f_hum_top[["max"]], " by ",
    x$settings$f_hum_top[["by"]], "\n",
    sep = ""
  )
  cat(
    "  k_hum: ",
    x$settings$k_hum[["min"]], " to ",
    x$settings$k_hum[["max"]], " by ",
    x$settings$k_hum[["by"]], "\n\n",
    sep = ""
  )

  cat("Best tested calibration:\n")

  best <- x$best_params[, c(
    "f_hum_top", "k_hum", "f_rom_top",
    "d_index", "RMSE", "R2", "Bias", "MAE", "n"
  ), drop = FALSE]

  print(best, row.names = FALSE)

  cat("\nRecommended parameter set:\n")
  print(x$recommended_params, row.names = FALSE)

  cat("\nRecommendation:\n")
  cat("  ", x$recommendation, "\n", sep = "")

  invisible(x)
}


#' @export
summary.ctool_calibration <- function(object, ...) {

  cat("C-TOOL calibration summary\n")
  cat("=========================\n\n")

  cat("Calibration data:\n")
  cat("  Observations: ", nrow(object$observed), "\n", sep = "")
  cat("  Tested combinations: ", nrow(object$all_results), "\n\n", sep = "")

  cat("Calibrated parameters:\n")
  cat("  f_hum_top\n")
  cat("  k_hum\n\n")

  cat("Parameter ranges:\n")
  cat(
    "  f_hum_top: ",
    object$settings$f_hum_top[["min"]], " to ",
    object$settings$f_hum_top[["max"]], " by ",
    object$settings$f_hum_top[["by"]], "\n",
    sep = ""
  )
  cat(
    "  k_hum: ",
    object$settings$k_hum[["min"]], " to ",
    object$settings$k_hum[["max"]], " by ",
    object$settings$k_hum[["by"]], "\n\n",
    sep = ""
  )

  cat("Calibration settings:\n")
  cat("  f_fom_top: ", object$settings$f_fom_top, "\n", sep = "")
  cat("  cn_init: ", object$settings$cn_init, "\n", sep = "")
  cat("  Ranking metric: ", object$settings$metric, "\n", sep = "")
  cat("  Minimize metric: ", object$settings$minimize, "\n\n", sep = "")

  cat("Best tested calibration:\n")

  print(
    object$best_params[, c(
      "f_hum_top", "k_hum", "f_rom_top",
      "d_index", "RMSE", "R2", "Bias", "MAE", "n"
    ), drop = FALSE],
    row.names = FALSE
  )

  cat("\nCurrent parameters versus best tested calibration:\n")

  print(object$metrics, row.names = FALSE)

  cat("\nRecommended parameter set:\n")
  print(object$recommended_params, row.names = FALSE)

  cat("\nRecommendation:\n")
  cat("  ", object$recommendation, "\n", sep = "")

  invisible(object)
}


.ctool_calibration_check_numeric_scalar <- function(x, name) {

  if (!is.numeric(x) || length(x) != 1L || is.na(x)) {
    stop("'", name, "' must be a single numeric value.", call. = FALSE)
  }

  invisible(TRUE)
}


.ctool_calibration_check_soil_config <- function(soil_config) {

  required <- c("f_hum_top", "k_hum", "f_rom_top")

  missing <- required[!required %in% names(soil_config)]

  if (length(missing) > 0L) {
    stop(
      "'soil_config' must contain: ",
      paste(required, collapse = ", "),
      ". Missing: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


.ctool_calibration_check_temperature_config <- function(temperature_config) {

  required <- c("month", "Tavg")

  missing <- required[!required %in% names(temperature_config)]

  if (length(missing) > 0L) {
    stop(
      "'temperature_config' must contain columns: ",
      paste(required, collapse = ", "),
      ". Missing: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


.ctool_calibration_prepare_observed <- function(
    observed,
    years_col = "Year",
    obs_col = "SOC_obs"
) {

  if (!is.data.frame(observed)) {
    stop("'observed' must be a data frame.", call. = FALSE)
  }

  if (!years_col %in% names(observed)) {
    stop(
      "Column '", years_col, "' was not found in 'observed'.",
      call. = FALSE
    )
  }

  if (!obs_col %in% names(observed)) {
    stop(
      "Column '", obs_col, "' was not found in 'observed'.",
      call. = FALSE
    )
  }

  observed_df <- data.frame(
    Year = as.integer(observed[[years_col]]),
    SOC_obs = as.numeric(observed[[obs_col]])
  )

  observed_df <- observed_df[stats::complete.cases(observed_df), , drop = FALSE]

  if (nrow(observed_df) < 2L) {
    stop(
      "'observed' must contain at least two complete observations.",
      call. = FALSE
    )
  }

  observed_df <- observed_df[order(observed_df$Year), , drop = FALSE]

  rownames(observed_df) <- NULL

  observed_df
}


.ctool_calibration_make_parameter_sequence <- function(x, name) {

  if (!is.numeric(x)) {
    stop("'", name, "' must be numeric.", call. = FALSE)
  }

  required_names <- c("min", "max", "by")

  if (!all(required_names %in% names(x))) {
    stop(
      "'", name, "' must be a named numeric vector with names ",
      "'min', 'max', and 'by'. For example: ",
      name, " = c(min = 0.20, max = 0.60, by = 0.05).",
      call. = FALSE
    )
  }

  x_min <- x[["min"]]
  x_max <- x[["max"]]
  x_by <- x[["by"]]

  .ctool_calibration_check_numeric_scalar(x_min, paste0(name, "['min']"))
  .ctool_calibration_check_numeric_scalar(x_max, paste0(name, "['max']"))
  .ctool_calibration_check_numeric_scalar(x_by, paste0(name, "['by']"))

  if (x_by <= 0) {
    stop("'", name, "['by']' must be > 0.", call. = FALSE)
  }

  if (x_max < x_min) {
    stop(
      "'", name, "['max']' must be >= '", name, "['min']'.",
      call. = FALSE
    )
  }

  values <- seq(from = x_min, to = x_max, by = x_by)

  if (length(values) == 0L) {
    stop("'", name, "' generated an empty parameter sequence.", call. = FALSE)
  }

  values
}


.ctool_calibration_update_soil <- function(
    soil_config,
    f_hum_top,
    k_hum,
    f_fom_top
) {

  .ctool_calibration_check_numeric_scalar(f_hum_top, "f_hum_top")
  .ctool_calibration_check_numeric_scalar(k_hum, "k_hum")
  .ctool_calibration_check_numeric_scalar(f_fom_top, "f_fom_top")

  f_rom_top <- 1 - f_hum_top - f_fom_top

  if (f_rom_top <= 0) {
    stop(
      "Invalid parameter combination: 'f_rom_top' is <= 0.",
      call. = FALSE
    )
  }

  soil_new <- soil_config

  soil_new$f_hum_top <- f_hum_top
  soil_new$k_hum <- k_hum
  soil_new$f_rom_top <- f_rom_top

  soil_new
}


.ctool_calibration_run_simulation <- function(
    time_config,
    cinput_config,
    temperature_config,
    management_config,
    soil_config,
    cn_init
) {

  pools <- initialize_soil_pools(cn_init, soil_config)
  pools <- c(pools[[1]], pools[[2]])

  sim <- run_ctool(
    time_config,
    cinput_config,
    management_config,
    temperature_config,
    soil_config,
    pools,
    FALSE
  )

  sim <- as.data.frame(sim)

  if (!"yrs" %in% names(sim)) {
    stop("The C-TOOL output must contain a column named 'yrs'.", call. = FALSE)
  }

  if (!"C_topsoil" %in% names(sim)) {
    stop(
      "The C-TOOL output must contain a column named 'C_topsoil'.",
      call. = FALSE
    )
  }

  yrs <- sort(unique(sim$yrs))

  out <- data.frame(
    yrs = yrs,
    SOC = NA_real_
  )

  for (i in seq_along(yrs)) {
    out$SOC[i] <- mean(sim$C_topsoil[sim$yrs == yrs[i]], na.rm = TRUE)
  }

  out$Year <- out$yrs + 1L

  out[, c("Year", "yrs", "SOC")]
}
