/*
RUN THIS THIRD: This script should be run after the Default_Data_Script

Below are creations of stored procedures and triggers useful to the database
and their implementation with the use of transactions.
*/

--drop procedures/triggers to facilitate rerunning of script
DROP PROCEDURE IF EXISTS AddChurch;
DROP PROCEDURE IF EXISTS AddDefaultMinistries;
DROP PROCEDURE IF EXISTS AddCustomMinistries;
DROP PROCEDURE IF EXISTS AddFamily;
DROP PROCEDURE IF EXISTS AddChurchgoer;
DROP PROCEDURE IF EXISTS AddGuardian;
DROP PROCEDURE IF EXISTS LogDonation;
DROP PROCEDURE IF EXISTS FamilyLeavesChurch;
DROP PROCEDURE IF EXISTS AddEvent;
DROP PROCEDURE IF EXISTS AttendEvent;
DROP PROCEDURE IF EXISTS ChangeStatus;
DROP PROCEDURE IF EXISTS CheckIn;
DROP TRIGGER IF EXISTS ChildSubtypeCreate;
DROP TRIGGER IF EXISTS ChildSubtypeUpdate;
DROP TRIGGER IF EXISTS TeenSubtypeCreate;
DROP TRIGGER IF EXISTS TeenSubtypeUpdate;
DROP TRIGGER IF EXISTS NoNegativeDonations;
DROP TRIGGER IF EXISTS HistoricalStatusEntryTrig;
GO

--stored procedure to add new church
CREATE PROCEDURE AddChurch @church_name VARCHAR(100), @tax_id VARCHAR(50),
	@church_address VARCHAR(255), @church_city VARCHAR(50), @state_id DECIMAL(6), @church_zip VARCHAR(10),
	@mission_stmt VARCHAR(1024), @church_login VARCHAR(20), @church_pw VARCHAR(20)
AS
BEGIN
--insert church information
	INSERT INTO Church(church_name, tax_id, church_address, church_city, state_id,
		church_zip, mission_stmt, church_login, church_pw)
	VALUES(@church_name, @tax_id, @church_address, @church_city, @state_id,
		@church_zip, @mission_stmt, @church_login, @church_pw);
END;
GO

--stored procedure to add selected pre-loaded ministries after adding an account
CREATE PROCEDURE AddDefaultMinistries @church_id DECIMAL(12), @default_ministry DECIMAL(12)
AS
BEGIN
	INSERT INTO Ministry (church_id, info_id)
		VALUES(	(SELECT church_id
					FROM Church
					WHERE church_id = @church_id),
				(SELECT info_id
					FROM Ministry_info
					WHERE info_id = @default_ministry));
END;
GO

--stored procedure to add custom ministries
CREATE PROCEDURE AddCustomMinistries @church_id DECIMAL(12), @ministry_name VARCHAR(100), @ministry_desc VARCHAR(255)
AS
BEGIN
	--insert new ministry into Ministry_info, set as not default
	INSERT INTO Ministry_info (ministry_name, ministry_desc, is_default)
		VALUES(@ministry_name, @ministry_desc, 'N');

	--insert into Ministry
	INSERT INTO Ministry (church_id, info_id)
		VALUES(	(SELECT church_id
					FROM Church
					WHERE church_id = @church_id),
				(SELECT info_id
					FROM Ministry_info
					WHERE @ministry_name = ministry_name));
END;
GO

--stored procedure to create family
CREATE PROCEDURE AddFamily @church_id DECIMAL(12), @family_salutation VARCHAR(50), @home_phone DECIMAL(10), @family_address VARCHAR(255),
		@family_city VARCHAR(50), @state_id DECIMAL(6), @family_zip VARCHAR(10), @attending_since DATE
AS
BEGIN
INSERT INTO Family (church_id, family_salutation, home_phone, family_address, family_city, state_id, family_zip, attending_since)
	VALUES(@church_id, @family_salutation, @home_phone, @family_address, @family_city, @state_id, @family_zip, @attending_since);
