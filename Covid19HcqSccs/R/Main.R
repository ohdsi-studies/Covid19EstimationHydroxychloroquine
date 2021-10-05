# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of Covid19HcqSccs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the Covid19HcqSccs Study.
#' 
#' The \code{createCohorts}, \code{synthesizePositiveControls}, \code{runAnalyses}, and \code{runDiagnostics} arguments
#' are intended to be used to run parts of the full study at a time, but none of the parts are considered to be optional.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             privileges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param databaseId           A short unique identifier for the database. Will be used to generate
#'                             file names. 
#' @param createCohorts        Create the cohortTable table with the exposure and outcome cohorts?
#' @param runSccs              Perform the SCCS analyses? Requires the cohorts have been created.
#' @param runSccsDiagnostics   Generate SCCSdiagnostics?
#' @param generateBasicOutputTable Generate a basic table with effect size estimates?
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    databaseId,
                    createCohorts = TRUE,
                    runSccs = TRUE,
                    runSccsDiagnostics = TRUE,
                    generateBasicOutputTable = TRUE,
                    maxCores = 4) {
  if (!file.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }
  
  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "log.txt"))
  ParallelLogger::addDefaultErrorReportLogger()
  
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_FILE_LOGGER", silent = TRUE))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_ERRORREPORT_LOGGER", silent = TRUE), add = TRUE)
  
  
  if (!is.null(getOption("andromedaTempFolder")) && !file.exists(getOption("andromedaTempFolder"))) {
    warning("andromedaTempFolder '", getOption("andromedaTempFolder"), "' not found. Attempting to create folder")
    dir.create(getOption("andromedaTempFolder"), recursive = TRUE)
  }
  
  if (createCohorts) {
    ParallelLogger::logInfo("Creating outcome and exposure cohorts")
    createCohorts(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
  }
  
  if (runSccs) {
    ParallelLogger::logInfo("Running SCCS analyses")
    runSelfControlledCaseSeries(connectionDetails = connectionDetails,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                outcomeDatabaseSchema = cohortDatabaseSchema,
                                outcomeTable = cohortTable,
                                exposureDatabaseSchema = cohortDatabaseSchema,
                                exposureTable = cohortTable,
                                oracleTempSchema = oracleTempSchema,
                                outputFolder = outputFolder,
                                maxCores = maxCores)
  }
  
  if (runSccsDiagnostics) {
    ParallelLogger::logInfo("Running SCCS diagnostics")
    runSccsDiagnostics(outputFolder = outputFolder, databaseId = databaseId)
  }
  
  if (generateBasicOutputTable) {
    generateBasicOutputTable(outputFolder = outputFolder, databaseId = databaseId) 
    ParallelLogger::logInfo("Results are now available in ", file.path(outputFolder, "sccsDiagnostics"))
  }
  ParallelLogger::logFatal("Done")
  invisible(NULL)
}
