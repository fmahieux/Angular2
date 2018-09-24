
CREATE PROC [dbo].[GetSpObjectDataResult]( @JsonValues VARCHAR(MAX),
                                          @Orderby    VARCHAR(MAX) = ''
                                         ,@debug INT)
AS
BEGIN

SET NOCOUNT ON 
DECLARE @PageNumber   INT = 0
DECLARE @PageSize     INT = 0
DECLARE @AsJSon       BIT = 0
DECLARE @GridMode     BIT = 0
DECLARE @JsonType     VARCHAR(50)
DECLARE @sql          NVARCHAR(MAX) = '';
DECLARE @SqlRowsCount NVARCHAR(MAX) = '';
DECLARE @JsonResult   NVARCHAR(MAX)
DECLARE @RowsCount    INT
DECLARE @status       INT
DECLARE @CrLf         VARCHAR(1)   = CHAR(13);

SELECT @PageNumber = PageNumber
      ,@PageSize   = PageSize
      ,@AsJson     = AsJson        
      ,@GridMode   = GridMode
      ,@JsonType   = JsonType
  FROM dbo.FnGetJsonDefinition(@JsonValues)

  SELECT @sql = 'SELECT * FROM #data ORDER BY ' + CASE WHEN LTRIM(@OrderBy) = '' THEN '1' ELSE @OrderBy END 
  SELECT @SqlRowsCount = 'SET @RowsCount = (SELECT COUNT(*) FROM #data)'

 IF(@GridMode = 1 AND @PageNumber > 0 AND @PageSize > 0)
      BEGIN
        SELECT @sql = @sql  -- +  ' ORDER BY ' + CASE WHEN LTRIM(@OrderBy) = '' THEN '1' ELSE @OrderBy END 
                    + @CrLf 
                    + ' OFFSET ' + CONVERT(VARCHAR, (@PageNumber -1) * @PageSize ) + ' ROWS FETCH NEXT ' 
                    + CONVERT(VARCHAR, @PageSize) + ' ROWS ONLY'
      END

    IF(@AsJson = 1)
      BEGIN
        IF(@AsJson = 1)
          BEGIN
            SELECT @sql = @sql + @CrLf + ' FOR JSON ' + @JsonType
        
          END

        IF(@debug = 1)  
          BEGIN
            PRINT @CrLf + 'Final Statement :  ' + @CrLf + @sql
          END

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

            ---- Gets the total rows count
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
END
GO


