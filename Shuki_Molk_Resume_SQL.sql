USE [master]
GO

IF (SELECT database_id FROM SYS.DATABASES WHERE NAME = 'Shuki_Molk_Resume') IS NOT NULL
DROP DATABASE [Shuki_Molk_Resume]
GO

CREATE DATABASE [Shuki_Molk_Resume]
GO

USE [Shuki_Molk_Resume]
GO

CREATE FUNCTION uf_calculate_age (@dob DATE)
RETURNS TINYINT
AS
BEGIN

DECLARE @age TINYINT
IF @dob > CAST(GETDATE() AS DATE)
	SET @age = NULL --If date of birth is in the future, we return NULL
ELSE
	SET @age =
		CASE --1st CASE statment (checking the year)
			WHEN YEAR(@dob) = YEAR(GETDATE())
				THEN 0 -- The subject was born this year, so they aren't even 1.
			ELSE DATEDIFF(YEAR, @dob, GETDATE()) -- The subject was born before current year, so we return the diff in years,
													-- except, if the date (month and day) in this year has not yet "reached" the birthdate
													-- we would subtract 1 from this number.
				-	-- (here is the subtraction)
				CASE --2nd CASE statment (Checking the month)
					WHEN MONTH(@dob) < MONTH(GETDATE())	-- That means subject had already had their birthday, so we subtract 0.
						THEN 0 
					WHEN MONTH(@dob) > MONTH(GETDATE())	-- That means subject had not yet had their birthday, so we subtract 1.
						THEN 1
					ELSE								-- That means subject's birthday is in this month, so we check the day:
						CASE --3rd CASE statment (Checking the day)
							WHEN DAY(@dob) <= DAY(GETDATE()) --That means subject had already had their birthday, so we subtract 0.
								THEN 0
							ELSE 1 -- That means subject had not yet had their birthday, so we subtract 1

						END -- Of 3rd CASE statment (Checking the day)
				END -- Of 2nd CASE statment (Checking the month)
		END -- Of 1st CASE statment (checking the year)

RETURN @age
END -- Of function
GO

CREATE TABLE Personal_Details
	(
	first_name		VARCHAR(20)	
	,last_name		VARCHAR(20)	NOT NULL
	,cellular		CHAR(10)	NOT NULL
	,landline		VARCHAR(10)	
	,email			VARCHAR(50)	NOT NULL
	,date_of_birth	DATE		NOT NULL
	,age			AS dbo.uf_calculate_age(date_of_birth)
	-----------------------
	,CONSTRAINT prsnldtls_pk			PRIMARY KEY (first_name)
	,CONSTRAINT prsnldtls_cellular_ck	CHECK (cellular LIKE '0%')
	,CONSTRAINT prsnldtls_email_ck		CHECK (email LIKE '_%@_%.__%')
	,CONSTRAINT prsnldtls_dob_ck		CHECK (date_of_birth <= CAST(GETDATE() AS DATE))
	)
GO

CREATE TRIGGER tgr_there_can_be_only_one
ON Personal_Details
AFTER INSERT
AS
BEGIN
IF (SELECT COUNT(*) FROM Personal_Details) >1
	BEGIN
		RAISERROR('Cannot add roes to this table', 16, 1)
		ROLLBACK TRANSACTION
	END
END
GO
----------------------------------------------------------------------------------------

CREATE TABLE Education
	(
	institute_id		TINYINT			IDENTITY(1,1)
	,institute_name		VARCHAR(50)		NOT NULL	
	,city				VARCHAR(30)		NOT NULL	
	,country			VARCHAR(30)		NOT NULL	
	,begin_date			DATE			NOT NULL
	,end_date			DATE		
	,study				VARCHAR(50)		NOT NULL	
	,degree				VARCHAR(20)		
	,supports_analysis	TINYINT			NOT NULL	
	,remarks			VARCHAR(150)	DEFAULT NULL	
	-----------------------
	CONSTRAINT edct_id_pk			PRIMARY KEY (institute_id)
	,CONSTRAINT edct_begin_date_ck	CHECK(begin_date <= GETDATE())
	,CONSTRAINT edct_support_ck		CHECK(supports_analysis BETWEEN 1 AND 10) --1 is the least <-> 10 is the most
	)
GO
----------------------------------------------------------------------------------------

CREATE TABLE Companies
	(
	company_id		TINYINT		IDENTITY(1,1)
	,company_name	VARCHAR(50)	NOT NULL	
	,city			VARCHAR(30)	NOT NULL	
	,country		VARCHAR(30)	NOT NULL	
	-----------------------
	CONSTRAINT cmpns_id_pk		PRIMARY KEY (company_id)
	)
GO
----------------------------------------------------------------------------------------

CREATE TABLE Experience
	(
	experience_id		TINYINT			IDENTITY(1,1)
	,company_id			TINYINT			NOT NULL
	,position			VARCHAR(50)	
	,begin_date			DATE			NOT NULL
	,end_date			DATE	
	,supports_analysis	TINYINT			NOT NULL
	,remarks			VARCHAR(150)	
	-----------------------
	CONSTRAINT expr_exp_id_pk		PRIMARY KEY (experience_id)
	,CONSTRAINT expr_cmpny_id_fk	FOREIGN KEY (company_id) REFERENCES Companies(company_id)
	,CONSTRAINT expr_begin_date_ck	CHECK(begin_date <= GETDATE())
	,CONSTRAINT expr_support_ck		CHECK(supports_analysis BETWEEN 1 AND 10) --1 is the least <-> 10 is the most
	)
