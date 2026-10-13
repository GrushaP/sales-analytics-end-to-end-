CREATE TABLE  bronze.crm_cust_info
( cst_id	int, 
cst_key	varchar(30),
cst_firstname	varchar(30),
cst_lastname	varchar(30),
cst_marital_status	varchar(5),
cst_gndr	varchar(5),
cst_create_date	date
)

select* from   bronze.crm_sales_details

CREATE TABLE  bronze.crm_prd_info
(
prd_id	int,
prd_key	varchar(100),
prd_nm	varchar(100),
prd_cost	int,
prd_line	varchar(100),
prd_start_dt	date,
prd_end_dt	date
)	
sls_order_dt
CREATE TABLE  bronze.crm_sales_details(
sls_ord_num	varchar(150),
sls_prd_key	varchar(150),
sls_cust_id	int ,
sls_order_dt	int ,
sls_ship_dt	int ,
sls_due_dt	int ,
sls_sales	int ,
sls_quantity	int ,
sls_price	int 
)

CREATE TABLE  bronze.erp_CUST_AZ12
(
CID	varchar(100),
BDATE	date,
GEN	varchar(100)
)
CREATE TABLE  bronze.erp_LOC_A101
(
CID	varchar(100),
CNTRY	varchar(100)
)

CREATE TABLE  bronze.erp_PX_CAT_G1V2
(ID	varchar(100),
CAT	varchar(100),
SUBCAT	varchar(100),
MAINTENANCE	varchar(100)
)
