# 📊 Data Warehouse and Analytics Project

Welcome to my **Data Warehouse and Analytics Project**! 🚀

This project is a hands-on portfolio project developed to strengthen my practical understanding of **SQL, data warehousing, ETL/ELT, data cleaning, data modeling, and analytics**.

The project follows an end-to-end workflow in which raw **CRM and ERP data** is loaded into a PostgreSQL data warehouse, cleaned and transformed through multiple layers, and prepared for analytical reporting.

> **Note:** This project is currently being developed through guided learning based on the **Data With Baraa SQL Data Warehouse Project**. I am implementing each stage myself to understand the concepts and workflow. Independent analysis, business insights, and additional portfolio contributions will be added as the project progresses.

---

## 🏗️ Data Architecture

The project follows the **Medallion Architecture**, consisting of three main data layers:

**Bronze → Silver → Gold**

![Data Warehouse Architecture](docs/data_architecture.png)

### 🥉 Bronze Layer — Raw Data

The Bronze layer stores data from the source systems in its original form.

* Source systems: **CRM and ERP**
* Source format: **CSV files**
* Database: **PostgreSQL**
* Object type: Tables
* Batch processing
* Full-load approach
* Truncate-and-insert loading
* No transformations applied

The purpose of this layer is to preserve the source data before cleaning and transformation.

---

### 🥈 Silver Layer — Clean & Standardized Data

The Silver layer converts raw source data into clean and consistent datasets suitable for further processing.

Key processes include:

* Data cleansing
* Duplicate handling
* Missing-value handling
* Data-type validation
* Data standardization
* Data normalization
* Derived columns
* Data enrichment
* Data integration
* Data-quality checks

---

### 🥇 Gold Layer — Business-Ready Data

The Gold layer contains data structured specifically for **analytics and reporting**.

Key processes include:

* Data integration
* Business logic
* Aggregation
* Fact and dimension modeling
* Star-schema development
* Analytical views
* Business-ready datasets

The Gold layer serves as the primary source for downstream **SQL analysis and BI reporting**.

---

## 🔄 Data Flow

```text
CRM CSV ─────┐
             │
ERP CSV ─────┘
      │
      ▼
┌─────────────────┐
│     BRONZE      │
│    Raw Data     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     SILVER      │
│     Clean &     │
│  Standardized   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      GOLD       │
│ Business-Ready  │
│   Data Models   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SQL Analytics  │
│      & KPIs     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  BI / Reporting │
└─────────────────┘
```

---

## 🎯 Project Objectives

The main objective of this project is to understand and implement an **end-to-end analytical data warehouse workflow**.

Through this project, I am developing practical experience in:

* Designing data warehouse architecture
* Creating databases and schemas
* Loading raw data into PostgreSQL
* Understanding ETL/ELT workflows
* Cleaning and transforming data using SQL
* Performing data-quality checks
* Integrating multiple data sources
* Designing fact and dimension tables
* Building star-schema data models
* Preparing data for analytical queries
* Performing SQL-based analysis
* Preparing datasets for BI and reporting

---

## 📋 Project Requirements

### Data Sources

The project uses data from two source systems:

* **CRM**
* **ERP**

The source data is provided as CSV files.

### Data Warehouse Requirements

The warehouse is designed to:

* Import CRM and ERP datasets into PostgreSQL.
* Preserve raw data in the Bronze layer.
* Clean and standardize data in the Silver layer.
* Resolve identified data-quality issues.
* Integrate information from multiple source systems.
* Create business-ready datasets in the Gold layer.
* Develop fact and dimension tables.
* Create an analytical star schema.
* Prepare data for reporting and analysis.
* Document the architecture, transformations, and data models.

The current project focuses on the latest available dataset. Historical tracking is outside the present scope.

---

## 📈 Planned Analytics & Reporting

After completing the data warehouse, the project will be extended with SQL-based analysis and reporting.