GO
----------------------------------------------------------------------------------------

CREATE TABLE Languages
	(
	language_id		TINYINT		IDENTITY(1,1)
	,language_name	VARCHAR(20)	NOT NULL	
	,proficiency	VARCHAR(20)	NOT NULL	
	-----------------------
	CONSTRAINT lnggs_lngg_id_pk	PRIMARY KEY (language_id)
	)
GO
----------------------------------------------------------------------------------------

CREATE TABLE Skills
	(
	skill_id			TINYINT		IDENTITY(1,1)
	,skill_name			VARCHAR(50)	NOT NULL
	,supports_analysis	TINYINT		NOT NULL
	
	-----------------------
	CONSTRAINT sklls_skll_id_pk		PRIMARY KEY (skill_id)
	,CONSTRAINT sklls_support_ck	CHECK(supports_analysis BETWEEN 1 AND 10) --1 is the least <-> 10 is the most
	)
GO

--======================================================================================--
--									Inserting data										--
--======================================================================================--

INSERT INTO Personal_Details
--first_name		last_name		cellular	landline	email					date_of_birth
VALUES
('Yehoshua Shai',	'Santana Molk', '0544690390', NULL,		'kambatz46@yahoo.com', '1978-07-25')
GO


INSERT INTO Education
VALUES
--institute_name			city			country		begin_date		end_date		area_of_study											degree	supports_analysis	remarks
('Bar-Ilan University',		'Ramat Gan',	'Israel',	'1996-10-01',	'1998-10-01',	'Logistics, Materials, and Supply Chain Management',	'BA',	8,					'Via the IDF academic reserve program')
,('John Bryce',				'Tel Aviv',		'Israel',	'2020-05-25',	'2020-11-25',	'Data Analyst Expert course',							NULL,	10,					'Lead by Ram Kedem, focusing on SQL, Python, Excel and Power BI')
,('Cigam - Centro Musical',	'Rio de Janeiro','Brazil',	'2009-07-01',	'2009-10-01',	'Harmony 2',											NULL,	5,					'Studying analysis of harmonic progressions in music. Completing the course which occurred in a language I did not dominate.')
,('Sailor',					'Yaffo',		'Israel',	'2016-06-13',	'2016-07-29',	'Sailing 21 ft sailboats',								NULL,	1,					NULL)
GO


INSERT INTO Companies
VALUES
--company_name						city				country
('KMS Technical Equipment ltd.',	'Rinatia',			'Israel')
,('Hotel De La Mer Tel Aviv',		'Tel Aviv',			'Israel')
,('Shopping.com',					'Netania',			'Israel')
,('IDF',							'Various Locations', 'Israel')
GO


INSERT INTO Experience
VALUES
--company_id	position					begin_date		end_date		supports_analysis	remarks
(1,				'COO',						'2013-09-01',	NULL,			8,					'ISO:9001 standard within 3 weeks')
,(2,			'Assisting Manager',		'2010-01-01',	'2010-08-01',	6,					NULL	)
,(2,			'Front Desk Receptionist',	'2007-10-01',	'2009-04-01',	3,					'Wrote and implemented the front desk procedures guidebook')
,(3,			'Content expert',			'2005-11-01',	'2006-06-01',	4,					NULL	)
,(4,			'Assts. Head of Department','2002-10-01',	'2004-05-01',	9,					'At the IDF Supply Center')
,(4,			'Operations Officer',		'2001-01-01',	'2002-09-30',	9,					'At the Northern command logistics Operations Room')
,(4,			'Supply Officer',			'2000-01-09',	'2000-12-31',	9,					'At Golani Training Base')
GO


INSERT INTO Languages
VALUES
--language_name		proficiency
('Hebrew',			'native')
,('English',		'full professional')
,('Portuguese',		'proficient')
,('Spanish',		'basic')
GO

INSERT INTO Skills
VALUES
--skill_name								supports_analysis
('Fast learning and adjustment',			7)
,('Separating the wheat from the chaff',	9)
,('Conciseness',							8)
,('Promoting initiatives',					5)
,('Establishing and improving procedures',	6)
GO

CREATE PROC usp_greetings
AS
BEGIN
	SELECT 'Thank you for taking the time and checking out my resume.' "Greetings!"
	UNION ALL
	SELECT 'This is but a basic demonstration of my abilities as a Data Analyst.'
	UNION ALL
	SELECT 'Please feel free to explore this small database in order to know a little more about me.'
	UNION ALL
	SELECT 'However, the best way to do so is of course by setting up an interview and it just happened'
	UNION ALL
	SELECT 'that I have my contact details ready right here:'
	UNION ALL
	SELECT '' 
	UNION ALL
	SELECT CONCAT('cellular: ', SUBSTRING(cellular,1,4),'-', SUBSTRING(cellular,5,3),'-',SUBSTRING(cellular,8,3), ', email: ', email) FROM Personal_Details
	UNION ALL
	SELECT '' 
	UNION ALL
	SELECT 'I would appreciate an update, even in the unlikely event of a "no".' 
	UNION ALL
	SELECT 'And to end with Katniss Everdeen''s quote:' 
	UNION ALL
	SELECT 'Thank you for your consideration!'
	UNION ALL
	SELECT 'Sincerely,'
	UNION ALL
	SELECT CONCAT(first_name,' ',last_name) FROM Personal_Details
END
GO

EXEC usp_greetings