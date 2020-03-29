CREATE EXTENSION "pgcrypto";
CREATE EXTENSION "btree_gist";

DROP TABLE IF EXISTS Promotion CASCADE;
DROP TABLE IF EXISTS FDSpromo CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Restpromo CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Food CASCADE;
DROP TABLE IF EXISTS Menu CASCADE;
DROP TABLE IF EXISTS PaymentOption CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS FromMenu CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS FDSManagers CASCADE;
DROP TABLE IF EXISTS RestaurantStaff CASCADE;
DROP TABLE IF EXISTS Place CASCADE;
DROP TABLE IF EXISTS DeliveryRiders CASCADE;
DROP TABLE IF EXISTS PartTime CASCADE;
DROP TABLE IF EXISTS FullTime CASCADE;
DROP TABLE IF EXISTS WorkingDays CASCADE;
DROP TABLE IF EXISTS ShiftOptions CASCADE;
DROP TABLE IF EXISTS WorkingWeeks CASCADE;
DROP TABLE IF EXISTS MonthlyDeliveryBonus CASCADE;
DROP TABLE IF EXISTS Delivers CASCADE; 

CREATE TABLE Restaurants ( 
	restaurantID    uuid DEFAULT gen_random_uuid(),
	name            VARCHAR(100)         NOT NULL,
	location        VARCHAR(255)         NOT NUll,
	minThreshold    INTEGER DEFAULT '0'  NOT NULL,
	PRIMARY KEY (RestaurantID)
);

