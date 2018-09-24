CREATE proc [dbo].[GetSpObjectData](@JsonValues NVARCHAR(MAX) = NULL 
                            ,@debug     BIT = 0   )
AS
  BEGIN
  SET NOCOUNT ON;
  DECLARE @ProcName     SYSNAME  = OBJECT_NAME(@@PROCID)
  DECLARE @sql          NVARCHAR(MAX) = '';
  DECLARE @SqlRowsCount NVARCHAR(MAX) = '';
  DECLARE @SelectClause NVARCHAR(MAX) = '';
  DECLARE @WhereClause  NVARCHAR(MAX) = '';
  DECLARE @OrderClause  NVARCHAR(MAX) = '';
  DECLARE @SourceId     INT
  DECLARE @stmt         NVARCHAR(MAX)
  DECLARE @StmtType    INT
  DECLARE @CrLf         VARCHAR(1)   = CHAR(13);
  DECLARE @JsonResult   NVARCHAR(MAX)
  DECLARE @RowsCount    INT
  DECLARE @status       INT

  -- Query Parameter
  DECLARE @ObjectId   INT = NULL
  DECLARE @ObjectName VARCHAR(100) = NULL
  DECLARE @PageNumber INT = 0
  DECLARE @PageSize   INT = 0
  DECLARE @AsJSon     BIT = 0
  DECLARE @LanguageId VARCHAR(6) = 'fr-fr'
  DECLARE @GridMode   BIT = 0
  DECLARE @JsonType   VARCHAR(50)

  -- Columns
  DECLARE @ColumnsCount      INT = 0;
  DECLARE @ColumnName        VARCHAR(100)
  DECLARE @ColumnIsKey       BIT
  DECLARE @ColumnIsLocalized BIT
  DECLARE @ColumnDatatype    d_name
  DECLARE @ColumnOrder       d_sequence

  -- Parameters
  DECLARE @ParamCount             INT  = 0
  DECLARE @ParamName              VARCHAR(100)
  DECLARE @ParamDatatypeiD        INT
  DECLARE @ParamValue             NVARCHAR(MAX)
  DECLARE @ParamDefaultValue      NVARCHAR(MAX)
  DECLARE @ParamDdl               VARCHAR(50)
  DECLARE @ParamOpenParenthesis   BIT
  DECLARE @ParamCloseParenthesis  BIT
  DECLARE @ParamOpenModulo        BIT
  DECLARE @ParamCloseModulo       BIT

  DECLARE @flag_lang              BIT = 0

  DECLARE @ParamValues TABLE (ParamName  VARCHAR(100)
                              ,ParamValue VARCHAR(100))   

  DECLARE @SpParams TABLE (ParamName    SYSNAME,
                           SystemTypeId INT)

  -- Gets the parameters into table
  IF(COALESCE(RTRIM(@JsonValues), '') = '')
    BEGIN
      RAISERROR('%s : No Query parameters have been defined.', 16,-1, @ProcName)
      RETURN(1)
    END

  -- Gets the query settings and parameters
  SELECT @ObjectId   = ObjectId
        ,@ObjectName = ObjectName
        ,@PageNumber = PageNumber
        ,@PageSize   = PageSize
        ,@AsJson     = AsJson
        ,@LanguageId = LanguageId
        ,@GridMode   = GridMode
    FROM dbo.FnGetJsonDefinition(@JsonValues)

  IF(@ObjectId IS NULL AND @ObjectName IS NULL)
    BEGIN
      RAISERROR('%s : Either @ObjectId or @ObjectName parameter should be defined.',16,-1, @ProcName)
      RETURN(1)
    END
               
  -- Gets the statement
  SELECT @stmt       = Statement
         ,@SourceId  = s.Id
         ,@StmtType = SqlSourceTypeId
         ,@JsonType   = ForJson
    FROM SqlObject o
    JOIN SqlSource s
      ON o.SelectId = s.id
   WHERE (o.Id  = @ObjectId OR @ObjectId IS NULL)
     AND (o.Name = @ObjectName OR @ObjectName IS NULL)

  IF(@debug = 1)
    BEGIN
      PRINT 'Database Object : ' + @stmt
    END
      
  -- Gets the Stored Procedure parameters
  SELECT @sql = 'SELECT name = REPLACE(name, ''@'', '''')
                        , system_type_id
                   FROM sys.parameters
                  WHERE object_id = OBJECT_ID(''' + @stmt + ''')'

  INSERT INTO @SpParams(ParamName, SystemTYpeId)
  EXEC(@sql)

  SELECT @RowsCount = @@ROWCOUNT

  IF(NOT EXISTS(SELECT 1 from @SpParams WHERE ParamName IN ('JsonValues', 'debug')))
    BEGIN
      RAISERROR('%s : Parameters [@JsonValues] and [@debug] are expected into database object [%s] parameters interface.',16,-1,@ProcName, @stmt)
      RETURN(1)
    END


  SELECT @sql  = 'EXEC ' + @stmt + ' '
  
  IF(@RowsCount > 0)
    BEGIN
      -- Gets the Parameters      
      INSERT INTO @ParamValues(ParamName, ParamValue)
      SELECT ParamName
           , ParamValue 
        FROM dbo.FnGetJsonParameters(@JsonValues) 

      IF(@debug = 1)
        BEGIN
          PRINT 'Execute Sql with these running values'
          DECLARE FTCH_PARAM CURSOR LOCAL FAST_FORWARD READ_ONLY
              FOR SELECT ParamName
                         ,ParamValue
                    FROM @ParamValues

          OPEN FTCH_PARAM
          FETCH NEXT FROM FTCH_PARAM INTO @ParamName, @ParamValue

          WHILE (@@FETCH_STATUS  = 0)
            BEGIN
              PRINT 'Parameter Name : ' + @ParamName + ' - Parameter Value : ' + @ParamValue
              FETCH NEXT FROM FTCH_PARAM INTO @ParamName, @ParamValue
            END
          CLOSE FTCH_PARAM
          DEALLOCATE FTCH_PARAM
          PRINT @CrLf
        END


      SELECT @ParamCount = 0
      DECLARE FTCH_DATA CURSOR LOCAL FAST_FORWARD READ_ONLY
          FOR SELECT p.ParamName,
                     p.ParamValue
                FROM @ParamValues p
                JOIN @SpParams sp
                  ON p.ParamName = sp.ParamName
      OPEN FTCH_DATA
      FETCH NEXT FROM FTCH_DATA INTO @ParamName, @ParamValue

      WHILE(@@FETCH_STATUS  = 0)
        BEGIN
          SELECT @sql = @sql + '@' + @ParamName + ' = ''' + @ParamValue + ''',',
                 @ParamCount = @ParamCount + 1
          
          IF(@ParamName = '@LanguageId')
            SELECT @flag_lang = 1

          FETCH NEXT FROM FTCH_DATA INTO @ParamName, @ParamValue
        END

      CLOSE FTCH_DATA
      DEALLOCATE FTCH_DATA

      SELECT @JsonValues = (SELECT PageNumber = @PageNumber
                                   ,PageSize  = @PageSize
                                   ,AsJson    = CONVERT(VARCHAR, @AsJson) 
                                   ,GridMode  = CONVERT(VARCHAR, @GridMode)
                                   ,JsonType  = @JsonType
                               FOR JSON PATH)

      IF(@flag_lang = 0 AND EXISTS(SELECT 1 FROM @SpParams WHERE ParamName = 'LanguageId'))
        BEGIN
          SELECT @sql = @sql + '@LanguageId =''' + @LanguageId + ''','
        END
      SELECT @sql = @sql + '@JsonValues =''' + CONVERT(VARCHAR(MAX),SUBSTRING(@JsonValues, 2, LEN(@JsonValues)-2)) + ''','
      SELECT @sql = @sql + '@debug =''' + CONVERT(VARCHAR, @debug) + ''''
    END  

    IF(@debug = 1)
      BEGIN
        PRINT 'Final Statement : ' + @sql
      END
    
    EXEC (@sql)
    RETURN(0)
  END
GO


