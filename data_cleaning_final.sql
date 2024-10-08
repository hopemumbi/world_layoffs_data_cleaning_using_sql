-- --------------------------------------------------
-- DATA IMPORTATION & STAGING SETUP
-- --------------------------------------------------

-- (i) Create the database and use the import wizard to create the table
CREATE DATABASE `world_layoffs`;
USE `world_layoffs`;

-- Optional: Drop the database if needed for a fresh start
-- DROP DATABASE `world_layoffs`;

-- Select all data from the original layoffs table
SELECT * FROM layoffs;

-- (ii) Staging Table Creation
-- Create a staging table to avoid tampering with the original table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Insert data into the staging table from the original table for cleaning
INSERT INTO layoffs_staging
SELECT * FROM layoffs;


-- --------------------------------------------------
-- DATA CLEANING
-- --------------------------------------------------

-- 1. Remove Duplicate Data
-- Using a Common Table Expression (CTE) to identify duplicate rows based on key columns
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
-- Select all duplicates (rows with row_num > 1)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1;
-- Optional filter for specific company
-- WHERE company = "Casper";

-- Create another staging table (`layoffs_staging2`) to store data after removing duplicates
CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data into the new staging table, adding row numbers to identify duplicates
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- Delete duplicate rows (row_num > 1) from the staging table
DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- 2. Handle Missing Values
-- Check for missing values in the `industry` column
SELECT DISTINCT(industry)
FROM layoffs_staging2;

-- Select all rows where the industry is NULL or empty
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Update: Replace empty strings in `industry` with NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industry values based on other rows for the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Select a specific company to check data
SELECT * 
FROM layoffs_staging2 
WHERE company = "Airbnb";

-- Remove rows where both `total_laid_off` and `percentage_laid_off` are NULL
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete rows with NULL values for both `total_laid_off` and `percentage_laid_off`
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- 3. Standardize Data Columns
-- Convert the `date` column from text to DATE type using STR_TO_DATE function (assuming format MM/DD/YYYY)
SELECT `date`, STR_TO_DATE(`date`, "%m/%d/%Y") 
FROM layoffs_staging2;

-- Update the `date` column to store the standardized date values
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

-- Check if the date format is standardized
SELECT `date`
FROM layoffs_staging2
ORDER BY `date`;

-- Convert the `date` column to the DATE data type in the table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 4. Correct Spelling Errors or Inconsistent Naming
-- Check for distinct values in the `industry` column
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry;

-- Select rows where the industry starts with "Crypto"
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE "Crypto%";

-- Standardize the naming of the "Crypto" industry to a single format
UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";


-- 5. Remove Unwanted Characters or Extra Spaces
-- Remove trailing periods from the `country` column (e.g., "United States.")
SELECT DISTINCT(country), TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;

-- Remove trailing periods from "United States" entries
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%";

-- Trim unwanted spaces from the `company` column
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Update the `company` column to remove extra white spaces
UPDATE layoffs_staging2
SET company = TRIM(company);


-- 6. Remove Unwanted Columns
-- Drop the `row_num` column since it was used for duplicate detection and is no longer needed
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- --------------------------------------------------
-- FINAL DATA CHECK
-- --------------------------------------------------

-- Select all data from the cleaned staging table
SELECT * 
FROM layoffs_staging2;
