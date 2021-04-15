DROP INDEX IF EXISTS DonationDateIdx ON Donation;
DROP INDEX IF EXISTS PersonLastNameIdx ON Churchgoer;
DROP INDEX IF EXISTS MinistryNameIdx ON Ministry_info;
DROP INDEX IF EXISTS ChurchStateIdx ON Church;
DROP INDEX IF EXISTS FamilyStateIdx ON Family;
DROP INDEX IF EXISTS FamilyChurchIdx ON Family;
DROP INDEX IF EXISTS ChurchgoerFamilyIdx ON Churchgoer;
DROP INDEX IF EXISTS ChurchgoerStatusIdx ON Churchgoer;
DROP INDEX IF EXISTS DonationMinistryIdx ON Donation;
DROP INDEX IF EXISTS DonationFamilyIdx ON Donation;
DROP INDEX IF EXISTS Event_MinistryIdx ON Church_event;
DROP INDEX IF EXISTS EventLocationIdx ON Church_event;
DROP INDEX IF EXISTS MinistryInfo_MinistryIdx ON Ministry;
DROP INDEX IF EXISTS MinistryChurchIdx ON Ministry;

--foreign key indexes
CREATE INDEX ChurchStateIdx
ON Church(state_id);

CREATE INDEX FamilyStateIdx
ON Family(state_id);

CREATE INDEX FamilyChurchIdx
ON Family(church_id);

CREATE INDEX ChurchgoerFamilyIdx
ON Churchgoer(family_id);

CREATE INDEX ChurchgoerStatusIdx
ON Churchgoer(status_code);

CREATE INDEX DonationMinistryIdx
ON Donation(ministry_id);

CREATE INDEX DonationFamilyIdx
ON Donation(family_id);

CREATE INDEX Event_MinistryIdx
ON Church_event(ministry_id);

CREATE INDEX EventLocationIdx
ON Church_event(location_id);

CREATE INDEX MinistryInfo_MinistryIdx
ON Ministry(info_id);

CREATE INDEX MinistryChurchIdx
ON Ministry(church_id);


--query-driven indexes
CREATE INDEX DonationDateIdx
ON Donation(donation_date);

CREATE INDEX PersonLastNameIdx
ON Churchgoer(last_name);

CREATE INDEX MinistryNameIdx
ON Ministry_info(ministry_name);



