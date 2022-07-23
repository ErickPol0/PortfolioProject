-- Import the data

-- To import the data covid_deaths and covid_vaccs, i intended to use the import wizard included in mysql, but many errors occur and it also
-- takes too long to load, so instead i only used the wizard to create the tables since i didn't want to go through the trouble of creating such
-- large tables, after that, the load data infile method makes it all much faster.

-- covid_deaths table
ALTER TABLE covid_deaths MODIFY population BIGINT;

LOAD DATA INFILE 'C:/Program Files/MySQL/sql analysis/covid_deaths.csv' 
INTO TABLE covid_deaths
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

update projectcovid.covid_deaths
set date = str_to_date(date, '%d/%m/%Y');

-- covid_vaccs table
ALTER TABLE covid_vaccs MODIFY tests_units TEXT;
ALTER TABLE covid_vaccs MODIFY total_vaccinations BIGINT;
ALTER TABLE covid_vaccs MODIFY people_vaccinated BIGINT;
ALTER TABLE covid_vaccs MODIFY people_fully_vaccinated BIGINT;
ALTER TABLE covid_vaccs MODIFY total_tests BIGINT;

LOAD DATA INFILE 'C:/Program Files/MySQL/sql analysis/covid _vaccinations.csv' 
INTO TABLE covid_vaccs
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

update projectcovid.covid_vaccs
set date = str_to_date(date, '%d/%m/%Y');



-- covid_deaths table analysis

-- total cases vs total deaths (Mexico)
-- death percentage with total numbers by day in mexico 
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'death percentage'
from projectcovid.covid_deaths
where location like '%Mexico%'
order by 1,2 desc;

-- new cases vs new deaths (Mexico - enero) 
-- death percentage with day numbers in mexico in the month of january
select location, date, new_cases, new_deaths, (total_deaths/total_cases)*100 as 'death percentage'
from projectcovid.covid_deaths
where location like '%Mexico%' and date like '2022-01%'
order by 1,2 desc;

-- new cases vs new deaths (Mexico - julio) 
-- death percentage with day numbers in mexico in the month of july
select location, date, new_cases, new_deaths, (total_deaths/total_cases)*100 as 'death percentage'
from projectcovid.covid_deaths
where location like '%Mexico%' and date like '2022-07%'
order by 1,2 desc;

-- population death percentage
-- percentage of mexican population that have died by day
select location,date, population,total_cases,total_deaths, (total_deaths/population)*100 as 'death percentage'
from projectcovid.covid_deaths
where location like '%Mexico%'
order by 2 desc;

-- population infected percentage
-- percentage of mexican population that have been infected by day
select location, date, population, total_cases, (total_cases/population)*100 as 'infected percentage'
from projectcovid.covid_deaths
where location like 'Mexico'
order by 2 desc;

-- countries with highest infection rate
select location, max(population), max(total_cases), max(total_deaths), (max(total_cases)/max(population))*100 as 'infected percentage', (max(total_deaths)/max(population))*100 as 'death percentage'
from projectcovid.covid_deaths
group by location
order by 5 desc;

-- countries with highest death rate
select location, max(population), max(total_cases), max(total_deaths), (max(total_cases)/max(population))*100 as 'infected percentage', (max(total_deaths)/max(population))*100 as 'death percentage'
from projectcovid.covid_deaths
group by location
order by 6 desc;

-- countries with most total cases
select location, max(total_cases), max(total_deaths)
from projectcovid.covid_deaths
where continent is not null
group by location
order by 2 desc;

-- countries with most total deaths
select location, max(total_cases), max(total_deaths)
from projectcovid.covid_deaths
where continent is not null
group by location
order by 3 desc;

-- continents - total cases x total deaths 
-- shows continent numbers
with cte_con (continent, location, population, total_cases, total_deaths) as (
	select continent, location, max(population) as population, max(total_cases) as total_cases, max(total_deaths) as total_deaths  
	from projectcovid.covid_deaths
	where continent is not null
	group by location
    )
select continent, sum(population) as population, sum(total_cases) as total_cases, sum(total_deaths) as total_deaths,
(total_cases/population)*100 as infec_percent, (total_deaths/population)*100 as death_percent 
from cte_con
group by continent;


-- global cases and deaths by day
-- shows global numbers per day
select date, sum(new_cases), sum(new_deaths)
from projectcovid.covid_deaths
group by date
order by 1;

-- global population cases and deaths
-- shows total global numbers
with cte_total_numbers (total_cases, total_deaths, population) as 
(
	select max(total_cases) as total_cases, max(total_deaths) as total_deaths, max(population) as population
	from projectcovid.covid_deaths
	where continent is not null
	group by location
)
select sum(population) as population ,sum(total_cases) as total_cases, sum(total_deaths) as total_deaths, (sum(total_cases)/sum(population))*100 as total_cases_percentage, (sum(total_deaths)/sum(population))*100 as total_deaths_percentage
from cte_total_numbers;


-- covid:death and covid_vaccs analysis

-- countries population vs tests
-- shows the percentage of test made over the population
select cv.location, cd.population, max(cv.total_tests) as total_test, (max(cv.total_tests)/max(cd.population))*100 as test_percentage
from projectcovid.covid_deaths as cd
join projectcovid.covid_vaccs as cv
	on cd.location = cv.location
    and cd.date = cv.date
where cv.continent is not null 
group by cv.location;	

-- world population vs test
-- shows the percentage of test made globally over the world population
with cte_tests (population, location, tests) as (
	select cd.population as population, cv.location as location, max(cv.total_tests) as tests
	from projectcovid.covid_vaccs as cv
    join projectcovid.covid_deaths as cd
		on cv.location = cd.location
        and cv.date = cd.date
	where cv.continent is not null
	group by cv.location
)
select sum(population) as world_population, sum(tests) as world_tests, (sum(tests)/sum(population))*100 as tests_percentage
from cte_tests;

-- countries population vs total people vaccinated
-- shows the percentage of how many have been vaccinated by country
select cv.location as location, max(cd.population) as population, max(cv.people_vaccinated) as people_vaccinated,
(max(cv.people_vaccinated)/max(cd.population))*100 as percentage_vaccinated
from projectcovid.covid_vaccs as cv
join projectcovid.covid_deaths as cd
	on cv.location = cd.location
	and cv.date = cd.date
where cv.continent is not null
group by cv.location;

-- global population vs total people vaccinated
with cte_vaccinations (location, population, people_vaccinated) as (
	select cv.location as location, cd.population as population, max(cv.people_vaccinated) as people_vaccinated
	from projectcovid.covid_vaccs as cv
	join projectcovid.covid_deaths as cd
		on cv.location = cd.location
		and cv.date = cd.date
	where cv.continent is not null
	group by cv.location
)
select sum(population) as world_population, sum(people_vaccinated) as people_vaccinated, (sum(people_vaccinated)/sum(population))*100 as percentage_vaccinated
from cte_vaccinations;


-- views

create view continent_cases_deaths as
with cte_con (continent, location, population, total_cases, total_deaths) as (
	select continent, location, max(population) as population, max(total_cases) as total_cases, max(total_deaths) as total_deaths  
	from projectcovid.covid_deaths
	where continent is not null
	group by location
    )
select continent, sum(population) as population, sum(total_cases) as total_cases, sum(total_deaths) as total_deaths,
(total_cases/population)*100 as infec_percent, (total_deaths/population)*100 as death_percent 
from cte_con
group by continent;
