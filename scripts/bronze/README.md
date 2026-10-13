Bronze Layer - Raw Data Ingestion

Raw CRM and ERP datasets were imported directly from CSV files into PostgreSQL.

Loading Method: Manual CSV import using PostgreSQL tools.

Process:

Created the required Bronze tables.

Imported CSV files into their corresponding PostgreSQL tables.

Verified that the records were successfully loaded.

Retained the raw data for subsequent cleaning and transformation in the Silver layer.

Note: The initial data import did not use TRUNCATE or an automated SQL loading script.
