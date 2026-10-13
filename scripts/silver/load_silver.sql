--CHECK FOR NULLS, DUPLICATES IN PRIMARY KEY 
--EXPECTATION : 0 

select* from  bronze.crm_cust_info

select cst_id,
count(*) as counter
from bronze.crm_cust_info
group by cst_id
having  count(*) >1

select * from bronze.crm_cust_info 
where cst_gndr is null

select 
from (

select *,
row_number() over(partition by cst_id order by cst_create_date desc ) as flaglast
from  bronze.crm_cust_info 
) T 
WHERE flaglast=1 

--REMOVING UNWANTED SPACES 
--EXPECTATION : 0 

SELECT cst_gndr FROM bronze.crm_cust_info
WHERE cst_gndr <> TRIM(cst_gndr)
--RESULT ---17 ROWS 
--CLEANING PROCEDURE WITH REMOVING CID DUPLICATES AND NULLS 

SELECT 
 cst_id, 
cst_key,
TRIM(cst_firstname) AS cst_firstname  ,
TRIM(cst_lastname) AS cst_lastname,
cst_marital_status,
cst_gndr
cst_create_date	
FROM 
(
  SELECT *, 
  ROW_NUMBER()OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS FLAGGED
  FROM  bronze.crm_cust_info 
) T 
WHERE FLAGGED = 1 

---DATA STANDARDISATION AND CONSISTENCY 

SELECT DISTINCT cst_marital_status from bronze.crm_cust_info
SELECT DISTINCT cst_gndr from bronze.crm_cust_info

--DATA STANDARDISATION AND CONSISTENCY  and cleaned 
select 
 cst_id, 
cst_key,
TRIM(cst_firstname) AS cst_firstname,--DATA CLEANING 
TRIM(cst_lastname) AS cst_lastname,
case --data standardization 
      WHEN UPPER(TRIM(cst_marital_status)) ='M' THEN 'MARRIED'
      WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'SINGLE'
	  ELSE 'N/A'--HANDLING MISSING VALUES / NULL VALUES 
END AS cst_marital_status , 
case--data standardization 
	  WHEN UPPER(TRIM(cst_gndr)) ='M' THEN 'MALE'
      WHEN UPPER(TRIM(cst_gndr)) ='F' THEN 'FEMALE'
	  ELSE 'N/A'
END AS cst_gndr,
cst_create_date
FROM ---REMOVING DUPLICATES , DATA CLEANING 
(
   SELECT *,
   ROW_NUMBER()OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS FLAGGED 
   FROM bronze.crm_cust_info 
) T 
WHERE FLAGGED = 1 ---DATA FILTERING 

---inserting the cleaned data  into silver 
insert into silver.crm_cust_info( cst_id, cst_key,cst_firstname  , cst_lastname,cst_marital_status ,  cst_gndr,cst_create_date)
 select 
 cst_id, 
cst_key,
TRIM(cst_firstname) AS cst_firstname  ,
TRIM(cst_lastname) AS cst_lastname,
case when UPPER(TRIM(cst_marital_status)) ='M' THEN 'MARRIED'
      WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'SINGLE'
	  ELSE 'N/A'
END AS cst_marital_status , 
case
	  WHEN UPPER(TRIM(cst_gndr)) ='M' THEN 'MALE'
      WHEN UPPER(TRIM(cst_gndr)) ='F' THEN 'FEMALE'
	  ELSE 'N/A'
END AS cst_gndr,
cst_create_date
FROM 
(
   SELECT *,
   ROW_NUMBER()OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS FLAGGED 
   FROM bronze.crm_cust_info 
) T 
WHERE FLAGGED = 1   
--- silver  CRM  TABLE 
select * from silver.crm_cust_info
select * from silver.crm_prd_info
select * from silver.crm_sales_details
--- bronze CRM PRD_INFO TABLE related tables 
select * from bronze.crm_prd_info
select* from   bronze.crm_sales_details
select* from   silver.erp_PX_CAT_G1V2

