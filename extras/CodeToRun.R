library(Covid19EstimationHydroxychloroquine)

# Optional: specify where the temporary files (used by the ff package) will be created:
options(andromedaTempFolder = "d:/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
outputFolder <- ""

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = paste(keyring::key_get("postgresServer"), 
                                                                               keyring::key_get("postgresDatabase"), sep = "/"),
                                                                user = keyring::key_get("postgresUser"),
                                                                password = keyring::key_get("postgresPassword"),
                                                                port = keyring::key_get("postgresPort"))

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

# For Oracle: define a schema that can be used to emulate temp tables:
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

resultsZipFile <- file.path(outputFolder, "export", paste0("Results", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)

launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)
