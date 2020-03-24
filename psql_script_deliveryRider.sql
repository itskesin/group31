DROP TABLE IF EXISTS DeliveryRiders CASCADE;
DROP TABLE IF EXISTS PartTime CASCADE;
DROP TABLE IF EXISTS FullTime CASCADE;
DROP TABLE IF EXISTS WorkingDays CASCADE;
DROP TABLE IF EXISTS ShiftOptions CASCADE;
DROP TABLE IF EXISTS WorkingWeeks CASCADE;
DROP TABLE IF EXISTS MonthlyDeliveryBonus CASCADE;

/*Delivery Riders*/
CREATE TABLE DeliveryRiders (
    uid integer primary key references Users on delete cascade,
	baseDeliveryFee integer NOT NULL
);


/*PartTime*/
Create Table PartTime (
	uid integer primary key references DeliveryRiders on delete cascade,
	weeklyBasePay integer NOT NULL
);

/*FullTime*/
Create Table FullTime (
	uid  integer primary key references DeliveryRiders on delete cascade,
	monthlyBasePay integer NOT NULL
);

/*WorkingDays - Used date and time datatypes without timezone*/
Create Table  WorkingDays(
	uid  integer,
	workDate date NOT NULL,
	intervalStart time NOT NULL,
	intervalEnd time NOT NULL,
	primary key (uid),
	foreign key (uid) references PartTime on delete cascade
);

/*ShiftOptions*/
Create Table ShiftOptions (
	shiftID integer,
	shiftDetails varchar(30) NOT NULL,
	primary key (shiftID)
);

/*WorkingWeeks*/
Create Table  WorkingWeeks (
	uid  integer,
	workDate date NOT NULL,
	shiftID  integer NOT NULL,
	primary key (uid),
	foreign key (uid) references FullTime on delete cascade,
	foreign key (shiftID) references ShiftOptions
);


/*MonthlyDeliveryBonus. monthYear will have bogus date*/
Create Table MonthlyDeliveryBonus (
	uid integer,
	monthYear date NOT NULL,
	numCompleted integer NOT NULL default 0,
	deliveryBonus integer NOT NULL default 0,
	primary key (uid),
	foreign key (uid) references DeliveryRiders on delete cascade
);
