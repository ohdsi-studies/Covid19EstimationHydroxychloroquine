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

#' Execute the Self-Controlled Case Series analyses
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param outcomeDatabaseSchema Schema name where the outcome cohorts are stored. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param outcomeTable         The name of the table in the outcome database schema that holds the outcome cohorts,
#' @param exposureDatabaseSchema Schema name where the exposure cohorts are stored. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param exposureTable         The name of the table in the exposure database schema that holds the exposure cohorts,
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#' @export
runSelfControlledCaseSeries <- function(connectionDetails,
                                        cdmDatabaseSchema,
                                        oracleTempSchema = NULL,
                                        outcomeDatabaseSchema = cdmDatabaseSchema,
                                        outcomeTable = "cohort",
                                        exposureDatabaseSchema = cdmDatabaseSchema,
                                        exposureTable = "drug_era",
                                        outputFolder,
                                        maxCores) {
  start <- Sys.time()
  sccsFolder <- file.path(outputFolder, "sccsOutput")
  if (!file.exists(sccsFolder))
    dir.create(sccsFolder)
  
  sccsSummaryFile <- file.path(outputFolder, "sccsSummary.csv")
  if (!file.exists(sccsSummaryFile)) {
    eoList <- createTos(outputFolder = outputFolder)
    sccsAnalysisListFile <- system.file("settings", "sccsAnalysisList.json", package = "Covid19HcqSccs")
    sccsAnalysisList <- SelfControlledCaseSeries::loadSccsAnalysisList(sccsAnalysisListFile)
    sccsResult <- SelfControlledCaseSeries::runSccsAnalyses(connectionDetails = connectionDetails,
                                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                                            oracleTempSchema = oracleTempSchema,
                                                            exposureDatabaseSchema = exposureDatabaseSchema,
                                                            exposureTable = exposureTable,
                                                            outcomeDatabaseSchema = outcomeDatabaseSchema,
                                                            outcomeTable = outcomeTable,
                                                            sccsAnalysisList = sccsAnalysisList,
                                                            exposureOutcomeList = eoList,
                                                            outputFolder = sccsFolder,
                                                            combineDataFetchAcrossOutcomes = TRUE,
                                                            compressSccsEraDataFiles = TRUE,
                                                            getDbSccsDataThreads = 1,
                                                            createSccsEraDataThreads = min(5, maxCores),
                                                            fitSccsModelThreads = max(1, floor(maxCores/4)),
                                                            cvThreads =  min(4, maxCores))
    
    sccsSummary <- SelfControlledCaseSeries::summarizeSccsAnalyses(sccsResult, sccsFolder)
    readr::write_csv(sccsSummary, sccsSummaryFile)
  }
  delta <- Sys.time() - start
  ParallelLogger::logInfo(paste("Completed SCCS analyses in", signif(delta, 3), attr(delta, "units")))
}

createTos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TosOfInterest.csv", package = "Covid19HcqSccs")
  tosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "Covid19HcqSccs")
  ncs <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  allControls <- ncs
  
  tos <- unique(rbind(tosOfInterest[, c("exposureId", "outcomeId")],
                      allControls[, c("exposureId", "outcomeId")]))
  
  createTo <- function(i) {
    exposureOutcome <- SelfControlledCaseSeries::createExposureOutcome(exposureId = tos$exposureId[i],
                                                                       outcomeId = tos$outcomeId[i])
    return(exposureOutcome)
  }
  tosList <- lapply(1:nrow(tos), createTo)
  return(tosList)
}

runSccsDiagnostics <- function(outputFolder, databaseId) {
  diagnosticsFolder <- file.path(outputFolder, "sccsDiagnostics")
  if (!file.exists(diagnosticsFolder)) {
    dir.create(diagnosticsFolder)
  }
  sccsSummaryFile <- file.path(outputFolder, "sccsSummary.csv")
  sccsSummary <- readr::read_csv(sccsSummaryFile, col_types = readr::cols())
  
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "Covid19HcqSccs")
  ncs <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  ncs <- merge(ncs, sccsSummary)
  
  evaluateSystematicError <- function(subset) {
    subset <- subset[!is.na(subset$`seLogRr(Exposure of interest)`), ]
    if (nrow(subset)  != 0) {
      fileName <- file.path(diagnosticsFolder, sprintf("NegativeControls_e%s_a%s_%s.png", subset$exposureId[1], subset$analysisId[1], databaseId))
      if (subset$analysisId[1] == 1) {
        title <- "Primary analysis" 
      } else {
        title <- "Adjusting for event-dependent observation" 
      }
      EmpiricalCalibration::plotCalibrationEffect(logRrNegatives = subset$`logRr(Exposure of interest)`,
                                                  seLogRrNegatives = subset$`seLogRr(Exposure of interest)`,
                                                  xLabel = "Incidence Rate Ratio",
                                                  title = title,
                                                  showCis = TRUE,
                                                  fileName = fileName)
    }
  }  
  lapply(split(ncs, paste(ncs$exposureId, ncs$analysisId)), evaluateSystematicError)
}

