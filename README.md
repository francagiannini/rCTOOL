
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rCTOOL

<!-- badges: start -->
<!-- badges: end -->

rCTOOL is an open-source R package, that encapsulates the capabilities
of C-TOOL (Petersen, Olesen, and Heidmann 2002; Taghizadeh-Toosi et al.
2014) while addressing its implementation limitations. The aim consists
of providing a user-friendly interface, facilitates running multiple
scenarios, and offers comprehensive documentation and licensing
information. This package streamlines the use of C-TOOL, making it more
accessible and effective for potential users.

<img src="man/figures/rCTOOLicon.jpg" width="50%" style="display: block; margin: auto;" />

## Installation

You can install the development version of rCTOOL from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("francagiannini/rCTOOL")
```

## Basic toy example

This is a simple example of the potential use of rCTOOL. The example
corresponds to one of the treatments presented by (Jensen et al. 2021)
and (Jensen et al. 2022) containing the C inputs for the treatment of
the spring barley crop with 4 DM Mg/ha straw incorporated into the soil
at a long-term experimental station Askov, Denmark.

``` r
library(rCTOOL)
library(tidyverse)

# load data ----
data('basic_example')
data('scenario_temperature') # this is equivalent to set_monthly_temperature_data(coords=c(9.114015, 55.47163), yr_start=1951, yr_end=2019)
```

Below the basic_example and temperature data sets are exemplified.

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

It is mandatory to define the time period, Carbon inputs (from manure
and/or plant), Management (months where the inputs are applied) and soil
configurations as well as temperature.

In this basic example, the temperature was already exported using the
package “easyclimate” for 1951-2019; basic_example contains the annual C
inputs from manure and plants, as well as their respective monthly
allocations.

``` r
# define timeperiod 
period <- define_timeperiod(yr_start = 1951, yr_end = 2019)

# get annual Carbon inputs 
cin <- define_Cinputs(management_filepath = basic_example)

# get management 
management <- management_config(management_filepath = basic_example, f_man_humification = 0.192)

