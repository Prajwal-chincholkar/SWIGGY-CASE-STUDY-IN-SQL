/*
sqlplus / as sysdba

SQL*Plus: Release 11.2.0.2.0 Production on Fri Dec 30 13:07:32 2022

Copyright (c) 1982, 2014, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

SQL> connect system
Enter password:
Connected.

SQL> create user prajwal_sql identified by 123;
 
User created.
 
SQL> grant connect to prajwal_sql;
 
Grant succeeded.

SQL> grant all privileges to prajwal_sql;

Grant succeeded.


*/

create table food(
            f_id int,
            f_name varchar2(20),
            "Type" varchar2(10)
);

-- insert values from "swiggy-schema - food.csv"

Select * From food;



create table menu(
            menu_id int,
            r_id int,
            f_id int,
            price int
);

-- insert values from "swiggy-schema - menu.csv"

Select * From menu;



create table order_details(
            id int,
            order_id int,
            f_id int
);

-- insert values from "swiggy-schema - order_details.csv"

Select * From order_details;



create table orders(
            order_id int,
            user_id int,
            r_id int,
            amount int,
            "date" date
);

-- insert values from "swiggy-schema - orders.csv"

Select * From orders;




create table restaurants(
            r_id int,
            r_name varchar2(12),
            cuisine varchar2(13),
            rating float(5)
);

-- insert values from "swiggy-schema - restaurants.csv"

Select * From restaurants;



create table customers(
            user_id int,
            "name" varchar2(20),
            email varchar2(30),
            "password" varchar2(20)
);

-- insert values from "swiggy-schema - users.csv"

Select * From customers;


commit;




-- Find customers who never ordered
Select c."name" From customers c
Where c.user_id not in (Select o.user_id From orders o);



-- Average Price of Dish over all restaurants
--Select f_id, round(avg(price),3) From menu
--Group by f_id
--Order by f_id;
Select m.f_id, f.f_name, round(avg(price),3) as avg_price From menu m
Join food f on m.f_id = f.f_id
Group by m.f_id, f.f_name
Order by m.f_id;



-- Find top restaurant in terms of number of orders for a given month (June)
--Select r_id, count(*) From orders
--Where to_char("date", 'month') Like 'june%'
--Group by r_id
--Order by count(*) desc;
Select o.r_id, r.r_name, count(*) From orders o
join restaurants r on o.r_id=r.r_id
Where to_char("date", 'Month') Like 'June%'
Group by o.r_id, r.r_name
Order by count(*) desc;

-- for month of May
Select o.r_id, r.r_name, count(*) From orders o
join restaurants r on o.r_id=r.r_id
Where to_char("date", 'Month') Like 'May%'
Group by o.r_id, r.r_name
Order by count(*) desc;

-- for month of July
Select o.r_id, r.r_name, count(*) From orders o
join restaurants r on o.r_id=r.r_id
Where to_char("date", 'Month') Like 'July%'
Group by o.r_id, r.r_name
Order by count(*) desc;



-- Restaurants with monthly sales > x (any threshold value)
Select o.r_id,r.r_name, sum(amount) as Revenue from orders o
Join restaurants r on o.r_id=r.r_id
Where to_char("date", 'Month') Like 'June%'
Group by o.r_id,r.r_name having(sum(amount) > 500);



-- Show all orders with order details for a particular customer in a particular date range
Select o.order_id, r.r_name, od.f_id, f.f_name, "date" From orders o
Join restaurants r on r.r_id = o.r_id
Join order_details od on o.order_id = od.order_id
Join food f on f.f_id=od.f_id
Where user_id = (Select user_id From customers Where customers."name" Like 'Saurabh')
and "date" between '10-06-2022' and '10-07-2022';



-- Find restaurants with max repeated customers
--Select r_id, user_id, count(*) as visits From orders
--Group by r_id, user_id
--Having count(*) > 1
--Order by r_id, user_id;
Select t.r_id, r.r_name, count(*) as loyal_customers
From(
        Select r_id, user_id, count(*) as visits From orders
        Group by r_id, user_id
        Having count(*) > 1
    ) t
Join restaurants r on r.r_id = t.r_id
Group by t.r_id, r.r_name
Order by loyal_customers desc;



-- Month over month revenue growth of swiggy (considering all restaurants belongs to swiggy)
--Select to_char("date",'Month') as Month, sum(amount) as Revenue From orders
--Group by to_char("date",'Month')
--Order by to_char("date",'Month') desc;
Select month, revenue, round(((revenue - LAG(Revenue,1) over(Order by Revenue))/LAG(Revenue,1) over(Order by Revenue))*100, 4) as monthly_increase_revenue From (
    With sales as
    (
        Select to_char("date",'Month') as Month, sum(amount) as Revenue From orders
        Group by to_char("date",'Month')
        Order by to_char("date",'Month') desc
    )
    Select Month, Revenue, LAG(Revenue,1) over(Order by Revenue) as pervious
    From sales
) t;



-- Customers --> favorite food
With temp as 
(
    Select o.user_id, od.f_id, count(*) as frequency From orders o
    Join order_details od on o.order_id=od.order_id
    Group by o.user_id, od.f_id
    Order by o.user_id
)
Select c.user_id,c."name", f.f_id, t1.frequency, f.f_name From temp t1
Join customers c on c.user_id = t1.user_id
Join food f on f.f_id = t1.f_id
Where t1.frequency =(  Select max(frequency) From temp t2
                        Where t2.user_id=t1.user_id
                    )
Order by c.user_id;