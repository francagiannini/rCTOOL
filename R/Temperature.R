#' convert_day_to_monthly_temperatures
#'
#' @param file either filepath or a dataframe containing the temperature data
#'
#' @description
#' reads file, identify whether file is a filepath or a dataframe containing the daily temperature data
#' calculates monthly mean Tmax, Tmin, Tavg as well as temperature range
#'
#' @return data.frame containing monthly temperatures as well as temperature range for a given daily temperature data
#' @export
#'
#' @examples convert_day_to_monthly_temperatures(file=temperature_df)
convert_day_to_monthly_temperatures = function(file) {

  # identify class of arg file; if it is character assume it is a filepath to be read, otherwise if it is a dataframe, move on
  if (class(file)=='character') {
    if (grepl('csv',file)==F) {stop('Please use a csv file.') }
    file = read.csv(file)
  }
  else {
    if (class(file) != 'data.frame') { stop('Argument "file" can be either a filepath to the temperature csv or it can directly be the temperature data.frame')}
  }

  if (length(which(names(file) %in% c('Tmax','Tmin','Tmax')))==0) { stop('File must have at least two columns named Tmax and Tmin and/or Tavg.')}
  if (length(which(names(file) %in% 'date'))==0) { stop('Temperature dates must be recorded in column named date with a YYYY-MM-DD format')}

  # identify months and years from YYYY-MM-DD
  file$month = as.numeric(substr(file$date, 6,7))
  file$yr =  as.numeric(substr(file$date, 1,4))

  # check if file has Tavg, if not contained in file calculate it
  if (length(which(names(file) %in% 'Tavg'))==0) { file$Tavg = (file$Tmax+file$Tmin)/2  }

  return(file |>
           group_by(month, yr) |>
           summarize(Tavg = mean(Tavg),
                     Tmin = mean(Tmin),
                     Tmax = mean(Tmax)) |>
           mutate(Range=Tmax-Tmin) |>
           arrange(yr, month))
}


#' populate_temperature
#'
#' @param coords vector of longitude and latitude
#' @param start starting date, can be a year or a date (YYYY-MM-DD)
#' @param end ending date, can be a year or a date (YYYY-MM-DD)
#'
#' @description
#' retrieves daily temperature data for specified coordinates and simulation period, computes average monthly temperatures as well as temperature range
#' @note Conditions like user specifying a date less than 1 month is not highlighted
#' @return dataframe with coordinates, month, year, average temperatures and temperature range
#' @export
#'
#' @examples populate_temperature(coords=c(9.114015,55.47163), yr_start=2006, yr_end=2010)
populate_temperature = function(coords = c(9.114015,55.47163),
                                yr_start,
                                yr_end) {

  # period arg changes the period input to easyclimate to whether user specifies a date or a year
  if (class(yr_start)=='numeric') { period_arg = yr_start:yr_end } else { period_arg = paste0(yr_start,':',yr_end) }

  # get daily data from easilyclimate
  temp_df = easyclimate::get_daily_climate(data.frame(lon=coords[1] , lat=coords[2]),
                                           period = period_arg,
                                           climatic_var = c('Tmax','Tmin'),
                                           version = 4)

  # compute monthl data
  month_temp_df = convert_day_to_monthly_temperatures(file = temp_df)

  return(month_temp_df)
}


#' set_monthly_temperature_data
#'
#' @param file either filepath or a dataframe containing the temperature data
#' @param ... user can specify different arguments, see description
#' @param coords vector of longitude and latitude
#' @param start starting date, can be a year or a date (YYYY-MM-DD)
#' @param end ending date, can be a year or a date (YYYY-MM-DD)
#' @param Tavg numeric vector containing average monthly temperature; caution because it needs to match the number of timesteps
#' @param Range numeric vector containing  monthly temperature ranges; caution because it needs to match the number of timesteps
#'
#' @description
#' User can specify temperature data based on 3 approaches
#' Approach 1 - directly specify a filepath or dataframe with temperature data by using the argument "file"
#' Approach 2 - if the user does not have temperature data, coordinates and simulation period can be specified using the arguments "coords", "yr_start", "yr_end"
#' Approach 3 - User can directly specify Average temperature and range in vectors using the argumemnts "Tavg" and "Range"
#' @return dataframe with at least average temperature and temperature range, can include month and years, depending on approach
#' @export
#'
#' @examples set_monthly_temperature_data(file=df_temp)
#' @examples set_monthly_temperature_data(coords = c(9.114015,55.47163), yr_start=2006, yr_end=2010)
#' @examples set_monthly_temperature_data(coords = c(9.114015,55.47163), yr_start='2006-01-01, yr_end='2010-01-01')
#' @examples set_monthly_temperature_data(coords = c(9.114015,55.47163), yr_start='2006-01-01, yr_end='2008-06-01')
#' @examples set_monthly_temperature_data(Tavg = c(5,6,7,8,9,15,14,11,10,9,5,1), Range = c(3.5,5.5,6,6.5,12,6,4.4,8.8,11.1,13.1,6.6))
set_monthly_temperature_data = function(file=NULL,
                                        ...) {

  if (missing(file)==T) {
    #  identify user specified arguments
    args = match.call(expand.dots = FALSE)$...

    if (length(names(args) %in% c('coords','yr_start','yr_end'))==3) {
      return(populate_temperature(coords, yr_start, yr_end))
    }
    else if (length(names(args) %in% c('Tavg','Range'))==2) {
      return(data.frame(Tavg=Tavg, Range=Range))
    }
  }

  else {
    # identify class of arg file; if it is character assume it is a filepath to be read, otherwise if it is a dataframe, move on
    if (class(file)=='character') {

      if (grepl('csv',filepath)==F) {stop('Please use a csv file.') }
      temp_df = read.csv(filepath)
    }
    else {

      if (class(file) != 'data.frame') { stop('Argument "file" can be either a filepath to the temperature csv or it can directly be the temperature data.frame')}
    }

    if (length(which(names(file) %in% c('Tavg','Range')))!=2) {stop('Make sure monthly temperature date contains Tavg and (temperature)Range.\nSee helper functions')}
  }
}