END;
GO

--stored procedure to create churchgoer
CREATE PROCEDURE AddChurchgoer @family_id DECIMAL(12), @status_code DECIMAL(12), @first_name VARCHAR(100), @last_name VARCHAR(100),
		@cell_phone DECIMAL(10), @secondary_phone DECIMAL(10), @email VARCHAR(255), @date_of_birth DATE, @churchgoer_type CHAR(1),
		@churchgoer_login VARCHAR(20), @churchgoer_pw VARCHAR(20)
AS
BEGIN
INSERT INTO Churchgoer (family_id, status_code, first_name, last_name, cell_phone, secondary_phone, email, date_of_birth, churchgoer_type, churchgoer_login, churchgoer_pw)
	VALUES(@family_id, @status_code, @first_name, @last_name, @cell_phone, @secondary_phone, @email, @date_of_birth, @churchgoer_type, @churchgoer_login, @churchgoer_pw);

END;
GO

--trigger to populate into Child Subtype
CREATE OR ALTER TRIGGER ChildSubTypeCreate
ON Churchgoer
AFTER INSERT
AS
BEGIN
IF (SELECT churchgoer_type FROM Inserted) = 'C'
	BEGIN
	INSERT INTO Child(churchgoer_id)
		SELECT churchgoer_id
		FROM Inserted
		WHERE churchgoer_id NOT IN(SELECT churchgoer_id FROM Child)
	END;
END;
GO

--trigger to check for update on child subtype
CREATE OR ALTER TRIGGER ChildSubtypeUpdate
ON Churchgoer
AFTER UPDATE
AS
BEGIN
	IF UPDATE(churchgoer_type)
	BEGIN
		INSERT INTO Child(churchgoer_id)
			SELECT i.churchgoer_id
			FROM Inserted i
			JOIN Deleted d ON i.churchgoer_id = d.churchgoer_id
			WHERE i.churchgoer_id NOT IN(SELECT churchgoer_id FROM Child) AND i.churchgoer_type = 'C';
	END;
END;
GO

--trigger to populate teen subtype
CREATE OR ALTER TRIGGER TeenSubTypeCreate
ON Churchgoer
AFTER INSERT
AS
BEGIN
IF (SELECT churchgoer_type FROM Inserted) = 'T'
	BEGIN
	INSERT INTO Teenager(churchgoer_id)
		SELECT churchgoer_id
		FROM Inserted
		WHERE churchgoer_id NOT IN(SELECT churchgoer_id FROM Teenager)
	END;
END;
GO

--trigger to check for update on teen subtype
CREATE OR ALTER TRIGGER TeenSubtypeUpdate
ON Churchgoer
AFTER UPDATE
AS
BEGIN
	IF UPDATE(churchgoer_type)
	BEGIN
		INSERT INTO Teenager(churchgoer_id)
			SELECT i.churchgoer_id
			FROM Inserted i
			JOIN Deleted d ON i.churchgoer_id = d.churchgoer_id
			WHERE i.churchgoer_id NOT IN(SELECT churchgoer_id FROM Teenager) AND i.churchgoer_type = 'T';
	END;
END;
GO

--procedure to add guardian.  Will use application logic to require entry for churchgoer_type C
CREATE PROCEDURE AddGuardian @child_id DECIMAL(12), @guardian_id DECIMAL(12)
AS
BEGIN
INSERT INTO Guardian (churchgoer_id, guardian_id)
	VALUES (@child_id, @guardian_id)
END;
GO 

--stored procedure to log donations
CREATE PROCEDURE LogDonation @ministry_id DECIMAL(12), @family_id DECIMAL(12), @donation_date DATE, @donation_amt DECIMAL(12,2)
AS
BEGIN
INSERT INTO Donation (ministry_id, family_id, donation_date, donation_amt)
	VALUES(@ministry_id, @family_id, @donation_date, @donation_amt)
