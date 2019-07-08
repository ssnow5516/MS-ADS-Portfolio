
IF OBJECT_ID('dbo.getShiftID') IS NOT NULL
   DROP FUNCTION dbo.getShiftID
GO
IF OBJECT_ID('dbo.getStatusID') IS NOT NULL
   DROP FUNCTION dbo.getStatusID
GO
IF OBJECT_ID('dbo.getAreaID') IS NOT NULL
   DROP FUNCTION dbo.getAreaID
GO
IF OBJECT_ID('dbo.getEmpID') IS NOT NULL
   DROP FUNCTION dbo.getEmpID
GO
IF OBJECT_ID('dbo.getJobID') IS NOT NULL
   DROP FUNCTION dbo.getJobID
GO
IF OBJECT_ID('dbo.getStationID') IS NOT NULL
   DROP FUNCTION dbo.getStationID
GO
IF OBJECT_ID('dbo.getRecID') IS NOT NULL
   DROP FUNCTION dbo.getRecID
GO

-- Get ID functions


CREATE FUNCTION dbo.getShiftID(@shiftname char(10))
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_Shift.ShiftID FROM pbs_Shift
	WHERE pbs_Shift.ShiftName = @shiftname
	
	RETURN @ret
END
GO

CREATE FUNCTION dbo.getStatusID(@statusname varchar(15))
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_JobStatus.StatusID FROM pbs_JobStatus
	WHERE pbs_JobStatus.StatusText = @statusname
	
	RETURN @ret
END
GO

ALTER TABLE pbs_Job ADD DEFAULT dbo.getStatusID('Pre-Production') FOR StatusID
GO

CREATE FUNCTION dbo.getAreaID(@areaname char(15))
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_Area.AreaID FROM pbs_Area
	WHERE pbs_Area.AreaName = @areaname
	
	RETURN @ret
END
GO

CREATE FUNCTION dbo.getEmpID(@lastname varchar(25), @firstname varchar(25))
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_Employee.EmployeeID FROM pbs_Employee
	WHERE pbs_Employee.LastName = @lastname AND pbs_Employee.FirstName = @firstname
	
	RETURN @ret
END
GO

CREATE FUNCTION dbo.getStationID(@stationname varchar(30), @areaID int)
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_Station.StationID FROM pbs_Station
	WHERE pbs_Station.StationName = @stationname AND pbs_Station.AreaID = @areaID
	
	RETURN @ret
END
GO


CREATE FUNCTION dbo.getRecID(@date date, @shiftID int, @areaID int)
RETURNS INT AS
BEGIN
	DECLARE @ret int

	SELECT @ret = pbs_AreaProductionRecord.RecordID FROM pbs_AreaProductionRecord
	WHERE pbs_AreaProductionRecord.ProductionDate = @date 
	AND pbs_AreaProductionRecord.ShiftID = @shiftID 
	AND pbs_AreaProductionRecord.AreaID = @areaID
	
	RETURN @ret
END
GO

CREATE FUNCTION dbo.getJobID(@projectNo varchar(40))
RETURNS INT AS
BEGIN
	DECLARE @ret int
	SELECT @ret = pbs_Job.JobID FROM pbs_Job
	WHERE pbs_Job.ProjectNumber = @projectNo
	RETURN @ret
END
GO

DECLARE @this decimal(5,2) = dbo.TotalJobHours('20180328-0004')
SELECT @this AS This
IF OBJECT_ID('pbs_addNewEmployee') IS NOT NULL
   DROP PROCEDURE pbs_addNewEmployee
GO
IF OBJECT_ID('pbs_certifyEmployee') IS NOT NULL
   DROP PROCEDURE pbs_certifyEmployee
GO
IF OBJECT_ID('pbs_addNewForkLiftCert') IS NOT NULL
   DROP PROCEDURE pbs_addNewForkLiftCert
GO
IF OBJECT_ID('pbs_addNewJob') IS NOT NULL
   DROP PROCEDURE pbs_addNewJob
GO
IF OBJECT_ID('pbs_CompleteJob') IS NOT NULL
   DROP PROCEDURE pbs_CompleteJob
GO
IF OBJECT_ID('pbs_addNewRecord') IS NOT NULL
   DROP PROCEDURE pbs_addNewRecord
GO
IF OBJECT_ID('pbs_addNewJobRecord') IS NOT NULL
   DROP PROCEDURE pbs_addNewJobRecord
GO
IF OBJECT_ID('pbs_addNewRecordEmployee') IS NOT NULL
   DROP PROCEDURE pbs_addNewRecordEmployee
GO
--Add Procedures
-- New Employee
CREATE PROCEDURE pbs_addNewEmployee(@firstname varchar(25), @lastname varchar(25), @shift char(10))
AS
BEGIN 
	DECLARE @shiftid int = dbo.getShiftID(@shift)
	INSERT INTO pbs_Employee (FirstName, LastName, ShiftID, isForkliftCertified)
	VALUES (@firstname, @lastname, @shiftid, 0)
