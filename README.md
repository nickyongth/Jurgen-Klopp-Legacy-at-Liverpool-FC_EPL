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

![Query 2 Answer](https://github.com/nickyongth/images-/blob/main/query2_answer.png)

3. Among Liverpool defenders with more than 40 match appearances, who are the top performers in terms of average tackle success rate, shots blocked, interceptions, and errors?

````sql
WITH ranked_defense AS (
    SELECT d.Player,
           ROUND(AVG(CAST(d.`Challenges Tkl%` AS DECIMAL(5,2))), 2) AS Avg_Tackle_Success_Rate,
           ROUND(AVG(CAST(d.`Blocks Sh` AS UNSIGNED)), 2) AS Avg_Shots_Blocked,
           ROUND(AVG(CAST(d.`Int` AS UNSIGNED)), 2) AS Avg_Interceptions,		
           ROUND(AVG(CAST(d.`Err` AS UNSIGNED)), 2) AS Avg_Errors,
           RANK() OVER (ORDER BY AVG(CAST(d.`Challenges Tkl%` AS DECIMAL(5,2))) DESC, AVG(CAST(d.`Err` AS UNSIGNED)) ASC) AS defense_rank
    FROM defense_lfc d
    JOIN (
        SELECT Player
        FROM playing_time_lfc
        WHERE Pos = 'DF'
        GROUP BY Player
        HAVING SUM(MP) > 40
    ) s ON d.Player = s.Player
    WHERE d.Pos = 'DF'
    GROUP BY d.Player
)
SELECT Player, Avg_Tackle_Success_Rate, Avg_Shots_Blocked, Avg_Interceptions, Avg_Errors
FROM ranked_defense
WHERE defense_rank <= 10;
````
**Answer:**

![Query 3 Answer](https://github.com/nickyongth/images-/blob/main/query3_answer.png)

4. Who are the top 10 Liverpool players with the highest average goal creation actions (including passes, take-ons, and drawing fouls leading to a goal) and shot creation actions (including passes, take-ons, and drawing fouls leading to a shot) over the past seven seasons?

````sql
WITH player_averages AS (
    SELECT gsc.Player, 
           ROUND(AVG(CAST(gsc.`GCA GCA` AS UNSIGNED)), 2) AS Avg_GCA,
           ROUND(AVG(CAST(gsc.`SCA SCA` AS UNSIGNED)), 2) AS Avg_SCA,
           ROUND(AVG(CAST(gsc.`GCA GCA` AS UNSIGNED) + CAST(gsc.`SCA SCA` AS UNSIGNED)), 2) AS Avg_GCA_SCA
    FROM gsc_lfc gsc
    GROUP BY gsc.Player
)
SELECT Player, Avg_GCA, Avg_SCA, Avg_GCA_SCA
FROM player_averages
ORDER BY Avg_GCA_SCA DESC
LIMIT 10;
````
**Answer:**

![Query 4 Answer](https://github.com/nickyongth/images-/blob/main/query4_answer.png)

5. What are Liverpool's home and away game win percentages, and how does the goal difference (goals for vs. goals against) compare in these settings for the last 7 seasons in the EPL?

````sql
WITH home_stats AS (
    SELECT season,
           COUNT(*) AS Home_Matches,
           COUNT(CASE WHEN Result = 'W' THEN 1 END) AS Home_Wins,
           SUM(CAST(GF AS UNSIGNED)) AS Home_Goals_For,
           SUM(CAST(GA AS UNSIGNED)) AS Home_Goals_Against
    FROM match_lfc
    WHERE Venue = 'Home'
    GROUP BY season
), away_stats AS (
    SELECT season,
           COUNT(*) AS Away_Matches,
           COUNT(CASE WHEN Result = 'W' THEN 1 END) AS Away_Wins,
           SUM(CAST(GF AS UNSIGNED)) AS Away_Goals_For,
           SUM(CAST(GA AS UNSIGNED)) AS Away_Goals_Against
    FROM match_lfc
    WHERE Venue = 'Away'
    GROUP BY season
)
SELECT hs.season, ROUND(hs.Home_Wins / hs.Home_Matches * 100, 2) AS Home_Win_Percentage,
       hs.Home_Goals_For - hs.Home_Goals_Against AS Home_Goal_Difference,
       ROUND(aws.Away_Wins / aws.Away_Matches * 100, 2) AS Away_Win_Percentage,
       aws.Away_Goals_For - aws.Away_Goals_Against AS Away_Goal_Difference
FROM home_stats hs
JOIN away_stats aws ON hs.season = aws.season
ORDER BY hs.season DESC;
````
**Answer:**

![Query 5 Answer](https://github.com/nickyongth/images-/blob/main/query5_answer.png)

6. What is the average ball possession percentage for Liverpool FC by season, and how does it relate to their win percentage in each of those 7 EPL seasons?

````sql
WITH season_stats AS (
    SELECT season, 
           AVG(CAST(Poss AS DECIMAL(5,2))) AS Avg_Possession,
           SUM(CASE WHEN Result = 'W' THEN 1 ELSE 0 END) / COUNT(*) AS Win_Percentage
    FROM match_lfc
    GROUP BY season
)
SELECT season, Avg_Possession, ROUND(Win_Percentage * 100, 2) AS Win_Percentage
FROM season_stats
ORDER BY Avg_Possession DESC;
````
**Answer:**

![Query 6 Answer](https://github.com/nickyongth/images-/blob/main/query6_answer.png)


## Tools and Technologies

- **Data Collection:** Python for web scraping data from FBref.
- **Database:** MySQL for SQL queries and analysis.


