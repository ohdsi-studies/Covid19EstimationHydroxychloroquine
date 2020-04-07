library(DatabaseConnector)
options(fftempdir = "s:/FFtemp")
connectionDetails <- createConnectionDetails(dbms = "pdw",
                                             server = Sys.getenv("PDW_SERVER"),
                                             port = Sys.getenv("PDW_PORT"))

cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_epi_688_cohorts"
oracleTempSchema <- NULL
outputFolder <- "c:/PreClinToRwe"
maxCores <- parallel::detectCores()

databases <- data.frame(databaseId = c("CCAE", 
                                       "MDCD", 
                                       "MDCR", 
                                       "Optum", 
                                       "JMDC"),
                        cdmDatabaseSchema = c("CDM_IBM_CCAE_V1061.dbo",
                                              "CDM_IBM_MDCD_V1023.dbo",
                                              "CDM_IBM_MDCR_V1062.dbo",
                                              "CDM_OPTUM_EXTENDED_SES_V1065.dbo",
                                              "CDM_JMDC_V1063.dbo"),
                        cohortTable = c("mschuemi_preclinTorwe_ccae",
                                        "mschuemi_preclinTorwe_mdcd",
                                        "mschuemi_preclinTorwe_mdcr",
                                        "mschuemi_preclinTorwe_optum",
                                        "mschuemi_preclinTorwe_jmdc"),
                        minAge = c(18,
                                   18,
                                   65,
                                   18,
                                   18),
                        maxAge = c(65,
                                   NA,
                                   NA,
                                   NA,
                                   NA))
databases$outputFolder <- file.path(outputFolder, databases$databaseId)