select prd_id,
count(*) as counter
from bronze.crm_prd_info
group by prd_id 
having count(*) >1 or count(*) is null 

SELECT prd_nm from  bronze.crm_prd_info 
where length(prd_nm) <> length(trim(prd_nm))

SELECT prd_cost,prd_nm from  bronze.crm_prd_info 
where prd_cost < 0 or prd_cost is null 

SELECT DISTINCT prd_line FROM bronze.crm_prd_info 
--CHECKING THE DATES: THE END DATE SHOULD ALWAYS BE GREATER THEN THE START DATE 
SELECT prd_nm,prd_key,prd_end_dt,prd_start_dt FROM bronze.crm_prd_info
WHERE prd_start_dt >prd_end_dt
-- THE END DATE IS SMALLER THEN START DATE AND THERE IS AN OVERLAP IN THE DATES FOR THE SAME PRODUCT 
--- SO WE WILL USE THE START DATE OF THE NEXT COL AS THE END DATE OF THE CURRECT COLUMN -1 TO AVOID OVERLAPPING 
-- WE WILL USE LEAD AND LAG TO GET THE THE DATE OF NEXT ROW AS THE END DATE 
-- WE WILL FIRST TEST AND BUILD THE SOLUTION FOR ONE PRODUCT HAVING MULTIPLE START AND ENDS DATE ALL ARE OVERLAPPED

SELECT 
prd_id,
prd_key	,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt)OVER(PARTITION BY prd_key ORDER BY prd_start_dt ) -1  AS ENDDATE
FROM bronze.crm_prd_info 
WHERE prd_key ='AC-HE-HL-U509-R' OR prd_key = 'CO-MF-FR-M94S-42'
---spliting columns for joining with other comlumns 
insert into silver.crm_prd_info 
(prd_id,
cat_id ,
prd_key	,
prd_nm	,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt)
select 
prd_id,
Replace(SUBSTRING(prd_key,1,5),'-','_') As cat_id, --spliting the column into a new column substring(column name, start , length) & replaceing- with_ as our erpproduct table has _ so its important to replace it in order to join
SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
prd_nm,
COALESCE(prd_cost,0),
CASE Upper(trim(prd_line)) ---- ONLY USE THIS CASE SYNTAX FOR SIMPLE CAMP DONT USE IT FOR COMPLEX CALCULATIONS
     WHEN  'M' THEN 'Mountain'
	 WHEN  'R' THEN 'Road'
     WHEN  'S' THEN 'Other Sales'
     WHEN  'T' THEN 'Touring'
     ELSE  'N/A'
END AS prd_line,
prd_start_dt,
LEAD(prd_start_dt)OVER(PARTITION BY prd_key ORDER BY prd_start_dt ) -1  AS ENDDATE
from  bronze.crm_prd_info

---- CRM SALES TABLE 
select* from   bronze.crm_sales_details
select* from  silver.crm_cust_info
--CHECKS 
--primary key / duplicate, null value check 
select sls_ord_num
from bronze.crm_sales_details
WHERE sls_ord_num <> sls_ord_num

--CHECKING DATES PRESENT IN INT WHATER THEY ARE 0 OR LESS THEN 0 
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt <0

SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt = 0
------THE DATES ARE IN INT NOT IN DATE , 0 AND NEGATIVE  CANT BE CASTED TO DATE DIRECTLY ----
---STEP 1 CONVERT ALL 0 OR NEG TO NULL 
SELECT NULLIF(sls_order_dt,0) AS sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt = 0 
--- TO CAST AS DATE WE NEED THE LENGTH OF THE DATE EVEN IN INTEGER TO BE 8 ANYTHING LESS THEN THAT WILL BE COURPTED DATA 
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE LENGTH(CAST(sls_order_dt AS varchar)) <> 8 
--TO CAST INT TO DATE FIRST CHANGE IT TO VARCHAR THEN CHNAGE IT TO DATE ---
--CHECKING FOR sls_ship_dt SAME METHOD---
SELECT NULLIF(sls_ship_dt,0) AS sls_ship_dt FROM bronze.crm_sales_details
WHERE sls_ship_dt <=0
SELECT NULLIF(sls_ship_dt,0) AS sls_ship_dt FROM bronze.crm_sales_details
WHERE LENGTH(CAST(sls_ship_dt AS varchar)) <> 8 
---NO ERROR THE sls_ship_dt AND  sls_due_dt IS PERFECT BUT STILL WE ARE GOING TO APPLY  THE SAME SOL AS ORDER DATE FOR FUTURE PURPOSE 
 --- CHECK IF DUE DATE OR SHIPPING DATE IS GREATER THEN ORDER DATE 
SELECT sls_ord_num	,sls_prd_key,sls_cust_id  FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR  sls_order_dt > sls_due_dt

----------------------------------------------------------------------------------------------------------
-----BUSINESS RULE :---------------------------------------------
 --- SALE =QUANTITY * PRICE ----------------------------------------
 --- SALES CAN NOT BE ZERO , NULL , NEGATIVE ---------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------CHECKING THE SALES FOR THE BUSINESS RULE ----------
SELECT sls_sales AS GIVENSALES,sls_price AS ORIGINALPRICE,sls_quantity,CASE 
     WHEN sls_sales IS NULL OR sls_sales <0 OR sls_sales <> sls_price * sls_quantity
	 THEN ABS(sls_price) * sls_quantity 
	 ELSE sls_sales
END AS NEWSALES, 
 CASE 
     WHEN sls_price IS NULL OR sls_price <0 
	 THEN ABS(sls_sales)/NULLIF(sls_quantity,0) 
	 ELSE sls_price
END AS NEWsls_price
FROM bronze.crm_sales_details
WHERE sls_sales <> sls_price * sls_quantity OR sls_price IS NULL OR  sls_price<=0 OR sls_sales <=0 OR sls_sales IS NULL 

--- WE HAVE NULLS FOR PRICES , NEGATIVES AND OS ALSO HAVE NULL IN SALES 

----------------------------------------------------------------------------------------------------------
-----BUSINESS RULE :
-- in case the sales , price or  quantity have issues nulls , zero and neg then three options -------------------------------------------
 --- SALE = QUANTITY * PRICE ------if sales is wrong ----------------------------------
 --- if price is wrong calculate it through Quantity and Sales  ---------------------------
-----if price is negative convert it to the positive of the same quantity ---------------------------------------------------------------------
--------------------------------------------------------------------------------------
SELECT sls_quantity 
 CASE 
     WHEN sls_sales IS NULL OR sls_sales <0 OR sls_sales <> sls_price * sls_quantity
	 THEN ABS(sls_price) * sls_quantity 
	 ELSE sls_sales
END AS NEWSALES, 
 CASE 
     WHEN sls_price IS NULL OR sls_price <0 
	 THEN ABS(sls_sales)/NULLIF(sls_quantity,0) 
	 ELSE sls_price
END AS NEWsls_price
FROM bronze.crm_sales_details

---------------------------------------------------------------------------------------------------------
SELECT * FROM silver.crm_sales_details

INSERT INTO silver.crm_sales_details
(
sls_ord_num	,
sls_prd_key	,
sls_cust_id	 ,
sls_order_dt  ,
sls_ship_dt	 ,
sls_due_dt	 ,
sls_sales,
sls_quantity,
sls_price

)
SELECT sls_ord_num	,
sls_prd_key	,
sls_cust_id	 ,
CASE 
       WHEN LENGTH(CAST(sls_order_dt AS varchar(20))) <> 8 THEN NULL 
	   ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
END AS sls_order_dt,
CASE 
       WHEN LENGTH(CAST(sls_ship_dt AS varchar(20))) <> 8 THEN NULL 
	   ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
