
-- Enable xp_cmdshell to read multiple files
/*
EXEC sp_configure 'show advanced options', 1;  -- To allow advanced options to be changed.  
GO  
RECONFIGURE;  -- To update the currently configured value for advanced options.  
GO  
EXEC sp_configure 'xp_cmdshell', 1;  -- To enable the feature. 
GO  
RECONFIGURE;  -- To update the currently configured value for this feature.  
GO 
*/

--BULK INSERT MULTIPLE FILES From a Folder 

    --a table to loop thru filenames drop table ALLFILENAMES
	DROP TABLE IF EXISTS ALLFILENAMES
    CREATE TABLE ALLFILENAMES(WHICHPATH VARCHAR(255),WHICHFILE varchar(255))

    --some variables
    DECLARE @filename varchar(255),
            @path     varchar(255),
            @sql      varchar(8000),
            @cmd      varchar(1000)


    --get the list of files to process:
    SET @path = 'G:\NOAA\DailyWeatherApp\Data\'
    SET @cmd = 'dir ' + @path + '*.txt /b'
    INSERT INTO  ALLFILENAMES(WHICHFILE)
    EXEC Master..xp_cmdShell @cmd
    UPDATE ALLFILENAMES SET WHICHPATH = @path where WHICHPATH is null

	DELETE FROM ALLFILENAMES WHERE WHICHFILE IS NULL
	--SELECT * FROM ALLFILENAMES

	DROP TABLE IF EXISTS [NOAA].dbo.DegreeDaysCDD
	CREATE TABLE [NOAA].dbo.DegreeDaysCDD (ObservationId INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
								,ObservationDate DATE NOT NULL
								, ClimateDivisionId INT NOT NULL
								, Cooling INT)

    --cursor loop
    DECLARE c1 CURSOR FOR SELECT WHICHPATH,WHICHFILE FROM ALLFILENAMES WHERE WHICHFILE LIKE '%.txt%' AND WHICHFILE LIKE '%.Cooling%'
    OPEN c1
    FETCH NEXT FROM c1 INTO @path,@filename
    While @@fetch_status <> -1
      BEGIN

	  -- Read dates as string
		DROP TABLE IF EXISTS #ColNameString
		CREATE TABLE #ColNameString (ColNameString varchar(max));
		
		--bulk insert won't take a variable name, so make a sql and execute it instead:
		SET @sql = 'BULK INSERT #ColNameString FROM ''' + @path + @filename + ''' '
					+ 'WITH
					(
						FIRSTROW = 4,
						LASTROW = 4,
						FORMATFILE = ''G:\NOAA\DailyWeatherApp\SQL\Formats\ClimateDivisionsDegreeDaysDates.fmt''
					) '
		PRINT @sql
		EXEC (@sql)

		-- Remove cariage return at the end. This is need if auto downloading files
		UPDATE #ColNameString
		SET ColNameString = REPLACE(ColNameString,char(13),'')

		-- Separate date string into rows
		DROP TABLE IF EXISTS #StringDates
		CREATE TABLE #StringDates (Dates varchar(max));

		INSERT INTO #StringDates
		SELECT CAST(value AS date) as 'ObservationDate' 
		FROM STRING_SPLIT((select * from #ColNameString), '|')
		WHERE LEN(value) = 8
		ORDER BY ObservationDate

		DROP TABLE IF EXISTS #ColNameString

		-- Convert ObservationDate strings to dates
		DROP TABLE IF EXISTS #ObsDates
		CREATE TABLE #ObsDates (ObservationDate DATE, ObsDateRowNum INT);

		INSERT INTO #ObsDates (ObservationDate)
		SELECT CAST(Dates AS DATE) AS 'ObservationDate' FROM #StringDates
		ORDER BY CAST(Dates AS DATE)

		DROP TABLE IF EXISTS #StringDates


		-- Read the observation rows
		DROP TABLE IF EXISTS #Obs
		CREATE TABLE #Obs (ClimateDivisionId integer, ObsString varchar(max), ClimateDivRowNum INT);

		SET @sql = 'BULK INSERT #Obs FROM ''' + @path + @filename + ''' '
					+ 'WITH
					(
						FIRSTROW = 2,
						FORMATFILE = ''G:\NOAA\DailyWeatherApp\SQL\Formats\ClimateDivisionsDegreeDays.fmt''
					) '
		PRINT @sql
		EXEC (@sql)

		UPDATE #Obs
		SET ClimateDivRowNum = t.ClimateDivRowNum
		FROM #Obs o
		LEFT JOIN (
			SELECT ClimateDivisionId
				   ,ROW_NUMBER() OVER (ORDER BY ClimateDivisionId) AS 'ClimateDivRowNum'
			FROM #Obs
		) AS t on o.ClimateDivisionId = t.ClimateDivisionId


		-- Remove cariage return at the end. This is need if auto downloading files
		UPDATE #Obs
		SET ObsString = REPLACE(ObsString,CHAR(13),'')

		--ALTER TABLE #ObsDates
		--ADD ObsDateRowNum INT;

		UPDATE #ObsDates
		SET ObsDateRowNum = t.ObsDateRowNum
		FROM #ObsDates o
		LEFT JOIN (
			SELECT ObservationDate
				   ,ROW_NUMBER() OVER (ORDER BY ObservationDate) AS 'ObsDateRowNum'
			FROM #ObsDates
		) AS t on o.ObservationDate = t.ObservationDate


		-- Loop over ClimateDivisions and parse observation string into rows
		DECLARE @LoopCounter INT = 1
		WHILE ( @LoopCounter <= (SELECT COUNT(ObsString) FROM #Obs))
		BEGIN
			DROP TABLE IF EXISTS #CurClimateDiv
			CREATE TABLE #CurClimateDiv (ObsDateRowNum INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,  ClimateDivisionId INT, CDD INT);

			INSERT INTO #CurClimateDiv (ClimateDivisionId, CDD)
			SELECT --ROW_NUMBER() OVER (ORDER BY value) AS 'ObsDateRowNum' 
					(	SELECT ClimateDivisionId
						FROM #Obs
						WHERE ClimateDivRowNum = @LoopCounter
					) AS 'ClimateDivisionId'
					,value as 'CDD'
			FROM STRING_SPLIT(
								(
								SELECT ObsString 
								FROM (
									 SELECT * 
									 FROM #Obs
									 ) it 
								WHERE ClimateDivRowNum = @LoopCounter
								), '|') obs


			INSERT INTO [NOAA].dbo.DegreeDaysCDD (ObservationDate, ClimateDivisionId, Cooling)
			SELECT ObservationDate
				   ,ClimateDivisionId
				   ,CDD AS 'Cooling'
			FROM #CurClimateDiv obs
			LEFT JOIN #ObsDates od ON obs.ObsDateRowNum = od.ObsDateRowNum
			ORDER BY ObservationDate

			--DROP TABLE IF EXISTS #CurClimateDiv
			SET @LoopCounter  = @LoopCounter  + 1
		END


      FETCH NEXT FROM c1 INTO @path,@filename
      END
    CLOSE c1
    DEALLOCATE c1

	GO
	CREATE INDEX DateClimateDiv_idx
	ON [NOAA].dbo.DegreeDaysCDD (ObservationDate, ClimateDivisionId);

	--DROP TABLE IF EXISTS select * from #Obs
	--DROP TABLE IF EXISTS  select * from #ObsDates
	--DROP TABLE IF EXISTS ALLFILENAMES