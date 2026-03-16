-- ## Lahman Baseball Database Exercise
--- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
--- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)
--
-- 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT p.playerid, schoolname, namefirst, namelast, SUM(sal.salary) AS total_salary
FROM people p
INNER JOIN collegeplaying cp
ON p.playerid = cp.playerid
INNER JOIN schools sch
ON sch.schoolid = cp.schoolid
INNER JOIN salaries sal
ON sal.playerid = cp.playerid
WHERE schoolname = 'Vanderbilt University'
GROUP BY p.playerid, schoolname, namefirst, namelast
ORDER BY total_salary DESC;

WITH vandy_players AS (
SELECT DISTINCT playerid
FROM collegeplaying
WHERE schoolid = 'vandy'
)
SELECT
p.namefirst || ' ' || p.namelast AS full_name,
SUM(salary)::NUMERIC::MONEY AS total_earnings
FROM salaries s
INNER JOIN vandy_players v
ON s.playerid = v.playerid
INNER JOIN people p
ON s.playerid = p.playerid
GROUP BY full_name
ORDER BY total_earnings DESC;

SELECT
P.NAMEFIRST,
P.NAMELAST,
SUM(S.SALARY) AS TOTAL_SALARY
--,CP.SCHOOLID
FROM
PEOPLE AS P
INNER JOIN SALARIES AS S USING (PLAYERID)
--INNER JOIN COLLEGEPLAYING AS CP USING (PLAYERID)
WHERE
P.playerid IN (
SELECT playerid
FROM collegeplaying
WHERE schoolid = 'vandy'
)
GROUP BY
P.NAMEFIRST,
P.NAMELAST
--,CP.SCHOOLID
ORDER BY
TOTAL_SALARY DESC;

-- 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM((f.po)),
CASE WHEN pos = 'OF' THEN 'Outfield'
WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
WHEN pos IN ('P', 'C') THEN 'Battery'
ELSE 'Unknown'
END AS field_type 
FROM people as p
INNER JOIN fielding f
ON p.playerid = f.playerid
WHERE yearid = '2016'
GROUP BY field_type;



-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

SELECT 
CASE 
WHEN yearID BETWEEN 1920 AND 1929 THEN '1920s'
WHEN yearID BETWEEN 1930 AND 1939 THEN '1930s'
WHEN yearID BETWEEN 1940 AND 1949 THEN '1940s'
WHEN yearID BETWEEN 1950 AND 1959 THEN '1950s'
WHEN yearID BETWEEN 1960 AND 1969 THEN '1960s'
WHEN yearID BETWEEN 1970 AND 1979 THEN '1970s'
WHEN yearID BETWEEN 1980 AND 1989 THEN '1980s'
WHEN yearID BETWEEN 1990 AND 1999 THEN '1990s'
WHEN yearID BETWEEN 2000 AND 2009 THEN '2000s'
WHEN yearID BETWEEN 2010 AND 2020 THEN '2010s'
ELSE '2020s'
END AS decades,
ROUND((SUM(SO) * 1.0 / ((SUM(G)/ 2))), 2) AS average_strikeouts
FROM Teams
GROUP BY decades;

SELECT 
(yearid/10)*10 AS decades,
(SUM(HR) * 1.0 / ((SUM(G)/ 2))) AS average_homeruns
FROM Teams
WHERE Yearid >= 1920
GROUP BY decades;

WITH decades AS (
SELECT *
FROM generate_series(1920, 2016, 10) AS decade_start
)
SELECT
decade_start || 's' AS decade,
ROUND(SUM(so) * 1.0 / (SUM(g) / 2.0), 2) AS so_per_game,
ROUND(SUM(hr) * 1.0 / (SUM(g) / 2.0), 2) AS hr_per_game
FROM teams t
INNER JOIN decades d
ON t.yearid BETWEEN d.decade_start AND d.decade_start + 9
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

(yearid/10)*10 AS decade

-- 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

SELECT 
	namefirst, 
	namelast, 
	SB AS stolen_bases,
	CS AS caught_stealing,
	(SB * 1.0 / (SB + CS)) AS stolen_base_pct 
FROM batting 
INNER JOIN people USING (playerid)
WHERE yearid = 2016
AND (SB + CS) >= 20
ORDER BY stolen_base_pct DESC;

WITH sb_full AS (
SELECT
playerid,
SUM(sb) AS sb,
SUM(cs) AS cs,
SUM(sb) + SUM(cs) AS attempts
FROM batting
WHERE yearid = 2016
GROUP BY playerid
)
SELECT
namefirst || ' ' || namelast AS fullname,
sb,
attempts,
ROUND(sb * 1.0 / attempts, 3) AS sb_percentage
FROM sb_full s
INNER JOIN people p
ON s.playerid = p.playerid
WHERE attempts >= 20
ORDER BY sb_percentage DESC;

