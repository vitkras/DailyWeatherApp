USE [NOAA]
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetObservations](@CensusDivisionId int=NULL
											 , @StateName varchar(20)=NULL
											 , @startDate date
											 , @endDate date)
AS
BEGIN

	IF @CensusDivisionId IS NULL AND @StateName IS NULL
		SELECT ObservationDate
				, AVG(Cooling + 0.0) AS 'CDD'
				, AVG(Heating + 0.0) AS 'HDD'
				, AVG(Temperature + 0.0) AS 'Temp'
		FROM [NOAA].dbo.DegreeDays 
			WHERE ObservationDate BETWEEN @startDate AND @endDate	
		GROUP BY ObservationDate
		ORDER BY ObservationDate

	ELSE IF @StateName IS NOT NULL
		SELECT dd.ClimateDivisionId
				, AVG(Cooling + 0.0) AS 'CDD'
				, AVG(Heating + 0.0) AS 'HDD'
				, AVG(Temperature + 0.0) AS 'Temp'
		FROM [NOAA].dbo.DegreeDays dd
		LEFT JOIN [NOAA].dbo.ClimateDivisions cd ON dd.ClimateDivisionId = cd.Id
		INNER JOIN [NOAA].[dbo].[States] s ON cd.StateId = s.Id
		WHERE ObservationDate BETWEEN @startDate AND @endDate	
			AND s.Name = @StateName
		GROUP BY dd.ClimateDivisionId
		ORDER BY ClimateDivisionId

	ELSE
		SELECT dd.ClimateDivisionId
				, AVG(Cooling + 0.0) AS 'CDD'
				, AVG(Heating + 0.0) AS 'HDD'
				, AVG(Temperature + 0.0) AS 'Temp'
		FROM [NOAA].dbo.DegreeDays dd
		LEFT JOIN [NOAA].dbo.ClimateDivisions cd ON dd.ClimateDivisionId = cd.Id
		WHERE ObservationDate BETWEEN @startDate AND @endDate	
			AND cd.CensusDivisionId = @CensusDivisionId 
		GROUP BY dd.ClimateDivisionId
		ORDER BY ClimateDivisionId

END