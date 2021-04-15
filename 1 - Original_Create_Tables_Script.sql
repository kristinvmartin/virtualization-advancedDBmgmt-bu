/*
RUN THIS FIRST: This script should be before any others.

Below is data that creates the database tables and their constraints.

*/

--drop all tables to facilitate re-running script

DROP TABLE IF EXISTS Attends;
DROP TABLE IF EXISTS Teenager;
DROP TABLE IF EXISTS Child;
DROP TABLE IF EXISTS Guardian;
DROP TABLE IF EXISTS HistoricalStatus;
DROP TABLE IF EXISTS Churchgoer;
DROP TABLE IF EXISTS Churchgoer_status;
DROP TABLE IF EXISTS Recurring;
DROP TABLE IF EXISTS Non_recurring;
DROP TABLE IF EXISTS Church_event;
DROP TABLE IF EXISTS Event_location;
DROP TABLE IF EXISTS Donation;
DROP TABLE IF EXISTS Family;
DROP TABLE IF EXISTS Ministry;
DROP TABLE IF EXISTS Ministry_info;
DROP TABLE IF EXISTS Church;
DROP TABLE IF EXISTS States;


--create tables, establish primary keys

CREATE TABLE Church (
church_id DECIMAL(12) IDENTITY(100,1) NOT NULL PRIMARY KEY,
church_name VARCHAR(100) NOT NULL,
tax_id VARCHAR(50) NOT NULL,
church_address VARCHAR(255) NOT NULL,
church_city VARCHAR(50) NOT NULL,
state_id DECIMAL(6) NOT NULL,
church_zip VARCHAR(10) NOT NULL,
mission_stmt VARCHAR(1024),
church_login VARCHAR(20) NOT NULL,
church_pw VARCHAR(20) NOT NULL
);

CREATE TABLE Ministry_info (
info_id DECIMAL(12) IDENTITY(200,1) NOT NULL PRIMARY KEY,
ministry_name VARCHAR(100) NOT NULL,
ministry_desc VARCHAR(255),
is_default CHAR(1) NOT NULL
);

CREATE TABLE Ministry (
ministry_id DECIMAL(12) IDENTITY(250,1) NOT NULL PRIMARY KEY,
church_id DECIMAL(12) NOT NULL,
info_id DECIMAL(12) NOT NULL
);

CREATE TABLE Donation (
donation_id DECIMAL(12) IDENTITY(300,1) NOT NULL PRIMARY KEY,
ministry_id DECIMAL(12) NOT NULL,
family_id DECIMAL(12) NOT NULL,
donation_date DATE NOT NULL,
donation_amt DECIMAL(12,2) NOT NULL
);

CREATE TABLE Church_event (
event_id DECIMAL(12) IDENTITY(400,1) NOT NULL PRIMARY KEY,
ministry_id DECIMAL(12) NOT NULL,
location_id DECIMAL(12) NOT NULL,
event_name VARCHAR(100) NOT NULL,
event_desc VARCHAR(1024),
event_type CHAR(1) NOT NULL,
event_date DATE NOT NULL
);

CREATE TABLE Recurring (
event_id DECIMAL(12) NOT NULL PRIMARY KEY,
recurrence_weeks SMALLINT
);

CREATE TABLE Non_recurring (
event_id DECIMAL(12) NOT NULL PRIMARY KEY
);

CREATE TABLE Event_location (
location_id DECIMAL(12) IDENTITY(500,1) NOT NULL PRIMARY KEY,
location_name VARCHAR(100) NOT NULL,
location_desc VARCHAR(1024)
);

CREATE TABLE Family (
family_id DECIMAL(12) IDENTITY(600,1) NOT NULL PRIMARY KEY,
church_id DECIMAL(12) NOT NULL,
family_salutation VARCHAR(50) NOT NULL,
home_phone DECIMAL(10),
family_address VARCHAR(255),
family_city VARCHAR(50),
state_id DECIMAL(6),
family_zip VARCHAR(10),
attending_since DATE NOT NULL
);

CREATE TABLE Churchgoer (
churchgoer_id DECIMAL(12) IDENTITY(700,1) NOT NULL PRIMARY KEY,
family_id DECIMAL(12) NOT NULL,
status_code DECIMAL(12) NOT NULL,
first_name VARCHAR(100) NOT NULL,
last_name VARCHAR(100) NOT NULL,
cell_phone DECIMAL(10),
secondary_phone DECIMAL(10),
email VARCHAR(255),
date_of_birth DATE,
churchgoer_type CHAR(1),
churchgoer_login VARCHAR(20) NULL,
churchgoer_pw VARCHAR(20) NULL
);

