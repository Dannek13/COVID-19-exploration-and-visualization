# COVID-19 Data Exploration & Visualization (MySQL + Tableau)

## Project Overview
This project demonstrates a complete **SQL → Data Preparation → Tableau Public** workflow using a real-world COVID-19 dataset (Our World in Data, 2020–2025).  
The goal is to showcase practical data analysis skills — not to perform a scientific epidemiological study.

The dataset contains **500k+ rows**, covers 5+ years, and was transformed into a clean relational model for analysis and visualization.

## Tableau Dashboard
**Dashboard:** https://public.tableau.com/views/COVID-19GlobalDashboard_17630276514300/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

### Dashboard Preview <img width="1857" height="773" alt="image" src="https://github.com/user-attachments/assets/ab8db3b7-c241-4f1c-af31-ca9df8b39315" />


## Key Skills Demonstrated

### SQL (MySQL)
- JOINs (USING, ON)
- Window Functions (RANK, SUM OVER)
- CTEs (WITH)
- Creating VIEWs for BI tools
- Data Cleaning & NULL handling
- Aggregations (GROUP BY, HAVING)
- Subqueries & temporary tables
- Composite primary keys
- Schema design and data loading (LOAD DATA INFILE)

### Tableau Public (Dashboarding)
- KPI cards (global totals)
- Parameter-driven map visualizations
- Multi-line trend charts
- Interactive filters & date range controls
- Continent-level comparisons
- Color-encoded infection rate mapping
- Combining multiple SQL outputs into a single dashboard

### Data Preparation
- Splitting raw dataset into logical tables
- Removing unused columns
- Fixing empty-string → NULL inconsistencies
- Date standardization (YYYY-MM-DD)
- Excluding aggregated entities (World, income groups)  
- Ensuring unique daily country-level entries