END;
GO

--trigger disallows negative amounts in transactions
CREATE TRIGGER NoNegativeDonations
ON Donation
AFTER INSERT,UPDATE
AS
BEGIN
	DECLARE @donation_amt DECIMAL(12,2);
	SET @donation_amt = (SELECT INSERTED.donation_amt FROM INSERTED);
	IF @donation_amt < 0
	BEGIN
		ROLLBACK
		RAISERROR('Donations cannot be logged as negative values.',14,1);
	END;
END;
GO

--stored procedure to update status of all churchgoers in a family when the whole family leaves the church
CREATE PROCEDURE FamilyLeavesChurch @family_id DECIMAL(12)
AS
BEGIN
UPDATE Churchgoer
SET status_code = (SELECT status_code
					FROM Churchgoer_status
					WHERE status_name = 'Inactive')
WHERE family_id = @family_id;
END;
GO

--stored procedure creating an event
CREATE PROCEDURE AddEvent @ministry_id DECIMAL(12), @location_id DECIMAL(12), @event_name VARCHAR(100), @event_desc VARCHAR(1024), @event_type CHAR(1),
	@event_date DATE,@organizer_id DECIMAL(12)
AS
BEGIN
--create event -- will need application logic to prevent duplicate events within the same church
INSERT INTO Church_event (ministry_id, location_id, event_name, event_desc, event_type, event_date)
VALUES (@ministry_id, @location_id, @event_name, @event_desc, @event_type, @event_date)

--insert into bridge entity and add organizer info
INSERT INTO Attends (event_id,churchgoer_id,is_organizer,is_checked_in)
VALUES ((SELECT event_id
		FROM Church_event
		WHERE event_name = @event_name AND event_date = @event_date), @organizer_id,'Y',NULL)

END;
GO

--store procedure to create attendance by a churchgoer at an event
CREATE PROCEDURE AttendEvent @event_id DECIMAL(12), @churchgoer_id DECIMAL(12)
AS
BEGIN
INSERT INTO Attends (event_id, churchgoer_id, is_checked_in)
VALUES (@event_id, @churchgoer_id, NULL)
END;
GO

--stored procedure to update status of churchgoer.
CREATE PROCEDURE ChangeStatus @event_id DECIMAL(12), @churchgoer_id DECIMAL(12), @status CHAR(1)
AS
BEGIN
UPDATE Attends
SET is_checked_in = @status
WHERE event_id = @event_id AND churchgoer_id = @churchgoer_id
END;
GO

--stored procedure to check in child to event
CREATE PROCEDURE CheckIn @event_id DECIMAL(12), @child_id DECIMAL(12)
AS
BEGIN

--create attendance
EXEC AttendEvent @event_id, @child_id;		
--change status to checked_in
EXEC ChangeStatus @event_id, @child_id, 'Y';

--return information to print tag for child
SELECT kid.first_name, kid.last_name, subtype.allergy_info
FROM Churchgoer kid
JOIN Child subtype ON kid.churchgoer_id = subtype.churchgoer_id
WHERE kid.churchgoer_id = @child_id

SELECT parent.first_name, parent.last_name, parent.cell_phone
FROM Churchgoer parent
JOIN Guardian ON parent.churchgoer_id = guardian.guardian_id
WHERE @child_id = guardian.churchgoer_id

END;
GO

--Trigger for entry on historical churchgoer status
CREATE OR ALTER TRIGGER HistoricalStatusEntryTrig											--trigger for historical churchgoer_status
ON Churchgoer
AFTER UPDATE																				--does not include deletes and inserts
AS
BEGIN
INSERT INTO HistoricalStatus(churchgoer_id,old_status_code,new_status_code,date_of_change)	--insert new row into historical table
		SELECT i.churchgoer_id, d.status_code, i.status_code, GETDATE()						--insert values from inserted and deleted columns
		FROM Inserted i JOIN Deleted d
		ON i.churchgoer_id = d.churchgoer_id												--join to ensure proper match of churchgoer
		WHERE d.status_code <> i.status_code;												--only if status is different than old record
