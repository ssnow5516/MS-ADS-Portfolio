IF OBJECT_ID('dbo.TotalJobHours') IS NOT NULL
   DROP FUNCTION dbo.TotalJobHours
GO
-- Calculates how long it took to complete a job
CREATE FUNCTION dbo.TotalJobHours(@projectNo varchar(50))
RETURNS DECIMAL(5,2) AS
BEGIN
	DECLARE @ret Decimal(5,2)
	DECLARE @jobID int = dbo.getJobID(@projectNo)
	SELECT @ret = SUM(pbs_JobAreaProductionRecord.TotalHours)
	FROM pbs_JobAreaProductionRecord WHERE JobID = @jobID
	RETURN @ret
END
GO


IF OBJECT_ID('pbs_JobHoursSummary') IS NOT NULL
   DROP VIEW pbs_JobHoursSummary
GO
-- shows a summary of each job and how long that job took along with varioud final dollar figures
CREATE VIEW pbs_JobHoursSummary AS
SELECT pbs_Job.JobName
	, pbs_Job.ProjectNumber
	, pbs_Job.FinalRevenue
	, dbo.TotalJobHours(pbs_Job.ProjectNumber) AS TotalHours
	, pbs_Job.FinalMaterialCost
	, pbs_Job.FinalOverhead
	FROM pbs_Job
	WHERE pbs_Job.StatusID = dbo.getStatusID('Completed')
GO

IF OBJECT_ID('pbs_JobCorrelationSummary') IS NOT NULL
   DROP VIEW pbs_JobCorrelationSummary
GO
-- Formula for Pearson correlation retrieved from https://www.mssqltips.com/sqlservertip/4544/calculating-the-pearson-product-moment-correlation-coefficient-in-tsql/ on 6/28/18
-- shows correlation coefficients for Final Revenue, and each of the three identified contributing factors: labor, materials, overhead
CREATE VIEW pbs_JobCorrelationSummary AS
SELECT
	'Correlation Summary' AS Summary
	, ' ' AS ' '
	, SUM(FinalRevenue) AS Total
	, (Avg(FinalRevenue * dbo.TotalJobHours(pbs_Job.ProjectNumber)) - (Avg(FinalRevenue) * Avg(dbo.TotalJobHours(pbs_Job.ProjectNumber)))) / (StDevP(FinalRevenue) * StDevP(dbo.TotalJobHours(pbs_Job.ProjectNumber))) AS RevenueAndTotalHours
	, (Avg(FinalRevenue * FinalMaterialCost) - (Avg(FinalRevenue) * Avg(FinalMaterialCost)))/ (StDevP(FinalRevenue) * StDevP(FinalMaterialCost)) AS RevenueAndMaterials
	, (Avg(FinalRevenue * FinalOverhead) - (Avg(FinalRevenue) * Avg(FinalOverhead)))/ (StDevP(FinalRevenue) * StDevP(FinalOverhead)) AS RevenueAndOverhead
FROM pbs_Job WHERE pbs_Job.StatusID = dbo.getStatusID('Completed')
GO

IF OBJECT_ID('pbs_viewCompletedJobSummary') IS NOT NULL
   DROP VIEW pbs_viewCompletedJobSummary
GO
-- Combines the previous two views to be viewed as one
CREATE VIEW pbs_viewCompletedJobSummary AS
SELECT * FROM pbs_JobHoursSummary
UNION ALL
SELECT * FROM pbs_JobCorrelationSummary
GO


IF OBJECT_ID('dbo.StationHoursForDay') IS NOT NULL
   DROP FUNCTION dbo.StationHoursForDay
GO
-- returns the total hours among areas spent at respective stations for a specific day
CREATE FUNCTION dbo.StationHoursForDay(@date date, @station varchar(30))
RETURNS DECIMAL(5,2) AS
BEGIN
	DECLARE @ret Decimal(5,2)
	SELECT @ret = SUM(pbs_AreaProductionRecord.ProductionHours)
	FROM pbs_AreaProductionRecord 
	JOIN pbs_AreaProductionRecordEmployeeList ON pbs_AreaProductionRecord.RecordID = pbs_AreaProductionRecordEmployeeList.RecordID
	JOIN pbs_Station ON pbs_AreaProductionRecordEmployeeList.StationID = pbs_Station.StationID 
	WHERE ProductionDate = @date AND pbs_Station.StationName = @station
	RETURN @ret
END
GO

IF OBJECT_ID('dbo.ProductionSpeedForDay') IS NOT NULL
   DROP FUNCTION dbo.ProductionSpeedForDay
GO
-- returns the overall speed Panels/Hour for a given day. In real operations, the panels are weighted based on complexity but that is not included here
CREATE FUNCTION dbo.ProductionSpeedForDay(@date date)
RETURNS DECIMAL(5,2) AS
BEGIN
	DECLARE @panels Decimal(5,2)
	DECLARE @hours Decimal(5,2)
	SELECT @hours = SUM(pbs_AreaProductionRecord.ProductionHours)
	FROM pbs_AreaProductionRecord 
	WHERE ProductionDate = @date AND pbs_AreaProductionRecord.AreaID = 3 OR pbs_AreaProductionRecord.AreaID = 4 OR pbs_AreaProductionRecord.AreaID = 5
	SELECT @panels = SUM(pbs_AreaProductionRecord.Panels)
	FROM pbs_AreaProductionRecord 
	WHERE ProductionDate = @date AND pbs_AreaProductionRecord.AreaID = 3 OR pbs_AreaProductionRecord.AreaID = 4 OR pbs_AreaProductionRecord.AreaID = 5
	RETURN @panels/@hours
END
GO
-- Shows every day in the database with the hours for each respective station as well as Panels per hour for that day. Specifically to be exported as a CSV into Excel to run Regression
IF OBJECT_ID('pbs_StationHoursReport') IS NOT NULL
   DROP VIEW pbs_StationHoursReport
GO
CREATE VIEW pbs_StationHoursReport
AS
SELECT pbs_AreaProductionRecord.ProductionDate
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Layout'),0) AS Layout
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Cutter'),0) AS Cutter
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Hogger'),0) AS Hogger
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Scrape and Edge Seal 1'),0) AS [S/ES 1]
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Scrape and Edge Seal 2'),0) AS [S/ES 2]
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'QC'),0) AS QC
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Lumber Assistant'),0) AS LumberAssist
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'Lumber Install'),0) AS LumberInstall
, ISNULL(dbo.StationHoursForDay(ProductionDate, 'CA Stickers'),0) AS CAStickers
, dbo.ProductionSpeedForDay(ProductionDate) AS PanelsPerHour
FROM pbs_AreaProductionRecord 
	JOIN pbs_AreaProductionRecordEmployeeList ON pbs_AreaProductionRecord.RecordID = pbs_AreaProductionRecordEmployeeList.RecordID
	JOIN pbs_Station ON pbs_AreaProductionRecordEmployeeList.StationID = pbs_Station.StationID
	WHERE pbs_AreaProductionRecord.AreaID = 3 OR pbs_AreaProductionRecord.AreaID = 4 OR pbs_AreaProductionRecord.AreaID = 5
GROUP BY ProductionDate
GO