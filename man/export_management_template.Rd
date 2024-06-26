% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Parameter_config.R
\name{export_management_template}
\alias{export_management_template}
\title{export_management_template}
\usage{
export_management_template(yr_start, yr_end, filepath)
}
\arguments{
\item{yr_start}{initial simulation year}

\item{yr_end}{end simulation year}

\item{filepath}{filepath where management template is to be exported}
}
\description{
if user wants to specify monthly (or annual) C inputs and allocation fraction, it can export a template later to be read by the model
note that all relevant columns are exported as 0, to be later populated by the user
user needs to deleted columns that are not being used
please ensure no double accounting in columns, for instance, by populating "plant_monthly_allocation" the user should not distinguish grass nor grain crops
Furthermore, if user provides monthly C inputs, there is no need to populate allocation columns
these conditions are not provided in the code and must be manually done with commmon sense
}
\examples{
export_management_template(2006, 2010, './Management_config.csv')
}
