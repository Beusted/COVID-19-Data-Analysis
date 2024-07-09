Select *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4


-- SELECT *
-- FROM PortfolioProject..CovidVaccinations
-- ORDER BY 3, 4


-- Select Data that we are going to be using


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2




-- Looking at: Total Cases vs Total Deaths


SELECT
   location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathByCovid
FROM
   PortfolioProject..CovidDeaths
WHERE
   location like '%states%'
ORDER BY
   1, 2


-- Looking at: Total Cases vs Population
SELECT
   location, date, total_cases, population, (total_cases/population)*100 CasesByPop
FROM
   PortfolioProject..CovidDeaths
WHERE
   location like '%states%' and
   continent is not NULL
ORDER BY
   1, 2


-- Looking at: Country with highest Infection Rate compared to Population


SELECT
   location,
   population,
   MAX(total_cases) as HighestInfCount,
   MAX((total_cases/population))*100 CaseByPop
FROM
   PortfolioProject..CovidDeaths
WHERE
   continent is not NULL
GROUP BY
   location,
   population
ORDER BY
   CaseByPop desc


-- Showing Countries with highest Death Count per Population


SELECT
   location,
   MAX(total_deaths) DeathsPerPop
FROM
   PortfolioProject..CovidDeaths
WHERE
   continent is not NULL
GROUP BY
   location
ORDER BY
   DeathsPerPop desc


--Break down by Continent


SELECT
   continent,
   MAX(total_deaths) TotalDeathCount
FROM
   PortfolioProject..CovidDeaths
WHERE
   continent is not NULL
GROUP BY
   continent
ORDER BY
   TotalDeathCount desc


SELECT
   location,
   MAX(total_deaths) TotalDeathCount
FROM
   PortfolioProject..CovidDeaths
WHERE
   continent is NULL AND
   location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY
   location
ORDER BY
   TotalDeathCount desc

-- Global Numbers

SELECT
    MIN(date) Date,
    SUM(new_cases) TotalCases,
    SUM(new_deaths) TotalDeaths,
    (SUM(new_deaths) * 100.0 / SUM(new_cases)) AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent is NOT NULL
GROUP BY
    DATEDIFF(DAY, 0, date) / 7  -- Group by every 7 days
ORDER BY
    1;

-- Looking at Total Population vs Vaccinations

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations)
    OVER (PARTITION BY  dea.location
          ORDER BY dea.location, dea.date) AS RollingVaxCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE
    dea.continent is NOT NULL AND
    vac.new_vaccinations IS NOT NULL
ORDER BY
    1, 2;

-- CTEs / find percentage of vaccinated people in a country / using CTE because you can't use RollingVaxCount as a variable

WITH PopVac (continent, location, date, population, new_vaccinations, RollingVaxCount)

AS (

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaxCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE
    dea.continent is NOT NULL AND
    vac.new_vaccinations IS NOT NULL
)
SELECT
    *, (RollingVaxCount/population)*100 AS "PopVac%"
FROM
    PopVac

-- Temp Table

DROP TABLE IF EXISTS #PercentPopVax
CREATE TABLE #PercentPopVax
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    Date datetime,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingVaxCount NUMERIC
)

INSERT INTO #PercentPopVax
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaxCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE
    dea.continent is NOT NULL AND
    vac.new_vaccinations IS NOT NULL

SELECT
    *, (RollingVaxCount/population)*100 AS "PopVac%"
FROM
    #PercentPopVax
ORDER BY
    2, 1

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopVax as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaxCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE
    dea.continent is NOT NULL AND
    vac.new_vaccinations IS NOT NULL

SELECT *
FROM PercentPopVax