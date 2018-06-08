CREATE TABLE RESERVATIONS(
  RESERVATION_ID int NOT NULL PRIMARY KEY,
  DATE_BEGIN date NOT NULL,
  DATE_END date NOT NULL,
  APARTMENT_ID int,
  USER_ID int,
  STATUS int
);

CREATE TABLE PAYMENTS(
  PAYMENT_ID int NOT NULL PRIMARY KEY,
  RESERVATION_ID int,
  TYPE VARCHAR2(16) CHECK(TYPE IN ('advance', 'final')),
  VALUE int,
  STATUS VARCHAR2(16) CHECK(STATUS IN ('started', 'completed',
 	'canceled', 'refunded'))
);

CREATE TABLE LOCATIONS(
  LOCATION_ID int NOT NULL PRIMARY KEY,
  COUNTRY_NAME VARCHAR2(128),
  CITY VARCHAR2(128),
  LONGITUDE VARCHAR2(64),
  LATITUDE VARCHAR2(64),
  STREET VARCHAR2(128),
  STREET2 VARCHAR2(128),
  APARTMENT_NUMBER int,
  ZIP_CODE int
);

CREATE TABLE AGENCIES(
  AGENCY_ID INT NOT NULL PRIMARY KEY,
  LOCATION_ID INT,
  NAME VARCHAR2(64),
  INFO VARCHAR2(2048),
  PHONE VARCHAR2(32),
  WEB VARCHAR2(64)
);

CREATE TABLE USERS(
  USER_ID INT NOT NULL PRIMARY KEY,
  TYPE VARCHAR2(6) CHECK(TYPE IN('owner','agency','client')) NOT NULL,
  EMAIL VARCHAR2(128),
  PASSWORD VARCHAR(128) NOT NULL,
  INFO VARCHAR2(2048),
  PHONE VARCHAR2(32),
  NAME VARCHAR2(64),
  LAST_NAME VARCHAR2(64),
  LOCATION_ID INT
);

CREATE TABLE APARTMENTS(
    APARTMENT_ID int NOT NULL PRIMARY KEY,
    COST_PER_NIGHT int,
    BED_COUNT int,
    LOCATION_ID int NOT NULL,
    AGENCY_ID int,
    AIR_COND number CHECK(AIR_COND IN (1,0)),
    STANDARD number CHECK(STANDARD IN (1,2,3,4,5)),
    OWNER_ID int
);

ALTER TABLE RESERVATIONS
ADD CONSTRAINT FK_APARTMENTS
FOREIGN KEY (APARTMENT_ID)
  REFERENCES APARTMENTS(APARTMENT_ID);

ALTER TABLE PAYMENTS
ADD CONSTRAINT FK_RESERVATIONS
FOREIGN KEY (RESERVATION_ID)
  REFERENCES RESERVATIONS(RESERVATION_ID);

ALTER TABLE RESERVATIONS
ADD CONSTRAINT FK_USERS
FOREIGN KEY (USER_ID)
  REFERENCES USERS(USER_ID);

ALTER TABLE APARTMENTS
ADD CONSTRAINT FK_AGENCIES
FOREIGN KEY (AGENCY_ID)
  REFERENCES AGENCIES(AGENCY_ID);

ALTER TABLE APARTMENTS
ADD CONSTRAINT FK_LOCATIONS
FOREIGN KEY (LOCATION_ID)
  REFERENCES LOCATIONS(LOCATION_ID);

ALTER TABLE AGENCIES
ADD CONSTRAINT FK_LOCATIONS_AGENCIES
FOREIGN KEY (LOCATION_ID)
  REFERENCES LOCATIONS(LOCATION_ID);

ALTER TABLE APARTMENTS
ADD CONSTRAINT FK_USERS_APARTMENTS
FOREIGN KEY (OWNER_ID)
  REFERENCES USERS(USER_ID);

ALTER TABLE USERS
ADD CONSTRAINT FK_LOCATIONS_USERS
FOREIGN KEY (LOCATION_ID)
  REFERENCES LOCATIONS(LOCATION_ID);


