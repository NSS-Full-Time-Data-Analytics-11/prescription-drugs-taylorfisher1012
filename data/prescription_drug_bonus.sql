--1. How many npi's apear in the prescriber table but not the prescription table
SELECT COUNT(npi)
FROM (WITH npi_intersect AS (SELECT npi
						FROM prescription
					    INTERSECT
					   SELECT npi
					   FROM prescriber)
	 SELECT npi
	 FROM prescriber
	 EXCEPT 
	 SELECT npi
	 FROM npi_intersect) AS npi_prescriber_only; 

--2a. Find the top five drugs (generic_name) prescriber by prescribers with the specialty of Family Practice
SELECT drug_name, COUNT(nppes_provider_last_org_name) AS num_providers
FROM prescriber FULL JOIN prescription USING(npi)
				FULL JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY drug_name
ORDER BY num_providers DESC
LIMIT 5;

--2b. Find the top five drugs (generic name) prescribed by prescribers with the specialty of Cardiology
SELECT drug_name, COUNT(nppes_provider_last_org_name) AS num_providers
FROM prescriber FULL JOIN prescription USING(npi)
				FULL JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY drug_name
ORDER BY num_providers DESC
LIMIT 5;

--2c. Which drugs are in the top five presrcibed by Family Practice prescribers and Cardiologist 
SELECT drug_name, COUNT(nppes_provider_last_org_name) AS num_providers
FROM prescriber FULL JOIN prescription USING(npi)
				FULL JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology' OR specialty_description = 'Family Practice'
GROUP BY drug_name
ORDER BY num_providers DESC
LIMIT 5;

--3. Your goal in this question is to generate a list of top prescribers in each of the major metropolitan areas of tennessee
--3a. First write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims and include a column showing the city.
SELECT npi, total_claim_count, nppes_provider_city AS city
FROM prescriber FULL JOIN prescription USING(npi)
WHERE nppes_provider_city = 'NASHVILLE' AND total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC;
--3b. Now report the same for Memphis
SELECT npi, total_claim_count, nppes_provider_city AS city
FROM prescriber FULL JOIN prescription USING(npi)
WHERE nppes_provider_city = 'MEMPHIS' AND total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC;
--3c. Combine your results from a and b along with the results for Knoxville and Chattanooga
SELECT npi, total_claim_count, nppes_provider_city AS city
FROM prescriber FULL JOIN prescription USING(npi)
WHERE (nppes_provider_city = 'NASHVILLE' OR nppes_provider_city = 'MEMPHIS' OR nppes_provider_city = 'KNOXVILLE' OR nppes_provider_city = 'CHATTANOOGA')
		AND total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC;

--4. Find all counties which had an above average number of overdose deaths. Report the county name and number of overdose deaths
WITH county AS (SELECT CAST(fipscounty AS int), county
			   FROM fips_county)
SELECT county, SUM(overdose_deaths) 
FROM county FULL JOIN overdose_deaths USING(fipscounty)
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
						FROM overdose_deaths)
GROUP BY county; 

--5a. Write a query that finds the total population of tennesee
SELECT state, SUM(population)
FROM population FULL JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;

--5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population and the percentage of the total population of tennessee that is contained in that county








