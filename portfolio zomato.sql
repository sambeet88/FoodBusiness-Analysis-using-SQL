drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--1  what is the total amount spend by each customer?
select userid,sum(price) as amount_spent from sales s join product p on s.product_id=p.product_id group by userid;

--2.(a)How many days has each customer visited Zomato?

 select userid,count(distinct created_date) as no_of_visits from sales group by userid

 --2(b) How many days has each customer visited including signup and goldsignup days

select userid,count(visitdate) as totalvisits from(
select userid,created_date as visitdate from sales
union
select userid,gold_signup_date as visitdate from goldusers_signup
union
select userid,signup_date as visitdate from users)a
group by userid

--3.What is the first product purchased by each customer?
with cte as(
select userid,created_date,product_id,
rank() over(partition by userid order by created_date) as rnk from sales)
select userid,created_date,product_id from cte where rnk=1

--4. What is the most purchased item on the menu and how many times was it ordered by all customers?

select top 1 product_id,count(product_id) as no_of_purchase from sales group by product_id order by count(product_id) desc

--5.How many times was the most purchased item ordered by each indivisual customer?

select userid,count(product_id) as purchase from sales where product_id=
(select top 1 product_id from sales group by product_id order by count(product_id) desc)
group by userid

--6.Which item was the most popular for each customer?
with cte as(
select *,rank() over (partition by userid order by cnt desc) as rnk from 
(select userid,product_id,count(product_id) as cnt from sales group by userid,product_id)a)
select userid,product_id from cte where rnk=1

OR

select userid,product_id from(
select userid,product_id,count(product_id) as totalpurchase,DENSE_RANK() over (partition by userid order by count(product_id) desc) rn  
from sales  group by userid,product_id)a 
where rn=1

--7.Which item was purchased by the user first after they became a gold member?

select userid,product_id from(
select s.*,gold_signup_date,DENSE_RANK() over(partition by s.userid order by created_date asc)rn
from sales s join goldusers_signup g on s.userid=g.userid
where created_date>gold_signup_date)a
where rn=1

--8.Which item was purchased by the user just before they became a gold member?

select userid,product_id from(
select s.*,gold_signup_date,DENSE_RANK() over(partition by s.userid order by created_date desc)rn
from sales s join goldusers_signup g on s.userid=g.userid
where created_date<gold_signup_date)a
where rn=1

--9.What is the total number of order placed and total amount spent by each user before becoming gold member?

select userid,count(created_date) as total_order,sum(price) as total_amount from
(
select sales.userid,created_date,sales.product_id,gold_signup_date,price from sales 
join goldusers_signup on sales.userid=goldusers_signup.userid
and gold_signup_date>=created_date
join product on sales.product_id=product.product_id
)a
group by userid
/*10. If buying each product generates points for Rs 5=2 zomato point and each product has different purchasing points
For eg for p1 Rs 5= 1 zomato point,for p2 Rs 10=5 zomato point and p3 rs5=1 zomato point
calculate points collected and amount earned  by each customer and for which product most points have been given till now?*/
Ans
--for points collected and amount earned  by each customer
with cte as (select product_id,
case when product_id=1 then price/5 
when product_id=2 then price/2 
when product_id=3 then price/5
end as zomatopoints
from product)
select userid,sum(zomatopoints) as collectedpoints, sum(zomatopoints)*2.5 as earnedamount from sales s join cte on s.product_id=cte.product_id  
group by userid;
--for which product most points have been given till now
with cte as (select product_id,
case when product_id=1 then price/5 
when product_id=2 then price/2 
when product_id=3 then price/5
end as zomatopoints
from product)
select top 1 s.product_id,sum(zomatopoints) as collectedpoints from sales s join cte on s.product_id=cte.product_id 
group by s.product_id order by collectedpoints desc;

/*11.In the first one year after a cutomer joins the gold program(including their join date)irrespective
of what the customer has purchased they earn 5 zomato points for every 10 rs.who earned more 1 or 3?
and what was their points earnin in their first year*/
select s.userid,s.created_date,g.gold_signup_date,p.price,p.price/2 as pointsearned
from sales s join goldusers_signup g on s.userid=g.userid and created_date>=gold_signup_date and created_date<=DATEADD(YEAR,1, gold_signup_date) 
join product p on s.product_id=p.product_id

---rank all the transaction of the customers

select *,rank() over (partition by userid order by created_date)rnk from sales 

---rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as NA



WITH cte AS (
    SELECT 
        s.*,
        g.gold_signup_date
    FROM 
        sales s 
    LEFT JOIN 
        goldusers_signup g ON s.userid = g.userid and created_date>=gold_signup_date
),
cte1 as(
SELECT 
    *,
   cast( (CASE 
        WHEN gold_signup_date IS NULL THEN 0
        ELSE rank() over(partition by userid order by created_date desc) end ) as varchar) as rnk   
FROM 
    cte)
select *,case when rnk=0 then 'na' else rnk end as rank from cte1;







				 
