/** view total number of orders **/
SELECT EXTRACT(MONTH FROM (date)) AS month, COUNT(orderid) AS num
FROM Orders
GROUP BY EXTRACT(MONTH FROM (date));

/** view total cost of all orders **/
SELECT EXTRACT(MONTH FROM (date)) AS month, SUM(cost) AS totalCost
FROM Orders
GROUP BY EXTRACT(MONTH FROM (date));

/** view total number of DISTINCT ACTIVE customers **/
SELECT EXTRACT(MONTH FROM (date)) AS month, COUNT(DISTINCT uid) AS customers
FROM Place natural join Orders
GROUP BY EXTRACT(MONTH FROM (date));

/** view total number of NEW customers **/
SELECT EXTRACT(MONTH FROM (signupDate)) AS month, COUNT(DISTINCT uid) AS customers
FROM Customers
GROUP BY EXTRACT(MONTH FROM (signupDate));

/** view the total number of orders by EACH customer **/
SELECT uid as Customer, COUNT(orderID) as num
FROM Place natural join Orders
GROUP BY uid, EXTRACT(MONTH FROM (date));

/** view the total cost of orders by each customer **/
SELECT uid as Customer, SUM(cost) as totalcost
FROM Orders natural join (Place natural join Customers)
GROUP BY uid, EXTRACT(MONTH FROM (date));

