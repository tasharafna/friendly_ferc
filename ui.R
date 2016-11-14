library(shiny)
library(RMySQL)
library(ggplot2)
library(fasttime)
library(dplyr)
library(lubridate)
library(stringr)
library(DT)
library(plotly)


######


source("creds.R")



########################## Get authorities

GetAllAuthorities <- function() {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  authority_query <- "Select distinct point_of_delivery_balancing_authority from fieldslite"
  authority_frame <- dbGetQuery(con, authority_query)
  
  dbDisconnect(con)
  
  return (authority_frame$point_of_delivery_balancing_authority)
  
}


GetTopAuthorities <- function() {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  authority_query <- "Select point_of_delivery_balancing_authority, sum(total_quantity) as total_quantity from fieldslite group by point_of_delivery_balancing_authority order by total_quantity desc"
  authority_frame <- dbGetQuery(con, authority_query)
  
  dbDisconnect(con)
  
  return (authority_frame$point_of_delivery_balancing_authority)
  
}

ExpandAuthorities <- function(nicknames) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  match_query <- "Select * from authority_match"
  match_frame <- dbGetQuery(con, match_query)
  
  dbDisconnect(con)
  
  # match nicknames to names
  index <- match(nicknames, match_frame$nickname)
  names <- match_frame$name[index]
  
  
  # Return it in alphabetical order
  return (sort(names))
  
}



################### Text

welcome <- "This is Friendly FERC, a convenient portal for viewing and downloading public electricity contract data. We call this interface 'EQR Lite'. See the FAQ tab for the weedy details."

price_hour_text <- 'Shows the weighted average price of electricity sold in each hour of the day, calculated from data matching the selected date range.'
quantity_hour_text <- 'Shows the sum total quantity of electricity sold in each hour of the day, calculated from data matching the selected date range.'
quantity_month_text <- 'Shows the sum total quantity of electricity sold in each month / year, calculated from data matching the selected date range.'
price_month_text <- 'Shows the weighted average price of electricity sold in each month / year, calculated from data matching the selected date range.'
price_datetime_text <- 'The black line shows the weighted average price of electricity sold in each available time period, calculated from data matching the selected date range. The blue line shows a moving average of the black line. Note: Sellers vary widely in the time period granularity of their reporting. Most report one or more transactions each hour, but some report just once per day or even less frequent. '
quantity_datetime_text <- 'The black line shows the sum total quantity of electricity sold in each available time period, calculated from data matching the selected date range. The red line shows a moving average of the black line. Note: Sellers vary widely in the time period granularity of their reporting. Most report one or more transactions each hour, but some report just once per day or even less frequent. '
customer_breakdown_text <- 'Shows the percentage share of sales for the top 15 customers of the seller company in the selected balancing authority. Note: This graph is not affected by the date range slider, it represents all available data.'




############################ Main section

shinyUI(
  
  fluidPage(
    
    tags$head(includeScript("google-analytics.js")),
    headerPanel("Friendly FERC: EQR Lite (*Q3 2016*)", windowTitle = "Friendly FERC"),
    
  
  sidebarLayout(
    
    sidebarPanel(
      
      helpText(welcome),
      
      textOutput('summary_sentence'),
      
      selectizeInput('point_of_delivery_balancing_authority', 'Select Balancing Authority: ',
                  choices=ExpandAuthorities(GetTopAuthorities()),
                  selected = 'California Independent System Operator', multiple=FALSE),
      
      uiOutput('seller_ui'),
      
      uiOutput('customer_ui'),
      
      helpText("Hit 'Go' to update all graphs."),
      
      actionButton('action', 'Go')
      

      
    ),
    mainPanel(
      sliderInput('date_range','Select Date Range: ', 
                  min=as.Date('2013-07-01'), max=as.Date('2016-09-30'),
                  value=c(as.Date('2015-01-01'),as.Date('2015-12-31')),
                  timeFormat="%F"),
      tabsetPanel(
        tabPanel('Price Hour', 
                 plotlyOutput('price_hour'),
                 helpText(price_hour_text),
                 DT::dataTableOutput('price_hour_table'),
                 downloadButton('download_price_hour', 'Download Graph'),
                 downloadButton('download_hour', 'Download CSV')),
        tabPanel('Price Month', 
                 plotlyOutput('price_month'),
                 helpText(price_month_text),
                 DT::dataTableOutput('price_month_table'),
                 downloadButton('download_price_month', 'Download Graph'),
                 downloadButton('download_month', 'Download CSV')),
        tabPanel('Quantity Hour', 
                 plotlyOutput('quantity_hour'),
                 helpText(quantity_hour_text),
                 downloadButton('download_quantity_hour', 'Download Graph'),
                 downloadButton('download_hour_copy', 'Download CSV')),
        tabPanel('Quantity Month', 
                 plotlyOutput('quantity_month'),
                 helpText(quantity_month_text),
                 downloadButton('download_quantity_month', 'Download Graph'),
                 downloadButton('download_month_copy', 'Download CSV')),
        tabPanel("Price Datetime", 
                 plotOutput('price_datetime'),
                 helpText(price_datetime_text),
                 downloadButton('download_price_datetime', 'Download Graph'),
                 downloadButton('download_datetime', 'Download CSV')),
        tabPanel("Quantity Datetime", 
                 plotOutput('quantity_datetime'),
                 helpText(quantity_datetime_text),
                 downloadButton('download_quantity_datetime', 'Download Graph'),
                 downloadButton('download_datetime_copy', 'Download CSV')),
        tabPanel("Customer Breakdown",
                 plotOutput('customer_breakdown'),
                 helpText(customer_breakdown_text),
                 downloadButton('download_customer_breakdown', 'Download Graph')),
        tabPanel('FAQ', includeHTML('index.html'))
      )
      
    )
    
  )
  
)
)



