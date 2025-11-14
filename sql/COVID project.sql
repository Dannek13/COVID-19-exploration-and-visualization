-- COVID-19 Data Exploration and Visualisation Project
-- Author: D.Grinin
-- Description: Full SQL script used for data loading, cleaning, exploration and view creation
-- Language: Comments in Czech and English

-- Nejprve je potřeba vytvořitGROUP BY country, Population, date tabulky pro nahrání dat z .CSV, z důvodu velikosti souborů je lepší využít skriptu než rozhraní v MySQL
-- Aby se předešlo případným chybám přidám DROP TABLE IF EXISTS
-- Vytvářím dvě tabulky 'CovidDeaths' a 'CovidVaccinations', propojeny jsou pomocí FOREIGN KEY

-- EN: First I drop the tables if they already exist (DROP TABLE IF EXISTS) to prevent errors when running the script multiple times.
-- Then I create two tables 'CovidDeaths' and 'CovidVaccinations'. The tables are linked using a FOREIGN KEY

DROP TABLE IF EXISTS CovidDeaths;
CREATE TABLE CovidDeaths (
continent VARCHAR (255),
code VARCHAR (255),
country VARCHAR (255),
date DATE,
population BIGINT,
total_cases BIGINT,
new_cases INT,
total_deaths BIGINT,
new_deaths INT,
PRIMARY KEY (country, date)
);

DROP TABLE IF EXISTS CovidVaccinations;
CREATE TABLE CovidVaccinations (
continent VARCHAR (255),
code VARCHAR (255),
country VARCHAR (255),
date DATE,
total_tests BIGINT,
new_tests INT,
new_vaccinations INT,
total_vaccinations BIGINT,
people_vaccinated INT,
PRIMARY KEY (country, date),
FOREIGN KEY (country, date) REFERENCES CovidDeaths (country, date)
ON DELETE CASCADE
);