END AS sls_ship_dt ,
CASE 
       WHEN LENGTH(CAST(sls_due_dt AS varchar(20))) <> 8 THEN NULL 
	   ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
END AS sls_due_dt ,
CASE 
     WHEN sls_sales IS NULL OR sls_sales <0 OR sls_sales <> sls_price * sls_quantity
	 THEN ABS(sls_price) * sls_quantity 
	 ELSE sls_sales
END AS sls_sales,
sls_quantity ,
CASE 
     WHEN sls_price IS NULL OR sls_price <0 
	 THEN ABS(sls_sales)/NULLIF(sls_quantity,0) 
	 ELSE sls_price
END AS sls_price
from   bronze.crm_sales_details

------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
------------------------------------------ERP--------------------------------------------------------
SELECT * FROM   bronze.erp_CUST_AZ12
SELECT * FROM   silver.crm_cust_info
SELECT * FROM   silver.erp_CUST_AZ12
SELECT * FROM   bronze.erp_LOC_A101
SELECT CID FROM bronze.erp_CUST_AZ12 
WHERE CID IS NULL 
SELECT 
case 
 when cid like 'NAS%' THEN SUBSTRING(cid,4,length(cid)) 
 ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_CUST_AZ12 
where case 
 when cid like 'NAS%' THEN SUBSTRING(cid,4,length(cid)) ELSE cid
END  not in (select cst_key from  silver.crm_cust_info)
--another way
SELECT CID , substring(cid,length(cid)-4,length(cid)) FROM bronze.erp_CUST_AZ12 
---age 
select bdate from bronze.erp_CUST_AZ12
where bdate <'1926-12-12' or bdate > CURRENT_DATE

select distinct gen from bronze.erp_CUST_AZ12

insert into silver.erp_CUST_AZ12
(
CID	,
BDATE,
GEN	
)
SELECT 
case 
 when cid like 'NAS%' THEN SUBSTRING(cid,4,length(cid)) 
 ELSE cid
END AS cid,
case 
when bdate > current_date then null
 else bdate
end as bdate ,
case when UPPER(trim(gen)) IN ('F','FEMALE') THEN 'FEMALE'
     when UPPER(trim(gen)) IN ('M','MALE') THEN 'MALE'
	 ELSE 'N/A'
END AS gen
FROM bronze.erp_CUST_AZ12 
-------------------------------------------------------
SELECT * FROM   silver.crm_cust_info
SELECT * FROM   bronze.erp_LOC_A101
SELECT * FROM   silver.erp_LOC_A101

select replace(cid,'-','') as cid,
count(*)
from bronze.erp_LOC_A101
group by cid
order by count(*) desc 

select  distinct CNTRY from silver.erp_LOC_A101

insert into silver.erp_LOC_A101
(
 cid,
 CNTRY
)
select 
replace(cid,'-','') as cid ,
case 
 when TRIM(CNTRY)='DE' THEN 'Germany'
 when  TRIM(CNTRY) IN('US','USA') then 'United States'
 when  TRIM(CNTRY)='' or CNTRY is null then 'n/a'
 else CNTRY
end as CNTRY 
from 
bronze.erp_LOC_A101
where replace(cid,'-','') not in(select cst_key from silver.crm_cust_info )


-------------------
SELECT * FROM   bronze.erp_PX_CAT_G1V2
SELECT * FROM   silver.crm_prd_info 
SELECT * FROM   silver.erp_PX_CAT_G1V2

SELECT trim (cat)
FROM silver.crm_cust_info
WHERE cat <> trim(cat)

SELECT trim (subcat)
FROM bronze.erp_PX_CAT_G1V2  
WHERE subcat <> trim(subcat)

insert into silver.erp_PX_CAT_G1V2
(ID	,
CAT	,
SUBCAT	,
MAINTENANCE 
)
select ID	,
CAT	,
SUBCAT	,
MAINTENANCE 
from bronze.erp_PX_CAT_G1V2