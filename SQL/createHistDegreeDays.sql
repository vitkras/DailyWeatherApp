
USE [NOAA]

DROP TABLE IF EXISTS dbo.DegreeDays
CREATE TABLE dbo.DegreeDays (ObservationId INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
							,ObservationDate DATE NOT NULL
							,ClimateDivisionId INT NOT NULL
							,Cooling INT
							,Heating INT)

INSERT INTO dbo.DegreeDays
SELECT COALESCE(c.ObservationDate, h.ObservationDate)
	   ,COALESCE(c.ClimateDivisionId, h.ClimateDivisionId)
	   ,c.Cooling
	   ,h.Heating
FROM dbo.DegreeDaysCDD c
INNER JOIN dbo.DegreeDaysHDD h ON c.ClimateDivisionId = h.ClimateDivisionId
								AND c.ObservationDate = h.ObservationDate
ORDER BY COALESCE(c.ObservationDate, h.ObservationDate), COALESCE(c.ClimateDivisionId, h.ClimateDivisionId)

CREATE INDEX ObservationDate_idx 
ON dbo.DegreeDays (ObservationDate);

CREATE INDEX ClimateDivisonsId_idx 
ON dbo.DegreeDays (ClimateDivisionId);

CREATE INDEX DateClimateDiv_idx 
ON dbo.DegreeDays (ObservationDate, ClimateDivisionId);

ALTER TABLE dbo.DegreeDays
ADD FOREIGN KEY (ClimateDivisionId) REFERENCES dbo.ClimateDivisions(ClimateDivisionId)

DROP TABLE IF EXISTS dbo.DegreeDaysCDD
DROP TABLE IF EXISTS dbo.DegreeDaysHDD


-- Update dbo.DegreeDays table derived daily temperature avg
ALTER TABLE NOAA.dbo.DegreeDays 
ADD Temperature int;
GO

UPDATE NOAA.dbo.DegreeDays 
SET NOAA.dbo.DegreeDays.Temperature = t.Temperature
FROM NOAA.dbo.DegreeDays dd
INNER JOIN (
			SELECT ObservationId
				 , Cooling
				 , Heating
				 , CAST(CASE
				  	 WHEN Heating > 0 THEN 65 - Heating
					 WHEN Cooling > 0 THEN 65 + Cooling
					 ELSE 65
				   END AS INT) AS 'Temperature'
			FROM [NOAA].dbo.DegreeDays
		) AS t ON t.ObservationId = dd.ObservationId