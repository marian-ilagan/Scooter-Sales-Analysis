#Submitted by Marian Ilagan 301236806
/***BE SURE TO DROP ALL TABLES IN WORK THAT BEGIN WITH "CASE_"***/

/*Set Time Zone*/
set time_zone='-4:00';
select now();

/***PRELIMINARY ANALYSIS***/

/*Create a VIEW in WORK called CASE_SCOOT_NAMES that is a subset of the prod table
which only contains scooters.
Result should have 7 records.*/

CREATE VIEW WORK.CASE_SCOOT_NAMES AS
	SELECT *
    FROM BA710CASE.ba710_prod
    WHERE product_type = 'scooter';

select * from work.case_scoot_names;

/*The following code uses a join to combine the view above with the sales information.
  Can the expected performance be improved using an index?
  A) Calculate the EXPLAIN COST.
  B) Create the appropriate indexes.
  C) Calculate the new EXPLAIN COST.
  D) What is your conclusion?:
  
*/

create table work.case_scoot_sales as 
	select a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, date(b.sales_transaction_date) as sale_date,
    b.sales_amount, b.channel, b.dealership_id
from work.case_scoot_names a 
inner join ba710case.ba710_sales b
    on a.product_id=b.product_id;
    
select * from work.case_scoot_sales;

#a) Calculate explain cost: 4596.09
EXPLAIN FORMAT = JSON select a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, date(b.sales_transaction_date) as sale_date,
    b.sales_amount, b.channel, b.dealership_id
from work.case_scoot_names a 
inner join ba710case.ba710_sales b
    on a.product_id=b.product_id;

#b) Create the appropriate indexes
Create index idx_prod on ba710case.ba710_sales(product_id);
Create index idx_prod on work.case_scoot_names(product_id); #cannot create index on view, only on base tables

#c) Calculate the new EXPLAIN COST
#Answer: Rerunning the explain plan query above, the new cost is 616.50.

#d) Conclusion: Creating an index on the base table ba710case.ba710_sales for product_id column has reduced the cost from 4596.09 to 616.5.


/***PART 1: INVESTIGATE BAT SALES TRENDS***/  
    
/*The following creates a table of daily sales and will be used in the following step.*/

CREATE TABLE work.case_daily_sales AS
	select p.model, p.product_id, date(s.sales_transaction_date) as sale_date, 
		   round(sum(s.sales_amount),2) as daily_sales
	from ba710case.ba710_sales as s 
    inner join ba710case.ba710_prod as p
		on s.product_id=p.product_id
    group by date(s.sales_transaction_date),p.product_id,p.model;


/*Examine the drop in sales.*/
/*Create a table of cumulative sales figures for just the Bat scooter from
the daily sales table you created.
Using the table created above, add a column that contains the cumulative
sales amount (one row per date).
Hint: Window Functions, Over*/

CREATE TABLE work.daily_sales_bat AS
select *, round(sum(daily_sales) over(order by sale_date),2) as cumulative_sales
from work.case_daily_sales
where model = 'Bat';

/*Using the table above, create a VIEW that computes the cumulative sales 
for the previous 7 days for just the Bat scooter. 
(i.e., running total of sales for 7 rows inclusive of the current row.)
This is calculated as the 7 day lag of cumulative sum of sales
(i.e., each record should contain the sum of sales for the current date plus
the sales for the preceeding 6 records).
*/

CREATE VIEW WORK.cumu_sales_bat AS
	select *, round(sum(daily_sales) over(rows between 6 preceding and current row),2) as cumu_sales_7_days
	from work.daily_sales_bat;


/*Using the view you just created, create a new view that calculates
the weekly sales growth as a percentage change of cumulative sales
compared to the cumulative sales from the previous week (seven days ago).

See the Word document for an example of the expected output for the Blade scooter.*/
CREATE VIEW WORK.daily_sales_bat_final AS
select *, (cumulative_sales-(lag(cumulative_sales,7) over()))/(lag(cumulative_sales,7) over())*100 as pct_weekly_increase_cumu_sales
from WORK.cumu_sales_bat;

#final
select * from WORK.daily_sales_bat_final;

