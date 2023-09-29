--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. 
SELECT npi, total_claim_count
FROM prescription FULL JOIN prescriber USING(npi)
WHERE total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 1;

--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, total_claim_count
FROM prescription FULL JOIN prescriber USING(npi)
WHERE total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 1;

--2a.Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber FULL JOIN prescription USING(npi)
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--2b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM drug LEFT JOIN prescription USING(drug_name)
		  LEFT JOIN prescriber USING(npi)
WHERE opioid_drug_flag = 'Y'
	  AND specialty_description IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--2c.
SELECT npi, drug_name, specialty_description
FROM prescriber LEFT JOIN prescription USING(npi)
EXCEPT
SELECT npi, drug_name, specialty_description
FROM prescription LEFT JOIN prescriber USING(npi);
--COME BACK TRY A CTE
--2d.

--3a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, total_drug_cost::money
FROM drug FULL JOIN prescription USING(drug_name)
WHERE total_drug_cost IS NOT NULL
ORDER BY total_drug_cost DESC
LIMIT 1;

--3b. Which drug (generic_name) has the highest total cost per day?
SELECT drug_name, ROUND((total_drug_cost/total_day_supply),2) AS cost_per_day
FROM prescription
ORDER BY cost_per_day DESC
LIMIT 1;

--4a. For each drug in the drug table, return the drug name and then a column named 'drug type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 'antibiotic' for drugs which have antibiotic_drug_flag = 'Y' and says 'neither' for all other drugs.

SELECT drug_name, 
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   		ELSE 'neither' 
	   END AS drug_type
FROM drug;

--4b. Building off of the query you wrote for part a, determine whether more was spend (total_drug_cost) on opioids or antibiotics. Hint: Format the total costs as MONEY for easier comparison.
WITH drug_types AS (SELECT drug_name, total_drug_cost::money, 
	   				CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   					 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   					 ELSE 'neither' 
	   			END AS drug_type
	   			FROM drug LEFT JOIN prescription USING(drug_name))
SELECT drug_type, SUM(total_drug_cost::money) AS drug_total_cost
FROM drug_types
GROUP BY drug_type;


--5a. How many CBSAs are in Tennessee? **Warning: The cbsa table contains information for all states not just tennesee.
SELECT COUNT(*)
FROM cbsa
WHERE cbsaname LIKE '%TN';
--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, MAX(population) AS max_population, MIN(population) AS min_population
FROM cbsa FULL JOIN fips_county USING(fipscounty)
		  FULL JOIN population USING(fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname;
		  
--5c. What is the largest (in terms of population) county which is not included in the CBSA? Report the county name and population
WITH county_not_cbsa AS (SELECT fipscounty
					   FROM population FULL JOIN fips_county USING(fipscounty)			  
					   EXCEPT
					   SELECT fipscounty
					   FROM cbsa)
SELECT county, population
FROM county_not_cbsa LEFT JOIN population USING(fipscounty)
					 LEFT JOIN fips_county USING(fipscounty)
WHERE population IS NOT NULL
ORDER BY population DESC
LIMIT 1;						

--6a.Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name an total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--6b. For each instance you found in part a add a column that indicated whether the drug is an opioid
SELECT drug_name, total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   ELSE 'not opioid' END AS drug_type
FROM drug LEFT JOIN prescription USING(drug_name)
WHERE total_claim_count > 3000;

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row 
SELECT nppes_provider_last_org_name, nppes_provider_first_name, drug_name, total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   ELSE 'not opioid' END AS drug_type
FROM drug LEFT JOIN prescription USING(drug_name)
		  LEFT JOIN prescriber USING(npi)
WHERE total_claim_count > 3000;

--7. The goal of this exercise is to generate a full list of all pain managment specialists in Nashville and the number of claims they had for each opioid. Hint the results from all 3 parts will have 637 rows.
--7a. First create a list of all npi/drug_name combinations for pain managment specialists in the city of Nashville, where the drug is an opioid. Double check query befor running it. You will only need to use the prescriber and drug tables since you dont need the claim numbers yet.
SELECT npi, drug_name, specialty_description
FROM prescriber FULL JOIN prescription USING(npi)
				FULL JOIN drug USING(drug_name)
WHERE specialty_description = 'Pain Management'
      AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y';

--7b.Next report the number of claims per drug per prescriber. Be sure to include all combination whether or not the prescriber had any claims. You should report the npi, the drug_name and the number of claims
WITH pain_management AS (SELECT *
							FROM prescriber FULL JOIN prescription USING(npi)
											FULL JOIN drug USING(drug_name)
							WHERE specialty_description = 'Pain Management'
      						AND nppes_provider_city = 'NASHVILLE'
	  						AND opioid_drug_flag = 'Y')
SELECT nppes_provider_last_org_name, drug_name, SUM(total_claim_count) AS total_claim_count
FROM pain_management
GROUP BY drug_name, nppes_provider_last_org_name;

--7c. Finally if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - google the coalesce function
WITH pain_management AS (SELECT *
							FROM prescriber FULL JOIN prescription USING(npi)
											FULL JOIN drug USING(drug_name)
							WHERE specialty_description = 'Pain Management'
      						AND nppes_provider_city = 'NASHVILLE'
	  						AND opioid_drug_flag = 'Y')
SELECT nppes_provider_last_org_name, drug_name, SUM(total_claim_count) AS total_claims
FROM pain_management
GROUP BY drug_name, nppes_provider_last_org_name;


