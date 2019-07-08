/* Scott Snow
	IST 659
	April 2018 Term
	Course Project Table Creation
	Premier Building Systems Operations Database
*/
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_AreaProductionRecordEmployeeList')
BEGIN
	DROP TABLE pbs_AreaProductionRecordEmployeeList
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_JobAreaProductionRecord')
BEGIN
	DROP TABLE pbs_JobAreaProductionRecord
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Station')
BEGIN
	DROP TABLE pbs_Station
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_AreaProductionRecord')
BEGIN
	DROP TABLE pbs_AreaProductionRecord
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_AreaCertification')
BEGIN
	DROP TABLE pbs_AreaCertification
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Job')
BEGIN
	DROP TABLE pbs_Job
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Area')
BEGIN
	DROP TABLE pbs_Area
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Shift')
BEGIN
	ALTER TABLE pbs_Shift
		DROP CONSTRAINT IF EXISTS FK_Lead
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Employee')
BEGIN
	ALTER TABLE pbs_Employee
		DROP CONSTRAINT IF EXISTS FK_Shift
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Employee')
BEGIN
	DROP TABLE pbs_Employee
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_Shift')
BEGIN
	DROP TABLE pbs_Shift
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pbs_JobStatus')
BEGIN
	DROP TABLE pbs_JobStatus
END
GO

CREATE TABLE pbs_Area (
	AreaID int identity primary key
	, AreaName char(15) UNIQUE not null
)
GO

CREATE TABLE pbs_Shift (
	ShiftID int identity primary key
	, ShiftName char(10) UNIQUE not null
	, LeadOperatorID int
)
GO

CREATE TABLE pbs_Employee (
	EmployeeID int identity primary key
	, FirstName varchar(25) not null
	, LastName varchar(25) not null
	, ShiftID int  not null
	, isForkliftCertified bit not null
	CONSTRAINT FK_Shift FOREIGN KEY(ShiftID) REFERENCES pbs_Shift(ShiftID)
	CONSTRAINT uc_Names UNIQUE(FirstName, LastName)
)
GO

CREATE TABLE pbs_AreaCertification (
	CertID int identity primary key
	, EmployeeID int FOREIGN KEY REFERENCES pbs_Employee(EmployeeID) not null
	, AreaID int FOREIGN KEY REFERENCES pbs_Area(AreaID) not null
	, DateCertified datetime 
)
GO

CREATE TABLE pbs_AreaProductionRecord (
	RecordID int identity primary key
	, AreaID int FOREIGN KEY REFERENCES pbs_Area(AreaID) not null
	, ProductionDate date not null
	, ProductionHours decimal(4,2) not null
	, Panels int not null
	, PressesIO int
	, ShiftID int FOREIGN KEY REFERENCES pbs_Shift(ShiftID) not null
)
GO


CREATE TABLE pbs_JobStatus (
	StatusID int identity primary key
	, StatusText varchar(15) UNIQUE not null
)
GO

CREATE TABLE pbs_Job (
	JobID int identity primary key
	, JobName varchar(50) not null
	, MasterPanelQty int not null
	, PanelQty int not null
	, StatusChangeDate datetime DEFAULT GETDATE() not null
	, ProjectManagerID int FOREIGN KEY REFERENCES pbs_Employee(EmployeeID)
	, StatusID int FOREIGN KEY REFERENCES pbs_JobStatus(StatusID)
	, ProjectNumber varchar(40)
	, FinalRevenue decimal(11,2)
	, FinalMaterialCost decimal(11,2)
	, FinalOverhead decimal(11,2)
)
GO

CREATE TABLE pbs_JobAreaProductionRecord (
	JobAreaRecordID int identity primary key
	, JobID int FOREIGN KEY REFERENCES pbs_Job(JobID) not null
	, RecordID int FOREIGN KEY REFERENCES pbs_AreaProductionRecord(RecordID) not null
	, TotalHours decimal (4,2) not null
)
GO

CREATE TABLE pbs_Station (
	StationID int identity primary key
	, StationName varchar(30) not null
	, AreaID int FOREIGN KEY REFERENCES pbs_Area(AreaID) not null
	, CONSTRAINT pbs_St UNIQUE(StationName, AreaID)
)
GO

CREATE TABLE pbs_AreaProductionRecordEmployeeList (
	EmpAreaProdRecordID int identity primary key
	, EmployeeID int FOREIGN KEY REFERENCES pbs_Employee(EmployeeID) not null
	, RecordID int FOREIGN KEY REFERENCES pbs_AreaProductionRecord(RecordID) not null
	, StationID int FOREIGN KEY REFERENCES pbs_Station(StationID) not null
)
GO