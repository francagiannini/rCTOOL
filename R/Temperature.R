#' TODO: add function to scrape temp data by coordinate


#' prepare_temperature
#'
#' @param filepath 
#' @param Tavg_col 
#' @param Trange_col 
#' @param default_Trange 
#'
#' @return
#' @export
#'
#' @examples
prepare_temperature = function(filepath,
                               Tavg_col='Tavg',
                               Trange_col=NULL,
                               default_Trange=15) {
  
  if (grepl('csv',filepath)==F) {stop('Please use a csv file.') }
  file = read.csv(filepath)
  
  if (missing(Trange_col)==T) { 
    Trange_col = 'Trange'
    file[,Trange_col] = default_Trange 
  }
  return(list(
    Tavg = file[,Tavg_col],
    Trange_col=file[,Trange_col]
  ))
}
