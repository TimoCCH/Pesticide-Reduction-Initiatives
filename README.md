# Pesticide-Reduction-Initiatives-Data Workflow Overview
This component of the project focuses on acquiring, processing, and integrating external data sources to extend the SQL database used for pesticide reduction analysis.

1. Pesticide_Info (BVL)

Data are obtained from the Federal Office of Consumer Protection and Food Safety (BVL). The dataset includes pesticide ID, registration date, active ingredients, regulatory notes, and health codes.
The structure is normalised into:

A primary pesticide table

Ingredient tables

Additional information tables

The ingredient data are further classified into IRAC, FRAC, and HRAC sub-tables according to resistance classification codes.

2. Application_Info (BVL)

Application-related data from BVL, including application ID, crop/area of use, and timing of application.

3. KTBL

Machinery and operational data scraped from the KTBL website, including:

Process Group

Work Operation

Machine Combination

Field Size (ha)

Soil Cultivation Resistance

Two Python scraping implementations are provided to support different operating systems.

4. Pesticides_Price

Price data collected from Avagrar, BayWa, and MyAgrar, structured for integration into the SQL database.

5. PPDB

Active ingredient data scraped from the PPDB database. Combined with BVL data, these inputs are used to compute the Pesticide Load Indicator (PLI).

6. Database Integration

All processed datasets are cleaned, standardised, and imported into the project’s SQL database, where merging, linking, and indicator calculations are performed.

7. Documentation

Further methodological and institutional details are provided in Pesticide Reduction Initiatives.pdf.
