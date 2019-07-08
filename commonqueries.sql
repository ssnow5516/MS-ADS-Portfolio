SELECT * FROM pbs_Shift
SELECT * FROM pbs_Employee

-- See Employee with shift listing. 
SELECT LastName, FirstName, ShiftName AS [Shift]
FROM pbs_Employee
JOIN pbs_Shift ON pbs_Employee.ShiftID = pbs_Shift.ShiftID
ORDER BY LastName

-- See Shift Leads
SELECT pbs_Shift.ShiftName
, pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS Lead
FROM pbs_Shift 
JOIN pbs_Employee ON pbs_Shift.LeadOperatorID = pbs_Employee.EmployeeID

-- See Certified Operators
SELECT pbs_Employee.LastName + ', ' + pbs_Employee.FirstName AS Operator,
pbs_Area.AreaName
FROM pbs_AreaCertification 
JOIN pbs_Area ON pbs_Area.AreaID = pbs_AreaCertification.AreaID
JOIN pbs_Employee ON pbs_Employee.EmployeeID = pbs_AreaCertification.EmployeeID
ORDER BY Operator

-- See forklift operators
SELECT pbs_Employee.LastName + ', ' + pbs_Employee.FirstName AS [Forklift Operators]
FROM pbs_Employee
WHERE isForkliftCertified = 1

SELECT COUNT(EmployeeID)
FROM pbs_Employee
WHERE isForkliftCertified = 1

-- A Shift
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 1

-- B Shift
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 2
-- C Shift
SELECT pbs_Employee.FirstName + ' ' + pbs_Employee.LastName AS [Name]
FROM pbs_Employee
WHERE ShiftID = 3