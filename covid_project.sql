
--percentage of cases that resulted in death
SELECT location, date, total_cases, total_deaths,
       (total_deaths/total_cases)*100 AS perc_dead FROM deaths
        WHERE location = 'United States'
ORDER BY 2 DESC

--total cases versus population (with caveat that individual can be represented multiple times in dataset.
-- I am also looking at excess mortality via WHO in future)

SELECT location, date, total_cases, total_deaths,
       (total_cases/population)*100 AS perc_pop_ FROM deaths
        WHERE location = 'United States'
ORDER BY 2 DESC

--highest percentage of infection rate, which country?
SELECT location, population, MAX(total_cases) as highest_by_country,
       MAX(total_cases/population)*100 AS perc_pop_ FROM deaths
       -- WHERE location = 'United States'
        GROUP BY population, location
ORDER BY 4 DESC

--highest percentage of death, which country?

SELECT location, population, MAX(total_cases) as highest_by_country,
       MAX(total_deaths/population)*100 AS perc_pop FROM deaths
       -- WHERE location = 'United States'
        GROUP BY population, location
ORDER BY 4 DESC

--total deaths by country
SELECT location, population, MAX(total_deaths) as highest_by_country,
       MAX(total_deaths/population)*100 AS perc_pop FROM deaths
       -- WHERE location = 'United States'
                                                    WHERE continent IS NOT NULL
        GROUP BY population, location
ORDER BY 3 DESC

--examine by income, EU, etc

SELECT location, MAX(total_deaths) ,
       MAX(total_deaths/population)*100 AS perc_pop FROM deaths
       -- WHERE location = 'United States'
        WHERE continent IS NULL
        GROUP BY location
ORDER BY 2 DESC

--showing country on cont with highest death count. does not show spec country; eg, North America's max represents
-- the US, but IS is not shown in output

SELECT continent, location, MAX(total_deaths) ,
       MAX(total_deaths/population)*100 AS perc_pop FROM deaths
       -- WHERE location = 'United States'
        WHERE continent IS NOT NULL
        GROUP BY continent, location

--global numbers, this query looks at new cases and deaths by day

SELECT date, SUM(new_cases)--, SUM(new_deaths)
       --(total_deaths/total_cases)*100 AS perc_dead
       FROM deaths
        WHERE continent IS NOT NULL
        GROUP BY date
ORDER BY 1

-- change date type of other table so we can join; I am not going to join by primary key here
ALTER TABLE vaccinations ALTER COLUMN date TYPE date USING to_date(date,'mm/dd/yy')

--join deaths and vaccinations on location and date

SELECT * FROM deaths dea
    JOIN vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

--total pop versus vaccinations,

         SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS climbing_count_vax,
        (climbing_count_vax/population)*100
         FROM deaths dea
    JOIN vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Using CTE, we can do operations on the column we created in the same query
WITH pop_v_vac (continent, location, date, population, new_vaccinations, climbing_count_vax)
AS
(
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS climbing_count_vax

         FROM deaths dea
    JOIN vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
 SELECT *, (climbing_count_vax/population)*100 AS perc_vaccinated FROM pop_v_vac


--looking at this again, but just US this time. Climbing_count_vax counts individual days' vaccination numbers by location
--and adds it to the total for that location (rolling count). Looking at their github (https://github.com/owid/covid-19-data/tree/master/public/data/),
-- new_vaccinations is not as accurate of a measure as people_fully_vaccinated when we are trying to get the percentage of people vaccinated.
-- The new_vaccinations column, judging just by US numbers, includes follow-up booster shots in addition to the first two initial shots.
--People_vaccinated is just the # people who have had at least one dose of the vaccine.
--For example, on a day in December 2022 (2022-12-27): total_vaccinations = 663,822,575, people_fully-vaccinated = 229,135,170,people_vaccinated = 268,363,272
--Regardless, let's attempt to see what new_vaccinations looks like as a percentage.


 WITH pop_v_vac (continent, location, date, population, new_vaccinations, climbing_count_vax)
AS
(
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS climbing_count_vax

         FROM deaths dea
    JOIN vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.location = 'United States'
)
 SELECT *, (climbing_count_vax/population)*100 AS perc_vaccinated FROM pop_v_vac


-- Instead, here is a much simpler way of looking at this information with the below date. Let's use the latest non null date available
--to us, 2022-12-27. In the US, 663 million total vaccinations have been administered and 68% of Americans have received the initial protocol.
SELECT vac.location, dea.population, vac.date, vac.total_vaccinations, (vac.people_fully_vaccinated/dea.population)*100 as perc_vaccinated
FROM vaccinations vac
    JOIN deaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
    WHERE vac.location = 'United States'
ORDER BY 2,3


--we can create view for data visualization later

CREATE VIEW percent_vaccinated_US AS
SELECT vac.location, dea.population, vac.date, vac.total_vaccinations, (vac.people_fully_vaccinated/dea.population)*100 as perc_vaccinated
FROM vaccinations vac
    JOIN deaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
    WHERE vac.location = 'United States'


--another view

CREATE VIEW perc_pop_dead AS
SELECT location, population, MAX(total_cases) as cases_by_country,
       MAX(total_deaths/population)*100 AS perc_pop_dead FROM deaths
       WHERE continent IS NOT NULL
        GROUP BY population, location
ORDER BY 1,2