SELECT
namefirst || ' ' || namelast AS fullname,
SUM(sb) AS sb,
(SUM(sb) + SUM(cs)) AS attempts,
ROUND(SUM(sb) * 100.0 / (SUM(sb) + SUM(cs)), 1) || '%' AS sb_percentage
FROM batting b
INNER JOIN people p
ON b.playerid = p.playerid
WHERE yearid = 2016
GROUP BY fullname
HAVING (SUM(sb) + SUM(cs)) >= 20
ORDER BY SUM(sb) * 100.0 / (SUM(sb) + SUM(cs)) DESC;

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


WITH ws_winners AS (
    SELECT
        teamid,
        yearid,
        w,
        wswin
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016
        AND wswin = 'Y'
),
most_wins AS (
    SELECT
        yearid,
        MAX(w) AS max_wins
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016
    GROUP BY yearid
),
winners_with_most_wins AS (
    SELECT
        w.yearid,
        teamid,
        w
    FROM ws_winners w
    INNER JOIN most_wins m
        ON w.yearid = m.yearid
        AND w.w = m.max_wins
)
SELECT
    ROUND(
        100.0 * (SELECT COUNT(*) FROM winners_with_most_wins)
              / (SELECT COUNT(*) FROM ws_winners),
        1
    ) AS pct_ws_winners_with_most_wins;

-- Los Angeles Dodgers have the lowest number of wins while obtaining a world series victory.

-- Seattle Mariners have the highest number of wins without obtaining a world series victory.

-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH both_league_winners AS (
    (
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
          AND lgid = 'AL'
    )
    INTERSECT
    (
        SELECT playerid
        FROM awardsmanagers
        WHERE awardid = 'TSN Manager of the Year'
          AND lgid = 'NL'
    )
)
SELECT
    namefirst || ' ' || namelast AS full_name,
    a.yearid,
    a.lgid,
    name
FROM awardsmanagers a
INNER JOIN people p
    ON a.playerid = p.playerid
INNER JOIN managers m
    ON a.playerid = m.playerid AND a.yearid = m.yearid
INNER JOIN teams t
    ON m.teamid = t.teamid AND m.yearid = t.yearid
WHERE a.playerid IN (SELECT * FROM both_league_winners)
  AND awardid = 'TSN Manager of the Year'
ORDER BY full_name, yearid;

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

WITH full_pitching AS (
    SELECT
        playerid,
        SUM(so) AS so,
        SUM(gs) AS gs
    FROM pitching
    WHERE yearid = 2016
    GROUP BY playerid
    HAVING SUM(gs) >= 10
),
full_salaries AS (
    SELECT
        playerid,
        SUM(salary) AS salary
    FROM salaries
    WHERE yearid = 2016
    GROUP BY playerid
)
SELECT
    namefirst || ' ' || namelast AS full_name,
    ROUND(salary::numeric / so, 2)::money AS salary_per_strikeout,
    salary::numeric::money,
    so
FROM full_pitching p
INNER JOIN full_salaries s
    ON p.playerid = s.playerid
INNER JOIN people pe
    ON p.playerid = pe.playerid
ORDER BY salary_per_strikeout DESC;


-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.

WITH three_k_hits AS (
SELECT 
	namefirst,
	namelast,
	playerid, 
	SUM(h) AS hits
FROM batting
INNER JOIN people USING (playerid)
GROUP BY playerid, namefirst, namelast
HAVING SUM(h) >= 3000
)
SELECT 
	namefirst,
	namelast,
	playerid, 
	hits,
	yearid,
	inducted
FROM three_k_hits
LEFT JOIN
(SELECT inducted, yearid, playerid
FROM halloffame
WHERE inducted = 'Y'
) AS hof USING (playerid)

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

WITH team_hits AS (
SELECT 
	playerid, 
	teamid,
	SUM(h),
	namefirst || ' ' || namelast AS full_name
FROM people p
INNER JOIN batting USING(playerid)
GROUP BY p.playerid, teamid, namefirst, namelast
HAVING SUM(h) > 1000)

SELECT full_name
FROM team_hits 
GROUP BY playerid, full_name
HAVING COUNT(teamid) >=2;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
--
-- After finishing the above questions, here are some open-ended questions to consider.
--
-- **Open-ended questions**
--
-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
--
-- 12. In this question, you will explore the connection between number of wins and attendance.
--
--    a. Does there appear to be any correlation between attendance at home games and number of wins?  
--    b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
--
--
-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?