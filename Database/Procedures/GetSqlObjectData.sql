
CREATE procedure [dbo].[GetSqlObjectData](@JsonValues NVARCHAR(MAX) = NULL 
                                         ,@debug     BIT = 0   )
AS
  BEGIN
  /***********************************************************************************************
  *                                                                                              *
  *  This allows to generate SQL statements based on Sql configuration (see Sql* tables)         *
  *                                                                                              *
  *  Parameter @JsonValues allows you to provide the query parameters                            *
  *  - ObjectId   : Object Id defined in SqlObject Table                                         *
  *  - ObjectName : Object name defined in SqlObject table                                       *
  *  - LanguageId : LanguageId to be used in translation in the Select Statement                 *
  *  - PageNumber : Number of a page to be displayed insided a grid                              *
  *  - PageSize   : Nomber of rows to be returned                                                *
  *  - AsJson     : If data should be returned as JSON                                           *
  *  - Parameters : Running values parameters                                                    * 
  *  - GridMode   : If returned data should be structure for grid usage                          *
  *                                                                                              *
  *  See example below                                                                           *
  ***********************************************************************************************/
  
  /*
  Example :                                                                                   
  EXEC [GetSqlObjectData] @JsonValues = '{"ObjectId": "1", "GridMode" : "1","LanguageId" : "fr-fr", "PageNumber": "1", "PageSize" : "100", "AsJson" : "1","Parameters" :[{"ParamName" : "LanguageId", "ParamValue" : "fr-fr"}], "SkipParams":[{"ParamName" : "CategoryId"}]}',
                       @debug = 1
  */

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
  DECLARE @ColumnsDef TABLE ( ColumnName        VARCHAR(100)
                             ,ColumnIsKey       BIT
                             ,ColumnIsLocalized BIT
                             ,ColumnDatatype    d_name
                             ,ColumnOrder       d_sequence
                            )                           

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

  DECLARE @ParamValues TABLE (ParamName  VARCHAR(100)
                              ,ParamValue VARCHAR(100))   

  DECLARE @SkipParams TABLE (ParamName  VARCHAR(100))   

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

  IF(@stmt IS NULL)
    BEGIN
      RAISERROR('%s : No Statement can be found for ObjectId [%d] - ObjectName [%s]', 16,-1, @ProcName, @ObjectId, @ObjectName)
      RETURN(1)
    END
    
  IF(@StmtType NOT IN (1,2))
    BEGIN
      RAISERROR('%s: Statement type [%d] is not from the expected type.',16,-1,@ProcName)
      RETURN(1)
    END      

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

  -- Gets the parameters defined for the query and to be ignored
  INSERT INTO @SkipParams(ParamName)
  SELECT ParamName
    FROM dbo.FnGetJsonSkipParameters(@JsonValues)

  IF(@debug = 1)
    BEGIN
      PRINT 'Execute Sql ignoring the folowing parameters'
      DECLARE FTCH_SKIP CURSOR LOCAL FAST_FORWARD READ_ONLY
          FOR SELECT ParamName
                FROM @SkipParams

      OPEN FTCH_SKIP
      FETCH NEXT FROM FTCH_SKIP INTO @ParamName

      WHILE (@@FETCH_STATUS  = 0)
        BEGIN
          PRINT 'Parameter Name : ' + @ParamName 
          FETCH NEXT FROM FTCH_SKIP INTO @ParamName
        END
      CLOSE FTCH_SKIP
      DEALLOCATE FTCH_SKIP
      PRINT @CrLf
    END     
       
    -- table
    IF(@StmtType = 1)
      BEGIN
        IF(OBJECT_ID(@stmt) IS NULL)
          BEGIN
            RAISERROR('%s : Database object [%s] does not exist.',16,-1,@ProcName, @stmt)
            RETURN(1)
          END

        INSERT INTO @ColumnsDef
        SELECT ColumnName      = c.[Name]
              ,IsKey           = IsKey
              ,IsLocalized     = IsLocalized
              ,DataType        = d.Name
              ,OrderSequenceNr = c.OrderSequenceNr
        FROM dbo.SqlColumn c
        JOIN dbo.SqlDatatype d
          ON c.DatatypeId = d.Id
        WHERE c.SourceId = @SourceId
        ORDER BY c.SequenceNr

        SELECT @ColumnsCount = @@ROWCOUNT

        -- Build select
        IF(@ColumnsCount > 0)
          BEGIN
            SELECT @SelectClause = ''
            DECLARE FTCH_DATA CURSOR LOCAL FAST_FORWARD READ_ONLY
                FOR SELECT ColumnName  
                           ,ColumnIsKey       
                           ,ColumnIsLocalized
                           ,ColumnDataType 
                           ,ColumnOrder
                      FROM @ColumnsDef

            OPEN FTCH_DATA
            FETCH NEXT FROM FTCH_DATA INTO @ColumnName, @ColumnIsKey, @ColumnIsLocalized, @ColumnDatatype, @ColumnOrder

            WHILE(@@FETCH_STATUS = 0)
              BEGIN
                SELECT @SelectClause = @SelectClause + ',' + CASE WHEN @ColumnIsLocalized = 1 THEN @ColumnName + ' = dbo.FnGetResource(' + QUOTENAME(@ColumnName) + ',''' + CONVERT(VARCHAR, @LanguageId) + ''')'
                                                                                          ELSE QUOTENAME(@ColumnName)
                                                                                          END

                FETCH NEXT FROM FTCH_DATA INTO @ColumnName, @ColumnIsKey, @ColumnIsLocalized, @ColumnDatatype, @ColumnOrder
              END
    
            CLOSE FTCH_DATA
            DEALLOCATE FTCH_DATA
          END
        ELSE
          BEGIN
            SELECT @SelectClause = ',*'
          END

        SELECT @SelectClause = SUBSTRING(@SelectClause, 2, LEN(@SelectClause) - 1)
        IF(@debug = 1)
          BEGIN
            PRINT 'Select Clause : ' + @SelectClause
          END
        
        -- build parameters
        SELECT @WhereClause = '1 = 1 AND ';

        DECLARE FTCH_PARAM CURSOR LOCAL FAST_FORWARD
            FOR SELECT   Name             = p.Name
                       , DatatypeId       = p.DatatypeId
                       , DefaultValue     = ISNULL(v.ParamValue, p.DefaultValue)
                       , Ddl              = o.Ddl
                       , OpenParenthesis  = o.OpenParenthesis
                       , CloseParenthesis = o.CloseParenthesis
                       , OpenModulo       = o.OpenModulo
                       , CloseModulo      = o.CloseModulo
                  FROM SqlParameter p
                  JOIN SqlOperator o
                    ON o.Id = p.OperatorId
                  LEFT JOIN @ParamValues v
                    ON p.Name = v.ParamName
                  LEFT JOIN @SkipParams s
                    ON s.ParamName = p.Name
                  WHERE p.SourceId = @SourceId
                    AND p.Enabled = 1
                    AND o.Enabled = 1
                    AND s.ParamName IS NULL
                  ORDER BY p.SequenceNr

        OPEN FTCH_PARAM
        FETCH NEXT FROM FTCH_PARAM INTO @ParamName, @ParamDatatypeId, @ParamDefaultValue, @ParamDdl, @ParamOpenParenthesis, 
                                        @ParamCloseParenthesis, @ParamOpenModulo, @ParamCloseModulo
  
        WHILE (@@FETCH_STATUS  = 0)
          BEGIN
            SELECT @ParamCount = @ParamCount + 1;

            SELECT @WhereClause = @WhereClause + QUOTENAME(@ParamName) + ' '
            IF(@ParamDefaultValue IS NULL)
              BEGIN
                SELECT @whereClause = @WhereClause + 'IS NULL'
              END
            ELSE
              BEGIN 
                SELECT @whereClause = @WhereClause + @ParamDdl + ' ' 
                                      + CASE WHEN @ParamOpenParenthesis = 1 THEN '(' ELSE '' END                                
                                      + ''''
                                      + CASE WHEN @ParamOpenModulo = 1 THEN '%' ELSE '' END
                                      -- first convert to base datatype to check if default value is from right datatype
                                      + CASE @ParamDatatypeId WHEN 1 THEN REPLACE(@ParamDefaultValue, '''', '''''')
                                                              WHEN 2 THEN CONVERT(VARCHAR, CONVERT(INT, @ParamdefaultValue))
                                                              WHEN 3 THEN CONVERT(VARCHAR, CONVERT(BIT, @ParamdefaultValue))
                                                              WHEN 4 THEN CONVERT(VARCHAR, CONVERT(FLOAT, REPLACE(@ParamdefaultValue, ',', '.')))
                                                              -- no parameter value as image (Value = 5)
                                                              WHEN 6 THEN CONVERT(VARCHAR, CONVERT(DATETIME, @ParamdefaultValue), 120)
                                                              WHEN 7 THEN CONVERT(VARCHAR, CONVERT(DATE, @ParamdefaultValue), 112)
                                                              WHEN 8 THEN CONVERT(VARCHAR, CONVERT(TIME, @ParamdefaultValue),114)
                                                              ELSE '#ERROR#'
                                                              END
                                      + CASE WHEN @ParamCloseModulo = 1 THEN '%' ELSE '' END
                                      + ''''
                                      + CASE WHEN @ParamCloseParenthesis = 1 THEN '(' ELSE '' END                                                                      
              END

             SELECT @whereClause = @WhereClause + ' AND '
            FETCH NEXT FROM FTCH_PARAM INTO @ParamName, @ParamDatatypeId, @ParamDefaultValue, @ParamDdl, @ParamOpenParenthesis, 
                                            @ParamCloseParenthesis, @ParamOpenModulo, @ParamCloseModulo
          END

          CLOSE FTCH_PARAM
          DEALLOCATE FTCH_PARAM

          IF(@ParamCount > 0)
            BEGIN
              SELECT @WhereClause = ' WHERE ' + RTRIM(LEFT(RTRIM(@WhereClause), LEN(@whereClause) -4));
            END
          ELSE
            BEGIN
              SELECT @WhereClause = ''
            END       
          
          IF(@debug = 1)
            BEGIN
              PRINT 'Where Clause : ' + @WhereClause
            END

      -- build order clause
          SELECT @OrderClause = ''
          DECLARE FTCH_ORDER CURSOR LOCAL FAST_FORWARD
              FOR SELECT ColumnName,
                          ColumnOrder
                    FROM @ColumnsDef
                    WHERE ColumnOrder <> 0
                    ORDER BY ABS(ColumnOrder)

          OPEN FTCH_ORDER
          FETCH NEXT FROM FTCH_ORDER INTO @ColumnName, @ColumnOrder

          WHILE (@@FETCH_STATUS = 0)
            BEGIN
              SELECT @OrderClause = @OrderClause + QUOTENAME(@ColumnName)  + ' ' + CASE WHEN @ColumnOrder > 0 THEN 'ASC' ELSE 'DESC' END + ', '
            
              FETCH NEXT FROM FTCH_ORDER INTO @ColumnName, @ColumnOrder
            END
        
          CLOSE FTCH_ORDER
          DEALLOCATE FTCH_ORDER

          IF(LEN(@OrderClause) > 0)
            BEGIN
              SELECT @OrderClause = ' ORDER BY ' + LEFT(RTRIM(@OrderClause), LEN(RTRIM(@OrderClause)) -1)
            END
          ELSE
            BEGIN
              -- offset-fetch need an order by clause
              IF(@PageNumber > 0 AND @PageSize > 0)
                BEGIN
                  SELECT @OrderClause = ' ORDER BY 1'
                END
            END

          IF(@debug = 1)
            BEGIN
              PRINT 'OrderBy Clause : ' + @OrderClause
            END

        -- build the final statement
          SELECT @sql = 'SELECT ' + @SelectClause + 
                      + @CrLf + ' FROM ' + QUOTENAME(@stmt)
                      + @CrLf + @WhereClause 
                      + @Crlf + @OrderClause
        END
      ELSE
        BEGIN
          SELECT @sql = @stmt

          -- if this is a sql statement only replace value
          SELECT @sql = REPLACE(@sql, '@LanguageId', @LanguageId)

          SELECT @sql = REPLACE(@sql, '@' + ParamName, ParamValue)
            FROM @ParamValues
        END

        SELECT @SqlRowsCount = 'SET @RowsCount = (SELECT COUNT(*) '
                            + @CrLf + ' FROM ' + QUOTENAME(@stmt)
                            + @CrLf + @WhereClause + ')'

        -- Data page request
        --IF(@GridMode = 1 AND @PageNumber > 0 AND @PageSize > 0)
        --  BEGIN
        --    SELECT @sql = @sql + @CrLf 
        --                + ' OFFSET ' + CONVERT(VARCHAR, (@PageNumber -1) * @PageSize ) + ' ROWS FETCH NEXT ' 
        --                + CONVERT(VARCHAR, @PageSize) + ' ROWS ONLY'
        --  END

        -- if requested as json
        IF(@AsJson = 1)
          BEGIN
            SELECT @sql = @sql + @CrLf + ' FOR JSON ' + @JsonType
          END

        IF(@debug = 1)  
          BEGIN
            PRINT @CrLf + 'Final Statement :  ' + @CrLf + @sql
          END

        IF(@AsJson = 1)
          BEGIN
            IF(@GridMode = 1)
              BEGIN
                IF(@debug = 1)
                  BEGIN
                    PRINT @CrLf + 'JSON Grid Mode structure is on' 
                  END
                -- Gets the JSON values
                SELECT @sql = 'SET @JsonResult = (' + @sql + ')'
                IF(@debug = 1)
                  BEGIN
                    PRINT 'Data rows : ' + @sql
                  END
                EXEC sp_executesql @sql, N'@JsonResult NVARCHAR(MAX) OUTPUT', @JsonResult OUTPUT

                -- Gets the total rows count
                IF(@debug = 1)
                  BEGIN
                    PRINT 'Sql for Rows count : ' + @SqlRowsCount
                  END
                EXEC sp_executesql @SqlRowsCount, N'@RowsCount NVARCHAR(MAX) OUTPUT', @RowsCount OUTPUT

                SELECT TotalRows    = @RowsCount
                       ,PageNumber  = CASE WHEN @PageNumber = 0 THEN 1 ELSE @PageNumber END
                       ,PageSize    = @PageSize
                       ,Rows        = @JsonResult
                   FOR JSON PATH
              END
            ELSE
              BEGIN
                IF(@debug = 1)
                  BEGIN
                    PRINT @CrLf + 'JSON Grid Mode structure is off' 
                  END
                EXEC(@sql)
              END
          END
        ELSE
          BEGIN
            EXEC(@sql)
          END
    RETURN(0)
  END
GO


