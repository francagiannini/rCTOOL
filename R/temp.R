

soil_temp <-
  function(depth,
           month,
           T_ave = temp_m,
           A_0 = temp_amp,
           th_diff) {
    #function(j) {
    browser()
    # depth in meters#

    z = depth / 2 * 0.01

    #temporal position in daily bases setted as the last day of each month

    t = month

    #angular frequency
    # here the cycle is daily, for secondly cycles (365 * 24 * 3600)

    rho <-
      pi * 2 / 365 #as.numeric(j["daysinmonth"]) #/30#


    # Damping depth here in m
    D <- sqrt(2 * th_diff / rho)

    # Soil temperature at t days and z depth in m Montein and Unsworth
    T_zt <-
      T_ave + A_0 * exp(-z / D) * sin(rho * t - z / D)

    T_zt

  }


# temp coefficient uniti at 10 C¤

temp_coef <-
  function(T_zt) {
  7.24 * exp(-3.432 + 0.168 * T_zt * (1 - 0.5 * T_zt / 36.9))

}
