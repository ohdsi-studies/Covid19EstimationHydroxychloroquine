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

createSccsAnalysesDetails <- function(fileName) {
  
  getDbSccsDataArgs <- SelfControlledCaseSeries::createGetDbSccsDataArgs(maxCasesPerOutcome = 500000,
                                                                         exposureIds = c("exposureId"))
  
  covarExposureOfInt <- SelfControlledCaseSeries::createCovariateSettings(label = "Exposure of interest",
                                                                          includeCovariateIds = "exposureId",
                                                                          start = 1,
                                                                          end = 0,
                                                                          addExposedDaysToEnd = TRUE)
  
  covarPreExp <- SelfControlledCaseSeries::createCovariateSettings(label = "Pre-exposure",
                                                                   includeCovariateIds = "exposureId",
                                                                   start = -30,
                                                                   end = -1)
  
  ageSettings <- SelfControlledCaseSeries::createAgeSettings(includeAge = TRUE)
  seasonalitySettings <- SelfControlledCaseSeries::createSeasonalitySettings(includeSeasonality = TRUE)
  
  createSccsEraDataArgs1 <- SelfControlledCaseSeries::createCreateSccsEraDataArgs(naivePeriod = 365,
                                                                                 firstOutcomeOnly = TRUE,
                                                                                 covariateSettings = list(covarExposureOfInt,
                                                                                                          covarPreExp),
                                                                                 ageSettings = ageSettings,
                                                                                 seasonalitySettings = seasonalitySettings)
  fitSccsModelArgs <- SelfControlledCaseSeries::createFitSccsModelArgs()
  
  sccsAnalysis1 <- SelfControlledCaseSeries::createSccsAnalysis(analysisId = 1,
                                                                description = "Using age, season, and pre-exposure",
                                                                getDbSccsDataArgs = getDbSccsDataArgs,
                                                                createSccsEraDataArgs = createSccsEraDataArgs1,
                                                                fitSccsModelArgs = fitSccsModelArgs)
  
  createSccsEraDataArgs2 <- SelfControlledCaseSeries::createCreateSccsEraDataArgs(naivePeriod = 365,
                                                                                  firstOutcomeOnly = TRUE,
                                                                                  covariateSettings = list(covarExposureOfInt,
                                                                                                           covarPreExp),
                                                                                  ageSettings = ageSettings,
                                                                                  seasonalitySettings = seasonalitySettings,
                                                                                  eventDependentObservation = TRUE)
  
  sccsAnalysis2 <- SelfControlledCaseSeries::createSccsAnalysis(analysisId = 2,
                                                                description = "Adjust for age, season, pre-exposure, time-dep. obs. ",
                                                                getDbSccsDataArgs = getDbSccsDataArgs,
                                                                createSccsEraDataArgs = createSccsEraDataArgs2,
                                                                fitSccsModelArgs = fitSccsModelArgs)
  
  
  sccsAnalysisList <- list(sccsAnalysis1, sccsAnalysis2)
  SelfControlledCaseSeries::saveSccsAnalysisList(sccsAnalysisList, fileName)
}
