
-- Schema of the tables
select top 5 * from COVID.dbo.Covid_Deaths
select top 5 * from COVID.dbo.Covid_Vaccination


--Changing Data type to correct format
alter table COVID.dbo.Covid_deaths alter column hosp_patients float
alter table COVID.dbo.Covid_deaths alter column hosp_patients_per_million float
alter table COVID.dbo.Covid_deaths alter column weekly_icu_admissions float
alter table COVID.dbo.Covid_deaths alter column weekly_icu_admissions_per_million float
alter table COVID.dbo.Covid_deaths alter column weekly_hosp_admissions float
alter table COVID.dbo.Covid_deaths alter column weekly_hosp_admissions_per_million float
					

--Total Deaths vs Total Cases
select continent,location,date,total_deaths,total_cases,(total_deaths/total_cases)*100 as Death_percentage
from COVID.dbo.Covid_Deaths
where location like 'India'
order by 2,3


--Total Cases vs Population
select continent,location,date,population,total_cases,round((total_cases/population)*100,2) as Cases_percentage
from COVID.dbo.Covid_Deaths
where location like 'India'
order by 3


--Countries with highest infection rate
select location,population,max(total_cases) as max_cases,round((max(total_cases)/population)*100,2) as Cases_percentage
from COVID.dbo.Covid_Deaths
group by location,population
order by 4 desc


--Countries death rate greater than 0.1
select continent,location,population,max(total_deaths) as max_deaths,round((max(total_deaths)/population)*100,2) as Death_percentage
from COVID.dbo.Covid_Deaths
group by continent,location,population
having round((max(total_deaths)/population)*100,2) >.1
order by 1,5 desc



--Global Numbers
select sum(distinct(population)) total_population,
sum(new_cases) as total_cases,
sum(new_deaths) as total_deaths,
round(sum(new_deaths)/sum(new_cases)*100,3) as death_percentage_per_cases,
round(sum(new_deaths)/sum(distinct(population))*100,3) as death_percentage
from COVID.dbo.Covid_Deaths
having sum(new_cases) !=0 
order by 1,2


--Global Numbers
with t1 (continent,location,date,population,new_vaccinations,total_vacc) as 
(select D.continent,D.location,d.date,d.population,coalesce(v.new_vaccinations,0),
coalesce((sum(v.new_vaccinations) over(partition by d.location order by d.date)),0) as total_vacc
from COVID.dbo.Covid_Deaths  as D
join COVID.dbo.Covid_Vaccination as V
on D.date=V.date and D.location=V.location)

select *,total_vacc/population as per_people_vaccinated
from t1

--creating View for total_vaccinations
create view percent_people_vaccinated as  
select D.continent,D.location,d.date,d.population,v.new_vaccinations,
coalesce((sum(v.new_vaccinations) over(partition by d.location order by d.date)),0) as total_vacc
from COVID.dbo.Covid_Deaths  as D
join COVID.dbo.Covid_Vaccination as V
on D.date=V.date and D.location=V.location


--featching view
select * from percent_people_vaccinated


-- 1. 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From COVID.dbo.Covid_Deaths
where continent is not null 
order by 1,2


-- 2. 
Select continent, SUM(new_deaths) as TotalDeathCount
From COVID.dbo.Covid_Deaths
Group by continent
order by TotalDeathCount desc


-- 3.
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From COVID.dbo.Covid_Deaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.
Select Location, Population,date, 
max(new_cases), 
Max((new_cases/population))*100 as currentPopulationInfected,
MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 as PercentPopulationInfected
From COVID.dbo.Covid_Deaths
Group by Location, Population, date
order by location,date



--5 rate of vaccination vs rate of infection
with t1(date,continent,location,infection_rate) as
(select d1.date, d1.continent, d1.location, 
coalesce(case when d1.new_cases!=0 then d2.new_cases/d1.new_cases else 0 end,0)
from COVID.dbo.Covid_Deaths as d1
join COVID.dbo.Covid_Deaths as d2
on datediff(day,d1.date,d2.date)=1 and d1.location=d2.location),

t2(date,continent,location,vaccination_rate) as
(select d1.date, d1.continent, d1.location, 
coalesce(case when d1.new_vaccinations!=0 then d2.new_vaccinations/d1.new_vaccinations else 0 end,0)
from COVID.dbo.Covid_Vaccination as d1
join COVID.dbo.Covid_Vaccination as d2
on datediff(day,d1.date,d2.date)=1 and d1.location=d2.location)

select t1.continent,t1.location, t1.date,t1.infection_rate,t2.vaccination_rate
from t1
join t2
on t1.date=t2.date and t1.location=t2.location