-- Nyní mohu nahrát data z lokálních souborů .csv pomocí příkazu LOAD DATA LOCAL INFILE
-- Hodnoty jsou odděleny středníkem (;), textové hodnoty uzavřeny v uvozovkách ("), 
-- a jednotlivé řádky jsou odděleny znakem nového řádku (\n).
-- Pomocí IGNORE 1 ROWS přeskočím hlavičku tabulky (názvy sloupců).

-- EN: Loading data into individual tables using the LOAD DATA LOCAL INFILE command to import data from a local .csv file.
-- Values are separated by semicolons (;), text values enclosed in double quotes (") and rows are separated by newline characters (\n).
-- The IGNORE 1 ROWS option skips the header row (column names).

LOAD DATA LOCAL INFILE 'C:/.../.../.../SQL projekt/CovidDeaths.csv'
INTO TABLE CovidDeaths
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/.../.../.../SQL projekt/CovidVaccinations.csv'
INTO TABLE CovidVaccinations
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Nyní jsou tabulky připraveny k použití
-- Výběr a kontrola hlavních dat, která budu používat
-- EN: Selecting and inspecting the main data I'll be using

SELECT country, date, total_cases, new_cases, total_deaths, population 
FROM coviddeaths
ORDER BY country, date;

/*Porovnání celkového počtu případů COVID-19 s celkovým počtem úmrtí v České republice
-Použil jsem funkci LIKE '%czech%', jelikož si nejsem jist, jaký název autoři dat použili (Czechia vs. Czech Republic, obdobně jako United States vs. United States of America).
-Stejný dotaz lze použít i pro jiné země úpravou podmínky WHERE
-CFR – case fatality rate, velmi hrubý odhad pravděpodobnosti úmrtí po nakažení */

/*EN: Comparing total of COVID-19 cases with total deaths in the Czech republic
-Using LIKE '%czech%' if I’m not sure which term the dataset uses (Czechia vs. Czech Republic, similar to United States vs. United States of America)
-The same query can be used for other countries by changing the WHERE clause
-CFR – case fatality rate (a very rough estimate of the likelihood of dying after contracting the disease)*/

SELECT country, date, total_cases, total_deaths, 
	ROUND((total_deaths/total_cases)*100,2) AS CFR
FROM coviddeaths
WHERE country LIKE '%czech%'
ORDER BY country, date;

-- Vrchol pandemie COVID-19 v jednotlivých zemích
-- Použil jsem funkci RANK() a poddotaz v FROM funkci k nalezenní nejvyššího denního počtu potvrzených připadů v každé zemi
-- Podmínka new_cases 0 pro vyloučení zemí bez žádných případů

-- EN: Peak of the COVID-19 pandemic in each country
-- Using the RANK() window function and subquery in the FROM clause to find the highest number of confirmed cases in one day per country.
-- Used new_cases > 0 in WHERE clause to filter out countries with no data 

SELECT country, new_cases, date
FROM (
	SELECT country, new_cases, date, 
	RANK() OVER (PARTITION BY country ORDER BY new_cases DESC) AS Ranks 
    FROM coviddeaths) AS TopNewCases
WHERE Ranks = 1 AND new_cases > 0;

-- Procento populace nakažené COVID-19 v jednotlivých zemích a datech
-- Jedná se pouze o velmi hrubý odhad. Nezohledňuje opětovné onemocnění, zároveň populace je pro každé datum v dané zemi stejné. 

-- EN: Percentage of population infected with covid 
-- This is very rough estimate only, not fully accurate. I't doesn't account for people infected multiple times and population is constant for every date in this table

SELECT country, date, total_cases, total_deaths, population, 
	ROUND((total_cases/population)*100,2) AS infection_rate
FROM coviddeaths
ORDER BY country, date;

-- Země seřazené podle nejvyšší míry infekce v procentech populace
-- (1/4) Využito pro Tableau vizualizaci

-- EN: Countries ordered by highest infection rate.
-- (1/4) This Query will be used for visualization in Tableau Public

SELECT country, population, MAX(total_cases) AS TotalCases,
	ROUND((MAX(total_cases)/population)*100,2) AS infection_rate
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY country, population
HAVING infection_rate IS NOT NULL
ORDER BY infection_rate DESC;

-- Zde jsem si uvědomil chybu: při načítání dat do tabulky jsem nepoužil správnou podmínku pro oddělování
-- Ve sloupci byly místo hodnoty NULL prázdné texty/strings. Použitím funkce UPDATE jsem tyto hodnoty změnil na NULL. Pokud bych tak neučinil nemohl  bych použít podmínku IS/NOT/ NULL

-- EN: Here I realized my mistake, I didn't use the correct formula when loading data into table
-- There was an empty string instead of NULL. By using UPDATE statement I replaced empty strings with NULL
  
SET SQL_SAFE_UPDATES = 0;
UPDATE coviddeaths
SET continent = NULL
WHERE continent = '';
SET SQL_SAFE_UPDATES = 1;

-- Země seřazené podle celkového počtu úmrtí
-- Již spojené záznamy jako World nebo World excl. China jsem vyloučil pomocí podmínky ve WHERE

-- EN: Countries ordered by total deaths
-- Filtered out aggregated entries like World, World excl. China .... using the WHERE function

SELECT country, MAX(total_deaths) AS DeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY country
ORDER BY DeathCount DESC;
 
-- Nyní zobrazím počet smrtí seskupená podle kontinentů
-- Tato tabulka již obsahuje agregovaná data podle kontinentů, ale obsahují i nepotřebné záznamy
-- Ty vyfiltruji pomocí WHERE a IN()
-- (2/4) Query využito pro vizualizaci v Tableau Public

-- EN: Now I want to look at the numbers of deaths grouped by continent
-- This dataset already includes aggregate data by continents, but it also contains some unrelated entries such as 'Summer Olympics 2020' or 'high-income countries'
-- This data are not needed for now, so I specify which records I want by using a WHERE function and IN() clause
-- (2/4) This Query will be used for visualization in Tableau Public

SELECT country as continent, MAX(total_deaths) AS DeathCount
FROM coviddeaths
WHERE country IN ('Europe','North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY country
ORDER BY DeathCount DESC;

-- Zobrazení celosvětových denních počtů nových úmrtí a případů

-- EN: Showing global numbers per date - new deaths and cases 

SELECT 
	date, 
	SUM(new_deaths) AS daily_global_deaths, 
    SUM(new_cases) AS daily_global_cases
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Zobrazení procenta populace nakažené COVID-19 podle zemí
-- Dotaz vypočítá, jaká část populace byla infikována k danému datu
-- Zahrnuty jsou pouze záznamy s uvedeným kontinentem a výsledky jsou seřazeny od nejvyššího podílu infekcí.
-- (3/4) využito pro Tableau vizualizaci

-- EN: Displaying percentage of population infected with COVID-19 by country
-- The query calculates what portion of each country's population was infected
-- Only records with a specified continentResults are ordered by highest infection percentage.
-- (3/4) Used for Tableau visualization

SELECT country, population, date, total_cases as InfectionCount, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL AND date < '2025-09-28'
-- GROUP BY country, Population, date
HAVING PercentPopulationInfected IS NOT NULL
ORDER BY PercentPopulationInfected DESC;

-- Vypočítá globální souhrn případů a úmrtí na COVID-19. 
-- Nejprve CTE 'eachtotal' získá maximální hodnotu celkových případů a úmrtí pro každou zemi. 
-- Následně se tyto hodnoty sečtou napříč všemi zeměmi a vypočítá se globální procento úmrtnosti.
-- (4/4) využito pro Tableau vizualizaci

-- EN: Calculates the global total of COVID-19 cases and deaths.
-- First, the CTE 'eachtotal' retrieves the maximum total cases and total deaths  for each country. 
-- Then, these totals are summed across all countries, and the global death percentage is computed.
-- (4/4) Used for Tableau visualization

WITH eachtotal AS (
SELECT 
    country,
    MAX(total_cases) AS cases,
    MAX(total_deaths) AS deaths
FROM
    coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY country)

SELECT 
    SUM(cases) AS GlobalCases,
    SUM(deaths) AS GlobalDeaths,
    ROUND((SUM(deaths) / SUM(cases)) * 100, 2) DeathPercentage
FROM
    eachtotal;

-- Nyní využiji druhou tabulku CovidVaccinations, nejprve si ji prohlédnu

-- EN: Now I'm going to use the second table CovidVaccinations. First, I want to inspect this table

SELECT *
FROM covidvaccinations;

-- Teď potřebuji tyto dvě tabulky spojit, protože údaje o populaci jsou v tabulce coviddeaths a údaje o očkování jsou v tabulce covidvaccinations
-- Použil jsem JOIN s klauzulí USING, protože není potřeba složitějších podmínek pro spojení – sloupce date a country jsou shodné v obou tabulkách
-- Zde jsem použil window funkci SUM() OVER, pro spočítání kumulativního počtu očkovacích dávek v čase. Je to však jen ukázka, protože tabulka už obsahuje sloupec total_vaccinations

 -- EN: Now I need to join these two tables, because population data is in coviddeaths while vaccination data is in covidvaccinations
 -- I used JOIN with USING because there are no complex join conditions needed – the date and country fields are the same in both tables
 -- Here I used the window function SUM() OVER to calculate cumulative vaccination doses over time; this is just for demonstration, since the table already has a total_vaccinations column
 
SELECT cd.continent, cd.country, cd.date, population, new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY country ORDER BY date) AS cumulative_vaccinations
FROM coviddeaths cd
JOIN covidvaccinations cv
	USING (date, country)
WHERE cd.continent IS NOT NULL
ORDER BY continent, country, date;

-- Pro zjištění počtu očkovacích dávek na 100 osob v každé zemi, můžu použít temp table nebo CTE

-- EN: To see the vaccination doses per 100 people in country, I can use a temporary table or a CTE
 
 WITH VacPercent AS (
 SELECT cd.continent, cd.country, cd.date, population, new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY country ORDER BY date) AS cumulative_vaccinations
FROM coviddeaths cd
JOIN covidvaccinations cv
	USING (date, country)
WHERE cd.continent IS NOT NULL)

SELECT *, ROUND((cumulative_vaccinations / population)*100,2) AS doses_per_100_people
FROM VacPercent; 

-- Druhá varianta vytvoření dočasné/ temporary tabulky

-- EN: Second option is to create a temp table

DROP TEMPORARY TABLE IF EXISTS VaccinationDoses;
CREATE TEMPORARY TABLE VaccinationDoses
(
Continent varchar(255),
Location varchar(255),
Date date,
Population bigint,
New_vaccinations int,
cumulative_vaccinations bigint
);

INSERT INTO VaccinationDoses
SELECT cd.continent, cd.country, cd.date, population, new_vaccinations,
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.country ORDER BY cd.date) AS cumulative_vaccinations
FROM coviddeaths cd
JOIN covidvaccinations cv
	ON cd.country = cv.country
	AND cd.date = cv.date;

