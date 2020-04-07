library(Covid19HcqSccs)

options(fftempdir = "s:/FFtemp")
connectionDetails <- createConnectionDetails(dbms = "pdw",
                                             server = Sys.getenv("PDW_SERVER"),
                                             port = Sys.getenv("PDW_PORT"))
studyFolder <- "s:/Covid19HcqSccs"
maxCores <- parallel::detectCores()

# Optional: E-mail settings if you want to receive an e-mail on errors or completion:
mailSettings <- list(from = Sys.getenv("mailAddress"),
                     to = c(Sys.getenv("mailToAddress")),
                     smtp = list(host.name = Sys.getenv("mailSmtpServer"),
                                 port = Sys.getenv("mailSmtpPort"),
                                 user.name = Sys.getenv("mailAddress"),
                                 passwd = Sys.getenv("mailPassword"),
                                 ssl = TRUE),
                     authenticate = TRUE,
                     send = TRUE)
ParallelLogger::addDefaultEmailLogger(mailSettings)

# CCAE settings
databaseId <- "CCAE"
cdmDatabaseSchema <- "CDM_IBM_CCAE_V1103.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_ccae"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

# MDCR settings
databaseId <- "MDCR"
cdmDatabaseSchema <- "CDM_IBM_MDCR_V1104.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_mdcr"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

# MDCD settings
databaseId <- "MDCD"
cdmDatabaseSchema <- "CDM_IBM_MDCD_V1105.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_mdcd"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

# JMDC settings
databaseId <- "JMDC"
cdmDatabaseSchema <- "CDM_JMDC_V1106.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_jmdc"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

# Optum settings
databaseId <- "Optum"
cdmDatabaseSchema <- "CDM_OPTUM_EXTENDED_DOD_V1107.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_optum"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

# CPRD settings
databaseId <- "CPRD"
cdmDatabaseSchema <- "CDM_CPRD_V1102.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_covid19sccs_cprd"
oracleTempSchema <- NULL
outputFolder <- file.path(studyFolder, databaseId)

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