END
GO 
-- Certifies employee
CREATE PROCEDURE pbs_certifyEmployee(@date date, @area char(15), @lastname varchar(25), @firstname varchar(25))
AS
BEGIN
	DECLARE @empID int = dbo.getEmpID(@lastname, @firstname)
	DECLARE @areaID int = dbo.getAreaID(@area)
	INSERT INTO pbs_AreaCertification (EmployeeID, AreaID, DateCertified)
	VALUES (@empID, @areaID, @date)
END
GO
-- Changes Forklift Certification
CREATE PROCEDURE pbs_addNewForkLiftCert(@lastname varchar(25), @firstname varchar(25))
AS
BEGIN
	DECLARE @empID int = dbo.getEmpID(@lastname, @firstname)
	UPDATE pbs_Employee SET isForkliftCertified = 1 WHERE EmployeeID = @empID
END
GO
-- New Job with default estimates
CREATE PROCEDURE pbs_addNewJob(@projectNo varchar(40), @pmfirst varchar(25), @pmlast varchar(25), @panelQty int, @masterpQty int, @jobname varchar(50))
AS
BEGIN
	INSERT INTO pbs_Job (JobName, MasterPanelQty, PanelQty, ProjectManagerID, ProjectNumber)
	VALUES (@jobname, @masterpQty, @panelQty, dbo.getEmpID(@pmfirst, @pmlast), @projectNo)
END
GO
-- Add completed values to a job
CREATE PROCEDURE pbs_CompleteJob(@projectNo varchar(40), @fmc decimal(11,2), @fr decimal(11,2), @fo decimal(11,2))
AS
BEGIN
	UPDATE pbs_Job SET FinalMaterialCost = @fmc, FinalRevenue = @fr, FinalOverhead = @fo, StatusID = dbo.getStatusID('Completed')
	WHERE pbs_Job.ProjectNumber = @projectNo
END
GO
-- The bulkiest section, Adds a new record
CREATE PROCEDURE pbs_addNewRecord(@date date, @shift char(10), @area char(15), @totalhours decimal(4,2), @panels int, @pressesIO int)
AS
BEGIN
	DECLARE @shiftID int = dbo.getShiftID(@shift)
	DECLARE @areaID int = dbo.getAreaID(@area)
	INSERT INTO pbs_AreaProductionRecord (AreaID, ProductionDate, ProductionHours, Panels, PressesIO, ShiftID)
	VALUES (@areaID, @date, @totalhours, @panels, @pressesIO, @shiftID)
END
GO
-- Adds a Job Record instance
CREATE PROCEDURE pbs_addNewJobRecord(@shift char(10), @area char(15), @date date, @jobPN varchar(40), @jobhours decimal(4,2), @status varchar(15))
AS 
BEGIN
	DECLARE @shiftID int = dbo.getShiftID(@shift)
	DECLARE @areaID int = dbo.getAreaID(@area)
	DECLARE @recID int = dbo.getRecID(@date, @shiftID, @areaID)
	DECLARE @statusID int = dbo.getStatusID(@status)
	DECLARE @jobID int = dbo.getJobID(@jobPN)
	INSERT INTO pbs_JobAreaProductionRecord(JobID, RecordID, TotalHours)
	VALUES (@jobID, @recID, @jobhours)
	UPDATE pbs_Job SET pbs_Job.StatusID = @statusID, pbs_Job.StatusChangeDate = @date WHERE pbs_Job.JobID = @jobID
END
GO
-- Adds an Employee Record instance. 
CREATE PROCEDURE pbs_addNewRecordEmployee(@shift char(10), @area char(15), @date date, @station varchar(30), @empfn varchar(25), @empln varchar(25))
AS 
BEGIN
	DECLARE @shiftID int = dbo.getShiftID(@shift)
	DECLARE @areaID int = dbo.getAreaID(@area)
	DECLARE @recID int = dbo.getRecID(@date, @shiftID, @areaID)
	DECLARE @stationID int = dbo.getStationID(@station, @areaID)
	DECLARE @empID int = dbo.getEmpID(@empfn, @empln)
	INSERT INTO pbs_AreaProductionRecordEmployeeList (RecordID, EmployeeID, StationID)
	VALUES (@recID, @empID, @stationID)
END
GO

IF OBJECT_ID('pbs_FullRoster') IS NOT NULL
   DROP VIEW pbs_FullRoster
GO
IF OBJECT_ID('pbs_ShiftLeads') IS NOT NULL
   DROP VIEW pbs_ShiftLeads
