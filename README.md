OHDSI COVID-19 Studyathon: Hydroxychloroquine population-level effect estimation
=============

<img src="https://img.shields.io/badge/Study%20Status-Design%20Finalized-brightgreen.svg" alt="Study Status: Design Finalized"> 

- Analytics use case(s): **Population-Level Estimation**
- Study type: **Clinical Application**
- Tags: **Study-a-thon, COVID-19**
- Study lead: **Jennifer Lane, James Weaver**
- Study lead forums tag: **[jenniferlane](https://forums.ohdsi.org/u/jenniferlane), [jweave17](https://forums.ohdsi.org/u/jweave17)**
- Study start date: **March 26, 2020**
- Study end date: **-**
- Protocol: **[PDF (as filed with PASS)](https://github.com/ohdsi-studies/Covid19EstimationHydroxychloroquine/blob/master/documents/OHDSI%20COVID-19%20Studyathon_PLE_HCQ_Protocol_v1.4.pdf)**
- Publications: **-**
- Results explorer: **https://data.ohdsi.org/Covid19EstimationHydroxychloroquine/**

Many existing drugs are being considered for use in treatment and prophylaxis of COVID-19 in rapid clinical trials across the world. However, the full safety profiles of these drugs is often unknown, and the current trials are unlikely to be powered or have sufficent follow-up time to evaluate most safety outcomes. The aim of this OHDSI study is to use existing retrospective data to evaluate the safety of these drugs. Where possible, we also attempt to estimate potential efficacy, for example using prior viral infections as surrogate outcome, or where available by using COVID-19 as outcome.

This study is part of the [OHDSI 2020 COVID-19 study-a-thon](https://www.ohdsi.org/covid-19-updates/).

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, or Microsoft APS.
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

See [this video](https://youtu.be/K9_0s2Rchbo) for instructions on how to set up the R environment on Windows.

How to run
==========
1. In `R`, use the following code to install the dependencies:

  ```r
  install.packages("devtools")
  library(devtools)
  install_github("ohdsi/SqlRender")
  install_github("ohdsi/DatabaseConnector")
  install_github("ohdsi/OhdsiSharing")
  install_github("ohdsi/FeatureExtraction")
  install_github("ohdsi/CohortMethod")
  install_github("ohdsi/EmpiricalCalibration")
  install_github("ohdsi/MethodEvaluation")
  ```
*Note: Failure to update packages to latest versions as of 26MAR2020 (especially Empirical Calibration) may result in errors in study packaging during export. If you encounter an error message during installation that says, 'Failure to create lock directory.' Try the following.*
```r
install_github("ohdsi/FeatureExtraction" dependencies = TRUE, INSTALL_opts = '--no-lock')*
  ```
  
2. In 'R', use the following code to install the Covid19EstimationHydroxychloroquine package:

  ```r
  devtools::install_github("ohdsi-studies/Covid19EstimationHydroxychloroquine")
  ```
*Note: If you encounter errors in devtools pulling the package, you may find it easier to download the repo zip locally and uploading it through your RStudio console. Instructions to upload packages are provided in [The Book of OHDSI](https://ohdsi.github.io/TheBookOfOhdsi/PopulationLevelEstimation.html#running-the-study-package).*

3. Once installed, you can execute the study by modifying and using the following code:
	
  ```r
  library(Covid19EstimationHydroxychloroquine)
  
  # Optional: specify where the temporary files (used by the ff package) will be created:
  options(fftempdir = "")
  
  # Maximum number of cores to be used:
  maxCores <- parallel::detectCores()
  
  # Minimum cell count when exporting data:
  minCellCount <- 5
  
  # The folder where the study intermediate and result files will be written:
  outputFolder <- "c:/Covid19EstimationHydroxychloroquine"
  
  # Details for connecting to the server:
  # See ?DatabaseConnector::createConnectionDetails for help
  connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "",
                                                                  server = "",
                                                                  user = "",
                                                                  password = "")
  
  # The name of the database schema where the CDM data can be found:
  cdmDatabaseSchema <- ""
  
  # The name of the database schema and table where the study-specific cohorts will be instantiated:
  cohortDatabaseSchema <- ""
  cohortTable <- ""
  
  # Some meta-information that will be used by the export function:
  # Please use a short and descriptive databaseId and databaseName, e.g. OptumDOD
  databaseId <- ""
  databaseName <- ""
  databaseDescription <- ""
  
  # If using Oracle, define a schema that can be used to emulate temp tables. Otherwise set as NULL:
  oracleTempSchema <- NULL
  
  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortDatabaseSchema = cohortDatabaseSchema,
          cohortTable = cohortTable,
          oracleTempSchema = oracleTempSchema,
          outputFolder = outputFolder,
          databaseId = databaseId,
          databaseName = databaseName,
          databaseDescription = databaseDescription,
          createCohorts = TRUE,
          synthesizePositiveControls = FALSE,
          runAnalyses = TRUE,
          runDiagnostics = TRUE,
          packageResults = TRUE,
          maxCores = maxCores)
  ```

4. To view the results, use the Shiny app. Please keep the results blinded.

  ```r
  resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
  dataFolder <- file.path(outputFolder, "shinyData")
  prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
  launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)
```
5. When completed, the output will exist as a .ZIP file in the `export` directory in the `output` folder location. This file contains the results to submit to the study lead. To do so, please use the function below.  You must supply the directory location to where you have saved the `study-data-site-covid19.dat` file to the `privateKeyFileName` argument. You must contact the [study coordinator](mailto:kristin.kostka@iqvia.com) to receive the required private key.

  ```r
	keyFileName <- "<directory loaction of study-data-site-covid19.dat>"
	username <- "study-data-covid19"
	OhdsiSharing::sftpUploadFile(privateKeyFileName = keyFileName,
                             userName = userName,
                             remoteFolder = "Covid19EstimationHydroxychloroquine",
                             fileName = "<directory location of outputFolder/export>")
  ```
  
License
=======
The Covid19EstimationHydroxychloroquine package is licensed under Apache License 2.0
