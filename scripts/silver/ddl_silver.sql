CREATE TABLE  silver.crm_cust_info
( cst_id	int, 
cst_key	varchar(30),
cst_firstname	varchar(30),
cst_lastname	varchar(30),
cst_marital_status	varchar(50),
cst_gndr	varchar(50),
cst_create_date	date
)

select* from   silver.crm_cust_info

CREATE TABLE  silver.crm_prd_info
(
prd_id	int,
cat_id  varchar(100),
prd_key	varchar(100),
prd_nm	varchar(100),
prd_cost	int,
prd_line	varchar(100),
prd_start_dt	date,
prd_end_dt	date
)	
sls_order_dt
CREATE TABLE  silver.crm_sales_details(
sls_ord_num	varchar(150),
sls_prd_key	varchar(150),
sls_cust_id	int ,
sls_order_dt DATE ,
sls_ship_dt	DATE ,
sls_due_dt	DATE ,
sls_sales	int ,
sls_quantity	int ,
sls_price	int 
)

CREATE TABLE  silver.erp_CUST_AZ12
(
CID	varchar(100),
BDATE	date,
GEN	varchar(100)
)
CREATE TABLE  silver.erp_LOC_A101
(
CID	varchar(100),
CNTRY	varchar(100)
)

CREATE TABLE  silver.erp_PX_CAT_G1V2
(ID	varchar(100),
CAT	varchar(100),
SUBCAT	varchar(100),
MAINTENANCE	varchar(100)
)

truncate table   silver.erp_LOC_A101

drop table silver.crm_sales_details