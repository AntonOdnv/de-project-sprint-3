DROP TABLE IF EXISTS mart.f_customer_retention;

CREATE TABLE mart.f_customer_retention (	
	new_customers_count int4 NULL,
	returning_customers_count int4 NULL,
	refunded_customer_count int4 NULL,
	period_name varchar(20) NOT NULL default 'weekly'::character varying,
	period_id int4 NOT NULL,
	item_id int4 NOT NULL,
	new_customers_revenue numeric(10, 2) null,
	returning_customers_revenue numeric(10, 2) null,
	customers_refunded int4 null);

INSERT INTO  mart.f_customer_retention (period_id, 
										item_id, 
										new_customers_count, 
										returning_customers_count, 
										refunded_customer_count, 
										new_customers_revenue, 
										returning_customers_revenue, 
										customers_refunded)
WITH time_customer_item_group_with_customer_types AS(
WITH time_customer_item_group AS (
SELECT period_id,
	   customer_id, 
	   item_id, 	    
	   SUM(CASE 
	   		WHEN sales.status != 'refunded' THEN 1 ELSE 0 	   		
	       END) AS orders, 
	   SUM(payment_amount) AS total_amount,
	   SUM(CASE 
	   		WHEN sales.status = 'refunded' THEN 1 ELSE 0 	   		
	   	   END) AS is_refund
FROM mart.f_sales AS sales
LEFT JOIN (
	   SELECT date_id, 
	   	      substring(replace(replace(week_of_year_iso, '-', ''), 'W', '') FROM 1 FOR 6)::integer AS period_id 
	   FROM mart.d_calendar
	   	  ) AS cal USING (date_id)
GROUP BY period_id, customer_id, item_id)
SELECT *,
	   MAX(orders) OVER(PARTITION BY (period_id, customer_id)) AS new_return_indicator,
	   SUM(is_refund) OVER(PARTITION BY (period_id, customer_id)) AS client_refund_indicator
FROM time_customer_item_group)
SELECT period_id, 
	   item_id,
	   SUM(CASE WHEN new_return_indicator = 1 THEN 1 ELSE 0 END) AS new_customers_count,
	   SUM(CASE WHEN new_return_indicator > 1 THEN 1 ELSE 0 END) AS returning_customers_count,
	   SUM(client_refund_indicator) AS refunded_customer_count,
	   SUM(CASE WHEN new_return_indicator = 1 THEN total_amount ELSE 0 END) AS new_customers_revenue,
	   SUM(CASE WHEN new_return_indicator > 1 THEN total_amount ELSE 0 END) AS returning_customers_revenue,
	   SUM(is_refund) AS customers_refunded
FROM time_customer_item_group_with_customer_types
GROUP BY period_id, item_id
ORDER BY item_id ASC, period_id ASC