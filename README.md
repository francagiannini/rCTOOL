
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rCTOOL

<!-- badges: start -->
<!-- badges: end -->

rCTOOL is an open-source R package, that encapsulates the capabilities
of C-TOOL while addressing its implementation limitations. The aim
consists of providing a user-friendly interface, facilitates running
multiple scenarios, and offers comprehensive documentation and licensing
information. This package streamlines the use of C-TOOL, making it more
accessible and effective for potential users

## Installation

You can install the development version of rCTOOL from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("francagiannini/rCTOOL")
```

## Basic example

This is a basic example that showcases the potential use of rCTOOL. This
is illustrated with samples from the Askov long-term trials in Denmark.

``` r
library(rCTOOL)
library(tidyverse)

# load data ----
data('basic_example')
data('scenario_temperature') # this is equivalent to set_monthly_temperature_data(coords=c(9.114015, 55.47163), yr_start=1951, yr_end=2019)
```

Below the basic_example and temperature datasets are exemplified.

``` r
head(basic_example, 2)
#>   mon  yrs id year Cin_top Cin_sub Cin_man manure_monthly_allocation
#> 1   1 1951  1 1951   3.566    0.39       0                         0
#> 2   2 1951  1 1952   3.566    0.39       0                         0
#>   plant_monthly_allocation
#> 1                        0
#> 2                        0
```

``` r
head(scenario_temperature, 2)
#> # A tibble: 2 × 6
#> # Groups:   month [2]
#>   month    yr  Tavg   Tmin  Tmax Range
#>   <dbl> <dbl> <dbl>  <dbl> <dbl> <dbl>
#> 1     1  1951  0.89 -0.7    2.48  3.18
#> 2     2  1951  1.17 -0.251  2.59  2.84
```

It is mandatory to define the timeperiod, Carbon inputs (from manure
and/or plant), Management (months where the inputs are applied) and soil
configurations as well as temperature. In this basic example, the
temperature was already exported using the package “easyclimate” for
1951-2019; basic_example contains the annual C inputs from manure and
plants, as well as their respective monthly allocations.

``` r
# define timeperiod 
period = define_timeperiod(yr_start = 1951, yr_end = 2019)

# get annual Carbon inputs 
cin = define_Cinputs(management_filepath = basic_example)

# get management 
management = management_config(management_filepath = basic_example, f_man_humification = 0.192)

# get soil configuration 
soil = soil_config(Csoil_init = 105, # Initial C stock at 1m depth
                   f_hum_top =  0.533,
                   f_rom_top =  0.405,
                   f_hum_sub =  0.387,
                   f_rom_sub =  0.610,
                   Cproptop = 0.55, # landmarkensite report askov
                   clay_top = 0.11,
                   clay_sub = 0.20,
                   phi = 0.035,
                   f_co2 = 0.628,
                   f_romi = 0.012,
                   k_fom  = 0.12,
                   k_hum = 0.0028,
                   k_rom = 3.85e-5,
                   ftr = 0.0025)
```

We also need to initialize soil pools before the simulation starts.
Initial soil pools depend on the Carbon:Nitrogen ratio, the humification
and romification fractions in top- and subsoils as well as the initial C
stock.

``` r
# initialize soil pools
soil_pools = initialize_soil_pools(cn = 12, soil_config = soil)
```

We can now start the monthly simulation. The verbose argument, currently
set to FALSE, provides a check mass-balance to ensure the model is
working correctly. \[Note to improve the mass balance, currently wrong\]

``` r
# run rCTOOL
output = run_ctool(time_config = period,
                   cin_config = cin,
                   m_config = management,
                   t_config = scenario_temperature,
                   s_config = soil,
                   soil_pools = soil_pools,
                   verbose = F)
```

We can plot the results.
<img src="man/figures/README-pressure-1.png" width="100%" />
