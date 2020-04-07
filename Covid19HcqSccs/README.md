Self-Controlled Case Series Analysis of the Safety of Hydroxychloroquine
========================================================================

Hydroxychloroquine is being considered for use in treatment and prophylaxis of COVID-19 in rapid clinical trials across the world. However, the full safety profiles of this drugs is unknown, and the current trials are unlikely to be powered or have sufficient follow-up time to evaluate most safety outcomes. The aim of this OHDSI study is to use existing retrospective data to evaluate the safety of Hydroxychloroquine, using the self-controlled case series (SCCS) design.

This study is part of the [OHDSI 2020 COVID-19 study-a-thon](https://www.ohdsi.org/covid-19-updates/).

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, or Microsoft APS.
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

See [here](https://ohdsi.github.io/MethodsLibrary/rSetup.html) for instructions on how to set up the R environment on Windows.

How to run
==========

1. First, install the package:
  ```r
  # Prevents errors due to packages being built for other R versions: 
  Sys.setenv("R_REMOTES_NO_ERRORS_FROM_WARNINGS" = TRUE)

  # First, it probably is best to make sure you are up-to-date on all existing packages. 
  # Important: This code is best run in R, not RStudio, as RStudio may have some libraries 
  # (like 'rlang') in use.
  update.packages(ask = "graphics")

  # When asked to update packages, select '3' ('none') (could be multiple times)
  # When asked whether to install from source, select 'No' (could be multiple times)
  install.packages("devtools")
  devtools::install_github("ohdsi/ParallelLogger", ref = "develop")
  devtools::install_github("ohdsi/Cyclops")
  devtools::install_github("ohdsi/EmpiricalCalibration")
  devtools::install_github("ohdsi/SelfControlledCaseSeries")
  devtools::install_github("ohdsi-studies/Covid19EstimationHydroxychloroquine/Covid19HcqSccs")
  ```
2. Execute the study by modifying and executing the following code:
  ```r
  library(Covid19HcqSccs)
  
  # Optional: specify where the temporary files (used by the ff package) will be created:
  options(fftempdir = "c:/fftemp")
  
  # Maximum number of cores to be used:
  maxCores <- parallel::detectCores()
  
  # The folder where the study intermediate and result files will be written:
  outputFolder <- "c:/Covid19HcqSccs"
  
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
  # Please use a short and descriptive databaseId, e.g. OptumDOD
  databaseId <- ""

  
  # If using Oracle, define a schema that can be used to emulate temp tables. Otherwise set as NULL:
  oracleTempSchema <- NULL
  
  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortDatabaseSchema = cohortDatabaseSchema,
          cohortTable = cohortTable,
          oracleTempSchema = oracleTempSchema,
          outputFolder = outputFolder,
          databaseId = databaseId,
          createCohorts = TRUE,
          runSccs = TRUE,
          runSccsDiagnostics = TRUE,
          generateBasicOutputTable = TRUE,
          maxCores = maxCores)
  ```

Support
=======
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="https://github.com/OHDSI/Covid19EstimationHydroxychloroquine/issues">GitHub issue tracker</a> for all bugs/issues/enhancements

License
=======
The Covid19HcqSccs package is licensed under Apache License 2.0
