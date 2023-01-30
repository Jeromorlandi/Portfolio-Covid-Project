-- seleccionamos la data que vamos a usar
SELECT location, date, total_cases, new_cases, total_deaths, population FROM CovidDeaths;

-- ANALIZAMOS LOS CASOS TOTALES VS LAAS MUERTES TOTALES

-- seleccionamos la data que vamos a usar. Multiplicamos por 1.0 para que redondee los decimales. Si no, la columna aparec en cero
-- esto muestra la posibilidad de morir si te contagias de covid en un determinado momento del tiempo

SELECT location, date, total_deaths,total_cases, (total_deaths*1.0/total_cases*1.0)*100  as deathper
FROM CovidDeathsAct
WHERE location LIKE '%argentina%';

-- analizamos los casos totales vs población
SELECT location, date, population,total_cases*1.0, (total_cases*1.0/population)*100 as casesper
FROM CovidDeathsAct cda 
WHERE location LIKE '%argentina%';

-- que país tiene el mayor porcentaje de población infectada 
SELECT location, population, MAX(total_cases*1.0) as HighestInfCount, MAX(total_cases*1.0/population)*100 as casesper
FROM CovidDeathsAct cda 
GROUP BY location, population
ORDER BY casesper desc;

-- que países tienen la mayor cantidad de muertos 
SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidDeathsAct cda 
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestDeathCount desc;

-- que continentes  tienen la mayor cantidad de muertos 
SELECT continent , MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidDeathsAct cda 
WHERE continent IS NOT NULL
GROUP BY continent 
ORDER BY HighestDeathCount desc;

-- que países tienen la mayor cantidad de muertos por población
SELECT location, population, MAX(total_deaths*1.0) as HighestDeathCount, MAX(total_deaths*1.0/population)*100 as deathsper
FROM CovidDeathsAct
WHERE continent is NOT NULL
GROUP BY location
ORDER BY deathsper desc;




-- número globales por fecha


SELECT  date, SUM(new_cases) as total_newcases, SUM(CAST (new_deaths as int)) as total_newdeaths, SUM(CAST (new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeathsAct cda 
WHERE continent is not NULL
GROUP BY date;

-- número globales en total


SELECT  SUM(new_cases) as total_newcases, SUM(CAST (new_deaths as int)) as total_newdeaths, SUM(CAST (new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeathsAct cda 
WHERE continent is not NULL;

-- VAMOS A UNIR LAS DOS BASES DE DATOS 
SELECT*
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
and dea.date = vac.date;

-- total de la poblacion vs cantidad de poblacion vacunada 
SELECT dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations  as INT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVAC
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL;

--Maximo
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations
, MAX(cast (vac.new_vaccinations  as INT)) OVER(PARTITION BY dea.location) as MAxPeopleVAC
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
WHERE dea.continent IS NOT NULL;

-- vamos a crear un CTE (una especie de tabla temporal para poder seguir trabajando con los datos). 
-- esta bueno para mostrar habilidad pero no muestra población vacunada sino cantidad de vacunas, lo que incluye todas las dosis

WITH Popvsvac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVAC) as
(
SELECT dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations 
, SUM(cast (vac.new_vaccinations  as INT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVAC
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVAC/ population)*100 
FROM Popvsvac;

-- TEMP TABLE. Lo mismo que lo anterior pero sacado distinto metodo
DROP TABLE IF EXISTS MAXPEOPLE
CREATE TABLE MAXPEOPLE
(
Continent nvarchar(200),
Location nvarchar(200),
Date datetime,
Population numeric, 
New_vaccinations numeric,
RollingPeopleVac numeric
)
INSERT INTO MAXPEOPLE
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast (vac.new_vaccinations  as INT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVAC
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
and dea.date=vac.date 
--WHERE dea.continent IS NOT NULL
SELECT *, (RollingPeopleVAC/dea.population)*100
FROM MAXPEOPLE;


-- Crear visualización para despues pasar a Tableau

Create View PercentPeopleVax as 
SELECT dea.continent, dea.date, dea.location, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations  as INT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVAC
FROM CovidDeathsAct dea
JOIN CovidVaxAct vac
ON dea.location=vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL;


Select *
From PercentPeopleVax;

