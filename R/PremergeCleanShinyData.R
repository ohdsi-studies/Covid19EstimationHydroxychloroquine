# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of Covid19EstimationHydroxychloroquine
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

#' @export
premergeCleanShinyData <- function(fullShinyDataFolder,
                                   premergedCleanShinyDataFolder) { 

  if (!file.exists(premergedCleanShinyDataFolder)) {
    dir.create(premergedCleanShinyDataFolder)
  }
  
  # Copied from global.R ---------------------------------------------------------------------------
  splittableTables <- c("covariate_balance", "preference_score_dist", "kaplan_meier_dist")
  files <- list.files(fullShinyDataFolder, pattern = ".rds")
  
  # Find part to remove from all file names (usually databaseId):
  databaseFileName <- files[grepl("^database", files)]
  removeParts <- paste0(gsub("database", "", databaseFileName), "$")
  
  # Remove data already in global environment:
  for (removePart in removeParts) {
    tableNames <- gsub("_t[0-9]+_c[0-9]+$", "", gsub(removePart, "", files[grepl(removePart, files)])) 
    camelCaseNames <- SqlRender::snakeCaseToCamelCase(tableNames)
    camelCaseNames <- unique(camelCaseNames)
    camelCaseNames <- camelCaseNames[!(camelCaseNames %in% SqlRender::snakeCaseToCamelCase(splittableTables))]
    suppressWarnings(
      rm(list = camelCaseNames)
    )
  }
  
  # Load data from data folder. R data objects will get names derived from the filename:
  loadFile <- function(file, removePart) {
    tableName <- gsub("_t[0-9]+_c[0-9]+$", "", gsub(removePart, "", file)) 
    camelCaseName <- SqlRender::snakeCaseToCamelCase(tableName)
    if (!(tableName %in% splittableTables)) {
      newData <- readRDS(file.path(fullShinyDataFolder, file))
      if (camelCaseName == "cohortMethodResult") {
        if (removePart != "_Meta-analysis.rds$") {
          newData$sources <- rep("", nrow(newData))
        }
      }
      colnames(newData) <- SqlRender::snakeCaseToCamelCase(colnames(newData))
      if (exists(camelCaseName, envir = .GlobalEnv)) {
        existingData <- get(camelCaseName, envir = .GlobalEnv)
        newData <- rbind(existingData, newData)
        newData <- unique(newData)
      }
      assign(camelCaseName, newData, envir = .GlobalEnv)
    }
    invisible(NULL)
  }
  for (removePart in removeParts) {
    dummy <- lapply(files[grepl(removePart, files)], loadFile, removePart)
  }
  
  # data clean -----------------------------------------------------------------------------------------
  outcomeOfInterest$definition <- NULL
  outcomeOfInterest <- outcomeOfInterest[!duplicated(outcomeOfInterest), ]
  
  exposureOfInterest$definition <- NULL
  exposureOfInterest <- exposureOfInterest[!duplicated(exposureOfInterest), ]
  
  cohortMethodAnalysis$definition <- NULL
  cohortMethodAnalysis <- cohortMethodAnalysis[!duplicated(cohortMethodAnalysis), ]
  
  cohortMethodResult$i2 <- round(cohortMethodResult$i2, 2)
  
  drops <- 
    (cohortMethodResult$databaseId == "OptumEHR" & cohortMethodResult$analysisId == 1) | # OptumEHR on-treatment
    (cohortMethodResult$databaseId %in% c("CCAE", "DAGermany", "JMDC", "MDCD", "MDCR", "OptumEHR", "OpenClaims", "AmbEMR") & cohortMethodResult$outcomeId %in% c(18, 19)) | # death
    (cohortMethodResult$databaseId %in% c("AmbEMR", "CPRD", "DAGermany", "IMRD", "SIDIAP") & cohortMethodResult$outcomeId %in% c(22, 13, 20, 21, 17, 8, 11)) # databases with no IP
  cohortMethodResult <- cohortMethodResult[!drops, ]
  
  dbOrder <- c("AmbEMR", "CCAE", "Clinformatics", "CPRD", "DAGermany", "IMRD", "IPCI", "JMDC", "MDCD", "MDCR", "OpenClaims", "OptumEHR", "SIDIAP", "VA", "Meta-analysis")
  database$dbOrder <- match(database$databaseId, dbOrder)
  database <- database[order(database$dbOrder), ]
  database$dbOrder <- NULL
  
  blinds <-
    (cohortMethodResult$databaseId == "CPRD" & cohortMethodResult$targetId == 137) |
    (cohortMethodResult$databaseId == "JMDC" & cohortMethodResult$targetId == 2) |
    (cohortMethodResult$databaseId == "DAGermany" & cohortMethodResult$targetId == 137) |
    (cohortMethodResult$databaseId == "IMRD" & cohortMethodResult$targetId == 137) |
    (cohortMethodResult$databaseId == "SIDIAP" & cohortMethodResult$targetId %in% c(137, 2)) |
    (cohortMethodResult$databaseId == "IPCI" & cohortMethodResult$targetId %in% c(137, 2))
  
  cohortMethodResult$rr[blinds] <- NA
  cohortMethodResult$ci95Ub[blinds] <- NA
  cohortMethodResult$ci95Lb[blinds] <- NA
  cohortMethodResult$logRr[blinds] <- NA
  cohortMethodResult$seLogRr[blinds] <- NA
  cohortMethodResult$p[blinds] <- NA
  cohortMethodResult$calibratedRr[blinds] <- NA
  cohortMethodResult$calibratedCi95Ub[blinds] <- NA
  cohortMethodResult$calibratedCi95Lb[blinds] <- NA
  cohortMethodResult$calibratedLogRr[blinds] <- NA
  cohortMethodResult$calibratedSeLogRr[blinds] <- NA
  cohortMethodResult$calibratedP[blinds] <- NA
  
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with chest pain or angina"] <- "Chest pain or angina"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Venous thromboembolic (pulmonary embolism and deep vein thrombosis) events"] <- "Venous thromboembolism"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Acute renal failure events"] <- "Acute renal failure"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with end stage renal disease"] <- "End stage renal disease"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with hepatic failure"] <- "Hepatic failure"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Acute pancreatitis events"] <- "Acute pancreatitis"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with heart failure"] <- "Heart failure"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Total cardiovascular disease events"] <- "Cardiovascular events"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Person with cardiac arrhythmia"] <- "Cardiac arrhythmia"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Persons with bradycardia"] <- "Bradycardia"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Gastrointestinal bleeding events"] <- "Gastrointestinal bleeding"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] All-cause mortality"] <- "All-cause mortality"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Cardiovascular-related mortality"] <- "Cardiovascular-related mortality"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Transient ischemic attack events"] <- "Transient ischemic attack"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Stroke (ischemic or hemorrhagic) events"] <- "Stroke"
  outcomeOfInterest$outcomeName[outcomeOfInterest$outcomeName == "[LEGEND HTN] Acute myocardial infarction events"] <- "Myocardial infarction"
  outcomeOfInterest$order <- match(outcomeOfInterest$outcomeName, c("All-cause mortality",
                                                                    "Cardiovascular-related mortality",
                                                                    "Myocardial infarction",
                                                                    "Chest pain or angina",
                                                                    "Heart failure",
                                                                    "Cardiovascular events",
                                                                    "Cardiac arrhythmia",
                                                                    "Bradycardia",
                                                                    "Transient ischemic attack",
                                                                    "Stroke",
                                                                    "Venous thromboembolism",
                                                                    "Gastrointestinal bleeding",
                                                                    "Acute renal failure",
                                                                    "End stage renal disease",
                                                                    "Hepatic failure",
                                                                    "Acute pancreatitis"))
  outcomeOfInterest <- outcomeOfInterest[order(outcomeOfInterest$order), ]
  outcomeOfInterest$order <- NULL
  
  exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI-Covid19] Hydroxychloroquine + Azithromycin"] <- "Hydroxychloroquine + Azithromycin with prior RA"
  exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI Cov19] New users of Hydroxychloroquine with prior rheumatoid arthritis"] <- "Hydroxychloroquine with prior RA"
  exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI-Covid19] Hydroxychloroquine + Amoxicillin"] <- "Hydroxychloroquine + Amoxicillin with prior RA"
  exposureOfInterest$exposureName[exposureOfInterest$exposureName == "[OHDSI Cov19] New users of sulfasazine with prior rheumatoid arthritis"] <- "Sulfasalazine with prior RA"
  exposureOfInterest <- exposureOfInterest[order(exposureOfInterest$exposureId), ]
  
  cohortMethodAnalysis$description[cohortMethodAnalysis$description == "No prior outcome in last 30d, 5 PS strata, TAR on-treatment+14d"] <- "5 PS strata, on-treatment + 14 days follow-up"
  cohortMethodAnalysis$description[cohortMethodAnalysis$description == "No prior outcome in last 30d, 5 PS strata, TAR 30d fixed"] <- "5 PS strata, 30 days follow-up"
  cohortMethodAnalysis <- cohortMethodAnalysis[order(cohortMethodAnalysis$analysisId, decreasing = TRUE), ]
  
  # Write merged data objects to new folder ------------------------------------------------------------------------
  rm(covariateBalanceTnaCna)
  removePart <- removeParts[1]
  tableNames <- gsub("_t([0-9]|NA)+_c([0-9]|NA)+$", "", gsub(removePart, "", files[grepl(removePart, files)])) 
  tableNames <- unique(tableNames)
  tableNames <- tableNames[!(tableNames %in% splittableTables)]
  
  saveTable <- function(tableName) { # tableName <- tableNames[6]
    fileName <- file.path(premergedCleanShinyDataFolder, sprintf("%s_All.rds", tableName))
    camelCaseName <- SqlRender::snakeCaseToCamelCase(tableName)
    data <- get(camelCaseName, envir = .GlobalEnv)
    if (tableName == "covariate") {
      data$covariateName <- as.factor(data$covariateName)
    }
    colnames(data) <- SqlRender::camelCaseToSnakeCase(colnames(data))
    print(fileName)
    saveRDS(data, fileName)
  }
  lapply(tableNames, saveTable)
  
  # Copy splittable tables ------------------------------------------------------------------------------
  toCopy <- files[grepl(paste(splittableTables, collapse = "|"), files)]
  file.copy(file.path(fullShinyDataFolder, toCopy), file.path(premergedCleanShinyDataFolder, toCopy))
}