Planned analytical areas include:

### 👥 Customer Analysis

* Customer purchasing behavior
* Customer spending
* High-value customers
* Customer contribution to revenue
* Customer purchasing patterns

### 📦 Product Analysis

* Product performance
* Category performance
* Best-performing products
* Low-performing products
* Product revenue contribution
* Product rankings

### 💰 Sales Analysis

* Total sales
* Revenue trends
* Monthly and yearly performance
* Sales growth
* Average order value
* Sales by customer
* Sales by product
* Sales by category

> These analyses are planned project extensions and will be updated as I complete the analytical phase of the project.

---

## 🛠️ Technology Stack

| Technology     | Purpose                                             |
| -------------- | --------------------------------------------------- |
| **PostgreSQL** | Database and data warehouse                         |
| **SQL**        | Data loading, cleaning, transformation and analysis |
| **CSV**        | CRM and ERP source datasets                         |
| **Draw.io**    | Architecture and data-model diagrams                |
| **Git**        | Version control                                     |
| **GitHub**     | Project repository and portfolio documentation      |
| **Notion**     | Project planning and task management                |
| **Power BI**   | Planned dashboard and reporting layer               |

---

## 📂 Repository Structure

```text
data-warehouse-analytics-project/
│
├── datasets/
│   ├── crm/
│   └── erp/
│
├── docs/
│   ├── data_architecture.png
│   ├── data_architecture.drawio
│   ├── data_flow.drawio
│   ├── data_models.drawio
│   ├── data_catalog.md
│   └── naming-conventions.md
│
├── scripts/
│   ├── bronze/
│   │   ├── ddl_bronze.sql
│   │   └── load_bronze.sql
│   │
│   ├── silver/
│   │   ├── ddl_silver.sql
│   │   └── load_silver.sql
│   │
│   └── gold/
│       └── ddl_gold.sql
│
├── analytics/
│   ├── customer_analysis.sql
│   ├── product_analysis.sql
│   └── sales_analysis.sql
│
├── tests/
│   └── data_quality_checks.sql
│
├── dashboard/
│
├── README.md
├── LICENSE
└── .gitignore
```

---

## 📌 Project Progress

The project is being completed in stages:

**Requirements Analysis → Data Architecture → Project Initialization → Bronze Layer → Silver Layer → Gold Layer → SQL Analytics → BI & Reporting**

### Current Focus

I am currently building the **data warehouse and ETL/ELT components** while documenting the concepts and decisions made at each stage.

The repository will continue to evolve as additional analytical work, visualizations, business insights, and independent contributions are added.

---

## 🧠 Skills Being Developed

This project provides hands-on practice with:

* SQL
* PostgreSQL
* Data Warehousing
* ETL/ELT
* Data Cleaning
* Data Transformation
* Data Integration
* Data Quality
* Data Modeling
* Fact & Dimension Tables
* Star Schema
* Analytical SQL
* Business Intelligence
* Git & GitHub
* Technical Documentation

---

## 📚 Learning Attribution

This project is being developed as a **guided portfolio learning project** based on the **Data With Baraa SQL Data Warehouse Project**.

The original tutorial and project materials provided the learning structure and initial implementation guidance. I am reproducing the workflow hands-on to develop my understanding of data warehousing and analytics.

As the project progresses, I plan to extend the original implementation with my own:

* SQL analyses
* Business questions
* KPIs
* Data-quality investigations
* Visualizations
* Dashboard
* Business insights

Proper attribution to the original learning resource is maintained while documenting my own learning and future extensions.

---

## 👩‍💻 Author

**Grusha Pabbi**

Aspiring Data Analyst developing practical skills in:

**SQL • PostgreSQL • Data Warehousing • Data Modeling • Data Analytics • Business Intelligence**

---

## 🚧 Project Status

**In Progress**

The repository is actively being developed. Documentation, analytical queries, dashboards, and independent findings will be added as each phase is completed.
