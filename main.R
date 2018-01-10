library(shiny)
library(shinydashboard)
library(rgdal)
library(RODBC)
library(tmap)
library(dplyr)
library(leaflet)
library(plotly)

source("helper_functions.R")



# Do on application start
# ---------------------------------------------------------------------------------
weatherData = reactiveValues()  #getNoaaData()
mapPlot = readOGR('Data\\Shapefiles\\GIS.OFFICIAL_CLIM_DIVISIONS.shp', GDAL1_integer64_policy=TRUE)
names(mapPlot@data)[which(names(mapPlot@data)=="CLIMDIV")] <- "ClimateDivisionId"
mapPlot@data$NAME <- sapply(as.character(mapPlot@data$NAME),displayNameCap)

States <- GetStates()
# ---------------------------------------------------------------------------------


# Server code
# ---------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  AvgObsByClimateDiv <- reactive({
    SummarizeObservations(censusRegion = as.character(input$CensusRegion)
                          , State = as.character(input$State)
                       , startDate = as.character(input$dateRange[1])
                       , endDate = as.character(input$dateRange[2]))
  })
  
  AvgObsByDate <- reactive({
    GetObservations(censusRegion = as.character(input$CensusRegion)
                    , State = as.character(input$State)
                    , startDate = as.character(input$dateRange[1])
                    , endDate = as.character(input$dateRange[2]))
  })
  
    output$mapPlot <- renderLeaflet({
      weatherData <- AvgObsByClimateDiv()

      print(head(weatherData))
      
      mapPlot <- mapPlot[which(mapPlot@data$ClimateDivisionId %in% weatherData$ClimateDivisionId), ]
      mapPlot@data <- left_join(mapPlot@data, weatherData, by="ClimateDivisionId")
      mapPlot@data[[as.character(input$DepVar)]] <- round(mapPlot@data[[as.character(input$DepVar)]],1)
      
      onClickPopups <- c("State:" = "STATE"
                         ,"Climate Division: " = "NAME")
      if(input$DepVar == "HDD") {
        onClickPopups <- c(onClickPopups, "Avg. Cooling Degree Days: " = "HDD")
      } else if(input$DepVar == "CDD") {
        onClickPopups <- c(onClickPopups, "Avg. Heating Degree Days: " = "CDD")
      } else {
        onClickPopups <- c(onClickPopups, "Avg. Temperature (F): " = "Temp")
      }
      
      mapPlot <- tm_shape(mapPlot) + tm_polygons(input$DepVar, popup.vars = onClickPopups) 
      mapPlot <- tmap_leaflet(mapPlot) %>%  
        addLayersControl(
#          baseGroups = "Esri.WorldTopoMap",
          position = "topright"
        )
      
      if(input$CensusRegion == "CONUS") {
        # disable zoom to avoid costly computations
        mapPlot$x$calls[[1]]$args[[4]]$minZoom <- 4
        mapPlot$x$calls[[1]]$args[[4]]$maxZoom <- 4
        
        # fix map bounds around area of interest
        mapPlot$x$fitBounds[[1]] <- 45
        mapPlot$x$fitBounds[[2]] <- -135
        mapPlot$x$fitBounds[[3]] <- 30
        mapPlot$x$fitBounds[[4]] <- -64
      }
      
      mapPlot$elementId <- NULL
      mapPlot
    })
    
    output$HistObsChart <- renderPlotly({
      weatherData <- AvgObsByDate()
      t <- input$DepVar
      
      p <- ggplot(data = weatherData) + 
        geom_line(aes_string(x="ObservationDate", y=t))
      ggplotly(p)
    })
    

  observeEvent(input$CensusRegion,{
    updateSelectInput(session, "State", choices = c("All" = "NULL", 
                                                    filter(States, CensusDivisionId == input$CensusRegion)$Name))
  })
    
    
  observeEvent(input$tester,{
    print('test')
    print(input$CensusRegion)
    
  })

 
  
}
# ---------------------------------------------------------------------------------



# User interface
# ---------------------------------------------------------------------------------
ui <- dashboardPage(
  dashboardHeader(title = "Daily Temp Explorer"),
  
  dashboardSidebar(
    radioButtons('DepVar', "Variable",
                 c("Daily temperature" = "Temp",
                   "Heating" = "HDD",
                   "Cooling" = "CDD")),
    selectInput("CensusRegion", "Census region",
                c("Continental U.S." = "CONUS"
                  , "New England" = 1
                  , "Middle Atlantic" = 2
                  , "E N Central" = 3
                  , "W N Central" = 4
                  , "South Atlantic" = 5
                  , "E S Central" = 6
                  , "W S Central" = 7
                  , "Mountain" = 8
                  , "Pacific" = 9), selected = 1),
    selectInput("State", "State",
                c("All" = "NULL", States$Name)),
    dateRangeInput('dateRange', label = "Date range:", startview = "year",
                   start = '2016-01-01', end = '2017-01-01',
                   min = '1981-01-01'),
    
    actionButton('tester','tester')
    
  ),
  
  
  dashboardBody(
    
    fluidRow(
      box(title = "Climate Region Map", width=7, solidHeader = T, #status = "primary",
          #tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
          leafletOutput("mapPlot", width = "100%")
      ),
      box(title = "Population Statistics", width=5)
    ),
    
    fluidRow(
      box(title = "Historical Observations",
          plotlyOutput("HistObsChart")
      ),
      box(title = "Energy Consumption"
      )
    )
    
  )
)
# ---------------------------------------------------------------------------------


shinyApp(ui, server)

#runApp("G:\\NOAA\\Data\\RScripts\\shiny_dashboard.R", display.mode = "showcase")
