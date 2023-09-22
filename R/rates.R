
decay <- function(amount_t, k, tempCoefficient ){
  amount = amount_t * (-k * tempCoefficient)
  amount
}

hum_coef <- function(clayfrac) {

  R= 1.67 * (1.85 + 1.6 * exp(-7.86 * clayfrac))

  h= 1/(R+1)

  h
}