# get soil configuration 
soil <- soil_config(Csoil_init = 105, # Initial C stock at 1m depth
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
soil_pools <- initialize_soil_pools(cn = 12, soil_config = soil)
```

We can now start the monthly simulation. The verbose argument, currently
set to FALSE, provides a check mass-balance to ensure the model is
working correctly. \[Note to improve the mass balance, currently wrong\]

``` r
# run rCTOOL
output <- run_ctool(time_config = period,
                   cin_config = cin,
                   m_config = management,
                   t_config = scenario_temperature,
                   s_config = soil,
                   soil_pools = soil_pools,
                   verbose = F)
```

We can plot the results.

``` r
output |>
  mutate(time=make_date(year =yrs,month=mon)) |>
  ggplot(aes(x=time,y=C_topsoil))+
  geom_line()+
  geom_smooth()+
  theme_classic()
```

<img src="man/figures/README-pressure-1.png" width="100%" />

## Comparing multiple scenario toy example

Aiming to show how to run and compare multiple scenarios, we have set
ourselves the following challenge:

We have inherited an old field where cereals have been grown for many
many years and we want to increase C in Soil. We need to choose between…

- Creating a football pitch for students at AU Viborg recreation.

- Starting an organic dairy farm.

- Establishing a municipal (kommunal) pet cemetery…

<img src="man/figures/openhousefigure.jpg" width="100%" />

Loading scenario management data for the there options.

``` r
# load data ----
data('scenario')
data('scenario_temperature') # this is equivalent to set_monthly_temperature_data(coords=c(9.114015, 55.47163), yr_start=1951, yr_end=2019)
```

The scenario data set contains three different C input estimation for
the different scenarios:

For the football court scenario we assume a well-maintained stomped
ryegrass cover,

for the organic dairy farming we assume a crop rotation with grass,
maize and cereals for happy milking cows,

and finally for the pet cemetery we assume a less healthily reygrass and
a certain number of beloved dogs and cats from Viborg municipality
burred in the subsoil.

Now we will play with rCTOOL to explore the implications in terms of
soil C dynamics.

First lets take a look on the C inputs distribution:

    #> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    #> ℹ Please use `linewidth` instead.
    #> This warning is displayed once every 8 hours.
    #> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    #> generated.

<img src="man/figures/README-unnamed-chunk-10-1.png" width="100%" />

Then we provide a simulation parameters to the different modules time
period, management, soil parameters and pools initial distribution.

``` r
period <-  define_timeperiod(yr_start = 1951, yr_end = 2019)

management <- management_config(
  manure_monthly_allocation = c(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  plant_monthly_allocation = c(0, 0, 0, 8, 12, 16, 64, 0, 0, 0, 0, 0) / 100
) # set to default

soil <- soil_config(Csoil_init = 100,
                   f_hum_top = 0.4803,
                   f_rom_top = 0.4881,
                   f_hum_sub = 0.3123,
                   f_rom_sub = 0.6847,
                   Cproptop = 0.47,
                   clay_top = 0.1,
                   clay_sub = 0.15,
                   phi = 0.035,
                   f_co2 = 0.628,
                   f_romi = 0.012,
                   k_fom  = 0.12,
                   k_hum = 0.0028, 
                   k_rom = 3.85e-5,
                   ftr = 0.003)

soil_pools <- initialize_soil_pools(cn = 10, soil_config = soil)
```

Then we provide configuration for running each of the three
treatment/scenarios.

``` r
treatment <- unique(scenario$treatment)
cin_treatment <- lapply(treatment, function(x) { define_Cinputs(management_filepath = subset(scenario, treatment==x)) })
names(cin_treatment) <- treatment
```

Finally we run the simulation for each treatment/scenario.

``` r
output_treatment <- lapply(treatment, function(x) {
  output <- run_ctool(time_config = period, 
            cin_config = cin_treatment[[x]], 
            m_config = management, 
            t_config = scenario_temperature, 
            s_config = soil, 
            soil_pools = soil_pools)
  output$treatment = x
  return(output)
})

output_treatment <- data.table::rbindlist(output_treatment)
```

And the winning one is…

Lets explore:

<img src="man/figures/README-unnamed-chunk-14-1.png" width="100%" />

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-jensen22" class="csl-entry">

Jensen, Johannes L., Jørgen Eriksen, Ingrid K. Thomsen, Lars J.
Munkholm, and Bent T. Christensen. 2022. “Cereal Straw Incorporation and
Ryegrass Cover Crops: The Path to Equilibrium in Soil Carbon Storage Is
Short.” Journal Article. *European Journal of Soil Science* 73 (1).
<https://doi.org/10.1111/ejss.13173>.

</div>

<div id="ref-jensen21" class="csl-entry">

Jensen, Johannes L., Ingrid K. Thomsen, Jørgen Eriksen, and Bent T.
Christensen. 2021. “Spring Barley Grown for Decades with Straw
Incorporation and Cover Crops: Effects on Crop Yields and n Uptake.”
Journal Article. *Field Crops Research* 270.
<https://doi.org/10.1016/j.fcr.2021.108228>.

</div>

<div id="ref-petersen1ctool" class="csl-entry">

Petersen, Bjørn M., Jørgen E. Olesen, and Tove Heidmann. 2002. “A
Flexible Tool for Simulation of Soil Carbon Turnover.” Journal Article.
[www.elsevier.com/locate/ecolmodel](https://www.elsevier.com/locate/ecolmodel).

</div>

<div id="ref-tagctool2" class="csl-entry">

Taghizadeh-Toosi, Arezoo, Bent T. Christensen, Nicholas J. Hutchings,
Jonas Vejlin, Thomas Kätterer, Margaret Glendining, and Jørgen E.
Olesen. 2014. “C-TOOL: A Simple Model for Simulating Whole-Profile
Carbon Storage in Temperate Agricultural Soils.” Journal Article.
*Ecological Modelling* 292: 11–25.
https://doi.org/<https://doi.org/10.1016/j.ecolmodel.2014.08.016>.

</div>

</div>
