-- Login and User Creation. Generated Scripts from SSMS
USE [master]
GO
CREATE LOGIN [pbsProjects] WITH PASSWORD=N'123456' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
USE [PBS]
GO
CREATE USER [pbsProjects] FOR LOGIN [pbsProjects]
GO

USE [master]
GO
CREATE LOGIN [pbsProduction] WITH PASSWORD=N'123456' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
USE [PBS]
GO
CREATE USER [pbsProduction] FOR LOGIN [pbsProduction]
GO

USE [master]
GO
CREATE LOGIN [pbsManagement] WITH PASSWORD=N'123456' MUST_CHANGE, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
GO
USE [PBS]
GO
CREATE USER [pbsManagement] FOR LOGIN [pbsManagement]
GO

-- GRANTS for each User

-- Project Management can view Job related reports as well as add new jobs and enter closing information for post production jobs.
GRANT SELECT ON pbs_CompletedJobs TO pbsManagement	
GRANT SELECT ON pbs_InProduction TO pbsManagement
GRANT SELECT ON pbs_PreProduction	TO pbsManagement
GRANT SELECT ON pbs_OnHold		TO pbsManagement
GRANT SELECT ON pbs_JobHoursSummary	TO pbsProject
GRANT EXECUTE ON TotalJobHours	TO pbsProject
GRANT EXECUTE ON pbs_addNewJob	TO pbsProject
GRANT EXECUTE ON pbs_CompleteJob TO pbsProject

-- Production leadership can view job reports related to production, can execute job-production related functions and can execute functions to add new records.
GRANT SELECT ON pbs_FullRoster	TO pbsProduction
GRANT SELECT ON pbs_ShiftLeads	TO pbsProduction
GRANT SELECT ON pbs_CertifiedOperators		TO pbsProduction
GRANT SELECT ON pbs_ForkliftOperators		TO pbsProduction
GRANT SELECT ON pbs_AShift		TO pbsProduction
GRANT SELECT ON pbs_BShift		TO pbsProduction
GRANT SELECT ON pbs_CShift		TO pbsProduction
GRANT SELECT ON pbs_CompletedJobs TO pbsProduction
GRANT SELECT ON pbs_InProduction TO pbsProduction
GRANT SELECT ON pbs_PreProduction	TO pbsProduction
GRANT SELECT ON pbs_OnHold		TO pbsProduction
GRANT SELECT ON pbs_StationHoursReport	TO pbsProduction 
GRANT SELECT ON pbs_JobHoursSummary	TO pbsProduction
GRANT EXECUTE ON TotalJobHours	TO pbsProduction
GRANT EXECUTE ON StationHoursForDay	TO pbsProduction
GRANT EXECUTE ON ProductionSpeedForDay  TO pbsProduction
GRANT EXECUTE ON pbs_addNewRecord	TO pbsProduction
GRANT EXECUTE ON pbs_addNewJobRecord	TO pbsProduction
GRANT EXECUTE ON pbs_addNewRecordEmployee TO pbsProduction


-- upper level management has access to all views, external functions and procedures
GRANT SELECT ON pbs_FullRoster	TO pbsManagement
GRANT SELECT ON pbs_ShiftLeads	TO pbsManagement
GRANT SELECT ON pbs_CertifiedOperators		TO pbsManagement
GRANT SELECT ON pbs_ForkliftOperators		TO pbsManagement
GRANT SELECT ON pbs_AShift		TO pbsManagement
GRANT SELECT ON pbs_BShift		TO pbsManagement
GRANT SELECT ON pbs_CShift		TO pbsManagement
GRANT SELECT ON pbs_CompletedJobs TO pbsManagement	
GRANT SELECT ON pbs_InProduction TO pbsManagement
GRANT SELECT ON pbs_PreProduction	TO pbsManagement
GRANT SELECT ON pbs_OnHold		TO pbsManagement
GRANT SELECT ON pbs_StationHoursReport	TO pbsManagement
GRANT SELECT ON pbs_JobHoursSummary	TO pbsManagement
GRANT SELECT ON pbs_JobCorrelationSummary	TO pbsManagement
GRANT SELECT ON pbs_viewCompletedJobSummary	TO pbsManagement
GRANT EXECUTE ON TotalJobHours	TO pbsManagement
GRANT EXECUTE ON StationHoursForDay	TO pbsManagement
GRANT EXECUTE ON ProductionSpeedForDay  TO pbsManagement
GRANT EXECUTE ON pbs_CompleteJob	TO pbsManagement
GRANT EXECUTE ON pbs_addNewRecord	TO pbsManagement
GRANT EXECUTE ON pbs_addNewJobRecord	TO pbsManagement
GRANT EXECUTE ON pbs_addNewRecordEmployee	TO pbsManagement
GRANT EXECUTE ON pbs_addNewEmployee	TO pbsManagement
GRANT EXECUTE ON pbs_certifyEmployee	TO pbsManagement
GRANT EXECUTE ON pbs_addNewForkLiftCert	TO pbsManagement
GRANT EXECUTE ON pbs_addNewJob	TO pbsManagement

-- Currently no procedure for removing an employee who was terminated or left
GRANT EXECUTE ON getEmpID TO pbsManagement
GRANT DELETE ON pbs_Employee to pbsManagement


-- veiws all objects to assign user levels.
SELECT  *
FROM sys.objects
WHERE   type = 'V' OR type = 'FN' OR type = 'P' OR type = 'AF'