% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Temperature.R
\name{populate_temperature}
\alias{populate_temperature}
\title{populate_temperature}
\usage{
populate_temperature(coords = c(9.114015, 55.47163), yr_start, yr_end)
}
\arguments{
\item{coords}{vector of longitude and latitude}

\item{start}{starting date, can be a year or a date (YYYY-MM-DD)}

\item{end}{ending date, can be a year or a date (YYYY-MM-DD)}
}
\value{
dataframe with coordinates, month, year, average temperatures and temperature range
}
\description{
retrieves daily temperature data for specified coordinates and simulation period, computes average monthly temperatures as well as temperature range
}
\note{
Conditions like user specifying a date less than 1 month is not highlighted
}
\examples{
populate_temperature(coords=c(9.114015,55.47163), yr_start=2006, yr_end=2010)
}
