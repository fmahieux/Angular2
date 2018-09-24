
CREATE proc [dbo].[GetObjectData](@JsonValues NVARCHAR(MAX) = NULL 
                                ,@debug     BIT = 0   )
AS
  BEGIN
      SET NOCOUNT ON;
  DECLARE @ProcName    SYSNAME  = OBJECT_NAME(@@PROCID)
  DECLARE @SourceId    INT
  DECLARE @SourceName  d_name
  DECLARE @StmtType    INT
  DECLARE @status      INT
  DECLARE @Stmt        NVARCHAR(MAX)

  -- Query Parameter
  DECLARE @ObjectId   INT = NULL
  DECLARE @ObjectName d_name = NULL

  -- Gets the parameters into table
  IF(COALESCE(RTRIM(@JsonValues), '') = '')
    BEGIN
      RAISERROR('%s : No Query parameters have been defined.', 16,-1, @ProcName)
      RETURN(1)
    END

  -- Gets the query settings and parameters
  SELECT @ObjectId   = ObjectId
        ,@ObjectName = ObjectName
    FROM dbo.FnGetJsonDefinition(@JsonValues)

  IF(@ObjectId IS NULL AND @ObjectName IS NULL)
    BEGIN
      RAISERROR('%s : Either @ObjectId or @ObjectName parameter should be defined.',16,-1, @ProcName)
      RETURN(1)
    END
                   
  -- Gets the statement
  SELECT @ObjectId    = o.Id
         ,@ObjectName = o.Name
         ,@SourceId   = s.Id
         ,@SourceName = s.Name
         ,@StmtType   = s.SqlSourceTypeId
         ,@Stmt       = s.Statement
    FROM SqlObject o
    JOIN SqlSource s
      ON o.SelectId = s.id
   WHERE (o.Id  = @ObjectId OR @ObjectId IS NULL)
     AND (o.Name = @ObjectName OR @ObjectName IS NULL)

  IF(@debug = 1)
    BEGIN
      PRINT 'Object Id : ' + CONVERT(VARCHAR, @ObjectId) + ' - Name : ' + @ObjectName
      PRINT 'Source Id : ' + CONVERT(VARCHAR, @SourceId) + ' - Name : ' + @SourceName 
    END

  IF(COALESCE(@Stmt, '') = '')
    BEGIN
      RAISERROR('%s: No Statement is defined for Source [%d - %s].', 16,-1,@ProcName, @SourceId, @SourceName)
      RETURN(1)
    END

  -- if table query or stored procedure then database object should exist.
  IF(@StmtType IN (1,3) AND OBJECT_ID(@stmt) IS NULL)
    BEGIN
      RAISERROR('%s : Object [%s] is not a database object.',16,-1,@ProcName, @stmt)
      RETURN(1)
    END
  -- Stored Procedure
  IF(@StmtType IN (1, 2))
    BEGIN
      EXEC @status = dbo.GetSqlObjectData @JsonValues, @debug
      RETURN (@status)
    END

  IF(@StmtType = 3)
    BEGIN
      EXEC @status = dbo.GetSpObjectData @JsonValues, @debug
      RETURN(@status)
    END  

  RAISERROR('%s: Statement type [%d] is not supported.',16,-1, @ProcName, @StmtType)
  RETURN(1)
  END
GO