GO
IF OBJECT_ID('pbs_CertifiedOperators') IS NOT NULL
   DROP VIEW pbs_CertifiedOperators
GO
IF OBJECT_ID('pbs_ForkliftOperators') IS NOT NULL
   DROP VIEW pbs_ForkliftOperators
GO
IF OBJECT_ID('pbs_AShift') IS NOT NULL
   DROP VIEW pbs_AShift
GO
IF OBJECT_ID('pbs_BShift') IS NOT NULL
   DROP VIEW pbs_BShift
GO
IF OBJECT_ID('pbs_CShift') IS NOT NULL
   DROP VIEW pbs_CShift
GO
IF OBJECT_ID('pbs_CompletedJobs') IS NOT NULL
   DROP VIEW pbs_CompletedJobs
GO
IF OBJECT_ID('pbs_InProduction') IS NOT NULL
   DROP VIEW pbs_InProduction
GO
IF OBJECT_ID('pbs_PreProduction') IS NOT NULL
   DROP VIEW pbs_PreProduction
GO
IF OBJECT_ID('pbs_OnHold') IS NOT NULL
   DROP VIEW pbs_OnHold
GO
-- Common Views
-- See Employee with shift listing. 
GO
CREATE VIEW pbs_FullRoster AS
SELECT LastName, FirstName, ShiftName AS [Shift],
 ROW_NUMBER() OVER (ORDER BY LastName ASC) AS RowNum
FROM pbs_Employee
JOIN pbs_Shift ON pbs_Employee.ShiftID = pbs_Shift.ShiftID
GO
-- See Shift Leads
CREATE VIEW pbs_ShiftLeads AS
SELECT pbs_Shift.ShiftName
, pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS Lead
FROM pbs_Shift 
JOIN pbs_Employee ON pbs_Shift.LeadOperatorID = pbs_Employee.EmployeeID
GO
-- See Certified Operators
CREATE VIEW pbs_CertifiedOperators AS
SELECT pbs_Employee.LastName + ', ' + pbs_Employee.FirstName AS Operator,
pbs_Area.AreaName AS Area,
ROW_NUMBER() OVER (ORDER BY pbs_Area.AreaName ASC) AS RowNum
FROM pbs_AreaCertification 
JOIN pbs_Area ON pbs_Area.AreaID = pbs_AreaCertification.AreaID
JOIN pbs_Employee ON pbs_Employee.EmployeeID = pbs_AreaCertification.EmployeeID
GO
-- See forklift operators
CREATE VIEW pbs_ForkliftOperators AS
SELECT pbs_Employee.LastName + ', ' + pbs_Employee.FirstName AS [Forklift Operators], pbs_Shift.ShiftName,
ROW_NUMBER() OVER (ORDER BY pbs_Shift.ShiftName ASC) AS RowNum
FROM pbs_Employee
JOIN pbs_Shift ON pbs_Employee.ShiftID = pbs_Shift.ShiftID
WHERE isForkliftCertified = 1
GO
-- A Shift
CREATE VIEW pbs_AShift AS
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 1
GO
-- B Shift
CREATE VIEW pbs_BShift AS
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 2
GO
-- C Shift
CREATE VIEW pbs_CShift AS
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 3
GO
-- Completed Jobs
CREATE VIEW pbs_CompletedJobs AS
SELECT pbs_Job.JobName, pbs_Job.ProjectNumber, pbs_Job.FinalRevenue, pbs_Job.StatusChangeDate
FROM pbs_Job
WHERE pbs_Job.StatusID = dbo.getStatusID('Completed')
GO
-- In-Production Jobs
CREATE VIEW pbs_InProduction AS
SELECT pbs_Job.JobName, pbs_Job.ProjectNumber, pbs_Job.EstRevenue, pbs_Job.StatusChangeDate
FROM pbs_Job
WHERE pbs_Job.StatusID = dbo.getStatusID('In Progress') OR pbs_Job.StatusID = dbo.getStatusID('Started')
GO
-- Pre-Production Jobs
CREATE VIEW pbs_PreProduction AS
SELECT pbs_Job.JobName, pbs_Job.ProjectNumber, pbs_Job.EstRevenue, pbs_Job.StatusChangeDate
FROM pbs_Job
WHERE pbs_Job.StatusID = dbo.getStatusID('Pre-Production')
GO
-- On Hold Jobs
CREATE VIEW pbs_OnHold AS
SELECT pbs_Job.JobName, pbs_Job.ProjectNumber, pbs_Job.EstRevenue, pbs_Job.StatusChangeDate
FROM pbs_Job
WHERE pbs_Job.StatusID = dbo.getStatusID('On Hold')
GO


-- EXEC Statements
EXEC pbs_addNewEmployee 'Justin', 'Kubeck', 'B Shift'
EXEC pbs_addNewEmployee 'Curtis', 'Slater', 'Office'