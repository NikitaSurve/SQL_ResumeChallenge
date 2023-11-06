/* Q1 Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
Select distinct market from dim_customer where 
customer = "Atliq Exclusive" and 
region = "APAC";

/*Q2 What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
*/
with 
unique2020 as (
select Count(distinct(product_code)) as total2020 from fact_sales_monthly
where fiscal_year = 2020
),
unique2021 as (
select Count(distinct(product_code)) as total2021 from fact_sales_monthly
where fiscal_year = 2021

)
select p20.total2020 as Unique_product_2020, p21.total2021 as Unique_product_2021, Round((((p21.total2021-p20.total2020)*100)/p21.total2021),2) as percentage_change from unique2020 p20 cross join
unique2021 p21;


/*Q3 Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
*/
select count(distinct(product)) as uniquep, segment from dim_product
group by segment
order by uniquep desc;


/*Q4 Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

with 
unique2020 as (
select Count(distinct(p.product_code)) as total2020, segment from fact_sales_monthly f
join dim_product p on p.product_code = f.product_code
where fiscal_year = 2020
group by p.segment
),
unique2021 as (
select Count(distinct(p.product_code)) as total2021, segment from fact_sales_monthly f
join dim_product p on p.product_code = f.product_code
where fiscal_year = 2021
group by p.segment

)
select p20.segment, p20.total2020 as Unique_product_2020,
 p21.total2021 as Unique_product_2021, 
 (p21.total2021-p20.total2020) as difference
 from unique2020 p20 join
unique2021 p21
on p20.segment = p21.segment;


/*Q5 Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/
with 
productCost as (
select p.product_code, p.product, m.manufacturing_cost from dim_product p join 
fact_manufacturing_cost m on p.product_code = m.product_code
)
select * from productCost 
where manufacturing_cost in ((select max(manufacturing_cost) from productCost),
 (select min(manufacturing_cost) from productCost))
 order by manufacturing_cost desc;


/* Q6 Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/
with
CustomerDiscount as (
select c.customer_code, c.customer,d.pre_invoice_discount_pct,
dense_rank() over( order by d.pre_invoice_discount_pct desc) as rnk
 from dim_customer c
join fact_pre_invoice_deductions d
on d.customer_code = c.customer_code
where c.market = "India" and 
d.fiscal_year = 2021 and
d.pre_invoice_discount_pct >= (select avg(pre_invoice_discount_pct) from fact_pre_invoice_deductions)
)
select customer_code, customer, concat(Round(pre_invoice_discount_pct*100,2),"%") as  average_discount_percentage
 from CustomerDiscount where rnk<= 5;


/* Q7 Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

with 
GrossSales as (
select g.product_code, s.date, s.customer_code, g.gross_price, s.sold_quantity from fact_gross_price g 
join fact_sales_monthly s 
on s.product_code = g.product_code
),
SalesCustomer as (
select GS.*, c.customer from dim_customer c join GrossSales GS 
on GS.customer_code = c.customer_code
where customer = "Atliq Exclusive"
)

select year(date) as year, monthname(date) as month, Round(Sum(gross_price*sold_quantity/1000000),2) as gross_sales_amount_mln from SalesCustomer
group by year, month;

/* Q8 In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

select get_quater(date) as quater, sum(sold_quantity) as total_sold_quantity from  fact_sales_monthly 
where fiscal_year = 2020
group by quater
order by total_sold_quantity desc;


/* Q9 Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/
with GrossSales as
(
select g.product_code, s.customer_code, (g.gross_price * s.sold_quantity)/1000000 as gross_sales_mln from fact_gross_price g
join fact_sales_monthly s 
on g.product_code = s.product_code and 
g.fiscal_year = s.fiscal_year
where g.fiscal_year = 2021
),
totalsale as (
select sum(gross_sales_mln) as totalsales from GrossSales
)
,
channels as (
select c.channel,  round(Sum(gs.gross_sales_mln),2) as specificsale_mln from dim_customer c join GrossSales gs
on c.customer_code = gs.customer_code
group by c.channel
)
select c.channel, c.specificsale_mln, Round((specificsale_mln*100)/totalsales,2) as channelContribution_pct from channels c cross join totalsale ts 
order by channelContribution_pct desc;

/* Q10 Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
codebasics.io
product
total_sold_quantity
rank_order*/

with productSales as (
select p.product, p.division, p.product_code, sum(s.sold_quantity) as total_sold_quantity
from dim_product p join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.product, p.division, p.product_code
order by total_sold_quantity desc
),
rankorder as (

select *, dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order from productSales

)
select * from rankorder where rank_order <=3

