SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

Select 
ci.city_name,
Sum(s.total) as total_revenue
from sales as s
Join customers as c
on s.customer_id = c.customer_id
Join city as ci
on ci.city_id = c.city_id
where 
extract(YEAR from s.sale_date) = 2023
and
extract(quarter from s.sale_date) = 4
group by ci.city_name
order by 2 desc

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
p.product_name,
count(s.sale_id) as total_orders
FROM products as p
left join
sales as s
on s.product_id = p.product_id
group by product_name
order by total_orders desc


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city and total sales
-- no of customer in each of city

Select 
ci.city_name,
Sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_cx,
round 
(Sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cx
from sales as s
Join customers as c
on s.customer_id = c.customer_id
Join city as ci
on ci.city_id = c.city_id
group by ci.city_name
order by 2 desc

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)


With city_table as
(select city_name, ROUND((population *0.25)/1000000,2) as coffee_consumers
from city),
customers_table
as
(select ci.city_name,count(distinct c.customer_id) as unique_cx
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id =c.city_id
Group by 1)

select 
customers_table.city_name, 
city_table.coffee_consumers as coffee_consumer_in_millions,
customers_table.unique_cx
from city_table 
join customers_table
on city_table.city_name =customers_table.city_name

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?


select * from
(select 
ci.city_name,
p.product_name,
count(s.sale_id) as total_orders,
DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as ranking
from sales as s
join products as p
on s.product_id = p.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
Group by ci.city_name,p.product_name) as t1
where ranking <= 3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
-- coffee related products are from 1 to 14
select 
ci.city_name,
count(distinct c.customer_id) as unique_cx
from city as ci
Left join
customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id =c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
Group by ci.city_name

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
-- conclusion

with
city_table 
as
(Select 
ci.city_name,
Sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_cx,
round 
(Sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cx
from sales as s
Join customers as c
on s.customer_id = c.customer_id
Join city as ci
on ci.city_id = c.city_id
group by ci.city_name
order by 2 desc),
city_rent
as
(select city_name , estimated_rent from city)

select 
cr.city_name,
cr.estimated_rent,
ct.total_cx,
ct.avg_sale_per_cx,
Round(cr.estimated_rent/ct.total_cx,2) as avg_rent_pr_cx
from city_rent as cr
join city_table as ct
on cr.city_name =ct.city_name
order by 3 desc
-- city and total rent/total cx

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
with
monthly_sales
 as
(select 
ci.city_name,
Extract(month from sale_date) as month, 
Extract(year from sale_date) as year, 
sum(s.total) as total_sale
from sales as s
Join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1,2,3
order by 1,3,2),
growth_ratio
as
(select
city_name,
month,
year,
total_sale as cr_month_sale,
LAG(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
from monthly_sales)
select
city_name,
month,
year,
cr_month_sale,
last_month_sale,
ROUND((cr_month_sale-last_month_sale)/last_month_sale * 100,2) as growth_ratio
from
growth_ratio
where last_month_sale is not null

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with
city_table 
as
(Select 
ci.city_name,
Sum(s.total) as total_revenue,
count(distinct s.customer_id) as total_cx,
round 
(Sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cx
from sales as s
Join customers as c
on s.customer_id = c.customer_id
Join city as ci
on ci.city_id = c.city_id
group by ci.city_name
order by 2 desc),
city_rent
as
(select city_name ,
 estimated_rent,
 Round((population * 0.25)/1000000,3) as estimated_coffee_consumers_in_millions
 from city)

select 
cr.city_name,
total_revenue,
cr.estimated_rent as total_rent,
ct.total_cx,
estimated_coffee_consumers_in_millions,
ct.avg_sale_per_cx,
Round(cr.estimated_rent/ct.total_cx,2) as avg_rent_pr_cx
from city_rent as cr
join city_table as ct
on cr.city_name =ct.city_name
order by 2 desc

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.





