SELECT *, ROUND((cumulative_vaccinations/population)*100,2) AS doses_per_100_people
FROM VaccinationDoses;

-- Zobrazení dne, kdy jednotlivé země překročily hranici 50% proočkovanosti populace seřazené podle datumu
-- Pomocí prvního CTE vypočítám hodnoty procenta proočkovanosti v každém dni a pomocí WHERE nechám pouze hodnoty přesahující 50%
-- V druhém pak používám funkci RANK k přiřazení pořadí dle data, tedy po vyfiltrování hodnot pod 50% bude jako číslo 1 první datum kdy se dosáhlo hranice 50% a více

-- Displaying the first day when each country reached over 50% of its population vaccinated ordered by date
-- The first CTE calculates the vaccination rate and filters out all rows below 50%.
-- In the second CTE I'm using the RANK() window function, it selects the first date (rank = 1) when the 50% threshold was exceeded.

WITH vaccinationrates50 AS 
(
SELECT 
    cd.country,cd.date,
    ROUND((people_vaccinated / population) * 100,2) AS vaccination_rate
FROM coviddeaths cd
	JOIN covidvaccinations cv 
		USING (country , date)
WHERE cd.continent IS NOT NULL
HAVING vaccination_rate > 50
),
ranked AS 
(
SELECT 
	country, date, vaccination_rate, 
	RANK() OVER (PARTITION BY country ORDER BY date) as rnk
FROM vaccinationrates50
)
SELECT country, date, vaccination_rate
FROM ranked
WHERE rnk = 1
ORDER BY date;