END;
GO

--execution of stored procedures

/*
--data before executing AddChurch transaction, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Church;
*/

--add churches
BEGIN TRANSACTION AddChurch;
	EXEC AddChurch 'Hillcrest Church','04-9837457','771 Washington Street, 2nd Floor','Auburn',21,'01501',
		'Spirit filled church sharing the love of Christ and living by His example.', 'hillcrestma', 'IYJX8ppm';
COMMIT TRANSACTION AddChurch;
GO
BEGIN TRANSACTION AddChurch;
	EXEC AddChurch 'Holden Chapel', '03-0328490','279 Reservoir Street','Holden',21,'01520','By faith not by works','hcholden','Ffcf3byIfM';
COMMIT TRANSACTION AddChurch;
GO
BEGIN TRANSACTION AddChurch;
	EXEC AddChurch 'Faith Worship Center','77-2938428','585 Center Street','Manchester',7,'06040','Jesus is love.','FaithChurch','zuYNsVay';
COMMIT TRANSACTION AddChurch;
GO

/*
data after executing AddChurch transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Church;
*/

/*
data before executing AddDefaultMinistries transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Ministry;
SELECT * FROM Ministry_info;
*/

--add default ministries
BEGIN TRANSACTION AddDefaultMinistries;
	EXEC AddDefaultMinistries 100, 200;
	EXEC AddDefaultMinistries 100, 201;
COMMIT TRANSACTION AddDefaultMinistries;
GO
BEGIN TRANSACTION AddDefaultMinistries;
	EXEC AddDefaultMinistries 101, 202;
	EXEC AddDefaultMinistries 101, 203;
	EXEC AddDefaultMinistries 101, 201;
COMMIT TRANSACTION AddDefaultMinistries;
GO
BEGIN TRANSACTION AddDefaultMinistries;
	EXEC AddDefaultMinistries 102, 205;
COMMIT TRANSACTION AddDefaultMinistries;
GO

--add custom ministries
BEGIN TRANSACTION AddCustomMinistries;
	EXEC AddCustomMinistries 102,'General', NULL;
	EXEC AddCustomMinistries 102,'Elderly Ministry','Ministry for Seniors';
COMMIT TRANSACTION AddCustomMinistries;

/*
data after executing AddDefaultMinistries transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Ministry;
SELECT * FROM Ministry_info;
*/

/*
data before executing AddFamily transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Family;
*/

--add families
BEGIN TRANSACTION AddFamily;
	EXEC AddFamily 100, 'Buddleigh Family', NULL, '1 Nobel Terrace', 'Wonokromo', 21, '55975', '2018-JAN-01';
COMMIT TRANSACTION AddFamily;
GO
BEGIN TRANSACTION AddFamily;
	EXEC AddFamily 100, 'Ms. Fern Joret', 3556526820, '9776 Mosinee Junction', 'Liudong', 21, '96624', '2009-APR-20';
COMMIT TRANSACTION AddFamily;
GO
BEGIN TRANSACTION AddFamily;
	EXEC AddFamily 100, 'Raubenheimer-Tribble Family', NULL, '9083 Elmside Junction', 'Ushi', 7, '85576','2016-JUN-10';
COMMIT TRANSACTION AddFamily;
GO
BEGIN TRANSACTION AddFamily;
	EXEC AddFamily 101, 'Romeuf Family', 5083365320, NULL, NULL, NULL, NULL,'2018-JAN-01';
COMMIT TRANSACTION AddFamily;
GO
BEGIN TRANSACTION AddFamily;
	EXEC AddFamily 102, 'The Bousler Family', 4257685412, '974 Morrow Court', 'Malá Strana', 7, '91445','2000-FEB-09';
