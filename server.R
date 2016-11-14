library(shiny)
library(RMySQL)
library(ggplot2)
library(fasttime)
library(dplyr)
library(lubridate)
library(stringr)
library(mgcv)
library(grid)
library(gridExtra)
library(DT)
library(plotly)

# Set basic theme
theme_set(theme_grey(base_size = 14))


##########

source("creds.R")



########################### Primary functions

# Get the whole dataframe that matches seller + customer
GetRawData <- function(point_of_delivery_balancing_authority, seller_company_name, customer_company_name) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  query <- sprintf("Select * from eqrlite where point_of_delivery_balancing_authority='%s' and seller_company_name='%s' and customer_company_name='%s'",
                   point_of_delivery_balancing_authority, seller_company_name, customer_company_name)
  
  selected_frame <- dbGetQuery(con, query)
  
  selected_frame$transaction_begin_date <- fastPOSIXct(selected_frame$transaction_begin_date)
  
  selected_frame$hour <- hour(selected_frame$transaction_begin_date)
  selected_frame$month <- month(selected_frame$transaction_begin_date)
  selected_frame$year <- year(selected_frame$transaction_begin_date)
  
  dbDisconnect(con)
  
  return (selected_frame)
  
}



GetSummary <- function(selected_frame) {
  
  rows <- dim(selected_frame)[1]
  total_quantity <- format(round(sum(selected_frame$total_quantity)/1000, 1), nsmall=1)
  average_price <- format(round(sum(selected_frame$total_revenue) / sum(selected_frame$total_quantity), 2), nsmall=2)
  summary <- sprintf("*** Current selections contain %i rows, %s GWh at an average price of $%s ***", rows, total_quantity, average_price)
  return (summary)
}

GetTitle <- function(point_of_authority_balancing_authority, seller_company_name, customer_company_name) {
  
  title <- sprintf("%s sells to %s (%s)", seller_company_name, customer_company_name, point_of_authority_balancing_authority)
  
  return (title)
}


GetAuthorities <- function() {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  authority_query <- "Select point_of_delivery_balancing_authority from fieldslite group by point_of_delivery_balancing_authority"
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
  
  authority_query <- "Select point_of_delivery_balancing_authority, sum(total_quantity) as total_quantity from fieldslite group by point_of_delivery_balancing_authority order by total_quantity desc limit 50"
  authority_frame <- dbGetQuery(con, authority_query)
  
  dbDisconnect(con)
  
  return (authority_frame$point_of_delivery_balancing_authority)
  
}


GetSellers <- function(point_of_delivery_balancing_authority) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  sellers_query <- sprintf("Select seller_company_name from fieldslite where point_of_delivery_balancing_authority='%s' group by seller_company_name", point_of_delivery_balancing_authority)
  sellers_frame <- dbGetQuery(con, sellers_query)
  
  dbDisconnect(con)
  
  return (sellers_frame$seller_company_name)
  
}



GetCustomers <- function(point_of_delivery_balancing_authority, seller_company_name) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  customers_query <- sprintf("Select customer_company_name from fieldslite where point_of_delivery_balancing_authority='%s'and seller_company_name='%s' group by customer_company_name", point_of_delivery_balancing_authority, seller_company_name)
  customers_frame <- dbGetQuery(con, customers_query)
  
  dbDisconnect(con)
  
  return (customers_frame$customer_company_name)
  
}


GetCustomerQuantities <- function(point_of_delivery_balancing_authority, seller_company_name) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  customers_query <- sprintf("Select customer_quantity from fieldslite where point_of_delivery_balancing_authority='%s'and seller_company_name='%s' group by customer_company_name", point_of_delivery_balancing_authority, seller_company_name)
  customers_frame <- dbGetQuery(con, customers_query)
  
  dbDisconnect(con)
  
  return (customers_frame$customer_quantity)
  
}


ContractAuthorities <- function(names) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  match_query <- "Select * from authority_match"
  match_frame <- dbGetQuery(con, match_query)
  
  dbDisconnect(con)
  
  # match names to nicknames
  index <- match(names, match_frame$name)
  nicknames <- match_frame$nickname[index]
  
  return(nicknames)
  
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



PullCustomer <- function(customer_quantity) {
  
  customer_frame <- as.data.frame(str_match(customer_quantity, "(^.+)\\s\\*\\*\\*.+\\*\\*\\*"))
  names(customer_frame) <- c('customer_quantity','customer_company_name')
  
  return (as.character(customer_frame$customer_company_name))
}



GetCustomerBreakdown <- function(point_of_delivery_balancing_authority, seller_company_name) {
  
  con <- dbConnect(RMySQL::MySQL(),
                   dbname='ferc',
                   username=username,
                   password=password,
                   host='stolemarch.cskdhnmb36bo.us-east-1.rds.amazonaws.com',
                   port=3306)
  
  seller_query <- sprintf("Select customer_company_name, total_quantity from fieldslite where point_of_delivery_balancing_authority='%s'and seller_company_name='%s'", point_of_delivery_balancing_authority, seller_company_name)
  seller_frame <- dbGetQuery(con, seller_query)
  
  dbDisconnect(con)
  
  total <- sum(seller_frame$total_quantity)
  seller_frame$share_percentage <- (seller_frame$total_quantity / total) * 100
  
  seller_frame <- seller_frame %>% arrange(desc(share_percentage))
  seller_frame <- transform(seller_frame, 
                            customer_company_name = reorder(customer_company_name, share_percentage))
  
  return (seller_frame[1:15,])
}