CREATE TABLE Guardian (
guardian_id DECIMAL(12) NOT NULL,
churchgoer_id DECIMAL(12) NOT NULL,
PRIMARY KEY (guardian_id, churchgoer_id)
);

CREATE TABLE Child (
churchgoer_id DECIMAL(12) NOT NULL PRIMARY KEY,
allergy_info VARCHAR(1024)
);

CREATE TABLE Teenager (
churchgoer_id DECIMAL(12) NOT NULL PRIMARY KEY
);

CREATE TABLE Churchgoer_status (
status_code DECIMAL(12) IDENTITY(800,1) NOT NULL PRIMARY KEY,
status_name VARCHAR(100) NOT NULL,
status_desc VARCHAR(255)
);

CREATE TABLE Attends (
event_id DECIMAL(12) NOT NULL,
churchgoer_id DECIMAL(12) NOT NULL,
is_organizer CHAR(1),
is_checked_in CHAR(1),
PRIMARY KEY (event_id, churchgoer_id)
);

CREATE TABLE States (
state_id DECIMAL(6) NOT NULL PRIMARY KEY,
state_postal_code VARCHAR(40) NOT NULL
);

CREATE TABLE HistoricalStatus (
historical_status_id DECIMAL(12) IDENTITY(900,1) NOT NULL PRIMARY KEY,
churchgoer_id DECIMAL(12) NOT NULL,
old_status_code DECIMAL(12) NOT NULL,
new_status_code DECIMAL(12) NOT NULL,
date_of_change DATE NOT NULL
);


--insert foreign keys

ALTER TABLE Church
ADD CONSTRAINT state_church_fk FOREIGN KEY (state_id)
REFERENCES States(state_id);

ALTER TABLE Ministry
ADD CONSTRAINT church_min_fk FOREIGN KEY (church_id)
REFERENCES Church(church_id);

ALTER TABLE Ministry
ADD CONSTRAINT min_info_fk FOREIGN KEY (info_id)
REFERENCES Ministry_info(info_id);

ALTER TABLE Church_event
ADD CONSTRAINT min_event_fk FOREIGN KEY (ministry_id)
REFERENCES Ministry(ministry_id);

ALTER TABLE Church_event
ADD CONSTRAINT location_fk
FOREIGN KEY (location_id) REFERENCES Event_location(location_id);

ALTER TABLE Family
ADD CONSTRAINT church_fam_fk FOREIGN KEY (church_id)
REFERENCES Church(church_id);

ALTER TABLE Family
ADD CONSTRAINT church_state_fk FOREIGN KEY (state_id)
REFERENCES States(state_id);

ALTER TABLE Churchgoer
ADD CONSTRAINT family_fk FOREIGN KEY (family_id)
REFERENCES Family(family_id);

ALTER TABLE Churchgoer
ADD CONSTRAINT status_code_fk FOREIGN KEY (status_code)
REFERENCES Churchgoer_status(status_code);

ALTER TABLE Donation
ADD CONSTRAINT min_donation_fk FOREIGN KEY (ministry_id)
REFERENCES Ministry(ministry_id);

ALTER TABLE Donation
ADD CONSTRAINT fam_donation_fk FOREIGN KEY (family_id)
REFERENCES Family(family_id);

ALTER TABLE Recurring
ADD CONSTRAINT recur_fk FOREIGN KEY (event_id)
REFERENCES Church_event(event_id);

ALTER TABLE Non_recurring
ADD CONSTRAINT non_recur_fk FOREIGN KEY (event_id)
REFERENCES Church_event(event_id);

ALTER TABLE Guardian
ADD CONSTRAINT guardian_fk FOREIGN KEY (guardian_id)
REFERENCES Churchgoer(churchgoer_id);

ALTER TABLE Guardian
ADD CONSTRAINT child_guardian_fk FOREIGN KEY (churchgoer_id)
REFERENCES Churchgoer(churchgoer_id);

ALTER TABLE Child
ADD CONSTRAINT child_subtype_fk FOREIGN KEY (churchgoer_id)
REFERENCES Churchgoer(churchgoer_id);

ALTER TABLE Teenager
ADD CONSTRAINT teen_subtype_fk FOREIGN KEY (churchgoer_id)
REFERENCES Churchgoer(churchgoer_id);

ALTER TABLE Attends
ADD CONSTRAINT event_attends_fk FOREIGN KEY (event_id)
REFERENCES Church_event(event_id);

ALTER TABLE Attends
ADD CONSTRAINT churchgoer_attends_fk FOREIGN KEY (churchgoer_id)
REFERENCES Churchgoer(churchgoer_id);

ALTER TABLE HistoricalStatus
ADD CONSTRAINT historical_churchgoer_fk FOREIGN KEY (churchgoer_id)
REFERENCES Churchgoer(churchgoer_id);

