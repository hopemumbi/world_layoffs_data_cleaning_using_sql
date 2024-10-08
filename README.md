# World Layoffs Data Cleaning Project

This project focuses on cleaning and preparing a dataset related to company layoffs worldwide.
The goal is to standardize the dataset, remove inconsistencies, and ensure data accuracy for further analysis.

## Project Overview

The dataset used in this project contains information about layoffs across various companies, industries, and locations. Data cleaning is a critical step to ensure that the dataset is free of duplicates, standardized in format, and ready for analysis. This project covers:

1. **Data Importation**: Creating a database and importing the raw data into a staging table for cleaning.
2. **Data Cleaning**: Removing duplicates, handling missing values, standardizing data formats, correcting spelling errors, and removing unwanted characters.
3. **Final Output**: A cleaned dataset that can be used for further analysis or machine learning projects.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Database Setup](#database-setup)
- [Data Cleaning Process](#data-cleaning-process)
- [Contributing](#contributing)

## Prerequisites

To run the SQL queries and complete the data cleaning and exploratory data analysis, you will need the following:

- **MySQL 9.0**: The database management system used for this project.
- **MySQL Workbench**: A visual tool for database design, development, and administration, which was used for importing and managing the data.
- **Dataset**: The raw dataset of global company layoffs. You can download the dataset from [here](https://github.com/hopemumbi/world_layoffs_data_analysis_using_sql-/blob/main/layoffs.csv).

Make sure you have both MySQL 9.0 and MySQL Workbench installed and set up on your system.

## Database Setup

### Step 1: Create the Database

Create a new database where the data will be stored.

```sql
CREATE DATABASE `world_layoffs`;
USE `world_layoffs`;
```

### Step 2: Import the Raw Data

1. In the **Navigator** pane, right-click on the **Tables** section under the **world_layoffs** database.
2. Choose **Table Data Import Wizard** and follow the prompts to import the CSV file into the **`layoffs`** table.

After importing, you can create a staging table to keep the original data intact.


```sql
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;
```

## Data Cleaning Process

### Step 1: Remove Duplicate Data

Duplicates are identified based on key columns (e.g., company, industry, total laid off, etc.) and removed using a ROW_NUMBER() function.

```sql
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
DELETE FROM layoffs_staging2 WHERE row_num > 1;
```

### Step 2: Handle Missing Values
Missing values are addressed by either setting them to NULL or filling them based on other data for the same company.

```sql
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industry values for the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL OR t1.industry = ''
AND t2.industry IS NOT NULL;
```

### Step 3: Standardize Date Formats

Dates are standardized from text format to proper SQL DATE format.

```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

### Step 4: Correct Spelling Errors and Remove Unwanted Characters

Standardize industry names (e.g., "Crypto") and remove trailing spaces or punctuation from country names.

```sql
UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%";
```
### Step 5: Remove Unwanted Columns

After cleaning, columns used for duplicate detection (like row_num) are removed.

```sql
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

```
## Contributing

Contributions are welcome! If you have suggestions or improvements for the SQL script, feel free to open a pull request or submit issues.