COMMIT TRANSACTION AddFamily;
GO

/*
data after executing AddFamily transaction, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Family;
*/

/*
data before executing AddChurchgoer, AddGuardian transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Churchgoer;
SELECT * FROM Guardian;
*/

BEGIN TRANSACTION AddChurchgoer;
	EXEC AddChurchgoer 600, 800, 'Carly', 'Buddleigh', 4784004906, NULL, 'cbuddleigh0@bloglovin.com', NULL, 'C', NULL, NULL;
	EXEC AddChurchgoer 600, 800, 'Amber', 'Buddleigh', 6616224899, NULL, 'amcbrearty1@hubpages.com', '1969-AUG-01', NULL, NULL, NULL;
	EXEC AddChurchgoer 600, 800, 'Gayelord', 'Buddleigh', 7119116265, NULL, 'gwyard2@wikia.com', '1958-APR-23', NULL, NULL, NULL;
COMMIT TRANSACTION AddChurchgoer;
GO

BEGIN TRANSACTION AddGuardian;
	EXEC AddGuardian 700,701;
	EXEC AddGuardian 700, 702;
COMMIT TRANSACTION AddGuardian;
GO

BEGIN TRANSACTION AddChurchgoer;
	EXEC AddChurchgoer 601, 800, 'Shermie', 'Tinson', NULL, 3938822872, 'stinson3@networksolutions.com', '2006-JUL-18', 'C', NULL, NULL;
	EXEC AddChurchgoer 601, 800, 'Fern', 'Joret', 2035196757, NULL, 'fjoret4@digg.com', NULL, NULL, NULL, NULL;
COMMIT TRANSACTION AddChurchgoer;
GO

BEGIN TRANSACTION AddGuardian;
	EXEC AddGuardian 703, 704;
COMMIT TRANSACTION AddGuardian;
GO

BEGIN TRANSACTION AddChurchgoer;
EXEC AddChurchgoer 602, 801, 'Guillemette', 'Raubenheimer', 5722818643, 3092380938, 'graubenheimer5@tripadvisor.com', '1967-MAR-16', NULL, NULL, NULL;
EXEC AddChurchgoer 602, 801, 'Emelen', 'Tribble', 7389076107, NULL, NULL, '1991-OCT-20', NULL, NULL, NULL;
COMMIT TRANSACTION AddChurchgoer;
GO

BEGIN TRANSACTION AddChurchgoer;
	EXEC AddChurchgoer 603, 802, 'Darcee', 'Romeuf', 7492463831, NULL, 'dromeuf7@cbslocal.com', NULL, 'T', NULL, NULL;
	EXEC AddChurchgoer 603, 803, 'Odey', 'Romeuf', 8054840659, 6467714836, 'oeschalotte8@de.vu', '2014-OCT-10', 'C', NULL, NULL;
	EXEC AddChurchgoer 603, 802, 'Farr', 'Romeuf', 8374372518, NULL, 'fvitall9@alexa.com', NULL, NULL, NULL, NULL;
COMMIT TRANSACTION AddChurchgoer;
GO

BEGIN TRANSACTION AddGuardian;
	EXEC AddGuardian 707,709;
	EXEC AddGuardian 708,709;
COMMIT TRANSACTION AddGuardian;
GO

BEGIN TRANSACTION AddChurchgoer;
	EXEC AddChurchgoer 604, 804, 'Jourdain', 'Aleksich', NULL, NULL, 'jaleksicha@go.com', '1991-APR-23', NULL, NULL, NULL;
	EXEC AddChurchgoer 604, 802, 'Barry', 'Nattriss', 4258105156, NULL, 'bnattrissb@ocn.ne.jp', '1993-APR-04', 'T', NULL, NULL;
	EXEC AddChurchgoer 604, 802, 'Fredra', 'Bousler', 1655296477, 2393625096, 'fbouslerc@deviantart.com', NULL, NULL, NULL, NULL;
	EXEC AddChurchgoer 604, 802, 'Conny', 'Bousler', 8096117676, NULL, 'cmcmurdod@constantcontact.com', '1967-DEC-13', NULL, NULL, NULL;
	EXEC AddChurchgoer 604, 802, 'Karylin', 'Bousler', 9718728241, NULL, 'kbackene@bizjournals.com', NULL, 'T', NULL, NULL;
