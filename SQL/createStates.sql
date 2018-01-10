
-- Create order: dbo.States, dbo.CensusDivisions, dbo.ClimateDivisions

USE [NOAA]

-- Read States data
DROP TABLE IF EXISTS #dataTMP
CREATE TABLE #dataTMP (Abbreviation char(2), Name varchar(20));

GO
BULK
INSERT #dataTMP
FROM 'G:\NOAA\DailyWeatherApp\Data\StatesCONUS.txt'
WITH
(
	FIRSTROW = 2,
	FORMATFILE = 'G:\NOAA\DailyWeatherApp\SQL\Formats\StatesCONUS.fmt'
)
GO

select * from #dataTMP


-- create dbo.States
DROP TABLE IF EXISTS NOAA.dbo.States
Create Table NOAA.dbo.States
(
  Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
  ,Abbreviation char(2) NOT NULL
  ,Name varchar(20) NOT NULL
  --,CensusDivisionId INT
)

INSERT INTO NOAA.dbo.States (Abbreviation, Name)
SELECT Abbreviation, Name
FROM #dataTMP
ORDER BY Abbreviation, Name