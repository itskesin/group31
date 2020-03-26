/** view total number of orders **/
SELECT EXTRACT(MONTH FROM (date)) AS month, COUNT(orderid) AS num
FROM Orders
GROUP BY EXTRACT(MONTH FROM (date));

/** view total cost of all orders **/
SELECT EXTRACT(MONTH FROM (date)) AS month, SUM(cost) AS totalCost
FROM Orders
GROUP BY EXTRACT(MONTH FROM (date));

/** view total number of ACTIVE customers **/
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


--insert user, check user type 
CREATE OR REPLACE FUNCTION userType()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN 
	IF (NEW.type = 'Customers') THEN
		SELECT COUNT(*) INTO count FROM Customers WHERE NEW.uid = Customers.uid;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO Customers VALUES (NEW.uid,DEFAULT,DEFAULT,NULL);
				RETURN NEW;
			END;
		END IF;
	ELSIF (NEW.type = 'FDSManagers') THEN
		SELECT COUNT(*) INTO count FROM FDSManagers WHERE NEW.uid = FDSManagers.uid;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO Diners VALUES (NEW.uid);
				RETURN NEW;
			END;
		END IF;	
    ELSIF (NEW.type = 'RestaurantStaff') THEN
        SELECT COUNT(*) INTO count FROM RestaurantStaff WHERE NEW.uid = RestaurantStaff.uid;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO RestaurantStaff VALUES (NEW.uid);
				RETURN NEW;
			END;
		END IF;	
    ELSIF (NEW.type = 'DeliveryRiders') THEN
        SELECT COUNT(*) INTO count FROM DeliveryRiders WHERE NEW.uid = DeliveryRiders.uid;
		IF (count > 0) THEN RETURN NULL;
		ELSE
			BEGIN
				INSERT INTO DeliveryRiders VALUES (NEW.uname,0);
				RETURN NEW;
			END;
		END IF;	
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_type
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE PROCEDURE userType();