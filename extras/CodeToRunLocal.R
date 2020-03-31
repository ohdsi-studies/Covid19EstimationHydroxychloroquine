library(Covid19EstimationHydroxychloroquine)

options(fftempdir = "S:/FFTemp")
maxCores <- parallel::detectCores()
studyFolder <- "G:/StudyResults/Covid19EstimationHydroxychloroquine_2"

source("S:/MiscCode/SetEnvironmentVariables.R")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = Sys.getenv("server"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("port"))

mailSettings <- list(from = Sys.getenv("emailAddress"),
                     to = c(Sys.getenv("emailAddress")),
                     smtp = list(host.name = Sys.getenv("emailHost"), port = 25,
                                 user.name = Sys.getenv("emailAddress"),
                                 passwd = Sys.getenv("emailPassword"), ssl = FALSE),
                     authenticate = FALSE,
                     send = TRUE)

# CCAE settings ----------------------------------------------------------------
databaseId <- "CCAE"
databaseName <- "CCAE"
databaseDescription <- "CCAE"
cdmDatabaseSchema <- "CDM_IBM_CCAE_V1103.dbo"
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema = "scratch.dbo"
cohortTable = "covid19_hcq_ccae"

# Optum DOD settings -----------------------------------------------------------
databaseId <- "Optum"
databaseName <- "Optum"
databaseDescription <- "Optum DOD"
cdmDatabaseSchema = "CDM_OPTUM_EXTENDED_DOD_V1107.dbo"
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_optum"

# CPRD settings ----------------------------------------------------------------
databaseId <- "CPRD"
databaseName <- "CPRD"
databaseDescription <- "CPRD"
cdmDatabaseSchema = "CDM_CPRD_V1102.dbo"
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_cprd"

# MDCD settings ----------------------------------------------------------------
databaseId <- "MDCD"
databaseName <- "MDCD"
databaseDescription <- "MDCD"
cdmDatabaseSchema = "CDM_IBM_MDCD_V1105.dbo"
outputFolder <- file.path(studyFolder, databaseId)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_mdcd"

# MDCR settings ----------------------------------------------------------------
databaseId <- "MDCR"
databaseName <- "MDCR"
databaseDescription <- "MDCR"
cdmDatabaseSchema = "CDM_IBM_MDCR_V1104.dbo"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_mdcr"

# JMDC -------------------------------------------------------------------------
databaseId <- "JMDC"
databaseName <- "JMDC"
databaseDescription <- "JMDC"
cdmDatabaseSchema = "CDM_JMDC_V1106.dbo"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_jmdc"

# PanTher ----------------------------------------------------------------------
databaseId <- "PanTher"
databaseName <- "PanTher"
databaseDescription <- "PanTher"
cdmDatabaseSchema = "CDM_OPTUM_PANTHER_V1109.dbo"
outputFolder <- file.path(studyFolder, databaseName)
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "covid19_hcq_panther"


# Run --------------------------------------------------------------------------
OhdsiRTools::runAndNotify(expression = {
  execute(connectionDetails = connectionDetails,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortDatabaseSchema = cohortDatabaseSchema,
          cohortTable = cohortTable,
          oracleTempSchema = NULL,
          outputFolder = outputFolder,
          databaseId = databaseId,
          databaseName = databaseName,
          databaseDescription = databaseDescription,
          createCohorts = FALSE,
          synthesizePositiveControls = FALSE,
          runAnalyses = FALSE,
          runDiagnostics = FALSE,
          packageResults = FALSE,
          maxCores = maxCores)
}, mailSettings = mailSettings, label = paste0("EhdenRaDmardsEstimation ", databaseId), stopOnWarning = FALSE)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)

# move database-specific shiny files to shinyDataAll folder

assessCovarBalanaceAndPrevalence(shinyDataFolder = file.path(studyFolder, "ShinyDataAll"),
                                 studyFolder = studyFolder)

doMetaAnalysis(studyFolder = studyFolder,
               outputFolders = c(file.path(studyFolder, "Amb_EMR"),
                                 file.path(studyFolder, "CCAE"),
                                 file.path(studyFolder, "GERMANY"),
                                 file.path(studyFolder, "MDCD"),
                                 file.path(studyFolder, "MDCR"),
                                 file.path(studyFolder, "Optum"),
                                 file.path(studyFolder, "PanTher"),
                                 file.path(studyFolder, "THIN"),
                                 file.path(studyFolder, "SIDIAP"),
                                 file.path(studyFolder, "BELGIUM"),
                                 file.path(studyFolder, "EstonianHIS"),
                                 file.path(studyFolder, "JMDC"),
                                 file.path(studyFolder, "LPDFRANCE"),
                                 file.path(studyFolder, "IPCI-HI-LARIOUS-RA")), 
               maOutputFolder = file.path(studyFolder, "MetaAnalysis"),
               maxCores = maxCores)

# move meta-analysis shiny files to shinyDataAll folder

premergeShinyDataFiles(dataFolder = file.path(studyFolder, "ShinyDataAll"),
                       newDataFolder = file.path(studyFolder, "NewShinyDataAll"))

reportFolder <- "G:/StudyResults/EhdenRaDmardsEstimation2/report2"

for (analysis in c("primary", "matchedOnTreatment", "strataItt", "matchedItt")) {
  createManuscriptTables(reportFolder = reportFolder,
                         analysis = analysis,
                         createCountsTable = FALSE,
                         createNntTable = FALSE,
                         createCharsTables = FALSE,
                         createEventsTables = FALSE,
                         createForestPlots = TRUE,
                         createDiagnosticPlots = FALSE)
}





resultsFolder <- "S:/Git/GitHub/ohdsi-studies/EhdenRaDmardsEstimation/inst/shiny/EhdenRaDmardsEstimation/data" # main results, databaseIds changed
studyFolder <- "G:/StudyResults/EhdenRaDmardsEstimation2"
createAppendixPlotsAndTables(resultsFolder = resultsFolder, 
                             # resultsFolder = file.path(studyFolder, "NewShinyDataAll"),
                             reportFolder = file.path(studyFolder, "report2"),
                             createCountsTable = FALSE,
                             createCharsTable = FALSE,
                             createEventsTables = TRUE,
                             createForestPlots = TRUE,
                             createKmPlots = FALSE,
                             createDiagnosticsPlots = FALSE)


