
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