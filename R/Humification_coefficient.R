#' hum_coef
#' humification coefficient
#' @param f_clay fraction of clay in soil
#'
#' @return
#'
#' @examples
.hum_coef = function(f_clay) {
  
  R= 1.67 * (1.85 + 1.6 * exp(-7.86 * f_clay))
  return(1/(R+1))
}