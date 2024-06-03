Select *
From PortfolioProject..CovidDeath
where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select location, date, total_Cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeath
order by 1,2

-- Check my columns format

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeath' AND COLUMN_NAME IN ('total_Cases', 'total_deaths');


-- Convert 'date' to a date format
UPDATE PortfolioProject..CovidDeath
SET date = CAST(date AS DATE)
WHERE ISDATE(date) = 1

UPDATE PortfolioProject..CovidVaccinations
SET date = CAST(date AS DATE)
WHERE ISDATE(date) = 1


-- Convert Varchar to a numeric format

ALTER TABLE PortfolioProject..CovidDeath
ALTER COLUMN total_cases FLOAT;

ALTER TABLE PortfolioProject..CovidDeath
ALTER COLUMN total_deaths FLOAT

ALTER TABLE PortfolioProject..CovidDeath
ALTER COLUMN new_cases FLOAT

-- Convert columns to BIGINT to handle large values
ALTER TABLE PortfolioProject..CovidDeath
ALTER COLUMN total_cases BIGINT;

ALTER TABLE PortfolioProject..CovidDeath
ALTER COLUMN Population BIGINT;

ALTER TABLE PortfolioProject..CovidVaccinations
ALTER COLUMN new_vaccinations INT


-- Looking at Total Caes vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths / NULLIF(total_cases, 0))*100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeath
Where location like 'Taiwan'
ORDER BY 
    location, date;

-- Looking ar Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT 
    location, 
    date,
	Population,
    total_cases, 
    (total_cases / NULLIF(Population, 0))*100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeath
Where location like 'Taiwan'
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT 
    location, 
	Population,
    Max(total_cases) as HighstInfectionCount, 
    Max((total_cases / NULLIF(CAST(Population AS FLOAT), 0)))*100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeath
--Where location like 'Taiwan'
Group by
	Location, Population
ORDER BY PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

SELECT 
    location, 
	Max(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeath
Where continent is not null
Group by
	Location
ORDER BY TotalDeathCount desc


-- LETS BRAK THINGS DOWN BY CONTINENT

SELECT 
    continent, 
	Max(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeath
Where continent is not null
Group by continent
ORDER BY TotalDeathCount desc

-- Showing continents with the highest death count per population

SELECT 
    continent, 
	Max(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeath
Where continent is not null
Group by continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS

SELECT 
    date,
    SUM(CAST(new_cases AS INT)) as total_cases,
    SUM(CAST(new_deaths AS INT)) as total_deaths,
    CASE WHEN SUM(new_cases) = 0 THEN 0 
         ELSE SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeath
WHERE 
    continent IS NOT NULL
GROUP BY date
ORDER BY 
    1, 2;

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinatd
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

With PopvsVac ( continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinatd )
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinatd
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
SELECT *,
       CASE 
           WHEN CAST(Population as float) = 0 THEN 0
           ELSE (CAST(RollingPeopleVaccinatd AS float) / CAST(Population AS INT)) * 100
       END AS VaccinationRate
FROM PopvsVac

-- TMP TABLE


Drop Table if exists #PercntPopulationVaccinted
Create Table #PercntPopulationVaccinted
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinatd numeric
)
Insert into #PercntPopulationVaccinted
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinatd
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3

SELECT *,
       CASE 
           WHEN CAST(Population as float) = 0 THEN 0
           ELSE (CAST(RollingPeopleVaccinatd AS float) / CAST(Population AS INT)) * 100
       END AS VaccinationRate
FROM #PercntPopulationVaccinted



-- Creating View to stor data for latr visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinatd
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3


Select * 
From PercentPopulationVaccinated