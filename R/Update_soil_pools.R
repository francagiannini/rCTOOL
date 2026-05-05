#' .clean_monthly_allocations
#'
#' Clean and harmonize monthly allocation inputs.
#'
#' Reads management configuration with monthly allocation vectors and
#' returns a configuration containing `plant_monthly_allocation`.
#'
#' Depending on the user input:
#' - if plant, grain and grass allocations are all provided, plant
#'   allocation is recalculated as grain plus grass
#' - if only one allocation is provided, it is treated as plant allocation
#' - if two allocations are provided, they must correspond to grain and
#'   grass; otherwise an error is returned
#'
#' @param m_config Management configuration list.
#'
#' @return A management configuration list containing
#'   `plant_monthly_allocation`.
.clean_monthly_allocations <- function(m_config) {

  allocation_params <- c(
    "plant_monthly_allocation",
    "grain_monthly_allocation",
    "grass_monthly_allocation"
  )

  m_config <- m_config[lapply(m_config, length) > 0]
  idx_name <- names(m_config)

  len_cond <- length(which(allocation_params %in% idx_name))

  if (len_cond == 3) {
    m_config$plant_monthly_allocation <-
      m_config$grain_monthly_allocation + m_config$grass_monthly_allocation
    m_config$grain_monthly_allocation <- NULL
    m_config$grass_monthly_allocation <- NULL
  } else if (len_cond == 1) {
    selected_param <- allocation_params[allocation_params %in% idx_name]

    if (selected_param != "plant_monthly_allocation") {
      warning(
        "Only one allocation vector was provided and it was not ",
        "'plant_monthly_allocation'. This input is being treated as ",
        "plant allocation."
      )
    }

    m_config$plant_monthly_allocation <- m_config[[selected_param]]
  } else if (len_cond == 2) {
    selected_params <- allocation_params[allocation_params %in% idx_name]

    if (all(c("grain_monthly_allocation", "grass_monthly_allocation") %in% selected_params)) {
      m_config$plant_monthly_allocation <-
        m_config$grain_monthly_allocation + m_config$grass_monthly_allocation
      m_config$grain_monthly_allocation <- NULL
      m_config$grass_monthly_allocation <- NULL
    } else {
      stop(
        "You specified two allocation vectors, but these do not match a ",
        "grain/grass rotation. Please provide either 'plant_monthly_allocation' ",
        "or both 'grain_monthly_allocation' and 'grass_monthly_allocation'."
      )
    }
  }

  m_config
}

#' update_monthly_FOM_top
#'
#' @param FOM_top_t1 FOM content in the topsoil layer from the previous timestep.
#' @param Cin_plant_top Plant carbon input to the topsoil.
#' @param Cin_manure Manure carbon input.
#' @param month Month index from 1 to 12.
#' @param m_config Management configuration list.
#'
#' @return Updated FOM content in the topsoil layer after monthly carbon inputs.
#' @export
update_monthly_FOM_top <- function(FOM_top_t1,
                                   Cin_plant_top,
                                   Cin_manure,
                                   month,
                                   m_config) {

  FOM_top_t1 +
    Cin_plant_top * m_config[["plant_monthly_allocation"]][month] +
    Cin_manure * (1 - m_config[["f_man_humification"]]) *
    m_config[["manure_monthly_allocation"]][month]
}

#' update_monthly_FOM_sub
#'
#' @param FOM_sub_t1 FOM content in the subsoil layer from the previous timestep.
#' @param FOM_transport FOM transported from the topsoil.
#' @param C_in_plant_sub Plant carbon input to the subsoil.
#' @param month Month index from 1 to 12.
#' @param m_config Management configuration list.
#'
#' @return Updated FOM content in the subsoil layer after plant inputs and
#' transport from the topsoil.
#' @export
update_monthly_FOM_sub <- function(FOM_sub_t1,
                                   FOM_transport,
                                   C_in_plant_sub,
                                   month,
                                   m_config) {

  FOM_sub_t1 + FOM_transport +
    C_in_plant_sub * m_config[["plant_monthly_allocation"]][month]
}

#' update_monthly_HUM_top
#'
#' @param HUM_top_t1 HUM content in the topsoil layer from the previous timestep.
#' @param C_in_man Manure carbon input.
#' @param FOM_humified_top Humified FOM added to the topsoil HUM pool.
#' @param month Month index from 1 to 12.
#' @param m_config Management configuration list.
#'
#' @return Updated HUM content in the topsoil layer after manure inputs and
#' humified FOM additions.
#' @export
update_monthly_HUM_top <- function(HUM_top_t1,
                                   C_in_man,
                                   FOM_humified_top,
                                   month,
                                   m_config) {

  HUM_top_t1 +
    FOM_humified_top +
    C_in_man * m_config[["f_man_humification"]] *
    m_config[["manure_monthly_allocation"]][month]
}

#' update_monthly_HUM_sub
#'
#' @param HUM_sub_t1 HUM content in the subsoil layer from the previous timestep.
#' @param HUM_transport HUM transported from the topsoil.
#' @param FOM_humified_sub Humified FOM added to the subsoil HUM pool.
#'
#' @return Updated HUM content in the subsoil layer after transport and
#' humified FOM additions.
#' @export
update_monthly_HUM_sub <- function(HUM_sub_t1,
                                   HUM_transport,
                                   FOM_humified_sub) {

  HUM_sub_t1 + HUM_transport + FOM_humified_sub
}

#' update_monthly_ROM_top
#'
#' @param ROM_top_t1 ROM content in the topsoil layer from the previous timestep.
#' @param HUM_romified_top Romified HUM added to the topsoil ROM pool.
#'
#' @return Updated ROM content in the topsoil layer after romified HUM additions.
#' @export
update_monthly_ROM_top <- function(ROM_top_t1,
                                   HUM_romified_top) {

  ROM_top_t1 + HUM_romified_top
}

#' update_monthly_ROM_sub
#'
#' @param ROM_sub_t1 ROM content in the subsoil layer from the previous timestep.
#' @param HUM_romified_sub Romified HUM added to the subsoil ROM pool.
#' @param ROM_transport ROM transported from the topsoil.
#'
#' @return Updated ROM content in the subsoil layer after romified HUM additions
#' and transport from the topsoil.
#' @export
update_monthly_ROM_sub <- function(ROM_sub_t1,
                                   HUM_romified_sub,
                                   ROM_transport) {

  ROM_sub_t1 + HUM_romified_sub + ROM_transport
}
