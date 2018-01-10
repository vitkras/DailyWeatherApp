

# gets average noaa observations by climate region
SummarizeObservations = function(censusRegion="CONUS", State="NULL", startDate="2017-01-01", endDate=Sys.Date()) {
  myconn <-  odbcDriverConnect('driver={SQL Server};server=pangloss\\sqlexpress;database=NOAA;trusted_connection=true')

  if(censusRegion == "CONUS") {
    queryText <- "EXEC [NOAA].dbo.SummarizeObservations NULL"
  } else {
    queryText <- paste("EXEC [NOAA].dbo.SummarizeObservations", censusRegion)
  }
  
  if(State != "NULL") {
    queryText <- paste(queryText, ",'", State, "'", ",'", startDate, "','", endDate, "'", sep="")
  } else {
    queryText <- paste(queryText, ",", State, ",'", startDate, "','", endDate, "'", sep="")
  }
  
  output <- sqlQuery(myconn, queryText)
  close(myconn)

  return(output)
}


# gets average noaa observations by date
GetObservations = function(censusRegion="CONUS", State="NULL", startDate="2017-01-01", endDate=Sys.Date()) {
  myconn <-  odbcDriverConnect('driver={SQL Server};server=pangloss\\sqlexpress;database=NOAA;trusted_connection=true')
  
  if(censusRegion == "CONUS") {
    queryText <- "EXEC [NOAA].dbo.GetObservations NULL"
  } else {
    queryText <- paste("EXEC [NOAA].dbo.GetObservations", censusRegion)
  }
  
  if(State != "NULL") {
    queryText <- paste(queryText, ",'", State, "'", ",'", startDate, "','", endDate, "'", sep="")
  } else {
    queryText <- paste(queryText, ",", State, ",'", startDate, "','", endDate, "'", sep="")
  }
  
  output <- sqlQuery(myconn, queryText)
  close(myconn)
  
  output$ObservationDate <- as.Date(as.character(output$ObservationDate))
  return(output)
}


GetStates = function() {
  myconn <-  odbcDriverConnect('driver={SQL Server};server=pangloss\\sqlexpress;database=NOAA;trusted_connection=true')
  
  queryText <- "SELECT CensusDivisionId, Name
                 FROM [NOAA].[dbo].[States]
                 ORDER BY Name"
  
  output <- sqlQuery(myconn, queryText)
  close(myconn)
  output$Name <- as.character(output$Name)
  
  return(output)
}


# capitalizes first letters for user display
displayNameCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  s <- paste(toupper(substring(s, 1,1)), tolower(substring(s, 2)),
             sep="", collapse=" ")
  s <- paste(s[1], s[2])
  s <- gsub(" NA", "", s)
  return(s)
}