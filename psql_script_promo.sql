DROP TABLE IF EXISTS Promotion CASCADE;
DROP TABLE IF EXISTS Restpromo CASCADE;
DROP TABLE IF EXISTS FDSpromo CASCADE;


-- Should discount be numeric?
CREATE TABLE Promotion {
    promoID     INTEGER PRIMARY KEY,
    startDate   DATE NOT NULL,
    endDate     DATE NOT NULL,
    discount    NUMERIC check(discount > 0)
};


-- have to link to restaurant on Nyan's side
-- Has table integrated
CREATE TABLE Restpromo{
    promoID     INTEGER, 
    restID      INTEGER NOT NULL,
    PRIMARY KEY (promoID,restID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
    FOREIGN KEY (restID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
};

--
CREATE TABLE FDSpromo{
    promoID     INTEGER,
    PRIMARY KEY promoID,
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
};

--Does not enforce covering and non-overlapping, to be done under trigger?

