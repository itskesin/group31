/*check availability*/
CREATE OR REPLACE FUNCTION check_availability()
RETURNS TRIGGER AS $$
DECLARE currAvailability INTEGER;
DECLARE qtyOrdered INTEGER;

BEGIN
    SELECT availability into currAvailability 
    FROM Food 
    WHERE Food.foodname = NEW.foodName
    AND Food.restaurantID = NEW.restaurantID;

    SELECT quantity into qtyOrdered
    FROM FromMenu
    WHERE FromMenu.restaurantID = NEW.restaurantID
    AND FromMenu.foodName = NEW.foodName
    AND FromMenu.orderID = NEW.orderID;

    IF qtyOrdered > currAvailability THEN
        RAISE NOTICE 'Exceed Daily Limit';
        UPDATE Orders SET orderStatus = 'Failed';
        RETURN NULL; 
    ELSE 
        UPDATE Orders SET orderStatus = 'Confirmed';
        RAISE NOTICE 'Order Confirmed';
        RETURN NEW;
    END IF;


END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER availability_trigger
BEFORE INSERT ON FromMenu
FOR EACH ROW
EXECUTE PROCEDURE check_availability();




/*check whether order placed during operational hours*/
CREATE OR REPLACE FUNCTION check_operational_hours()
RETURNS TRIGGER AS $$
DECLARE currHour NUMERIC;
DECLARE openingHour NUMERIC;
DECLARE closingHour NUMERIC;

BEGIN
    openingHour := 10; --10am
    closingHour := 22; --10pm
    
    SELECT EXTRACT(HOUR from timeOrderPlace) as currHour
    FROM Orders
    WHERE NEW.orderID = Orders.OrderID;

    IF currHour < openingHour THEN
        UPDATE Orders SET orderStatus = 'Failed'; 
        RAISE NOTICE 'Not within Opening Hours'; 
    ELSIF currHour >= closingHour THEN
        UPDATE Orders SET orderStatus = 'Failed'; 
        RAISE NOTICE 'Not within Opening Hours'; 
    ELSE 
        RAISE NOTICE 'Within Opening Hours';
    END IF;
    RETURN NULL; /* return value of row-level trigger fired AFTER is always ignored */

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER operating_trigger
AFTER INSERT ON Place
FOR EACH ROW
EXECUTE PROCEDURE check_operational_hours();




/*ISA check for delivery riders*/
CREATE OR REPLACE FUNCTION check_riders()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;

BEGIN
    IF (NEW.type = 'FullTime') THEN
        SELECT COUNT(*) INTO count 
        FROM PartTime 
        WHERE NEW.uid = PartTime.uid;
        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO FullTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Full time rider added';
            RETURN NEW;
        END IF;

    ELSIF (NEW.type = 'PartTime') THEN
        SELECT COUNT(*) INTO count 
        FROM FullTime 
        WHERE NEW.uid = FullTime.uid;

        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO PartTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Part time rider added';
            RETURN NEW;
        END IF;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER riders_trigger
AFTER INSERT ON DeliveryRiders
FOR EACH ROW
EXECUTE PROCEDURE check_riders();




/*ISA check for users*/
CREATE OR REPLACE FUNCTION check_user()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN 
	IF (NEW.type = 'Customers') THEN
		SELECT COUNT(*) INTO count 
        FROM FDSManagers, RestaurantStaff, DeliveryRiders
        WHERE NEW.uid = FDSManagers.uid
        OR NEW.uid = RestaurantStaff.uid
        OR NEW.uid = DeliveryRiders.uid;
        
		IF (count > 0) THEN 
            RETURN NULL;
		ELSE
            INSERT INTO Customers VALUES (NEW.uid,DEFAULT,DEFAULT,NULL);
			RETURN NEW;

		END IF;
	ELSIF (NEW.type = 'FDSManagers') THEN
		SELECT COUNT(*) INTO count 
        FROM Customers, RestaurantStaff, DeliveryRiders
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = RestaurantStaff.uid
        OR NEW.uid = DeliveryRiders.uid;

		IF (count > 0) THEN RETURN NULL;
		ELSE
			INSERT INTO FDSManagers VALUES (NEW.uid);
			RETURN NEW;
		
		END IF;	
    ELSIF (NEW.type = 'RestaurantStaff') THEN
        SELECT COUNT(*) INTO count 
        FROM Customers, FDSManagers, DeliveryRiders
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = FDSManagers.uid
        OR NEW.uid = DeliveryRiders.uid;

		IF (count > 0) THEN RETURN NULL;
		ELSE
			
				INSERT INTO RestaurantStaff VALUES (NEW.uid);
				RETURN NEW;
			
		END IF;	
    ELSIF (NEW.type = 'DeliveryRiders') THEN
        SELECT COUNT(*) INTO count 
        FROM Customers, FDSManagers, RestaurantStaff
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = FDSManagers.uid
        OR NEW.uid = RestaurantStaff.uid;

		IF (count > 0) THEN 
            RETURN NULL;
		ELSE
            INSERT INTO DeliveryRiders VALUES (NEW.uname,DEFAULT,FullTime); --FUllTIME?
		    RETURN NEW;
		END IF;	
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_trigger
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE PROCEDURE check_user();



/*Update reward point after order completion*/
CREATE OR REPLACE FUNCTION update_rewards()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE customerId uuid;

BEGIN 
    currStatus := NEW.orderStatus;

    SELECT uid INTO customerId
    FROM Place
    WHERE NEW.orderid = Place.orderid;

    IF currStatus = 'Completed' THEN
        UPDATE Customers 
        SET rewardPts = rewardPts + TRUNC(NEW.cost)
        WHERE customerId = Customers.uid;
    END IF;


END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reward_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE PROCEDURE update_rewards();




/*Update delivery rider bonus after order completion*/
CREATE OR REPLACE FUNCTION update_bonus()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE riderId uuid;

BEGIN
    currStatus := NEW.orderStatus;

    SELECT uid INTO riderId
    FROM Delivers
    WHERE NEW.orderid = Delivers.orderid;

    IF currStatus = 'Completed' THEN
        UPDATE MonthlyDeliveryBonus 
        SET numCompleted = numCompleted + 1
        WHERE riderId = MonthlyDeliveryBonus.uid;

        UPDATE MonthlyDeliveryBonus 
        SET deliveryBonus = deliveryBonus + 3
        WHERE riderId = MonthlyDeliveryBonus.uid;
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bonus_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE PROCEDURE update_bonus();


/*ISA check for Promotion*/
CREATE OR REPLACE FUNCTION check_promotion()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;

BEGIN
    IF (NEW.type = 'FDSpromo') THEN
        SELECT COUNT(*) INTO count 
        FROM Restpromo 
        WHERE NEW.promoID = Restpromo.promoID;
        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO FDSpromo VALUES (NEW.promoID);
            RAISE NOTICE 'FDSpromo added';
            RETURN NEW;
        END IF;

    ELSIF (NEW.type = 'Restpromo') THEN
        SELECT COUNT(*) INTO count 
        FROM FDSpromo
        WHERE NEW.promoID = FDSpromo.promoID;

        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO Restpromo VALUES (NEW.promoID, NEW.promoID);
            RAISE NOTICE 'Restpromo added';
            RETURN NEW;
        END IF;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER promo_trigger
AFTER INSERT ON Promotion
FOR EACH ROW
EXECUTE PROCEDURE check_promotion();