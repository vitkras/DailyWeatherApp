
USE [NOAA]

-- Read climate divisions data
DROP TABLE IF EXISTS #dataTMP
CREATE TABLE #dataTMP (State char(2)
						,CD int
						,Name varchar(50)
						,Id int);

GO
BULK
INSERT #dataTMP
FROM 'G:\NOAA\DailyWeatherApp\Data\ClimateDivisions.txt'
WITH
(
	FIRSTROW = 2,
	FORMATFILE = 'G:\NOAA\DailyWeatherApp\SQL\Formats\ClimateDivisions.fmt'
)
GO

select * from #dataTMP


-- create dbo.ClimateDivisions table
DROP TABLE IF EXISTS NOAA.dbo.ClimateDivisions
CREATE TABLE NOAA.dbo.ClimateDivisions
(
	Id INT NOT NULL PRIMARY KEY CLUSTERED
	,Name VARCHAR(50) NOT NULL
	,StateId INT NOT NULL
	,CensusDivisionId INT NOT NULL
)

INSERT INTO NOAA.dbo.ClimateDivisions (Id, Name, StateId, CensusDivisionId)
SELECT dat.Id AS 'Id', dat.Name, s.Id AS 'StateId', s.CensusDivisionId AS 'CensusDivisionId'
FROM #dataTMP dat
LEFT JOIN NOAA.dbo.States s on dat.State=s.Abbreviation
ORDER BY dat.Id

ALTER TABLE NOAA.dbo.ClimateDivisions
ADD FOREIGN KEY (StateId) REFERENCES NOAA.dbo.States(Id)

ALTER TABLE NOAA.dbo.ClimateDivisions
ADD FOREIGN KEY (CensusDivisionId) REFERENCES NOAA.dbo.CensusDivisions(Id)

-- Index dbo.ClimateDivisions on StateId and CensusDivisionId 
DROP INDEX IF EXISTS dbo.ClimteDivisions.CensusDivisionId;
CREATE INDEX CensusDivisionId
ON NOAA.dbo.ClimateDivisions (CensusDivisionId);

DROP INDEX IF EXISTS dbo.ClimteDivisions.StateId;
CREATE INDEX StateId
ON NOAA.dbo.ClimateDivisions (StateId);