# 1)
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

# 2)
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

# 3)
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


# 4)
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

# 5)
WITH player_impact AS (
    SELECT pt.Player, 
           SUM(CAST(pt.`Team Success onG` AS UNSIGNED)) AS Goals_For,
           SUM(CAST(pt.`Team Success onGA` AS UNSIGNED)) AS Goals_Against,
           SUM(CAST(pt.`Team Success onG` AS UNSIGNED)) - SUM(CAST(pt.`Team Success onGA` AS UNSIGNED)) AS Goal_Difference
    FROM playing_time_lfc pt
    GROUP BY pt.Player
)
SELECT Player, Goals_For, Goals_Against, Goal_Difference
FROM player_impact
ORDER BY Goal_Difference DESC;

# 6)
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

# 7) 
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

# 8)
WITH attendance_performance AS (
    SELECT CASE
               WHEN Attendance < 20000 THEN 'Low'
               WHEN Attendance BETWEEN 20000 AND 40000 THEN 'Medium'
               WHEN Attendance > 40000 THEN 'High'
           END AS Attendance_Range,
           COUNT(CASE WHEN Result = 'W' THEN 1 END) AS Wins,
           COUNT(CASE WHEN Result = 'L' THEN 1 END) AS Losses,
           COUNT(CASE WHEN Result = 'D' THEN 1 END) AS Draws,
           SUM(CAST(GF AS UNSIGNED)) AS Goals_For,
           SUM(CAST(GA AS UNSIGNED)) AS Goals_Against
    FROM match_lfc
    WHERE Venue = 'Home'
    GROUP BY Attendance_Range
)
SELECT Attendance_Range, Wins, Losses, Draws, Goals_For, Goals_Against
FROM attendance_performance
ORDER BY Attendance_Range;

# 9)
WITH day_performance AS (
    SELECT Day, 
           COUNT(*) AS Total_Matches,
           COUNT(CASE WHEN Result = 'W' THEN 1 END) AS Wins,
           COUNT(CASE WHEN Result = 'L' THEN 1 END) AS Losses,
           COUNT(CASE WHEN Result = 'D' THEN 1 END) AS Draws,
           SUM(CAST(GF AS UNSIGNED)) AS Goals_For,
           SUM(CAST(GA AS UNSIGNED)) AS Goals_Against
    FROM match_lfc
    GROUP BY Day
)
SELECT Day, Wins, Losses, Draws, Goals_For, Goals_Against,
       ROUND(Wins / Total_Matches * 100, 2) AS Win_Percentage,
       Goals_For - Goals_Against AS Goal_Difference
FROM day_performance
ORDER BY Win_Percentage DESC;

