/* Inserting initial Data as of the database creation
This includes Employees, Jobs, and Area Production Records
*/


-- Create Shift Leads
INSERT INTO pbs_Employee (FirstName, LastName, ShiftID, isForkliftCertified)
VALUES
	('Alexander', 'Holaday', 2, 1),
	('Sarek', 'Chhthoun', 1, 1),
	('Dan', 'Glassman', 3, 0),
	('Russ', 'Highland', 4, 0)

-- Set Shift Leads
UPDATE pbs_Shift
SET pbs_Shift.LeadOperatorID = 1
WHERE ShiftID = 2 
UPDATE pbs_Shift
SET pbs_Shift.LeadOperatorID = 2
WHERE ShiftID = 1 
UPDATE pbs_Shift
SET pbs_Shift.LeadOperatorID = 3
WHERE ShiftID = 3 
UPDATE pbs_Shift
SET pbs_Shift.LeadOperatorID = 4
WHERE ShiftID = 4 

-- Create 1 to 1 Foreign Key Relationship
ALTER TABLE pbs_Shift 
	ADD CONSTRAINT FK_Lead FOREIGN KEY(LeadOperatorID) REFERENCES pbs_Employee(EmployeeID)
GO

-- Insert Production Employees
INSERT INTO pbs_Employee (FirstName, LastName, ShiftID, isForkliftCertified)
VALUES ('Scott','Snow',2,1),
('Jordan','Mangus',2,1),
('Kirk','Cruz',2,1),
('Michael','Winegarden',2,0),
('Michael','Hammock',2,0),
('Daniel','Wiley',2,0),
('Edward','Kent',2,0),
('Pon','Louen',2,1),
('Charlie','Rodriguez',1,0),
('Corey','Williams',1,0),
('Craig','Fisher',1,0),
('Mack','Varns',1,0),
('Nuth','Him',3,1),
('Pat','Cooper',3,0),
('Joeseph','Kitchichchang',3,0),
('Andrew','Quickeden',1,0),
('Brek','Hanson',1,1),
('Steve','Stewart',1,1),
('Michael','Lockhart',1,0),
('Scott','Farmer',1,0),
('Kris','Russell',3,1),
('Steven','Degenstein',3,1),
('Ron','Logan',3,1)

-- Create Certified Employee relationships

INSERT INTO pbs_AreaCertification (pbs_AreaCertification.EmployeeID, pbs_AreaCertification.AreaID)
VALUES (21, 1), (2, 1), (1, 3), (1, 1), (5, 1), (26, 3), (26, 5), (25, 3), (25, 5), (18, 3), (12, 3), (22, 5), (17, 3)

-- Sales and Project Managers
INSERT INTO pbs_Employee (FirstName, LastName, ShiftID, isForkliftCertified)
VALUES ('Rod', 'Hatton', 4, 0), 
	('Phil', 'Ligon', 4, 0),
	('Bim', 'Fischer', 4, 0),
	('Todd', 'Bell', 4, 0),
	('Matt', 'Karnes', 4, 0),
	('Mike', 'Karnes', 4, 0),
	('Drew', 'Cummings', 4, 0),
	('Ryan', 'Stowers', 4, 0),
	('John', 'Vanderhoof', 4, 0)

-- Initial Job Set
INSERT INTO pbs_Job (JobName, MasterPanelQty, PanelQty, ProjectManagerID, StatusID, ProjectNumber)
VALUES ('LAB GeoPhaze SIPS', 99, 99, 2, 2, '00000000-0000'), 
('Polestar Farm Bunkhouse', 13, 34, 32, 2, '20180219-0003'),
('Plaster Cabin', 24, 61, 28, 4, '20170227-006'),
('Shaktoolik HC', 75, 140, 32, 3, '20180206-0009'),
('Shaktoolik Utilidor', 28, 56, 32, 5, '20180328-0004'),
('Salgade Shell', 16, 31, 28, 5, '20180419-0003'),
('PO-NOEL18 Artisan', 17, 40, 32, 5, '20180514-0004'),
('18'' Yurt', 3, 5, 32, 5, '20180411-003'),
('Seibold Hangar', 19, 44, 32, 2, '20180126-004'),
('Christianson Residence', 47, 174, 32, 2, '201604140012')

--Initial Production Records 5/23-5/26
INSERT INTO pbs_AreaProductionRecord (AreaID, ProductionDate, ProductionHours, Panels, PressesIO, ShiftID)
VALUES (4, '5/25/2018', 9.75, 34, 15, 2),
(3, '5/25/2018', 8, 30, 11, 2),
(1, '5/25/2018', 10.75, 0, 28, 2),
(1, '5/24/2018', 10.75, 0, 35, 2),
(1, '5/23/2018', 10.75, 0, 23, 2),
(4, '5/24/2018', 9.5, 31, 19, 2),
(3, '5/24/2018', 10.75, 32, 16, 2),
(1, '5/26/2018', 10.75, 0, 17, 1),
(4, '5/26/2018', 10.75, 25, 16, 1)



-- Initial Job Production Records
INSERT INTO pbs_JobAreaProductionRecord (JobID, RecordID, TotalHours)
VALUES (7, 1, 1.5), (2, 1, 1.5), (4, 1, 6.75), (9, 2, 4 ),
(2, 2, 4), (4, 3, 4), (10, 3, 1.5), (2, 3, 1),
(9, 3, 1), (7, 3, 1.5), (3, 3, 1.75), (4, 4, 2.15),
(8, 4, 1.536), (1, 4, 3.071), (9, 4, 1.842), (7, 4, 2.15),
(5, 5, 3.74), (1, 5, 1.87), (4, 5, 2.8), (6, 5, 2.34),
(8, 6, 4), (7, 6, 3.5), (4, 6, 3), (1, 7, 2),
(9, 7, 8.75), (10, 8, 4.43), (4, 8, 6.32), (4, 9, 10.75)


-- Initial Employee Station Lists


INSERT INTO pbs_AreaProductionRecordEmployeeList (RecordID, EmployeeID, StationID)
VALUES (9, 15, 26), (9, 16, 27), (9, 13, 28), (9, 24, 30), (9, 14, 31), (9, 2, 23),
(8, 23, 4), (8, 20, 6), (8, 21, 9), (8, 22, 2), (8, 12, 3),
(7, 10, 15), (7, 9, 13), (7, 7, 17), (7, 27, 23),
(6, 8, 26), (6, 25, 27), (6, 18, 28),
(5, 5, 4), (5, 14, 6), (5, 7, 9), (5, 12, 2), (5, 11, 3),
(4, 5, 4), (4, 14, 6), (4, 6, 9), (4, 12, 2), (4, 11, 3),
(3, 5, 4), (3, 24, 6), (3, 6, 9), (3, 12, 2), (3, 11, 3),
(2, 10, 15), (2, 18, 17), (2, 27, 23), (2, 9, 13),
(1, 8, 26), (1, 7, 28), (1, 26, 30)