COMMIT TRANSACTION AddChurchgoer;
GO

/*
data after executing AddChurchgoer, AddGuardian transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Churchgoer;
SELECT * FROM Guardian;
*/

/*
data before executing LogDonation transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Donation;
*/

BEGIN TRANSACTION LogDonation;
	EXEC LogDonation 250, 600, '2018-Sep-30', 100;
COMMIT TRANSACTION LogDonation;
GO
BEGIN TRANSACTION LogDonation;
	EXEC LogDonation 250, 600, '2018-Oct-01', 100;
COMMIT TRANSACTION LogDonation;
GO

/*
data after executing LogDonation transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Donation;
*/

/*
data before executing AddEvent transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Church_event;
SELECT * FROM Attends;
*/

--add sample sunday school event
BEGIN TRANSACTION AddEvent;
	EXEC AddEvent 250,501,'Sunday School','Kid''s church begins after the Pastor dismisses kids from service after worship.','R','2018-OCT-07',711;
COMMIT TRANSACTION AddEvent;
GO

--add sample sunday school event (2)
BEGIN TRANSACTION AddEvent;
	EXEC AddEvent 250,501,'Sunday School','Kid''s church begins after the Pastor dismisses kids from service after worship.','R','2018-SEP-30',711;
COMMIT TRANSACTION AddEvent;
GO

/*
data after executing AddEvent transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Church_event;
SELECT * FROM Attends;
*/

/*
data before executing CheckIn transactions, commented out to avoid complicated output of script when run as a whole
SELECT * FROM Attends;
*/

--check in
BEGIN TRANSACTION CheckIn;
	EXEC CheckIn 400, 700;
COMMIT TRANSACTION CheckIn;
GO

/*
data after executing CheckIn transactions and before executing ChangeStatus transaction (to checkout a child),
commented out to avoid complicated output of script when run as a whole
SELECT * FROM Attends;
*/

--check out child
BEGIN TRANSACTION ChangeStatus;
	EXEC ChangeStatus 400, 700, 'N';
COMMIT TRANSACTION ChangeStatus;
GO

/*
data after executing ChangeStatus transaction (to checkout a child), commented out to avoid complicated output of script when run as a whole
SELECT * FROM Attends;
*/

/*
data before Historical Data trigger execution, commented out to avoid complicated output of script when run as a whole

SELECT c.churchgoer_id, c.family_id, c.first_name, c.last_name, cs.status_name
FROM Churchgoer c
JOIN Churchgoer_status cs on c.status_code = cs.status_code
JOIN Family f ON f.family_id = c.family_id;

SELECT * FROM HistoricalStatus;

*/
--update with status change
BEGIN TRANSACTION UpdateStatus;
UPDATE Churchgoer
SET status_code = 802
WHERE churchgoer_id = 700;
COMMIT TRANSACTION UpdateStatus;
GO

--update with no change in status
BEGIN TRANSACTION UpdateStatus;
UPDATE Churchgoer
SET first_name = 'Amberlee'
WHERE churchgoer_id = 701;
COMMIT TRANSACTION UpdateStatus;
GO

/*
data after Historical Data trigger execution, commented out to avoid complicated output of script when run as a whole


SELECT c.churchgoer_id, c.family_id, c.first_name, c.last_name, cs.status_name
FROM Churchgoer c
JOIN Churchgoer_status cs on c.status_code = cs.status_code
JOIN Family f ON f.family_id = c.family_id;

SELECT * FROM HistoricalStatus;

*/