-- View zobrazující první datum, kdy každá země překročila 50% proočkovanost populace
-- EN: View showing the first date each country surpassed 50% vaccination rate of its population

CREATE VIEW vaccination_milestones AS
SELECT country, date, vaccination_rate
FROM (
SELECT 
	country, date, vaccination_rate,
	RANK() OVER (PARTITION BY country ORDER BY date) as rnk
FROM (
SELECT 
	cd.country, cd.date,
	ROUND((people_vaccinated/population)*100,2) AS vaccination_rate
FROM coviddeaths cd
	JOIN covidvaccinations cv 
		USING (country , date)
WHERE cd.continent IS NOT NULL
HAVING vaccination_rate > 50) AS vaccinationrates50
) AS ranked
WHERE rnk = 1
ORDER BY date;

-- TOP 10 zemí s nejvyšší mírou nákazy a jejich míra očkovanosti 
-- EN: TOP 10 countries with the highest infection rate and their vaccination rate

SELECT cd.country, 
ROUND((MAX(total_cases)/ population) * 100,2) AS infection_rate, 
ROUND((MAX(people_vaccinated)/population)*100,2) AS vaccination_rate
FROM coviddeaths cd 
JOIN covidvaccinations cv USING (country, date)
WHERE cd.continent IS NOT NULL
GROUP BY country, population
ORDER BY infection_rate DESC
LIMIT 10;

-- Vytvoření view pro uložení dat o procentu očkované populace k následným vizualizacím
-- Window funkce SUM() OVER, která kumuluje počet očkování zemí v čase (ve vytvořeném view)

-- EN: Created view to store data for visualizations
-- Window function SUM() OVER partitioned by country to accumulate vaccinations by date (view)

CREATE VIEW VaccinationDoses AS
SELECT cd.continent, cd.country, cd.date, population, new_vaccinations, 
SUM(new_vaccinations) OVER (PARTITION BY cd.country ORDER BY cd.date) AS cumulative_vaccinations
FROM coviddeaths cd
JOIN covidvaccinations cv
	USING (country, date)
WHERE cd.continent IS NOT NULL;

