-- Dotazy použité pro vizualizaci v Tableau Public
-- Queries used for Tableau Public visualization

-- (1/4) Infection Rate by Country / Míra nakažení podle země

-- CZ:
-- Vypočítá podíl nakažené populace (infection_rate) pro každou zemi.
-- Používám MAX(total_cases), protože jde o kumulativní ukazatel — maximum tedy odpovídá poslední známé hodnotě.
-- Filtruji continent IS NOT NULL, abych odstranil agregace typu 'World'.

-- EN:
-- Calculates infection rate by country using MAX(total_cases) because total_cases is cumulative, so MAX returns the most recent value.
-- Rows without continent (e.g., aggregated data such as 'World') are excluded.

SELECT country, population, MAX(total_cases) AS TotalCases,
	ROUND((MAX(total_cases)/population)*100,2) AS infection_rate
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY country, population
HAVING infection_rate IS NOT NULL
ORDER BY infection_rate DESC;

-- (2/4) Deaths by Continent / Počet úmrtí podle kontinentů 

-- CZ:
-- Dataset obsahuje záznamy, kde je název kontinentu uveden ve sloupci "country".
-- Pomocí IN() explicitně vybírám pouze kontinentální agregace.
-- Slouží pro sloupcový graf (bar chart) v Tableau.

-- EN:
-- The dataset includes aggregated rows where "country" equals a continent name.
-- Only these continent labels are selected using IN().
-- Used for a bar chart in Tableau showing continent-level deaths.

SELECT country as continent, MAX(total_deaths) AS DeathCount
FROM coviddeaths
WHERE country IN ('Europe','North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY country
ORDER BY DeathCount DESC;

-- (3/4) Infection Rate Over Time / Vývoj míry nakažení v čase

-- CZ:
-- Tento dotaz se používá pro timeline graf v Tableau.
-- Vypočítá denní podíl nakažené populace.
-- Filtr date < '2025-09-28' odstraňuje poslední nekompletní data.

-- EN:
-- Used for the timeline chart in Tableau.
-- Computes the percentage of population infected for each country and date.
-- Filter date < '2025-09-28' ensures only valid historical data is included.

SELECT country, population, date, total_cases as InfectionCount, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL 
	AND date < '2025-09-28'
HAVING PercentPopulationInfected IS NOT NULL
ORDER BY PercentPopulationInfected DESC;

-- (4/4)  Global Totals + Global Death Percentage / Celkové globální případy, úmrtí a procento úmrtnosti

-- CZ:
-- Pomocí CTE 'eachtotal' získám pro každou zemi maximální hodnoty total_cases a total_deaths. 
-- Ty pak sečtu a vypočítám globální podíl úmrtí (case fatality percentage).

-- EN:
-- The CTE 'eachtotal' extracts maximum total_cases and total_deaths
-- per country. These values are summed in the outer query to compute

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
