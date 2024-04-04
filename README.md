# Jurgen Klopp's EPL Legacy at Liverpool FC: A Data-Driven Retrospective (2017-Present)

## Project Overview

As Jurgen Klopp's illustrious tenure as manager of Liverpool Football Club draws to a close with his retirement after this season, this project seeks to quantitatively capture and analyze his profound influence on the club's performance in the English Premier League from 2017 to the present. Using SQL and Python, the analysis delves into the myriad ways Klopp has shaped the team’s strategies, player development, and match performances. This retrospective aims to provide a data-backed exploration of Liverpool’s evolution under Klopp’s guidance, reflecting on the tactics, decisions, and player progressions that have marked this era.

## Data Source

The data for this analysis was scraped from [FBref](https://fbref.com/), a comprehensive football statistics website, using Python.

### Key Questions and Insights

1. Who are Liverpool FC's most efficient goal scorers in terms of total goals scored, shooting accuracy (as measured by the shots on target percentage), and goal-scoring efficiency (evaluated through the goals to shots ratio) during Klopp's tenure over the last seven EPL seasons?

````sql
WITH player_goal_stats AS (
    SELECT s.Player, s.Pos,
           SUM(CAST(`s`.`Performance Gls` AS UNSIGNED)) AS Total_Goals
    FROM standard_stats_lfc s
    GROUP BY s.Player, s.Pos
), player_shooting_stats AS (
    SELECT sh.Player,
           SUM(CAST(`sh`.`Standard Sh` AS UNSIGNED)) AS Total_Shots,
           ROUND(AVG(CAST(`sh`.`Standard SoT%` AS DECIMAL(5,2))), 2) AS Avg_Shots_On_Target_Percentage,
           ROUND(SUM(CAST(`sh`.`Standard Gls` AS UNSIGNED)) / NULLIF(SUM(CAST(`sh`.`Standard Sh` AS UNSIGNED)), 0), 2) AS Goal_Shot_Ratio
    FROM shooting_lfc sh
    GROUP BY sh.Player
)
SELECT pg.Player, pg.Pos, pg.Total_Goals,
       ps.Avg_Shots_On_Target_Percentage, ps.Goal_Shot_Ratio
FROM player_goal_stats pg
JOIN player_shooting_stats ps ON pg.Player = ps.Player
ORDER BY Total_Goals DESC
LIMIT 10;
````
**Answer:**

![Query 1 Answer](https://github.com/nickyongth/images-/blob/main/query1_answer.png)

2. Who are Liverpool's playmakers in terms of average assists, free kick passes, through balls, and crosses over the last seven EPL seasons?

````sql
WITH player_assists AS (
    SELECT p.Player, p.Pos,
           ROUND(AVG(CAST(p.`Ast` AS UNSIGNED)), 2) AS Avg_Assists
    FROM passing_lfc p
    GROUP BY p.Player, p.Pos
), player_pass_types AS (
    SELECT pt.Player,
           ROUND(AVG(CAST(pt.`Pass Types FK` AS UNSIGNED)), 2) AS Avg_FK_Passes,
           ROUND(AVG(CAST(pt.`Pass Types TB` AS UNSIGNED)), 2) AS Avg_Through_Balls,
           ROUND(AVG(CAST(pt.`Pass Types Crs` AS UNSIGNED)), 2) AS Avg_Crosses
    FROM pass_type_lfc pt
    GROUP BY pt.Player
)
SELECT pa.Player, pa.Pos, 
       pa.Avg_Assists,
       ppt.Avg_FK_Passes,
       ppt.Avg_Through_Balls,
       ppt.Avg_Crosses
FROM player_assists pa
JOIN player_pass_types ppt ON pa.Player = ppt.Player
ORDER BY Avg_Assists DESC
LIMIT 10; 
````
**Answer:**

## Tools and Technologies

- **Data Collection:** Python for web scraping data from FBref.
- **Database:** MySQL for SQL queries and analysis.


