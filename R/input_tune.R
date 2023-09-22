

# fCN <- function(cn, ROM) {
#   CNfraction = min(56.2 * cn ^ (-1.69), 1) }

pool_cn <- function(cn, HUM_frac, C_0) {
  CNfraction = min(56.2 * cn ^ (-1.69), 1)

  HUM = C_0 * HUM_frac * CNfraction
  ROM = C_0 - HUM

  c(HUM,ROM)
}


allo <- function(HI, SB, RE, RB, yield_MC, yield_CC) {

  Cresid = as.numeric(((1 / HI) - 1 - SB) * (yield_MC * 0.43))
  Cresid_cc = as.numeric(((1 / HI) - 1 - SB) * (yield_CC * 0.43))

  Cbelow = as.numeric((RB / ((1 - RB) * HI)) * (yield_MC * 0.43))
  Cbelow_cc = as.numeric((RB / ((1 - RB) * HI)) * (yield_CC * 0.43))

  Ctop = ifelse(Cresid < 0, 0 + (RE * Cbelow), Cresid + (RE * Cbelow))
  ifelse(Cresid_cc < 0, 0 + (RE * Cbelow_cc), Cresid_cc + (RE * Cbelow_cc))

  Csub = (1 - RE) * Cbelow + (1 - RE) * Cbelow_cc

  Cman = C_manure

  c(Ctop, Csub, Cman)
}
