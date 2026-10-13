----------gold layer --------------
----CUSTOMER-------------------------------------
create view gold.dim_customers as 
--SELECT cst_key,count(*) from ---subquery to check if we dont have any duplicates with having clause
--(
SELECT
 row_number()over(order by cst_id  ) as customer_key,---creating a surogate key through windows function 
CI.cst_id as customer_id, 
CI.cst_key as customer_number	,
CI.cst_firstname as firstname,
CI.cst_lastname as lastname,
LA.cntry as country,
CI.cst_marital_status as marital_status ,
CA.bdate as birthdate,
CASE 
  WHEN CI.cst_gndr <> 'N/A' THEN   CI.cst_gndr
   WHEN CI.cst_gndr ='N/A' THEN COALESCE(CA.gen,'N/A')
   ELSE 'N/A'
END AS gender,
CI.cst_create_date as create_date
FROM silver.crm_cust_info CI----MASTER TABLE 
LEFT JOIN  
silver.erp_CUST_AZ12 CA
ON CI.cst_key= CA.cid
LEFT JOIN 
 silver.erp_LOC_A101 LA
ON CA.cid=LA.cid 

--) group by cst_key 
--having count(*)>1 part of subquery to check if we dont have any duplicates with having clause


-----------------------
-----------------------
-- when you join tables , if you have more null values that mena the join isnt succesfull 
----if you have two similar column in the table but there rows contains different data for the same primary key,
---- then ask the stakeholder which data/ table /source is more realiable 
---THIS PROJECT : while join the above three table  two tables have gender of the customer but dont have all matching values 
---- so we will choose the default value of CRM table, incase of a conflict 
---------------
--------------
----integration 
SELECT CI.cst_id, 
CI.cst_gndr,
CA.gen,
CASE 
  WHEN CI.cst_gndr <> 'N/A' THEN   CI.cst_gndr
   WHEN CI.cst_gndr ='N/A' THEN COALESCE(CA.gen,'N/A')
   ELSE 'N/A'
END AS gen   
FROM silver.crm_cust_info CI
LEFT JOIN  
silver.erp_CUST_AZ12 CA
ON CI.cst_key= CA.cid
where CI.cst_id=1195
LEFT JOIN 
 silver.erp_LOC_A101 LA
ON CA.cid=LA.cid 


--check the view 
select * from gold.dim_customers
select distinct gender from gold.dim_customers

drop view gold.dim_customers
select * from silver.erp_LOC_A101

----------------------------------------------------------------------------------------------------------
--------------------------------------------PRODUCT---------------------------------------------------

 select * from silver.crm_prd_info---master table of product 
 select * from silver.erp_PX_CAT_G1V2---category
 select * from gold.dim_products 
 

--select  prd_key, count(*) from(
create view gold.dim_products as
select 
row_number()over(order by prd_start_dt ) as product_key,
PC.prd_id as product_id,
PC.prd_key as product_number,
PC.prd_nm as product_name,
PC.prd_line as product_line,
PC.cat_id as category_id ,
PN.cat as category,
PN.subcat as subcategory,
PN.maintenance ,
PC.prd_start_dt as start_date,
PC.prd_cost as product_cost
from silver.crm_prd_info PC
left join silver.erp_PX_CAT_G1V2 PN
ON PC.cat_id=PN.id
where PC.prd_end_dt is null

--) group by prd_key having count(*)>1
---------------------------------------------------------------
---------------------------------------------------------------
--------------------sales------------------------------------fact table-----------------------
-----join your dimension tables to fact table 
select * from gold.fact_sales

create view gold.fact_sales as
select 
SD.sls_ord_num AS order_number,
PT.product_key,
CT.customer_key	 ,
SD.sls_order_dt as order_date ,
SD.sls_ship_dt as shipping_date,
SD.sls_due_dt as due_date,
SD.sls_sales as sales_amount,
SD.sls_quantity as quantity,
SD.sls_price as sales_price
from silver.crm_sales_details SD
left join gold.dim_products PT
ON SD.sls_prd_key= PT.product_number
LEFT JOIN gold.dim_customers CT
ON SD.sls_cust_id=CT.customer_id

---check if the fact is joining with the dim 
select * from gold.fact_sales f
 join gold.dim_customers CT
 on f.product_key=CT.customer_key
