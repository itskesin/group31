DROP TABLE IF EXISTS Restaurant CASCADE;
DROP TABLE IF EXISTS Food CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Menu CASCADE;
DROP TABLE IF EXISTS FromMenu CASCADE;
DROP TABLE IF EXISTS Order CASCADE;


CREATE TABLE Restaurants (
restaurantID    INTEGER,
name            VARCHAR(100)         NOT NULL,
location        VARCHAR(255)         NOT NUll,
minThreshold    INTEGER DEFAULT '0'  NOT NULL,
PRIMARY KEY (RestaurantID)
);

CREATE TABLE Food(
foodName        VARCHAR(100)         NOT NULL,
availability    BOOLEAN              NOT NULL,
price           INTEGER              NOT NULL,
dailyLimit      INTEGER DEFAULT '50' NOT NULL,
RestaurantID    INTEGER,
PRIMARY KEY (RestaurantID, foodName),
FOREIGN KEY (RestaurantID) REFERENCES Restaurants (RestaurantID) ON DELETE CASCADE
);

CREATE TABLE Categories (
category    VARCHAR(100),
PRIMARY KEY (category)
);

CREATE TABLE Menu (
restaurantID    INTEGER         NOT NULL,
foodName        VARCHAR(100)    NOT NULL,
PRIMARY KEY (restaurantID,foodName)
);

CREATE TABLE Order (
orderID             INTEGER                         NOT NULL,
deliveryFee         INTEGER                         NOT NULL,
cost                INTEGER                         NOT NULL,
location            VARCHAR(255)                    NOT NULL,
date                DATE                            NOT NULL,
orderStatus         VARCHAR(50) DEFAULT 'Pending'   NOT NULL CHECK (orderStatus in ('Pending','Confirmed','Completed')),
deliveryDuration    INTEGER         NOT NULL,
timeOrderPlace      TIME,
timeDepartToRest    TIME,
timeArriveRest      TIME,
timeDepartFromRest  TIME,
timeOrderDelivered  TIME,
restaurantID        INTEGER         NOT NULL,
foodName            VARCHAR(100)    NOT NULL,
quantity            INTEGER
promotionID         INTEGER,

PRIMARY KEY (orderID),
FOREIGN KEY (restaurantID,foodName,promotionID,quantity) REFERENCES FromMenu (restaurantID,foodName,promotionID,quantity) ON DELETE CASCADE
);

CREATE TABLE FromMenu (
promotionID     INTEGER,
quantity        INTEGER         NOT NULL,
orderID         INTEGER         NOT NULL,
restaurantID    INTEGER         NOT NULL,
foodName        VARCHAR(100)    NOT NULL,
PRIMARY KEY (restaurantID,foodName),
FOREIGN KEY (promotionID) REFERENCES Restpromo (promoID),
FOREIGN KEY (restaurantID, foodName) REFERENCES Menu (restaurantID, foodName) ON DELETE CASCADE
);
