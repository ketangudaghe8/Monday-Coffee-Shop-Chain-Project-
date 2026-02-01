create database Coffee_Analysis;

use Coffee_Analysis;


-- Analysis

-- 1) Number of people consuming coffee in each city(given that 25% population does) 

SELECT 
    city_name,
    population,
    ROUND(population * 0.25) AS People_Consuming_coffee
FROM
    city
GROUP BY city_name , population
ORDER BY People_Consuming_coffee DESC;


-- 2) total sales in the last quarter of 2023

SELECT 
    SUM(S.total) AS Total_sale, Ci.city_name
FROM
    customers AS Cu
        JOIN
    sales AS S ON Cu.customer_id = S.customer_id
        JOIN
    city AS Ci ON Cu.city_id = Ci.city_id
WHERE
    YEAR(S.sale_date) = 2023
        AND QUARTER(S.sale_date) = 4
GROUP BY Ci.city_name
ORDER BY 1 DESC;


-- 3) Sales count based on product

select P.product_name as Product_name, count(S.sale_id) as Total_sale
from products as P 
Join 
sales as S on P.product_id = S.product_id
group by P.product_name
order by Total_sale desc;


-- 4) Average sales amount per person per city

SELECT 
    Ci.city_name,
    SUM(S.total) AS Total_sale,
    COUNT(DISTINCT (S.customer_id)) AS Customer_count,
    ROUND(SUM(S.total) / COUNT(DISTINCT (S.customer_id)),
            2) AS Sale_per_person
FROM
    city AS Ci
        JOIN
    customers AS Cu ON Ci.city_id = Cu.city_id
        JOIN
    sales AS S ON Cu.customer_id = S.customer_id
GROUP BY Ci.city_name
ORDER BY Total_sale DESC; 


-- 5) Coffee consumers in the city and current unique coffe consumers at shop


with City_table
as
(select city_name,
	   population * 0.25 as coffee_consumers
       from city
       ),

customer_table as     
       
(Select Ci.city_name,
	   count(distinct(S.customer_id)) as Unique_consumer_at_shop
from 
		city as Ci join customers as Cu
        on Ci.city_id = Cu.city_id
Join
		sales as S on
        Cu.customer_id = S.customer_id
group by Ci.city_name)       

Select Ct.city_name,
       Ct.coffee_consumers,
       Cs.Unique_consumer_at_shop
from city_table as Ct
join customer_table as Cs     
on Ct.city_name = Cs.city_name  
order by   Ct.coffee_consumers desc  ;


-- 6) Top 3 selling products in each city based on sales volume

Select *
from

(Select Ci.city_name,
       P.product_name,
       count(S.sale_id) as total_sale,
       dense_rank() over (partition by  Ci.city_name order by count(S.sale_id)) as ranking
From sales as S
join products as P
on S.product_id = P.product_id
join
customers as Cu
on Cu.customer_id = S.customer_id
join
city as Ci
on Ci.city_id = Cu.city_id
group by 1,2)
as T1
where ranking <=3;



-- 7) Unique customers per city who purchased "Coffee only"(Only people who purcahsed coffee products and not other items like mugs etc)

SELECT 
    Ci.city_name,
    COUNT(DISTINCT (S.customer_id)) AS Customer_count
FROM
    city AS Ci
        JOIN
    customers AS Cu ON Ci.city_id = Cu.city_id
        JOIN
    sales AS S ON Cu.customer_id = S.customer_id
        JOIN
    products AS P ON P.product_id = S.product_id
WHERE
    P.product_id IN (
        1 ,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14)
GROUP BY Ci.city_name
ORDER BY Customer_count DESC; 


-- 8) Avg Sale vs Avg rent per customer in each city

With Average_sale_per_customer
as
(SELECT 
    Ci.city_name,
    COUNT(DISTINCT (S.customer_id)) AS Customer_count,
    ROUND(SUM(S.total) / COUNT(DISTINCT (S.customer_id)),
            2) AS Avg_Sale_per_customer     
FROM
    city AS Ci
        JOIN
    customers AS Cu ON Ci.city_id = Cu.city_id
        JOIN
    sales AS S ON Cu.customer_id = S.customer_id
GROUP BY Ci.city_name
ORDER BY ROUND(SUM(S.total) / COUNT(DISTINCT (S.customer_id)),
            2)  DESC),

