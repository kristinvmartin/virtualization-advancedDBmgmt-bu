/*
RUN THIS SECOND: This script should be run after the Create_Tables_Script

Below is data that is going to be populated into the DB at inception. I want to leave the option open to edit these values at future times,
but the data won't be edited by users and won't be edited by those maintaining the database often enough to merit a stored procedure.
*/

--insert data into States table
INSERT INTO States (state_postal_code, state_id)
VALUES
('AL', 1),
('AK', 2),
('AZ', 3),
('AR', 4),
('CA', 5),
('CO', 6),
('CT', 7),
('DE', 8),
('FL', 9),
('GA', 10),
('HI', 11),
('ID', 12),
('IL', 13),
('IN', 14),
('IA', 15),
('KS', 16),
('KY', 17),
('LA', 18),
('ME', 19),
('MD', 20),
('MA', 21),
('MI', 22),
('MN', 23),
('MS', 24),
('MO', 25),
('MT', 26),
('NE', 27),
('NV', 28),
('NH', 29),
('NJ', 30),
('NM', 31),
('NY', 32),
('NC', 33),
('ND', 34),
('OH', 35),
('OK', 36),
('OR', 37),
('PA', 38),
('RI', 39),
('SC', 40),
('SD', 41),
('TN', 42),
('TX', 43),
('UT', 44),
('VT', 45),
('VA', 46),
('WA', 47),
('WV', 48),
('WI', 49),
('WY', 50);

--insert default values into Ministry_info
INSERT INTO Ministry_info (ministry_name, ministry_desc, is_default)
VALUES	('Children''s Ministry', 'Use this ministry for programs for teens.', 'Y'),
		('Youth Ministry', 'Use this ministry for programs for teens.', 'Y'),
		('Women''s Ministry', 'Use this ministry for programs for women.','Y'),
		('Men''s Ministry', 'Use this ministry for programs for men.', 'Y'),
		('Pastoral Ministry', 'Use this ministry for programs for pastors and pastoral development.', 'Y'),
		('Facilities Ministry', 'Use this ministry for anything related to the facilities of the church.', 'Y');

--insert default values into Churchgoer_status
INSERT INTO Churchgoer_status (status_name,status_desc)
VALUES	('Visitor','Someone visiting.'),
		('Regular Attender','Someone not a member but who attends regularly'),
		('Member','Someone who has met church requirements for church membership'),
		('Deceased','A past attender who has passed away.'),
		('Inactive','Someone who used to attend.');

--insert sample data into Event_location
INSERT INTO Event_location (location_name, location_desc)
VALUES	('Sanctuary', 'quam a odio in hac habitasse platea dictumst maecenas ut massa quis augue luctus tincidunt nulla mollis'),
		('Room 36', 'vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed augue aliquam erat volutpat'),
		('Pastor''s House', 'imperdiet nullam orci pede venenatis non sodales sed tincidunt eu felis fusce posuere felis sed lacus morbi sem mauris laoreet ut rhoncus aliquet pulvinar sed nisl nunc rhoncus dui'),
		('Ministry Room 2', 'ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat'),
		('Prayer Corner', NULL);