########################### Main section

# server
shinyServer( 
  
  function(input, output, session) {
    
    authority_nickname <- reactive({ContractAuthorities(input$point_of_delivery_balancing_authority)})
    
    customer_actual <- reactive({PullCustomer(input$customer_company_name)})

    title_change <- eventReactive(input$action, {GetTitle(authority_nickname(), input$seller_company_name, customer_actual())})
    
    output$seller_ui <- renderUI({
      
      validate(
        need(input$point_of_delivery_balancing_authority, 'Make selection to continue.')
      )
      
      selected_sellers <- GetSellers(authority_nickname())
      selectizeInput('seller_company_name', 'Select Seller Company: ',
                  choices=selected_sellers,
                  selected="Agua Caliente Solar, LLC", multiple=FALSE)
      
    })
    
    output$customer_ui <- renderUI({
      
      validate(
        need(input$seller_company_name, 'Make selection to continue.')
      )
      
      selected_customers <- GetCustomerQuantities(authority_nickname(), input$seller_company_name)
      selectInput('customer_company_name', 'Select Customer Company: ',
                  choices=selected_customers)
      
    })

    
    raw_frame <- eventReactive(input$action, {GetRawData(authority_nickname(),
                                                              input$seller_company_name, customer_actual())})
    
    
    date_fixer <- reactive({unlist(strsplit(paste(input$date_range, collapse =' '), ' '))})
    
    selected_frame <- reactive({raw_frame() %>% filter(transaction_begin_date > date_fixer()[1]) %>% filter(transaction_begin_date < date_fixer()[2])})
    
    
    summary_sentence <- reactive({
      GetSummary(selected_frame())
    })
    
    output$summary_sentence <- renderText(summary_sentence())
    
    frame_by_month <- reactive({selected_frame() %>% group_by(year, month) %>% summarise(total_quantity=sum(total_quantity),total_revenue=sum(total_revenue),average_price=total_revenue / total_quantity)})
    frame_by_hour <- reactive({selected_frame() %>% group_by(hour) %>% summarise(total_quantity=sum(total_quantity),total_revenue=sum(total_revenue),average_price=total_revenue / total_quantity)})

    output$download_month <- downloadHandler(
      
      filename = 'output_by_month.csv',
      content = function(file) {
        
        write.csv(frame_by_month(), file, row.names=F)
      })
    
    output$download_month_copy <- downloadHandler(
      
      filename = 'output_by_month.csv',
      content = function(file) {
        
        write.csv(frame_by_month(), file, row.names=F)
      })
    
    output$download_hour <- downloadHandler(
      
      filename = 'output_by_hour.csv',
      content = function(file) {
        
        write.csv(frame_by_hour(), file, row.names=F)
      })
    
    output$download_hour_copy <- downloadHandler(
      
      filename = 'output_by_hour.csv',
      content = function(file) {
        
        write.csv(frame_by_hour(), file, row.names=F)
      })
    
    output$download_datetime <- downloadHandler(
      
      filename = 'output_by_datetime.csv',
      content = function(file) {
        
        write.csv(selected_frame(), file, row.names=F)
      })
    
    output$download_datetime_copy <- downloadHandler(
      
      filename = 'output_by_datetime.csv',
      content = function(file) {
        
        write.csv(selected_frame(), file, row.names=F)
      })

    
    price_hour_graph <- function() {
      
      price_hour_frame <- selected_frame() %>%
        group_by(hour) %>%
        summarise(total_quantity=sum(total_quantity),
                  total_revenue=sum(total_revenue),
                  average_price=total_revenue / total_quantity)
      
      ggplot(aes_string(x='hour', y='average_price'),
             data=price_hour_frame) +
        geom_line(size=0.7, col='navyblue') +
        geom_point(size=1.5) +
        xlab('Hour of Day') +
        ylab('Average Price ($/MWh)') +
        ggtitle(title_change()) +
        theme_gray(10) +
        theme(plot.title = element_text(size=12, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold" , vjust=0.35))    
      }
    
    output$price_hour <- renderPlotly({price_hour_graph()})
    
    output$price_hour_table <- DT::renderDataTable({DT::datatable(frame_by_hour())})
      
    
    
    output$download_price_hour <- downloadHandler(
      filename = 'price_hour.jpeg',
      content = function(file) {
        ggsave(file, plot=price_hour_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    price_month_graph <- function() { 
      
      price_month_frame <- selected_frame() %>%
        group_by(year, month) %>%
        summarise(total_quantity=sum(total_quantity),
                  total_revenue=sum(total_revenue),
                  average_price=total_revenue / total_quantity)
      
      price_month_frame$month_start <- paste(price_month_frame$year,'-',price_month_frame$month,'-01',sep='')
      price_month_frame$month_start <- as.Date(price_month_frame$month_start, format='%Y-%m-%d')
      
      ggplot(aes_string(x='month_start', y='average_price'),
             data=price_month_frame) +
        geom_line(size=0.7, col='navyblue') +
        geom_point(size=1.5) +
        xlab('Month') +
        ylab('Average Price ($/MWh)') +
        ggtitle(title_change()) +
        theme_gray(10) +
        theme(plot.title = element_text(size=12, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
                axis.title.y = element_text(face="bold" , vjust=0.35))
      }
    
    output$price_month <- renderPlotly({price_month_graph()})
    
    output$price_month_table <- DT::renderDataTable({DT::datatable(frame_by_month())})
    
    output$download_price_month <- downloadHandler(
      filename = 'price_month.jpeg',
      content = function(file) {
        ggsave(file, plot=price_month_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    quantity_hour_graph <- function() {
      
      ggplot(aes_string(x='hour', y='total_quantity'),
             data=selected_frame() %>% group_by(hour) %>% summarise(total_quantity=sum(total_quantity))) +
        geom_line(size=0.7, col='red4') +
        geom_point(size=1.5) +
        xlab('Hour of Day') +
        ylab('Quantity (MWh)') +
        ggtitle(title_change())  +
        theme_gray(10) +
        theme(plot.title = element_text(size=12, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold", vjust=0.35))
      }
    
    output$quantity_hour <- renderPlotly({quantity_hour_graph()})
    
    output$download_quantity_hour <- downloadHandler(
      filename = 'quantity_hour.jpeg',
      content = function(file) {
        ggsave(file, plot=quantity_hour_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    quantity_month_graph <- function() {
      
      quantity_month_frame <- selected_frame() %>%
        group_by(year, month) %>%
        summarise(total_quantity=sum(total_quantity))
      
      quantity_month_frame$month_start <- paste(quantity_month_frame$year,'-',quantity_month_frame$month,'-01',sep='')
      quantity_month_frame$month_start <- as.Date(quantity_month_frame$month_start, format='%Y-%m-%d')
      
      ggplot(aes_string(x='month_start', y='total_quantity'),
             data=quantity_month_frame) +
        geom_line(size=0.7, col='red4') +
        geom_point(size=1.5) +
        xlab('Month') +
        ylab('Quantity (MWh)') +
        ggtitle(title_change()) +
        theme_gray(10) +
        theme(plot.title = element_text(size=12, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold" , vjust=0.35))
      }
    
    output$quantity_month <- renderPlotly({quantity_month_graph()})
    
    output$download_quantity_month <- downloadHandler(
      filename = 'quantity_month.jpeg',
      content = function(file) {
        ggsave(file, plot=quantity_month_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    price_datetime_graph <- function() {
      
      ggplot(aes_string(x='transaction_begin_date', y='average_price'),
             data=selected_frame()) +
        geom_line(alpha=0.7) +
        geom_smooth(col='navyblue') +
        xlab('Datetime') +
        ylab('Price ($/MWh)') +
        ggtitle(title_change()) +
        theme(plot.title = element_text(size=16, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold", vjust=0.35))
    }
    
    output$price_datetime <- renderPlot({price_datetime_graph()})
    
    
    output$download_price_datetime <- downloadHandler(
      filename = 'price_datetime.jpeg',
      content = function(file) {
        ggsave(file, plot=price_datetime_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    quantity_datetime_graph <- function() {
      
      ggplot(aes_string(x='transaction_begin_date', y='total_quantity'),
             data=selected_frame()) +
        geom_line(alpha=0.7) +
        geom_smooth(col='red4') +
        xlab('Datetime') +
        ylab('Quantity (MWh)') +
        ggtitle(title_change()) +
        theme(plot.title = element_text(size=16, face="bold", margin = margin(10, 0, 10, 0))) +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold" , vjust=0.35))
      }
    
    output$quantity_datetime <- renderPlot({quantity_datetime_graph()})
    
    output$download_quantity_datetime <- downloadHandler(
      filename = 'quantity_datetime.jpeg',
      content = function(file) {
        ggsave(file, plot=quantity_datetime_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    
    
    customer_breakdown_frame <- eventReactive(input$action,{GetCustomerBreakdown(authority_nickname(), input$seller_company_name)})

    
    
    customer_breakdown_graph <- function() {
      
      ggplot(aes(x=customer_company_name, y=share_percentage),
             data=customer_breakdown_frame()) +
        geom_bar(stat='identity', fill='red4') +
        coord_flip() +
        ylab('Share of sales (%)') +
        xlab('Customer Company') +
        theme(axis.title.x = element_text(face="bold", vjust=-0.35),
              axis.title.y = element_text(face="bold" , vjust=0.35))
      
    }
    
    output$customer_breakdown <- renderPlot({customer_breakdown_graph()})
    
    output$download_customer_breakdown <- downloadHandler(
      filename = 'customer_breakdown.jpeg',
      content = function(file) {
        ggsave(file, plot=customer_breakdown_graph(), 
               width=300, height=150,
               units='mm')
      }
    )
    
    

    
}
)

