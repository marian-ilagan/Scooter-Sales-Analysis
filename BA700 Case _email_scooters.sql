/*Submitted by Marian Ilagan 301236806*/

/* You work at a company that manufactures and sells electric scooters.  
   You have been told to investigate sales trends and marketing emails
   for the Bat Scooter were.
   Your job is to prepare the data for analysis.  
   Complete the steps in the template.*/

drop table if exists work.case_daily_sales;
drop table if exists work.case_sales_email;
drop table if exists work.case_sales_email_bat;
drop table if exists work.case_sales_email_bat_2;
drop table if exists work.case_scoot_names;
drop table if exists work.case_scoot_sales;

/*All tables should be created in your WORK schema, unless otherwise noted*/

/*Set Time Zone*/

set time_zone='-4:00';

select now();

/*Preliminary Data Collection
select * to investigate your tables.*/
select * from ba700case.ba700_prod;
select * from ba700case.ba700_sales;
select * from ba700case.ba700_emails;

/***PRELIMINARY ANALYSIS***/

/*Investigate production dates and prices from the prod table.
  Report (just a select statement) should only contain scooters.
  Order the report by base_msrp.*/

select * from ba700case.ba700_prod
where product_type = 'scooter'
order by base_msrp;

/*Create a new table work.case_scoot_names that is a subset of the prod table
which only contains scooters.
Result should have 7 records.*/

create table work.case_scoot_names as 
select * from ba700case.ba700_prod
where product_type = 'scooter'
order by base_msrp;

select * from work.case_scoot_names; 

/*Use a join to create a new table work.case_scoot_sales 
  that combines the table above with the sales information.
  Store the date from the sales table as a date (use the date function)
  Results should have 34284 rows.*/

drop table work.case_scoot_sales;

create table work.case_scoot_sales as
select c.*, s.customer_id, date(s.sales_transaction_date) sales_date,
s.sales_amount, s.channel, s.dealership_id
from work.case_scoot_names c
join ba700case.ba700_sales s
on c.product_id = s.product_id;
      
select * from work.case_scoot_sales;

/***General Sales Trends and Data Prep***/  

/*Select Bat models from your table.*/
/*Code:*/ 
select * from work.case_scoot_sales
where model = 'Bat';

/*Count the number of Bat sales from your table.*/
/*Code:*/
select count(*) bat_sales
from work.case_scoot_sales
where model = 'Bat';
    
/*Answer: total count of bat sales is 7,328*/

/*What is the total revenue of Bat sales?
  Round the result to the nearest dollar.*/
/*Code:*/
select round(sum(sales_amount),0)
from work.case_scoot_sales
where model = 'Bat';

/*Answer: Total sales amount of Bat model is 4,202,270*/

/*When was most recent Bat sale?*/
/*Code:*/
select max(sales_date)
from work.case_scoot_sales
where model = 'Bat';

/*Answer: The most recent Bat sale was made last May 31, 2019*/

/*Now create a table of daily sales.
  Call your new table work.case_daily_sales.
  Include model, product_id, sale_date (as a date using date function)
	 and a column for total sales for each day.  Call your new column daily_sales.
     daily_sales should aggregate the sum of sales amount by date and product id 
     (one record for each date & product id combination).
     Round daily_sales to two significant digits (2 decimal places.)
   Order the results by model and sales date.
*/

create table work.case_daily_sales as
	select p.model, p.product_id, 
	date(s.sales_transaction_date) sale_date,
	round(sum(s.sales_amount),2) daily_sales
	from ba700case.ba700_prod p
	join ba700case.ba700_sales s
	using (product_id)
	group by p.model, p.product_id, sale_date
	order by p.model, sale_date;

select * from work.case_daily_sales; /*7377k rows*/


/*Email & Sales Prep*/

/*Create a table called WORK.CASE_SALES_EMAIL that contains all of the
  email data as well as both the sales_transaction_date and the product_id 
  from sales. 
  Please use the WORK.CASE_SCOOT_SALES table to capture the sales information.*/

create table WORK.CASE_SALES_EMAIL as
	select e.*, s.sales_date, s.product_id
	from ba700case.ba700_emails e
	join WORK.CASE_SCOOT_SALES s
	on e.customer_id = s.customer_id; /*249,370 rows*/

select count(*) from work.case_sales_email;
 
/***Product email analysis****/
/*Bat emails 30 days prior to purchase
   Create a table from work.case_sales_email called work.case_sales_email_bat
   table that does the following:
      - contains only emails for the Bat scooter
      - contains only emails sent 30 days prior to the purchase date
           hint: use the datediff() function*/

create table work.case_sales_email_bat as
	select * 
	from work.case_sales_email
	where product_id in (select product_id
						from ba700case.ba700_prod
						where model = 'Bat')
	and datediff(sales_date, date(sent_date)) = 30; 

select * from work.case_sales_email_bat; /*30 rows*/
        
/*Filter emails*/
/*There appear to be a number of general promotional emails not 
specifically related to the Bat scooter.  Create a new table 
work.case_sales_email_bat_2 from the the table created above that removes 
emails that have the general sales subjects.

Remove emails containing:
Black Friday
25% off all EVs
It's a Christmas Miracle!
A New Year, And Some New EVs*/

create table work.case_sales_email_bat_2 as
    select *
	from work.case_sales_email_bat
	where email_subject not like '%Black Friday%'
	and email_subject not like '%25% off all EVs%'
	and email_subject not like '%It''s a Christmas Miracle!%'
	and email_subject not like '%A New Year, And Some New EVs%';

select * from work.case_sales_email_bat_2;

/*Question: How many rows are left in the relevant emails view.*/
/*Code:*/
select count(*) 
from work.case_sales_email_bat_2;

/*Answer: 14 rows/emails are left which are related to bat scooter*/


/*Question: How many emails were opened (opened='t')?*/
/*Code:*/
select opened, count(*)
from work.case_sales_email_bat_2
where opened = 't';
    
/*Answer: 1 email is opened*/
