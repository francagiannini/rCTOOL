Example 1 (in development)

library(rCTOOL)

# load data ----
data('scenario')
data('scenario_temperature') # set_monthly_temperature_data(coords=c(9.114015, 55.47163), yr_start=1951, yr_end=2019)

# define timeperiod ----
period = define_timeperiod(yr_start = 1951, yr_end = 2019)

# management ----
cin = define_Cinputs(management_filepath = scenario)

management = management_config(
  f_man_humification = 0.192,
  manure_monthly_allocation = c(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  plant_monthly_allocation = c(0, 0, 0, 8, 12, 16, 64, 0, 0, 0, 0, 0)
)

# soil ----
# Initial C stock at 1m depth
Cinit_ask_sr = 1.51*25*1.54 + # 0-25 data from 1981
  0.8*1.55*25 + # 25-50 # Bulk density aand C% from landmarkensite report askov
  0.2*1.6*50  # 50-100 # Bulk density aand C% from landmarkensite report askov
# Proportion of the total C allocated in topsoil
Cproptop = 1.51*25*1.54 / Cinit_ask_sr 

soil = soil_config(Csoil_init = Cinit_ask_sr, # Initial C stock at 1m depth
                   f_hum_top =  0.533,#
                   f_rom_top =  0.405,#
                   f_hum_sub =  0.387,#
                   f_rom_sub =  0.610,#
                   Cproptop = Cproptop, # landmarkensite report askov
                   clay_top = 0.11,
                   clay_sub = (0.11*15+0.21*25+0.22*40)/80,
                   phi = 0.035,
                   f_co2 = 0.628,
                   f_romi = 0.012,
                   k_fom  = 0.12,
                   k_hum = 0.0028,
                   k_rom = 3.85e-5,
                   ftr = 0.0025
)
# initialize soil pools
soil_pools = initialize_soil_pools(cn = 1.51/0.126,soil_config = soil)

# simulation ----

output = run_ctool(time_config = period,
                   cin_config = cin,
                   m_config = management,
                   t_config = scenario_temperature,
                   s_config = soil,
                   soil_pools = soil_pools, 
                   verbose = T)

output |>
  mutate(time=make_date(year =yrs,month=mon)) |>
  ggplot(aes(x=time,y=C_topsoil))+
  geom_line()+
  geom_smooth()
