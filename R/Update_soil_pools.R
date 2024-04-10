#' .clean_monthly_allocations
#'
#' @param m_config management config
#'
#'  @description
#'  Reads management config with monthly allocations (plant, grain/grass)
#'  Depending on the user specifications, adapts the management config:
#'  (i) if user specifies plant, grain and grass allocations, recalculate plant allocation (sum of grain and grass)
#'  (ii) if only one allocation is given, see whether it is plant (no crop rotation), provides user with a confirmation message
#'  (iii) if two allocation are given, confirm these match crop rotation (grass/grain), otherwise stop
#'
#' @return
#' Returns only plant monthly allocation irrespective of user input; this will be read with fucntions bellow
#'
#' @examples
.clean_monthly_allocations = function(m_config) {

  allocation_params = c('plant_monthly_allocation','grain_monthly_allocation','grass_monthly_allocation')

  # remove empty indexes
  m_config = m_config[lapply(m_config,length)>0]

  # store index names
  idx_name = names(m_config)

  # set conditions
  len_cond = length(which(allocation_params %in% idx_name))

  if (len_cond == 3) {
    # if len == 3, add grain and grass monthly allocation
    m_config$plant_monthly_allocation = m_config$grain_monthly_allocation + m_config$grass_monthly_allocation
    m_config$grain_monthly_allocation = NULL; m_config$grass_monthly_allocation = NULL
  }
  else if (len_cond == 1) {
    # if len == 1, set that to plant allocation; if different than plant, provide message confirming highlighting input data given
    selected_param = allocation_params[which(c(allocation_params %in% idx_name))]
    if (selected_param != 'plant_monthly_allocation') {
      menu(c('Yes','No'), title='You selected a possible crop rotation yet only chose one out of two. This is going to be assumed as plant allocation.\nDo you want this?')
    }
    m_config$plant_monthly_allocation = m_config[[selected_param]]
  }
  else if (len_cond == 2) {
    # if len == 2, check if it is grain and grass, if it is, add those fractions, otherwise stop
    selected_params = allocation_params[which(c(allocation_params %in% idx_name))]

    if (length(which('grain_monthly_allocation','grass_monthly_allocation' %in% selected_params))==2) {
      m_config$plant_monthly_allocation = m_config$grain_monthly_allocation + m_config$grass_monthly_allocation
      m_config$grain_monthly_allocation = NULL; m_config$grass_monthly_allocation = NULL
    }
    else {
      stop('You specified a crop rotation, please either select grain and grass allocation OR plant allocation if you no rotation is given')
    }
  }
  return(m_config)
}

#' update_FOM_top
#'
#' @param FOM_top_t1
#' @param Cin_plant
#' @param Cin_manure
#' @param month
#' @param m_config management configuration list
#'
#' @return
#' @export
#'
#' @examples
update_monthly_FOM_top = function(FOM_top_t1,
                                  Cin_plant_top,
                                  Cin_manure,
                                  month,
                                  m_config) {



  return(
    FOM_top_t1 +
      Cin_plant_top * m_config[['plant_monthly_allocation']][month] +
      Cin_manure * (1-m_config[['f_man_humification']])*m_config[['manure_monthly_allocation']][month]
  )
}

#' updated_monthly_FOM_sub
#'
#' @param FOM_sub_t1
#' @param FOM_transport
#' @param C_in_plant_sub
#' @param month
#' @param m_config
#'
#' @return
#' @export
#'
#' @examples
update_monthly_FOM_sub = function(FOM_sub_t1,
                                  FOM_transport,
                                  C_in_plant_sub,
                                  month,
                                  m_config) {

  return(FOM_sub_t1 + FOM_transport +
           C_in_plant_sub * m_config[['plant_monthly_allocation']][month])
}

#' update_monthly_HUM_top
#'
#' @param HUM_top_t1
#' @param C_in_man
#' @param FOM_humified_top
#' @param month
#' @param m_config
#'
#' @return
#' @export
#'
#' @examples
update_monthly_HUM_top = function(HUM_top_t1,
                                  C_in_man,
                                  FOM_humified_top,
                                  month,
                                  m_config) {

  return(HUM_top_t1 +
           FOM_humified_top +
           C_in_man * m_config[['f_man_humification']] * m_config[['manure_monthly_allocation']][month])
}

#' update_monthly_HUM_sub
#'
#' @param HUM_sub_t1
#' @param HUM_transport
#' @param FOM_humified_sub
#'
#' @return
#' @export
#'
#' @examples
update_monthly_HUM_sub = function(HUM_sub_t1,
                                  HUM_transport,
                                  FOM_humified_sub) {

  return(HUM_sub_t1 + HUM_transport + FOM_humified_sub)
}

#' update_monthly_ROM_top
#'
#' @param ROM_top_t1
#' @param HUM_romified_top
#'
#' @return
#' @export
#'
#' @examples
update_monthly_ROM_top = function(ROM_top_t1,
                                  HUM_romified_top) {

  return(ROM_top_t1 + HUM_romified_top)
}

#' update_monthly_ROM_sub
#'
#' @param ROM_sub_t1
#' @param HUM_romified_sub
#' @param ROM_transport
#'
#' @return
#' @export
#'
#' @examples
update_monthly_ROM_sub = function(ROM_sub_t1,
                                  HUM_romified_sub,
                                  ROM_transport) {

  return(ROM_sub_t1 + HUM_romified_sub + ROM_transport)
}


