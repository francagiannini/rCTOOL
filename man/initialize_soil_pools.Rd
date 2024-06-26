% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Parameter_config.R
\name{initialize_soil_pools}
\alias{initialize_soil_pools}
\title{initialize_soil_pools}
\usage{
initialize_soil_pools(cn, soil_config)
}
\arguments{
\item{cn}{soil carbon:nitrogen ratio}

\item{soil_config}{soil configuration file (list)}
}
\value{
list with the initialized top and bottom soil pool
}
\description{
initializes top and bottom soil pools
}
\examples{
initialize_soil_pools(cn=15, soil_config = s_config)
}