Avg_rent_per_customer as
( select city_name,
estimated_rent as rent
from
city)

select  
  Ac.city_name,
  Ac.Customer_count as unique_customers,
  Ac.Avg_Sale_per_customer,
  round((Ar.rent/Ac.Customer_count),2) as Average_rent_per_Customer
  from Average_sale_per_customer as Ac
  join Avg_rent_per_customer as Ar
  on Ac.city_name = Ar.city_name
  order by unique_customers desc;
  

-- 9) Growth rate per month for each city

With City_table
as
(Select Ci.city_name,
       year(S.sale_date) as Year,
       month(S.sale_date) as Month,
       sum(S.total) as Total_sale
From 
       city as Ci
   Join    
	   customers as Cu
   on
       Ci.city_id = Cu.city_id
   Join  
       Sales as S
   on
       S.customer_id = Cu.customer_id
group by city_name, Year, Month 
order by city_name, Year, Month),      
 
 Growth as
       
(Select Ci.city_name,
       year(S.sale_date) as Year,
       month(S.sale_date) as Month,
       sum(S.total) as Total_sale,
       Lag(sum(S.total),1) over (partition by Ci.city_name order by Ci.city_name,year(S.sale_date),month(S.sale_date)) as Previous_month_sale 
From 
       city as Ci
   Join    
	   customers as Cu
   on
       Ci.city_id = Cu.city_id
   Join  
       Sales as S
   on
       S.customer_id = Cu.customer_id
group by city_name, Year, Month 
order by city_name, Year, Month)        
  
Select city_name,
       Year,
       Month,
       Total_sale,
       Previous_month_sale,
       ((Total_sale-Previous_month_sale)/(Previous_month_sale) *100) Growth_ratio
From 
       Growth   ;
       
       
 -- 10) Market Potential Analysis
 -- Top 3 cities based on highest sale
 -- Return City_name,Estimated_coffee_consumers, total_customers, Average_sale_per_customer, Average_rent_per_customer,
    

With Average_sale_per_customer
as
(SELECT 
    Ci.city_name,
    COUNT(DISTINCT (S.customer_id)) AS Customer_count,
    SUM(S.total) as Total_Revenue,
    ROUND(SUM(S.total) / COUNT(DISTINCT (S.customer_id)),
            2) AS Avg_Sale_per_customer     
FROM
    city AS Ci
        JOIN
    customers AS Cu ON Ci.city_id = Cu.city_id
        JOIN
    sales AS S ON Cu.customer_id = S.customer_id
GROUP BY Ci.city_name
ORDER BY ROUND(SUM(S.total) / COUNT(DISTINCT (S.customer_id)),
            2)  DESC),

Avg_rent_per_customer as
( select city_name,
estimated_rent as Estimated_rent,
(population * 0.25) as Estimated_coffee_consumers
from
city)

select  
  Ac.city_name,
  round(Ar.Estimated_coffee_consumers) as Estimated_coffee_consumers,
  Ac.Customer_count as unique_customers,
  Ac.Total_revenue,
  Ac.Avg_Sale_per_customer,
  Ar.Estimated_rent,
  round((Ar.Estimated_rent/Ac.Customer_count),2) as Average_rent_per_Customer
  from Average_sale_per_customer as Ac
  join Avg_rent_per_customer as Ar
  on Ac.city_name = Ar.city_name
  order by Average_rent_per_Customer;
  
  
  -- Based on the above analysis
  -- Below are best perfroming stores considering various factors
  
  -- 1) Jaipur
  --  a) Average rent per customer is low i.e 156.52
  --  b) Customer count is high (69)
  --  c) Average sale per customer is moderate to high(11644.20)  

  -- 2) Pune 
  --  a) Average sale per customer is high hence the revenue is high (1258290)
  --  b) Total estimated coffee comsumers are High i.e 1875000 (customers will increase eventually)
  --  c) Rent per customer is low (294.23)
  
  -- 3) Delhi
  --  a) Customer count is high and also estimated comsumers are also high
  --       (customer_count = 68, Estimated_consumers= 7750000)
  --  b) Avg_Rent_per_customer is low to moderate (330.88)
  --  c) Average sales per customer is moderate (Accompanied by high customer count)
  --       (Average sale per customer = 11035.59)

	   

