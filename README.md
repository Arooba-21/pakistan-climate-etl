# 🌡️ Pakistan Climate ETL Analysis
End-to-end ETL pipeline analyzing 265 years of climate data (1750–2015)
across 3 levels: Global, Pakistan, and Karachi city.

## Tech Stack
Python | Pandas | PostgreSQL | SQLAlchemy | Jupyter Notebook

## Pipeline Architecture
Raw CSV Files → Python (Extract + Clean) → PostgreSQL (Load) → SQL (Analytics)

## Dataset
Source: Berkeley Earth via Kaggle  
Files used: GlobalTemperatures.csv, GlobalLandTemperaturesByCountry.csv, 
GlobalLandTemperaturesByMajorCity.csv  
Total records processed: ~8,000+ rows across 3 tables

## Data Cleaning Highlights
- Handled nulls strategically — forward fill for small gaps, 
  flagged historical nulls (pre-1850) instead of dropping
- Detected and clipped temperature outliers using boxplot analysis
- Parsed and extracted year/month from datetime for time-series analysis
- Retained uncertainty column as data quality filter for SQL queries

## Key Findings
- 🌍 Global land temperature increased ~1.3°C from 1900 to 2015
- 🇵🇰 Pakistan's hottest year on record: 1828 (avg X°C)
- 🏙️ Karachi warming rate: 4.44°C vs Pakistan national rate: 4.86°C
- ☀️ Karachi exceeds 32°C most frequently in: Month 06 (june)

## SQL Analytics (20 Queries)
- Decade-wise temperature trends since 1750
- Year-over-year change using LAG window function
- Pakistan vs Global warming rate comparison
- Karachi vs Pakistan summer month temperature difference
- Decade ranking using RANK() window function

## Files
| File | Description |
|------|-------------|
| `climate data cleaning.ipynb` | Full ETL pipeline — extract, clean, load |
| `climate_insights.sql` | 20 analytical SQL queries |

## What I Learned
- How to handle nulls in time-series climate data without corrupting history
- Using boxplots to investigate outliers before clipping
- Connecting Pandas to PostgreSQL via SQLAlchemy
- Writing complex CTEs and window functions for real analytical questions
