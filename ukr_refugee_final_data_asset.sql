
/*---------------------------------------------------
 Start with an anti-join to find data incompatibilities 
  * ` by returning NULL values
----------------------------------------------------*/

SELECT	
	country,
	date, 
	individuals,
	pop.[Population (2020)]
FROM 
	UKR_refugee_by_countries$
LEFT JOIN 
	population_by_country_2020$ AS pop
		ON country = [Country (or dependency)]
	WHERE Country IS NULL OR individuals IS NULL OR [Population (2020)] IS NULL OR date IS NULL;

/*---------------------------------------------------
NULL population values for 'Other EU countries', 
  * ` 'Republic of Moldova', 'Russian Federation'
 
Find different country names for the NULL values
  * ` in population_by_country_2020$
----------------------------------------------------*/
SELECT 
	[Country (or dependency)],
	[Population (2020)]
FROM 
	population_by_country_2020$
WHERE 
	[Country (or dependency)] LIKE '%Russ%' OR
	[Country (or dependency)] LIKE '%Mold%' OR
	[Country (or dependency)] LIKE '%Eu%';

/*---------------------------------------------------
 UPDATE UKR_refugee_by_countries$ where
  * ` [country]  becomes 'Russia', 'Moldova'
----------------------------------------------------*/

UPDATE UKR_refugee_by_countries$
SET country = CASE
			WHEN country = 'Russian Federation' THEN 'Russia'
			WHEN country = 'Republic of Moldova' THEN 'Moldova'
			ELSE country 
			END;

/*---------------------------------------------------
 Create table for final joined dataframe
  * ` then insert date with appropraite calculations
----------------------------------------------------*/
CREATE TABLE joined_refugee_country
	(Country NVARCHAR(250), -- matched country names
	 Date Date,				-- date 
	 Refugees INT,			-- number of refugees as of date
	 Increase INT,			-- increase in refugees over previous data entry
	 Population INT,		-- population of country (constant)
	 RefugeePct FLOAT,		-- percentage of refugees compared to population (constant)
	 );
	 

INSERT INTO joined_refugee_country
	Select 
		Refugee.country AS Country, 
		CONVERT(DATE, date) DT, 
		individuals AS refugees, 
		individuals - lag(individuals, 1, 0) Over(Partition By Refugee.country Order by date) AS Increase, 
		pop.[Population (2020)] AS Population, 
		ROUND(Refugee.individuals / pop.[Population (2020)] * 100, 3) AS RefugeePct
	FROM 
		UKR_refugee_by_countries$ AS Refugee
	LEFT JOIN 
		population_by_country_2020$ as pop
		ON 
			Refugee.country = pop.[Country (or dependency)];


/*---------------------------------------------------
 DELETE data where Country = 'Other European countries'
  * ` since non-specific country data can't be represented
  * ` geographically in Tableau
----------------------------------------------------*/

DELETE FROM joined_refugee_country
WHERE Country = 'Other European countries' 
	AND Population IS NULL;

/*---------------------------------------------------
 Final query to be used in Tableau Visualization
----------------------------------------------------*/
SELECT * 
FROM joined_refugee_country;
