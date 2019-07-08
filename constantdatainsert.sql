/* Scott Snow
	IST 659
	Course Project
	Premier Building Systems: Operations Database
	Inserting constant data
		Area
		Shift
		JobStatus
		Station

*/
-- Create Shifts
INSERT INTO pbs_Shift (ShiftName)
VALUES
	('A Shift'),
	('B Shift'),
	('C Shift'),
	('Office')



-- Create Areas
INSERT INTO pbs_Area (AreaName)
VALUES
	('Lamination'),
	('Splines'),
	('Fabrication 1'),
	('Fabrication 2'),
	('Router'),
	('Office')


-- Create Area Stations

INSERT INTO pbs_Station (StationName, AreaID)
VALUES ('QC', 4), ('Foam Leader', 1), ('Foam Cutter', 1), ('Laminator', 1), ('Press', 1), ('Hoist', 1), ('Press Operator 4', 1), ('Press Operator 5', 1),
('Rail Saw', 1),('Rail Saw Assistant', 1),('Splines Lead', 2),('Splines Assistant', 2),('Layout', 3),('Floater', 3), ('Cutter', 3),('Hogger', 3),
('Scrape and Edge Seal 1', 3), ('Scrape and Edge Seal 2', 3),('Lumber Install', 3), ('Lumber Assistant', 3), ('Lumber Cutter', 2), ('Router Operator', 5),
('QC', 3), ('Insulam Fab 1', 1), ('Insulam Fab 2', 1), ('Cutter', 4),('Hogger', 4), 
('Scrape and Edge Seal 1', 4), ('Scrape and Edge Seal 2', 4),('Lumber Install', 4), ('Lumber Assistant', 4),
('Hogger', 5), ('Scrape and Edge Seal 1', 5), ('Scrape and Edge Seal 2', 5),('Lumber Install', 5), ('Lumber Assistant', 5), ('CA Stickers', 3), ('CA Stickers', 4), ('CA Stickers', 5),
('Foam Leader 2', 1), ('Foam Cutter 2', 1), ('Layout', 4), ('Floater', 4)


-- Create job statuses
INSERT INTO pbs_JobStatus (StatusText)
VALUES ('Pre-Production'), ('Started'), ('In Progress'), ('On Hold'), ('Post-Production'), ('Completed') 