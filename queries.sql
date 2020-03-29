-- FOR FDS Manager --

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
SELECT EXTRACT(MONTH FROM (date)) AS month, uid as Customer, COUNT(orderID) as num
FROM Place natural join Orders
GROUP BY uid, EXTRACT(MONTH FROM (date));

/** view the total cost of orders by EACH customer **/
SELECT EXTRACT(MONTH FROM (date)) AS month, uid as Customer, SUM(cost) as totalcost
FROM Orders natural join (Place natural join Customers)
GROUP BY uid, EXTRACT(MONTH FROM (date));


-- For Restaurant Staff -- (for their own restaurant)

/** view total number of completed orders for each month (excludes delivery fees)**/
SELECT FM.restaurantID, EXTRACT(MONTH FROM (date)) AS month, COUNT(O.orderid) AS num
FROM Orders O, FromMenu FM
WHERE O.orderStatus = 'Completed'
AND O.orderID = FM.orderID
GROUP BY FM.restaurantID, EXTRACT(MONTH FROM (O.date));

/** view total costs of all completed orders **/
SELECT FM.restaurantID, EXTRACT(MONTH FROM (date)) AS month,SUM(O.cost) AS totalcost
FROM Orders O, FromMenu FM
WHERE O.orderStatus = 'Completed'
AND O.orderID = FM.orderID
GROUP BY FM.restaurantID, EXTRACT(MONTH FROM (O.date));

/** view top 5 fav food items (highest number of orders) **/
With foodItemsSold as ( -- number of food sold
    SELECT sum(quantity) as num, FM.foodName, FM.restaurantID, EXTRACT(MONTH FROM (date)) AS month 
    FROM orders O natural join fromMenu FM
    WHERE O.orderStatus = 'Completed'
    GROUP BY restaurantID, foodName, EXTRACT(MONTH FROM (O.date))
    ORDER BY num DESC
)

SELECT restaurantID, month, foodName
FROM foodItemsSold
LIMIT 5;

/** view the number of orders received for each promotion **/
SELECT EXTRACT(MONTH FROM (date)) AS month, promotionID, COUNT (*) as num
FROM FromMenu natural join Orders
WHERE orderStatus = 'Completed'
GROUP BY promotionID, EXTRACT(MONTH FROM (date));

/*Add to Menu*/ 
-- requires insertion into Food as well
INSERT INTO Food (foodName, availability, price, dailyLimit, RestaurantID, category) VALUES ($1,$2,$3,$4,$5,$6)
INSERT INTO Menu (restaurantID, foodName) VALUES ($1, $2)

/*Add Promotion for Restaurant*/
INSERT INTO Promotion(promoID, startDate, endDate, discPerc, discAmt) VALUES ($1,$2,$3,$4,$5)
-- Requires insertion into FDSpromo or RestPromo -- trigger needed for ISA check

/*Update Menu*/
UPDATE Food 
SET dailyLimit = $4 
WHERE foodName = $1 
AND RestaurantID = $5;

/*Update Promotion --necessary? 
Update Promotion 
SET 
WHERE
FROM RestPromo
WHERE promoID = $1
AND */

--need to match with the Restpromo
(promoID, startDate, endDate, discPerc, discAmt)

/*Delete Menu*/
DELETE FROM Food
WHERE foodName = $1
AND restaurantID = $5;

/*Delete Promotion*/
DELETE FROM Promotion
WHERE promoID = $1