CREATE TABLE Promotion ( --
    promoID     uuid  DEFAULT gen_random_uuid(),
	restaurantID uuid,
    startDate   DATE NOT NULL,
    endDate     DATE NOT NULL,
    discPerc    NUMERIC check(discPerc > 0),
    discAmt     NUMERIC check(discAmt > 0),
	type    	VARCHAR(255)  NOT NULL CHECK (type in ('FDSpromo', 'Restpromo')),
	PRIMARY KEY (promoID),
	FOREIGN KEY (restaurantID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);

CREATE TABLE FDSpromo (
    promoID     uuid,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE
);

CREATE TABLE Restpromo (
    promoID     uuid, 
    restID      uuid NOT NULL,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
    FOREIGN KEY (restID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);

CREATE TABLE Categories (
	category    VARCHAR(100),
	PRIMARY KEY (category)
);

CREATE TABLE Food (
	foodName        VARCHAR(100)         NOT NULL,
	availability    INTEGER              NOT NULL,
	price           NUMERIC              NOT NULL CHECK (price > 0),
	dailyLimit      INTEGER DEFAULT '50' NOT NULL,
	RestaurantID    uuid,
	category        VARCHAR(255)		 NOT NULL,
	PRIMARY KEY (RestaurantID, foodName),
	FOREIGN KEY (RestaurantID) REFERENCES Restaurants (RestaurantID) ON DELETE CASCADE,
	FOREIGN KEY	(category) REFERENCES Categories (category)
);

CREATE TABLE Menu (
	restaurantID    uuid        	NOT NULL,
	foodName        VARCHAR(100)    NOT NULL,
	Unique (restaurantID, foodName),
	FOREIGN KEY	(restaurantID) REFERENCES Restaurants (restaurantID) ON DELETE CASCADE,
	FOREIGN KEY	(restaurantID, foodName) REFERENCES Food (restaurantID,foodname) ON DELETE CASCADE
);

CREATE TABLE PaymentOption (
    payOption   VARCHAR(100),
    PRIMARY KEY (payOption)
);

CREATE TABLE Orders ( --
	orderID             uuid DEFAULT gen_random_uuid() 	  NOT NULL,
	deliveryFee         INTEGER                           NOT NULL,
	cost                INTEGER                           NOT NULL,
	location            VARCHAR(255)                      NOT NULL,
	date                DATE DEFAULT CURRENT_DATE         NOT NULL,
	payOption	    	VARCHAR(50)			    		  NOT NULL,
	orderStatus         VARCHAR(50) DEFAULT 'Pending'     NOT NULL CHECK (orderStatus in ('Pending','Confirmed','Completed','Failed')),
	deliveryDuration    INTEGER     					  NOT NULL,
	timeOrderPlace      TIME DEFAULT CURRENT_TIME,
	timeDepartToRest    TIME,
	timeArriveRest      TIME,
	timeDepartFromRest  TIME,
	timeOrderDelivered  TIME,
	PRIMARY KEY (orderID),
	FOREIGN KEY (payOption) REFERENCES PaymentOption (payOption)
);

CREATE TABLE FromMenu (
	promotionID     uuid,
	quantity        INTEGER         NOT NULL,
	orderID         uuid         NOT NULL,
	restaurantID    uuid         NOT NULL,
	foodName        VARCHAR(100)    NOT NULL,
	PRIMARY KEY (restaurantID,foodName,orderID),
	FOREIGN KEY (promotionID) REFERENCES Restpromo (promoID),
	FOREIGN KEY (orderID) REFERENCES Orders (orderID),
	FOREIGN KEY (restaurantID, foodName) REFERENCES Menu (restaurantID, foodName) ON DELETE CASCADE
);

CREATE TABLE Users (
	uid         uuid DEFAULT gen_random_uuid(),
	name        VARCHAR(255)     NOT NULL,
	username    VARCHAR(255)     NOT NULL,
	password    VARCHAR(255)     NOT NULL,
	type    VARCHAR(255)  NOT NULL CHECK (type in ('Customers', 'FDSManagers', 'RestaurantStaff', 'DeliveryRiders')),
	PRIMARY KEY (uid)
);

CREATE TABLE Customers (
	uid         uuid,
	rewardPts   INTEGER DEFAULT '0' NOT NULL,
	signUpDate  DATE    DEFAULT CURRENT_DATE NOT NULL,
	cardDetails VARCHAR(255),
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE
);

CREATE TABLE FDSManagers (
	uid         uuid,
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE
);

CREATE TABLE RestaurantStaff ( --not able to tell which restaurant this staff belongs to
	uid         uuid,
	restaurantID uuid, --
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE,
	FOREIGN KEY (restaurantID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);


CREATE TABLE Place (
	uid            uuid,
	orderid        uuid,  
	review         VARCHAR(255)     NOT NULL,
	star           INTEGER      DEFAULT NULL CHECK (star >= 0 AND star <= 5), 
	promoid        uuid,
	PRIMARY KEY (orderid),
	FOREIGN KEY (uid) REFERENCES Customers ON DELETE CASCADE,
	FOREIGN KEY (promoID) REFERENCES FDSpromo(promoID) ON DELETE CASCADE,
	FOREIGN KEY (orderid) REFERENCES Orders ON DELETE CASCADE
);

CREATE TABLE DeliveryRiders ( --includes salary field here?
    uid             uuid PRIMARY KEY,
	baseDeliveryFee NUMERIC NOT NULL DEFAULT 0, 
	type    VARCHAR(255)  NOT NULL CHECK (type in ('FullTime', 'PartTime')),
    FOREIGN KEY (uid) REFERENCES Users(uid) ON DELETE CASCADE
);

CREATE TABLE PartTime (
	uid             uuid PRIMARY KEY,
	weeklyBasePay   NUMERIC NOT NULL DEFAULT 100, /* $10 times minimum 10 hours in each WWS*/
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE FullTime (
	uid              uuid PRIMARY KEY,
	monthlyBasePay   INTEGER NOT NULL DEFAULT 1800,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE  WorkingDays (
	uid             uuid,
	workDate        DATE NOT NULL,
	intervalStart   TIME NOT NULL,
	intervalEnd     TIME NOT NULL,
	PRIMARY KEY (uid, workDate, intervalStart, intervalEnd),
	FOREIGN KEY (uid) REFERENCES PartTime(uid) ON DELETE CASCADE
);

CREATE TABLE ShiftOptions (
	shiftID         INTEGER, 
	shiftDetails    VARCHAR(30) NOT NULL,
	PRIMARY KEY (shiftID)
);

CREATE TABLE  WorkingWeeks (
	uid             uuid,
	workDate        DATE NOT NULL,
	shiftID         INTEGER NOT NULL,
	PRIMARY KEY (uid, workDate),
	FOREIGN KEY (uid) REFERENCES FullTime ON DELETE CASCADE,
	FOREIGN KEY (shiftID) REFERENCES ShiftOptions(shiftID)
);

/*MonthlyDeliveryBonus. monthYear will have bogus date*/
CREATE TABLE MonthlyDeliveryBonus (
	uid            	uuid,
	monthYear       DATE NOT NULL,
	numCompleted    INTEGER NOT NULL default 0,
	deliveryBonus   NUMERIC NOT NULL default 0,
	PRIMARY KEY (uid, monthYear),
	FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
); 

CREATE TABLE Delivers (
    orderID         uuid,
    uid             uuid,
    rating          INTEGER      DEFAULT NULL CHECK (rating >= 0 AND rating <= 5), 
    PRIMARY KEY (orderID,uid),
    FOREIGN KEY (orderID) REFERENCES Orders(orderID) ON DELETE CASCADE,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);