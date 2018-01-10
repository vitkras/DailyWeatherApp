USE [NOAA]

-- Read Census Divisions data
DROP TABLE IF EXISTS #dataTMP
CREATE TABLE #dataTMP (StateAbbreviation char(2)
						, StateName varchar(20)
						, Id int
						, CensusDivisionName varchar(20));

GO
BULK
INSERT #dataTMP
FROM 'G:\NOAA\DailyWeatherApp\Data\StatesCONUS-CensusDivisions.txt'
WITH
(
	FIRSTROW = 2,
	FORMATFILE = 'G:\NOAA\DailyWeatherApp\SQL\Formats\StatesCONUS-CensusDivisions.fmt'
)
GO

select * from #dataTMP




-- Create CensusDivisions table
DROP TABLE IF EXISTS NOAA.dbo.CensusDivisions
Create Table NOAA.dbo.CensusDivisions
(
  Id INT NOT NULL PRIMARY KEY CLUSTERED
  ,Name varchar(20) NOT NULL
)

INSERT INTO NOAA.dbo.CensusDivisions (Id, Name)
SELECT DISTINCT(Id), CensusDivisionName
FROM #dataTMP
ORDER BY Id



-- Update dbo.States table with CensusDivisionId
ALTER TABLE NOAA.dbo.States 
ADD CensusDivisionId int;

UPDATE NOAA.dbo.States 
SET NOAA.dbo.States.CensusDivisionId = cd.Id
FROM NOAA.dbo.States s
LEFT JOIN #dataTMP AS cd ON s.Abbreviation=cd.StateAbbreviation

ALTER TABLE NOAA.dbo.States
ALTER COLUMN Id int NOT NULL

ALTER TABLE NOAA.dbo.States
ADD FOREIGN KEY (CensusDivisionId) REFERENCES NOAA.dbo.CensusDivisions(Id)

-- Index dbo.States on CensusDivisionsId (nonclustered)
DROP INDEX IF EXISTS dbo.States.CensusDivisionId_idx
CREATE INDEX CensusDivisionId_idx
ON NOAA.dbo.States (CensusDivisionId);