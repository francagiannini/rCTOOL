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
#' @return The arguments are: cn;HUM_frac;C_0
#' @export
#' @examples
#' pool_cn(cn=12,HUM_frac = 0.33, C_0=75)
#' pool_cn(cn=8,HUM_frac = 0.33, C_0=75)

# fCN <- function(cn, ROM) {
#   CNfraction = min(56.2 * cn ^ (-1.69), 1) }

# pool_cn <- function(cn,
#                     HUM_frac,
#                     C_0) {
#   CNfraction = min(56.2 * cn ^ (-1.69), 1)
#
#   HUM = C_0 * HUM_frac * CNfraction
#   ROM = C_0 - HUM
#
#   c("FOM"=0,"HUM"=HUM,"ROM"=ROM)
# }


pool_cn <- function(cn,
                    HUM_frac,
                    ROM_frac,
                    C_0) {
  CNfraction = min(56.2 * cn ^ (-1.69), 1)

  FOM = 1-HUM_frac-ROM_frac
  HUM = C_0 * HUM_frac * CNfraction
  ROM = C_0 -HUM- FOM

  c("FOM"=FOM,"HUM"=HUM,"ROM"=ROM)
}

pool_cn

#' C input calculation
#'
#' Simple allometrics function to estimates of C input to the soil from information of yield
#'amounts. Calculations of total C (Mg/ha) deposited in top and sub soil
#'
#' @return The arguments are:
#' @export
#' @examples

allo <- function(yield_MC,
                 yield_CC,
                 C_manure,
                 HI,
                 SB,
                 RE,
                 RB,
                 Ccont=0.43) {

  Cresid = as.numeric(((1 / HI) - 1 - SB) * (yield_MC * Ccont))
  Cresid_cc = as.numeric(((1 / HI) - 1 - SB) * (yield_CC * Ccont))

  Cbelow = as.numeric((RB / ((1 - RB) * HI)) * (yield_MC * Ccont))
  Cbelow_cc = as.numeric((RB / ((1 - RB) * HI)) * (yield_CC * Ccont))

  Ctop = ifelse(Cresid < 0, 0 + (RE * Cbelow), Cresid + (RE * Cbelow))
  ifelse(Cresid_cc < 0, 0 + (RE * Cbelow_cc), Cresid_cc + (RE * Cbelow_cc))

  Csub = (1 - RE) * Cbelow + (1 - RE) * Cbelow_cc

  Cman = C_manure

  c(Ctop, Csub, Cman)
}

allo
