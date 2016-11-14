# friendly_ferc

This is Friendly FERC, a convenient portal for viewing and downloading public electricity contract data.

####Basics

What is FERC?
The Federal Energy Regulatory Commission, or FERC, is an independent agency that regulates the interstate transmission of electricity, natural gas, and oil.

What is Friendly FERC?
Friendly FERC is a convenient portal for viewing and downloading public data from FERC that is otherwise poorly accessible. We download, parse, and manage FERC EQR data each quarter so you don't have to.

Is this a free service?
Our current public interface (EQR Lite) is offered free of charge to the public. The source data itself is public.

Is this an official FERC data portal?
No, it is not. We are not in any way affiliated with or sponsored by FERC. Our interfaces were not built by FERC. This is not FERC. This is Friendly FERC.

####Data
What is EQR?
Most US sellers of contracted electricity must report price and quantity to FERC through Electronic Quarterly Reports. They consist of large data tables of transactions, reported often hourly, sometimes less often. The EQR Lite interface collects and munges part of this dataset. Specifically, the interface shows products marked 'energy' (ommiting data on 'capacity', 'energy imbalance', and other products). The source data can be found here.

Is the data adjusted or doctored?
The EQR Lite interface is as near a direct pull from the raw FERC-reported data as possible, with modest filtering, careful aggregation, and helpful translation of acronyms where possible.

How much data is here?
After clean up and dumping non-critical fields, the EQR dataset from Q3 2013 - Q2 2016 weighs in at ~95GB. The EQR lite interface pulls from an aggregated version of this dataset.

Can I use this data for anything I want?
Yes, this is public data. Please cite us so that your audience can come see for themselves.

What is this data useful for?
For one, market transparency. Large power plants and independent power producers (IPPs) often sign power purchase agreements (PPAs) with electric utilties without disclosing terms for delivery. These agreements can be complex, varying in price by season, by the hour, by day of the week, and/or by market commodity prices. And yet, usually these agreements are reported as a single number or not at all, leaving little recourse for journalists and academics who wish to dig deeper.

What do some of the graphs fail or downloads appear to be empty of data?
It's mostly likely because your selections reflect limited or no data at all. Many sellers report data sporatically. It's not uncommon to report an entire month's sales in a single row timestamped at midnight on a random day. A perfect, tidy dataset this is not. Also, try expanding the date range slider.

Are there plans to release more tools and features?
A 'heavier' and more granular interface for EQR data may be released, if there is interest. Matching this data with plant-level details, PPA contract details, or emissions data may also be possible. Let us know what new features would be most interesting. Requests for custom analytics based on this dataset are also welcome.

What tools were used to build this?
Data wrangling and management leverages the Python pandas library. The database is MySQL on an Amazon RDS instance. Graphs are made with the R package ggplot2 and the web interface is built using the R package shiny and hosted by RStudio's shinyapps.io.