generateBasicOutputTable <- function(outputFolder, databaseId) {
  diagnosticsFolder <- file.path(outputFolder, "sccsDiagnostics")
  sccsSummaryFile <- file.path(outputFolder, "sccsSummary.csv")
  sccsSummary <- readr::read_csv(sccsSummaryFile, col_types = readr::cols())
  
  pathToCsv <- system.file("settings", "NegativeControls.csv", package = "Covid19HcqSccs")
  negativeControls <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  
  calibrate <- function(subset) {
    ncs <- merge(subset, negativeControls)
    ncs <- ncs[!is.na(ncs$`seLogRr(Exposure of interest)`) & !is.infinite(ncs$`seLogRr(Exposure of interest)`), ]
    if (nrow(ncs)  != 0) {
      null <- EmpiricalCalibration::fitMcmcNull(logRr = ncs$`logRr(Exposure of interest)`,
                                                seLogRr = ncs$`seLogRr(Exposure of interest)`)
      calP <- EmpiricalCalibration::calibrateP(null, logRr = subset$`logRr(Exposure of interest)`,
                                               seLogRr = subset$`seLogRr(Exposure of interest)`)
      subset$calP <- calP$p
      subset$calPLb <- calP$lb95ci
      subset$calPUb <- calP$ub95ci
      
      model <- EmpiricalCalibration::convertNullToErrorModel(null)
      calCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = subset$`logRr(Exposure of interest)`,
                                                                 seLogRr = subset$`seLogRr(Exposure of interest)`,
                                                                 model = model)
                                                                 
      subset$calRr <- exp(calCi$logRr)
      subset$calLb95Rr <- exp(calCi$logLb95Rr)
      subset$calUb95Rr <- exp(calCi$logUb95Rr)
      subset$calLogRr <- calCi$logRr
      subset$calSeLogRr <- calCi$seLogRr
    } 
    return(subset)
  }  
  results <- lapply(split(sccsSummary, sccsSummary$exposureId), calibrate)
  results <- dplyr::bind_rows(results)
  results <- addCohortNames(data = results, IdColumnName = "exposureId", nameColumnName = "exposureName")
  results <- addCohortNames(data = results, IdColumnName = "outcomeId", nameColumnName = "outcomeName")
  results$negativeControl <- results$outcomeId %in% negativeControls$outcomeId
  results$description <- "Primary analysis"
  results$description[results$analysisId == 2] <- "Adjusting for event-dependent observation"
  results <- results[!results$negativeControl, ]
  
  results <- results[, c("exposureName", "outcomeName", "description", "caseCount", "rr(Exposure of interest)", "ci95lb(Exposure of interest)", "ci95ub(Exposure of interest)", "calP", "calRr", "calLb95Rr", "calUb95Rr")]
  colnames(results) <- c("Exposure", "Outcome", "Analysis", "Cases", "IRR", "CI95LB", "CI95UB", "Calibrated P", "Calibrated IRR", "Calibrated CI95LB", "Calibrated CI95UB")
  results <- results[order(results$Exposure, results$Outcome, results$Analysis), ]
  readr::write_csv(results, file.path(diagnosticsFolder, sprintf("allResults_%s.csv", databaseId)))
}

getAllControls <- function(outputFolder) {
  allControlsFile <- file.path(outputFolder, "AllControls.csv")
  if (file.exists(allControlsFile)) {
    # Positive controls must have been synthesized. Include both positive and negative controls.
    allControls <- read.csv(allControlsFile)
  } else {
    # Include only negative controls
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "Covid19HcqSccs")
    allControls <- readr::read_csv(pathToCsv, col_types = readr::cols())
    allControls$oldOutcomeId <- allControls$outcomeId
    allControls$targetEffectSize <- rep(1, nrow(allControls))
  }
  return(allControls)
}
