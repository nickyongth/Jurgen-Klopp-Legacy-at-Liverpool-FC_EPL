# Jurgen Klopp's Legacy at Liverpool FC: A Data-Driven Retrospective (2017-Present)

## Project Overview

As Jurgen Klopp's illustrious tenure as manager of Liverpool Football Club draws to a close with his retirement after this season, this project seeks to quantitatively capture and analyze his profound influence on the club from 2017 to the present. Using SQL and Python, the analysis delves into the myriad ways Klopp has shaped the team’s strategies, player development, and match performances. This retrospective aims to provide a data-backed exploration of Liverpool’s evolution under Klopp’s guidance, reflecting on the tactics, decisions, and player progressions that have marked this era.

## Data Source

The data for this analysis was scraped from [FBref](https://fbref.com/), a comprehensive football statistics website, using Python.

### Key Questions and Insights

1. Who are Liverpool FC's most efficient goal scorers in terms of total goals scored, shooting accuracy (as measured by the shots on target percentage), and goal-scoring efficiency (evaluated through the goals to shots ratio) during Klopp's tenure over the last seven EPL seasons?

````sql
SELECT 
  COUNT(DISTINCT id) AS unique_users
FROM health.user_logs
````


## Tools and Technologies

- **Data Collection:** Python for web scraping data from FBref.
- **Database:** MySQL for SQL queries and analysis.


