/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM 
	PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4


-- Select Data that we are going to be using

SELECT  location,
		date,
		total_cases,new_cases,
		total_deaths,population
FROM 
	PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Display this study's date range

SELECT MIN(date),MAX(DATE)
FROM PortfolioProject..CovidDeaths


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Lebanon

SELECT location,continent,date,total_cases,total_deaths, (total_deaths/total_cases)* 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%non%' AND total_deaths is not null
ORDER BY 1,2

--  total cases vs population
-- Shows what percentage of population got covid

SELECT location,date,total_cases,(total_cases/population)* 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT  location,population,
		MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population))* 100 AS PercentPopulationInfected
FROM 
	PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%'
GROUP BY population,location
ORDER BY PercentPopulationInfected DESC

-- This query shows the countries with the Highest Death count per Population

SELECT  location,
		MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAKing THINGS DOWN BY CONTINENT

-- Showing continents with highest deaths counts

SELECT  continent,
		MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM
	PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%'
WHERE
	continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- FIND OUT THE PERCENTAGE NUMBER OF FATAL CASES

SELECT location,continent,date,icu_patients,hosp_patients,
(CASE
	WHEN hosp_patients = 0
	THEN NULL
	ELSE CAST(icu_patients AS float) / CAST (hosp_patients AS float) * 100 
END) as Fatal_Cases_percent
FROM PortfolioProject..CovidDeaths
WHERE hosp_patients is not NULL AND  icu_patients is NOT NULL
ORDER BY 1,3

-- GLOBAL NUMBERS

-- global death percentage by date

SELECT date,SUM(new_cases) AS total_cases,SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%' AND total_deaths is not null
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- global death percentage till date

SELECT SUM(new_cases) AS total_cases,SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%non%' AND total_deaths is not null
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM 
	 PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopVsVac (Continent, location, date, population,new_vaccinations,RollingPeopleVaccinated)

AS

(
SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE 
	dea.continent is not null
--order by 2,3
)

SELECT *,(RollingPeopleVaccinated/population)*100 PercentageOfRollingVaccinations
FROM PopVsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM
	PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE 
	dea.continent is not null
--order by 2,3

SELECT *,(RollingPeopleVaccinated/population)*100 PercentageOfRollingVaccinations
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
	dea.location, 
	dea.date,
	dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
FROM 
	PortfolioProject..CovidDeaths dea
JOIN 
	PortfolioProject..CovidVaccinations vac
	ON 
	dea.location = vac.location
	and dea.date = vac.date
WHERE 
	dea.continent is not null
--order by 2,3

SELECT *
FROM 
	PercentPopulationVaccinated