/*Questions: On what date does the cumulative weekly sales growth drop below 10%?
Answer: 2016-12-06

Question: How many days since the launch date did it take for cumulative sales growth
to drop below 10%?
Answer: 57 days                  */

select min(sale_date)
from WORK.daily_sales_bat_final
where pct_weekly_increase_cumu_sales < 10;
#2016-12-06

select datediff(min(a.sale_date), b.production_start_date) 
from WORK.daily_sales_bat_final a,
ba710case.ba710_prod b
where b.model = 'Bat'
and pct_weekly_increase_cumu_sales < 10
group by b.production_start_date;

/*********************************************************************************************
Is the launch timing (October) a potential cause for the drop?
Replicate the Bat sales cumulative analysis for the Bat Limited Edition.
*/

#Creating table for bat limited edition with cumulative sales
CREATE TABLE work.daily_sales_bat_limited AS
select *, round(sum(daily_sales) over(order by sale_date),2) as cumulative_sales
from work.case_daily_sales
where model = 'Bat Limited Edition';

select * from work.daily_sales_bat_limited;

#Creating view for bat limited edition with cumulative sales for past 7 days
CREATE VIEW WORK.cumu_sales_bat_limited AS
	select *, round(sum(daily_sales) over(rows between 6 preceding and current row),2) as cumu_sales_7_days
	from work.daily_sales_bat_limited;

select * from WORK.cumu_sales_bat_limited;

#Creating view for bat limited edition with cumulative weekly growth
CREATE VIEW WORK.daily_sales_bat_limited_final AS
select *, (cumulative_sales-(lag(cumulative_sales,7) over()))/(lag(cumulative_sales,7) over())*100 as pct_weekly_increase_cumu_sales
from WORK.cumu_sales_bat_limited;

select * from WORK.daily_sales_bat_limited_final;

select min(sale_date)
from WORK.daily_sales_bat_limited_final
where pct_weekly_increase_cumu_sales < 10;
#2017-04-29

select datediff(min(a.sale_date), b.production_start_date) 
from WORK.daily_sales_bat_limited_final a,
ba710case.ba710_prod b
where b.model = 'Bat Limited Edition'
and pct_weekly_increase_cumu_sales < 10
group by b.production_start_date;
#73 days

select * from ba710case.ba710_prod
where model in ('Bat Limited Edition', 'Bat');
#October, #February

/*********************************************************************************************
However, the Bat Limited was at a higher price point.
Let's take a look at the 2013 Lemon model, since it's a similar price point.  
Is the launch timing (October) a potential cause for the drop?
Replicate the Bat sales cumulative analysis for the 2013 Lemon model.*/

select *
from ba710case.ba710_prod
where model like '%Lemon%'
and year = '2013';
#product_id = 3

#Creating table for Lemon 2013 model with cumulative sales
CREATE TABLE work.daily_sales_lemon2013 AS
select *, round(sum(daily_sales) over(order by sale_date),2) as cumulative_sales
from work.case_daily_sales
where model = 'Lemon'
and product_id = '3';

select * from work.daily_sales_lemon2013;

#Creating view for Lemon 2013 model with cumulative sales for past 7 days
CREATE VIEW WORK.cumu_sales_lemon2013 AS
	select *, round(sum(daily_sales) over(rows between 6 preceding and current row),2) as cumu_sales_7_days
	from work.daily_sales_lemon2013;

select * from WORK.cumu_sales_lemon2013;

#Creating view for bat limited edition with cumulative weekly growth
CREATE VIEW WORK.daily_sales_lemon2013_final AS
select *, (cumulative_sales-(lag(cumulative_sales,7) over()))/(lag(cumulative_sales,7) over())*100 as pct_weekly_increase_cumu_sales
from WORK.cumu_sales_lemon2013;

select * from WORK.daily_sales_lemon2013_final;

select min(sale_date)
from WORK.daily_sales_lemon2013_final
where pct_weekly_increase_cumu_sales < 10;
#2013-07-01

select datediff(min(a.sale_date), b.production_start_date) 
from WORK.daily_sales_lemon2013_final a,
ba710case.ba710_prod b
where b.product_id = 3
and pct_weekly_increase_cumu_sales < 10
group by b.production_start_date;
#61 days
