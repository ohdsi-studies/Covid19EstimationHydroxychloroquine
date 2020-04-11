# obtain results from sftp server
coorKeyFileName <- "G:/StudyResults/study-coordinator-covid19.dat"
userName <- "study-coordinator-covid19"
localFolder <- "G:/StudyResults/SFTP/hcq"
dir.create(localFolder)
sftpDirectory <- "Covid19EstimationHydroxychloroquine"

connection <- OhdsiSharing::sftpConnect(coorKeyFileName, userName)
OhdsiSharing::sftpCd(connection, sftpDirectory)
files <- OhdsiSharing::sftpLs(connection) 
OhdsiSharing::sftpGetFiles(connection, files, localFolder = localFolder)
OhdsiSharing::sftpDisconnect(connection)

