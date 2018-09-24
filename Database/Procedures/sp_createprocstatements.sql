create PROCEDURE [dbo].[sp_createprocstatements] (@table      sysname,
                                          @operation                    INT = 1)

AS

-- ************************************************************************************************************
-- * Purpose: Generate Stored Procedures(sp_create_ecptemplate adaptation)                                    *
-- *                                                                                                          *
-- * Inputs:                                                                                                  *
-- *          @table         = Table to create stored procedure from                                          *
-- *          @operation     = 1 -> select statement                                                          *
-- *                           2 -> Update/insert statement                                                   *
-- *                           3 -> Delete Statement                                                          *
-- *                           4 -> Purge Statement (cascading delete)                                        *
-- *          @project       = name of project to add in name of generated proc                               *
-- *          @script_binary_checksum_ind       = need for concurrency check on operation 2 of generated proc *
-- *          @script_username_ind              = username to be used as parameter in generated proc          *
-- *          @output_audit_info_ind            = return audit information after insert/update to caller      *
-- * Returns: Stored Procedure Script                                                                         *
-- *                                                                                                          *
-- * Notes:   Audit columns have to be placed at the end of table columns                                     *
--            definition                                                                                      *
-- ************************************************************************************************************

-- declare error/debug variables
   DECLARE @proc_name   sysname         -- procedure name
   DECLARE @status      INT             -- return status
   DECLARE @error       INT             -- saved error context
   DECLARE @rowcount    INT             -- saved rowcount context
   DECLARE @msg         VARCHAR(4000)   -- error message text

-- initialise error/debug variables
   SELECT @proc_name = OBJECT_NAME( @@PROCID ),
          @status    = 0,
          @error     = 0,
          @rowcount  = 0

-- declare local variables
declare @project                      VARCHAR(128) = NULL
declare @script_binary_checksum_ind   TINYINT = 0
declare @script_username_ind          TINYINT = 0
declare @output_audit_info_ind        TINYINT = 0
DECLARE @header               CHAR(4096)
DECLARE @column               sysname
DECLARE @pktable              sysname
DECLARE @fktable              sysname
DECLARE @pkcolumn             sysname
DECLARE @fkcolumn             sysname
DECLARE @fkkey                sysname
DECLARE @sp_proc_name         sysname
DECLARE @type                 sysname
DECLARE @basetype             sysname
DECLARE @loop                 INT
DECLARE @length               INT
DECLARE @usertype             INT
DECLARE @table_id             INT
DECLARE @full_table_name      VARCHAR(255) 
DECLARE @autoval              INT
DECLARE @nullable             INT
DECLARE @len                  INT
DECLARE @fkcount              INT
DECLARE @where                VARCHAR(1000)
DECLARE @innerwhere           VARCHAR(1000)
DECLARE @list                 VARCHAR(1000)
DECLARE @valuelist            VARCHAR(1000)
DECLARE @valueliststr         VARCHAR(8000)
DECLARE @stamp                INT
DECLARE @width                INT
DECLARE @flag                 INT
DECLARE @start                INT
DECLARE @pos                  INT
DECLARE @found                INT
DECLARE @fixed_param1         VARCHAR(100)
DECLARE @col                  INT
DECLARE @audit_col            INT
DECLARE @prec                 INT
DECLARE @scale                INT
DECLARE @msg2                 VARCHAR(4000)     -- error message text
DECLARE @identcol             sysname
DECLARE @projectfromtable     VARCHAR(100)
DECLARE @restofprocname       VARCHAR(255)
DECLARE @deleteorder          INT
DECLARE @firstfield           INT
DECLARE @table_nameid         VARCHAR(255)

CREATE TABLE #fkeysall(
                       rkeyid  int NOT NULL,
                       rkey1   int NOT NULL,
                       rkey2   int NOT NULL,
                       rkey3   int NOT NULL,
                       rkey4   int NOT NULL,
                       rkey5   int NOT NULL,
                       rkey6   int NOT NULL,
                       rkey7   int NOT NULL,
                       rkey8   int NOT NULL,
                       rkey9   int NOT NULL,
                       rkey10  int NOT NULL,
                       rkey11  int NOT NULL,
                       rkey12  int NOT NULL,
                       rkey13  int NOT NULL,
                       rkey14  int NOT NULL,
                       rkey15  int NOT NULL,
                       rkey16  int NOT NULL,
                       fkeyid  int NOT NULL,
                       fkey1   int NOT NULL,
                       fkey2   int NOT NULL,
                       fkey3   int NOT NULL,
                       fkey4   int NOT NULL,
                       fkey5   int NOT NULL,
                       fkey6   int NOT NULL,
                       fkey7   int NOT NULL,
                       fkey8   int NOT NULL,
                       fkey9   int NOT NULL,
                       fkey10  int NOT NULL,
                       fkey11  int NOT NULL,
                       fkey12  int NOT NULL,
                       fkey13  int NOT NULL,
                       fkey14  int NOT NULL,
                       fkey15  int NOT NULL,
                       fkey16  int NOT NULL,
                       constid int NOT NULL,
                       name    sysname NOT NULL
                      )
    
CREATE TABLE #fkeys(
                     pktable_id int NOT NULL,
                     pkcolid    int NOT NULL,
                     fktable_id int NOT NULL,
                     fkcolid    int NOT NULL,
                     KEY_SEQ    smallint NOT NULL,
                     fk_id      int NOT NULL,
                     PK_NAME    sysname NOT NULL
                    )
    
CREATE TABLE #fkeysout(
                       PKTABLE_QUALIFIER sysname NULL,
                       PKTABLE_OWNER     sysname NULL,
                       PKTABLE_NAME      sysname NOT NULL,
                       PKCOLUMN_NAME     sysname NOT NULL,
                       FKTABLE_QUALIFIER sysname NULL,
                       FKTABLE_OWNER     sysname NULL,
                       FKTABLE_NAME      sysname NOT NULL,
                       FKCOLUMN_NAME     sysname NOT NULL,
                       KEY_SEQ           smallint NOT NULL,
                       UPDATE_RULE       smallint NULL,
                       DELETE_RULE       smallint NULL,
                       FK_NAME           sysname NULL,
                       PK_NAME           sysname NULL,
                       DEFERRABILITY     smallint null
                      )

-- init local variables
  SET NOCOUNT ON
  SELECT @flag = 0
  SET @msg2=''

--***********************************************************************************************
--* CHECK IF TABLE EXISTS
--***********************************************************************************************
  IF (NOT EXISTS(SELECT * FROM sysobjects WHERE name = @table and type = 'U'))
    BEGIN
      --Unable to find table %s in the current database
      RAISERROR (55166, 16, 1, @proc_name, @table)
      RETURN (1)
    END

--***********************************************************************************************
-- check the operation
--***********************************************************************************************
  IF (@operation NOT IN (1,2,3))
    BEGIN
      --invalid value for parameter
      RAISERROR (55167, 16, 1, @proc_name, @table, 'Operation : 1 = Select 2 = Update/Insert 3 = Validate_delete 4 = Delete')
      RETURN (1)
    END

--***********************************************************************************************
-- procedure name
--***********************************************************************************************
  SELECT @table = RTRIM(@table)
         --get word between first and second underscore
       , @projectfromtable = '' --SUBSTRING(@table, CHARINDEX('_',@table)+1,CHARINDEX('_',@table,CHARINDEX('_',@table)+1)-(CHARINDEX('_',@table)+1)) + '_'

  --append _ if needed
  IF @project IS NULL
    BEGIN
      SET @project = @projectfromtable 
    END
  ELSE
    BEGIN
      SET @project = @project + CASE WHEN RIGHT(@project,1) <> '_' THEN '_'
                                                                   ELSE ''
                                                                   END
    END

  IF @project = @projectfromtable
    BEGIN
      SET @restofprocname = REPLACE(CASE WHEN LEFT(@table, 2) = 't_' THEN RIGHT(@table, LEN(@table) - 2)
                                                                     ELSE @table
                                                                     END
                                    , @projectfromtable
                                    , '')
    END
  ELSE
    BEGIN
      SET @restofprocname = CASE WHEN LEFT(@table, 2) = 't_' THEN RIGHT(@table, LEN(@table) - 2)
                                                             ELSE @table
                                                             END
    END

  IF (@operation = 1) 
    BEGIN
      SELECT @sp_proc_name = 'Get' + @restofprocname
    END

  IF (@operation = 2)
    BEGIN 
      SELECT @sp_proc_name = 'Save' + @restofprocname
    END      

  IF (@operation = 3)
    BEGIN 
      SELECT @sp_proc_name = 'Del' + @restofprocname
    END  

  IF (@operation = 4)
    BEGIN 
      SELECT @sp_proc_name = 'p_' + @project + 'del_' + @restofprocname
    END  

--************************************************************************************************
--   HEADER
--************************************************************************************************
  -- Construct Stored Procedure creation template

  
  PRINT ''
  PRINT 'IF OBJECT_ID(''' + @sp_proc_name + ''') IS NOT NULL'
  PRINT '  BEGIN'
  PRINT '    PRINT ''Dropping procedure ' + @sp_proc_name + '...'''
  PRINT '    DROP PROCEDURE ' + @sp_proc_name
  PRINT '  END'
  PRINT 'GO'

  -- create the stored procedure
  PRINT ''
  PRINT 'PRINT ''Creating procedure '+ @sp_proc_name + '...'''
  PRINT 'GO'
  PRINT '' 
    
  SELECT @msg = 'CREATE PROCEDURE '
                + @sp_proc_name 
                + '('
                --no params for purge procedure
/*
                + CASE WHEN @operation = 4 THEN ''
                                           ELSE '('
                                           END
*/
  PRINT @msg
  SELECT @len = LEN(@msg)

--****************************************************************************************
--*  RETRIEVE THE TABLE PRIMARY KEYS
--****************************************************************************************

    SELECT @full_table_name = QUOTENAME(@table)

        /*      Get Object ID */
    SELECT @table_id = OBJECT_ID(@full_table_name)

  -- declare and fill the cursor
    SELECT @column = NULL,
           @where = ''

   -- create a temp table to hold primary key names
    SELECT COLUMN_NAME = CONVERT(sysname,c.name),
           COLUMN_ORDER = IDENTITY(int, 1,1)
      INTO #tmp_pkeys
      FROM syscolumns c,
           sysindexes i,
           syscolumns c1
     WHERE c.id               = @table_id
       AND i.id               = c.id 
       AND (i.status & 0x800) = 0x800
       AND c.name             = INDEX_COL (@full_table_name, i.indid, c1.colid)
       AND c1.colid           <= i.keycnt       
       AND c1.id              = @table_id
     ORDER BY c.colid

   --*************************
   --retrieve where PK columns
   --*************************
    SELECT @where = @where + RTRIM(COLUMN_NAME) + '%'
    FROM #tmp_pkeys
    
  IF (@operation = 2)
    BEGIN          
      --DETERMINE THE LARGEST WIDTH OF A COLUMNS NAME
      SELECT @width = MAX(LEN(RTRIM(sc.name))) + 1 
      FROM syscolumns sc
      WHERE sc.id = @table_id

      SELECT @fixed_param1 = '@updated'
      IF (@width < LEN(@fixed_param1))
        BEGIN
          SELECT @width = LEN(@fixed_param1)
        END
      IF (@script_binary_checksum_ind = 1 AND @width < LEN('@binary_checksum'))
        BEGIN
          SELECT @width = LEN('@binary_checksum')
        END
      IF (@output_audit_info_ind = 1 AND @width < LEN('@last_modified'))
        BEGIN
          SELECT @width = LEN('@last_modified')
        END

    --***************************************************************************************
    --  CHECK IF AUDIT_DATE, AUDIT_USER, MODIFIED_BY, LAST_MODIFIED ARE USED IN THE TABLE   *
    --***************************************************************************************
      SELECT @stamp = 0
      IF (EXISTS(SELECT *
                 FROM syscolumns sc 
                 WHERE sc.id = @table_id
                 AND RTRIM(sc.name) IN ('audit_date','audit_user','last_modified','modified_by')))
        BEGIN
          -- the above columns must be at the end table defintion
          -- the last column number order
          SELECT @col = MAX(sc.colorder) 
          FROM syscolumns sc
          WHERE sc.id = @table_id
    
          SELECT @audit_col = -1
    
          SELECT @audit_col = sc.colorder
          FROM syscolumns sc
          WHERE sc.id = @table_id
          AND RTRIM(sc.name) IN ('audit_date','last_modified')   
    
          IF (@audit_col = @col)
            BEGIN
              SELECT @stamp = @stamp -1
            END
    
          IF (@col >1)
            BEGIN
              IF (@audit_col = @col -1)
                BEGIN
                  SELECT @stamp = @stamp -1
                END
            END
    
          SELECT @audit_col = sc.colorder
          FROM syscolumns sc
          WHERE sc.id = @table_id
          AND RTRIM(sc.name) IN ('audit_user','modified_by')         
    
          IF (@audit_col = @col)
            BEGIN
              SELECT @stamp = @stamp -1
            END
    
          IF (@col >1)
            BEGIN
              IF (@audit_col = @col -1)
                BEGIN
                  SELECT @stamp = @stamp -1
                END
            END
        END
    
    
    --****************************************************************************************
    --*  BIG LOOP
    --****************************************************************************************
      SELECT @loop = 1
    
      WHILE (@loop <10)
        BEGIN  
          SELECT @msg = ''
    
          -- stored procedure parameters
          IF (@loop = 1)
            BEGIN
              SELECT @msg=''
              SELECT @msg = @msg + SPACE(@len) 
                            + '@' + RTRIM(sc.name) 
                            + SPACE(@width - LEN(RTRIM(sc.name))) 
                            + RTRIM(st.name)
                            + CASE WHEN st.name IN ('char', 'nchar', 'nvarchar','varbinary','varchar') THEN '(' + CONVERT(VARCHAR,sc.length) + ')'
                                   WHEN st.name IN ('decimal', 'numeric') THEN '(' + CONVERT(VARCHAR,sc.xprec) + ',' + CONVERT(VARCHAR,sc.xscale)  + ')'
                                   ELSE ''
                                   END
                            + CASE WHEN COLUMN_NAME IS NOT NULL AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 1
                                   THEN ' = NULL OUTPUT' 
                                   ELSE CASE WHEN COLUMN_NAME IS NOT NULL THEN ''
                                             WHEN st1.name IN ('char', 'nchar', 'nvarchar','varbinary','varchar') THEN ' = ''dummy'''
                                             WHEN st1.name IN ('datetime', 'smalldatetime','timestamp') THEN ' = GETDATE'
                                             WHEN st1.name IN ('bit','int','tinyint','smallint','int','float','numeric','money','smallmoney','real','decimal') THEN ' = 0'
                                             ELSE ' = NULL'
                                             END
                                   END
                            + ','
                            + CASE WHEN COLUMN_NAME IS NOT NULL 
                                   THEN ' -- PRIMARY KEY' 
                                   ELSE '' 
                                   END
                            + CHAR(13) + CHAR(10)
                     , @identcol = CASE WHEN COLUMN_NAME IS NOT NULL AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 1
                                        THEN COLUMN_NAME
                                        ELSE @identcol
                                        END
              FROM syscolumns sc
              JOIN systypes st ON st.xusertype = sc.xusertype
              JOIN systypes st1 on st.xtype = st1.xusertype
              LEFT JOIN #tmp_pkeys ON COLUMN_NAME = sc.name
              WHERE sc.id = @table_id
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
                AND sc.name NOT IN ('audit_date','audit_user','last_modified','modified_by')
              ORDER BY colorder

              SELECT @msg = LEFT(@msg, LEN(@msg) - CHARINDEX(',', REVERSE(@msg))) + ')'
              PRINT @msg

            END --IF

                  -- test if user is allowed to insert/update if check requested by input parameter
          --IF (@loop = 2 AND @script_username_ind = 1)
          --  BEGIN
          --    PRINT '-- ******************************************************************************'
          --    PRINT '-- * Test if user is allowed to insert this row of data                         *'
          --    PRINT '-- ******************************************************************************'
          --    PRINT ''

          --    SELECT @msg = 'SELECT '

          --    SELECT @firstfield = MIN(sc.colorder)
          --    FROM syscolumns sc
          --    LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
          --    WHERE sc.id = @table_id

          --    SELECT @msg = @msg
          --                  + CASE WHEN sc.colorder = @firstfield THEN '' ELSE SPACE(7) END
          --                  + sc.name
          --                  + SPACE(@width - LEN(RTRIM(sc.name)))
          --                  + '= @' + rtrim(sc.name)
          --                  + ','
          --                  + CHAR(13) + CHAR(10)
          --    FROM syscolumns sc
          --    JOIN systypes st ON st.xusertype = sc.xusertype
          --    JOIN systypes st1 on st.xtype = st1.xusertype
          --    LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
          --    WHERE sc.id = @table_id
          --      AND sc.name NOT IN ('audit_date','last_modified', 'audit_user','modified_by')
          --    ORDER BY colorder

          --    SELECT @msg = SUBSTRING(@msg, 1, LEN(@msg) - CHARINDEX(',', REVERSE(@msg)))
          --                  + CHAR(13) + CHAR(10)
          --    PRINT @msg

          --    SELECT @table_nameid = QUOTENAME('#' + RTRIM(NEWID()))
          --    SELECT @msg = 'INTO ' + @table_nameid + CHAR(13) + CHAR(10)
          --    PRINT @msg
          --    PRINT ''

          --    SELECT @msg = '-- create a query for this result set' + CHAR(13) + CHAR(10)
          --    SELECT @msg = @msg + 'SET @query' + SPACE(4) + '= ''SELECT * FROM ' + @table_nameid + ''''  + CHAR(13) + CHAR(10)
          --    PRINT @msg
          --    PRINT ''

          --    SELECT @msg = 'EXEC @status = p_sec_apply_datasecurity ',
          --           @len = len(@msg) + 1
          --    SELECT @msg = @msg + '@query' + SPACE(5) + '= @query OUTPUT,' + CHAR(13) + CHAR(10)
          --    SELECT @msg = @msg + SPACE(@len) + '@user_name' + SPACE(1) + '= @user_name,' + CHAR(13) + CHAR(10)
          --    SELECT @msg = @msg + SPACE(@len) + '@exec_ind' + SPACE(2) + '= 0,' + CHAR(13) + CHAR(10)
          --    SELECT @msg = @msg + SPACE(@len) + '@debug' + SPACE(5) + '= 0' + CHAR(13) + CHAR(10)
          --    PRINT @msg

          --    SELECT @msg = 'SET @error = @@error'  + CHAR(13) + CHAR(10)   
          --    SELECT @msg = @msg + 'IF @status <> 0 OR @error <> 0'  + CHAR(13) + CHAR(10)  
          --    SELECT @msg = @msg + SPACE(2) + 'BEGIN'  + CHAR(13) + CHAR(10)        
          --    SELECT @msg = @msg + SPACE(4) + '-- %s: Problem applying data-level security (Status %d, Error %d).'  + CHAR(13) + CHAR(10)   
          --    SELECT @msg = @msg + SPACE(4) + 'RAISERROR (55175, 16, 1, @proc_name, @status, @error)'  + CHAR(13) + CHAR(10)        
          --    SELECT @msg = @msg + SPACE(4) + 'RETURN(1)'  + CHAR(13) + CHAR(10)       
          --    SELECT @msg = @msg + SPACE(2) + 'END'  + CHAR(13) + CHAR(10)  
          --    PRINT @msg
          --    PRINT ''

          --    SELECT @msg = '-- test if data still valid for this user'  + CHAR(13) + CHAR(10)      
          --    SELECT @msg = @msg + 'SET @query = ''IF EXISTS('' + @query + '')'  + CHAR(13) + CHAR(10)      
          --    SELECT @msg = @msg + SPACE(2) + 'BEGIN'  + CHAR(13) + CHAR(10)        
          --    SELECT @msg = @msg + SPACE(4) + 'SET @validuser = 1'  + CHAR(13) + CHAR(10)   
          --    SELECT @msg = @msg + SPACE(2) + 'END'''  + CHAR(13) + CHAR(10)        
          --    PRINT @msg
          --    PRINT ''
          --    PRINT ''

          --    SELECT @msg = '-- run the query'  + CHAR(13) + CHAR(10)       
          --    SELECT @msg = @msg + 'EXEC master..sp_executesql @query, N''@validuser CHAR(1) OUTPUT'', '    
          --    SELECT @msg = @msg + '@validuser = @validuser OUTPUT'  + CHAR(13) + CHAR(10)  
          --    PRINT @msg
          --    PRINT ''

          --    SELECT @msg = '-- trap error'  + CHAR(13) + CHAR(10)  
          --    SELECT @msg = @msg + 'SET @error = @@error'  + CHAR(13) + CHAR(10)    
          --    SELECT @msg = @msg + 'IF @error <> 0'  + CHAR(13) + CHAR(10)  
          --    SELECT @msg = @msg + SPACE(2) + 'BEGIN'  + CHAR(13) + CHAR(10)        
          --    SELECT @msg = @msg + SPACE(4) + 'PRINT @query'  + CHAR(13) + CHAR(10) 
          --    SELECT @msg = @msg + SPACE(4) + '-- %s: Problem running data-secured query [%s].'  + CHAR(13) + CHAR(10)      
          --    SELECT @msg = @msg + SPACE(4) + 'RAISERROR (55176, 16, 1, @proc_name, @query)'  + CHAR(13) + CHAR(10) 
          --    SELECT @msg = @msg + SPACE(4) + 'RETURN(1)'  + CHAR(13) + CHAR(10)       
          --    SELECT @msg = @msg + SPACE(2) + 'END'  + CHAR(13) + CHAR(10)  
          --    PRINT @msg
          --    PRINT ''

          --    SELECT @msg = '-- user valid?'  + CHAR(13) + CHAR(10) 
          --    SELECT @msg = @msg + 'IF @validuser <> ''1'''  + CHAR(13) + CHAR(10)  
          --    PRINT @msg

          --  END -- IF (@loop = 2 AND @script_username_ind = 1)

          -- concurrency check if requested by input parameter
          --IF (@loop = 3 AND @script_binary_checksum_ind = 1)
          --  BEGIN
          --    SELECT @msg = 'IF @binary_checksum IS NOT NULL' + CHAR(13) + CHAR(10)
          --    SELECT @msg = @msg + 'AND (',
          --           @len = 5
          --    SELECT @msg = @msg + 'SELECT BINARY_CHECKSUM(*)' + CHAR(13) + CHAR(10) 
          --                  + SPACE(@len) + '  FROM ' + RTRIM(@table) + CHAR(13) + CHAR(10)
          --                  + SPACE(@len) + ' WHERE '
          --    SELECT @msg = @msg 
          --                  + CASE WHEN COLUMN_ORDER=1 THEN '' 
          --                                             ELSE SPACE(@len) + '   AND ' 
          --                                             END
          --                  + pk.COLUMN_NAME 
          --                  + ' = @' + pk.COLUMN_NAME
          --                  + CHAR(13) + CHAR(10)
          --    FROM syscolumns sc 
          --    JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
          --    WHERE sc.id = @table_id
          --    ORDER BY sc.colorder

          --    SELECT @msg = @msg + SPACE(@len) + ') <> @binary_checksum' + CHAR(13) + CHAR(10)

          --    PRINT ''
          --    PRINT ''
          --    PRINT '-- ******************************************************************************'
          --    PRINT '-- * Concurrency check                                                          *'
          --    PRINT '-- ******************************************************************************'
          --    PRINT ''
          --    PRINT @msg 

          --  END -- IF (@loop = 3 AND @script_binary_checksum_ind = 1)

          -- exists statement               
          IF (@loop = 4)
            BEGIN
              SELECT @msg = 'IF (EXISTS(',
                     @len = LEN(@msg)
              SELECT @msg = @msg + 'SELECT 1' + CHAR(13) + CHAR(10) 
                            + SPACE(@len) + '  FROM ' + RTRIM(@table) + CHAR(13) + CHAR(10)
                            + SPACE(@len) + ' WHERE '
              SELECT @msg = @msg 
                            + CASE WHEN COLUMN_ORDER=1 THEN '' 
                                                       ELSE SPACE(@len) + '   AND ' 
                                                       END
                            + pk.COLUMN_NAME 
                            + ' = @' + pk.COLUMN_NAME
                            + CHAR(13) + CHAR(10)
              FROM syscolumns sc 
              JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
              WHERE sc.id = @table_id
              ORDER BY sc.colorder

              SELECT @msg = @msg + SPACE(@len-1) + ')' + CHAR(13) + CHAR(10) + SPACE(3) + ')'

              PRINT '-- ******************************************************************************'
              PRINT '-- * Actual INSERT/UPDATE                                                       *'
              PRINT '-- ******************************************************************************'
              PRINT ''
              PRINT 'BEGIN TRY'
              PRINT ''
              --PRINT 'SELECT @mod_date = CURRENT_TIMESTAMP,'
              --IF @script_username_ind = 1
              --  BEGIN
              --    PRINT '       @mod_user = @user_name'
              --  END
              --ELSE
              --  BEGIN
              --    PRINT '       @mod_user = SYSTEM_USER'
              --  END
              --PRINT ''
              PRINT @msg 
            END --IF (@loop = 4)

          -- update statement
          IF (@loop = 5)
            BEGIN
              PRINT SPACE(4) + '-- Performs the Update Statement'
              SELECT @msg = SPACE(4) + 'UPDATE ' + RTRIM(@table)
              SELECT @len = LEN(@msg)
              PRINT @msg

              SELECT @firstfield = MIN(sc.colorder)
              FROM syscolumns sc
              LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
              WHERE sc.id = @table_id
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 0  --no apply on identity column
                AND k.COLUMN_NAME IS NULL

              SELECT @msg = SPACE(7) + 'SET '
              SELECT @msg = @msg
                            + CASE WHEN sc.colorder = @firstfield THEN '' ELSE SPACE(11) END
                            + sc.name
                            + SPACE(@width - LEN(RTRIM(sc.name)))
                            + CASE WHEN (RTRIM(sc.name) IN ('audit_date','last_modified')) THEN '= @mod_date'
                                   WHEN (RTRIM(sc.name) IN ('audit_user','modified_by')) THEN '= @mod_user'
                                   ELSE '= @' + rtrim(sc.name)
                                   END
                            + ','
                            + CHAR(13) + CHAR(10)
              FROM syscolumns sc
              JOIN systypes st ON st.xusertype = sc.xusertype
              JOIN systypes st1 on st.xtype = st1.xusertype
              LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
              WHERE sc.id = @table_id
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 0  --no apply on identity column
                AND k.COLUMN_NAME IS NULL
              ORDER BY colorder

              SELECT @msg = SUBSTRING(@msg, 1, LEN(@msg) - CHARINDEX(',', REVERSE(@msg)))
                            + CHAR(13) + CHAR(10)
              PRINT @msg
            END --IF (@loop = 5)

          -- where clause on primary keys
          IF (@loop = 6)
            BEGIN
              SELECT @msg = SPACE(5) + 'WHERE '
              SELECT @msg = @msg
                            + CASE WHEN COLUMN_ORDER = 1 THEN '' ELSE SPACE(5) + '  AND ' END
                            + COLUMN_NAME + SPACE(@width - LEN(RTRIM(COLUMN_NAME))) + '=  @' + COLUMN_NAME
                            + CHAR(13) + CHAR(10)
              FROM #tmp_pkeys
              ORDER BY COLUMN_ORDER

              PRINT @msg
            END --IF (@loop = 6)
    
          -- update where clause
          IF (@loop = 7)
            BEGIN
              SELECT @firstfield = MIN(sc.colorder)
              FROM syscolumns sc
              LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
              WHERE sc.id = @table_id
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 0  --no apply on identity column
                AND k.COLUMN_NAME IS NULL

              SELECT @msg = ''
              --SELECT @msg = @msg 
              --              + CASE WHEN sc.colorder = @firstfield THEN SPACE(6) + ' AND (BINARY_CHECKSUM( ' 
              --                                                    ELSE SPACE(28) + ',' 
              --                                                    END
              --              + sc.name
              --              + SPACE(@width - LEN(RTRIM(sc.name)))
              --              + CHAR(13) + CHAR(10),
              --       @msg2 = @msg2 + SPACE(28) + ',@' + rtrim(sc.name) 
              --               + CHAR(13) + CHAR(10)
         
              --FROM syscolumns sc
              --JOIN systypes st ON st.xusertype = sc.xusertype
              --JOIN systypes st1 on st.xtype = st1.xusertype
              --LEFT JOIN #tmp_pkeys k ON k.COLUMN_NAME = sc.name
              --WHERE sc.id = @table_id
              --  AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
              --  AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 0  --no apply on identity column
              --  AND k.COLUMN_NAME IS NULL
              --  AND RTRIM(sc.name) NOT IN ('audit_date','audit_user','last_modified','modified_by')
              --ORDER BY colorder

              --if there were updates...
              --IF LEN(@msg) > 0
              --  BEGIN
              --    SELECT @msg = @msg + SPACE(27) + ') <> ' + CHAR(13) + CHAR(10) 
              --                  + SPACE(12) + 'BINARY_CHECKSUM( ' 
              --                  + RTRIM(SUBSTRING(LTRIM(@msg2),2,LEN(@msg2))) 
              --                  + SPACE(27) + ')' + CHAR(13) + CHAR(10) 
              --                  + SPACE(11) + ')'
              --  END

              PRINT @msg
            END --IF (@loop = 7)

          -- insert statement columns (in msg)/values ( in msg2)
          IF (@loop = 8)
            BEGIN   
              PRINT SPACE(4) + '-- Performs the Insert Statement'
              SELECT @msg = SPACE(4) + 'INSERT INTO ' + RTRIM(@table) + '('
              SELECT @len = LEN(@msg)
              PRINT @msg

              SELECT @msg = ''
                   , @msg2 = ''

              SELECT @msg = @msg
                            + SPACE(@len)
                            + ','
                            + RTRIM(sc.name)
                            + CHAR(13) + CHAR(10),
                     @msg2 = @msg2
                             + SPACE(@len)
                             + ','
                             + CASE WHEN RTRIM(sc.name) IN ('audit_date','last_modified') THEN '@mod_date'
                                    WHEN RTRIM(sc.name) IN ('audit_user','modified_by') THEN '@mod_user'
                                    ELSE '@' + RTRIM(sc.name)
                                    END
                             + CHAR(13) + CHAR(10)
              FROM syscolumns sc
              WHERE sc.id = @table_id
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsComputed') = 0  --DO NOT SELECT COMPUTED COLUMNS FOR UPDATE/INSERT
                AND COLUMNPROPERTY(sc.id, sc.name, 'IsIdentity') = 0  --no apply on identity column
              ORDER BY colorder

              SELECT @msg = SPACE(@len)
                            + SUBSTRING(LTRIM(@msg), 2, LEN(@msg))
                            + SPACE(@len-1)
                            + ')'
                   , @msg2 = SPACE(@len)
                            + SUBSTRING(LTRIM(@msg2), 2, LEN(@msg2))
                            + SPACE(@len-1)
                            + ')'
              --print insert statement columns
              PRINT @msg

              --print insert statement values
              SELECT @msg = 'VALUES ('
              SELECT @msg = SPACE(@len - LEN(@msg)) + @msg     
              PRINT @msg
              PRINT @msg2


            END --IF (@loop = 8)

          -- messages after columns
          IF (@loop = 1)
            BEGIN
              --IF @script_username_ind = 1
              --  BEGIN
              --    SELECT @msg = '@user_name' + ' '
              --    PRINT  SPACE(@len) + @msg + SPACE(@width - LEN(RTRIM(@msg))) + 'd_user = NULL,'
              --  END
              --IF @script_binary_checksum_ind = 1
              --  BEGIN
              --    SELECT @msg = '@binary_checksum' + ' '
              --    PRINT  SPACE(@len) + @msg + SPACE(@width - LEN(RTRIM(@msg))) + 'int = NULL,'
              --  END
              --IF @output_audit_info_ind = 1
              --  BEGIN
              --    SELECT @msg = '@last_modified' + ' '
              --    PRINT  SPACE(@len) + @msg + SPACE(@width - LEN(RTRIM(@msg))) + 'sysname = NULL OUTPUT,'
              --    SELECT @msg = '@modified_by' + ' '
              --    PRINT  SPACE(@len) + @msg + SPACE(@width - LEN(RTRIM(@msg))) + 'sysname = NULL OUTPUT,'
              --  END
              IF(COALESCE(LTRIM(@msg), '') <> '')
                BEGIN
                  SELECT @msg = ''--LEFT(RTRIM(@msg), LEN(RTRIM(@msg)) - 1)
                END
              --SELECT @msg = RTRIM(@fixed_param1) + ' '
              --PRINT  SPACE(@len) + @msg + SPACE(@width - LEN(RTRIM(@msg))) + 'BIT = 0 OUTPUT)'
              SELECT @msg = RTRIM(@table) + ' Update/Insert'
              PRINT 'AS'
              PRINT ''
              PRINT '-- ******************************************************************************'
              PRINT '-- * Purpose: ' + @msg + SPACE(66 - LEN(@msg))+ '*'
              PRINT '-- *                                                                            *'
              IF @script_binary_checksum_ind = 1 OR @script_username_ind = 1 OR @output_audit_info_ind = 1
                BEGIN
                  PRINT '-- * Inputs: All table columns are parameters to this procedure                 *'
                  IF @script_username_ind = 1
                    BEGIN
                      PRINT '-- *         @username: used to test if the user is allowed to inert the row.   *'
                    END
                  IF @script_binary_checksum_ind = 1
                    BEGIN
                      PRINT '-- *         @binary_checksum: used for concurrency checking, to see if the     *'
                      PRINT '-- *                           record hasn’t been modified by another process   *'
                      PRINT '-- *                           since it was read (which is when this checksum   *'
                      PRINT '-- *                           value got calculated)                            *'
                    END
                  PRINT '-- *                                                                            *'
                  PRINT '-- * Returns: 0 if successful, 1 if errors occurred                             *'
                  IF @output_audit_info_ind = 1
                    BEGIN
                      PRINT '-- *          @last_modified: returns audit info to the caller.                 *'
                      PRINT '-- *          @modified_by: returns audit info to the caller.                   *'
                    END
                  PRINT '-- *                                                                            *'
                  PRINT '-- * Notes: ieseg        - Auto Generated Stored Procedure                      *'
                END
              ELSE
                BEGIN
                  PRINT '-- * Inputs: Filled with Table PK Columns                                       *'
                  PRINT '-- *                                                                            *'
                  PRINT '-- * Returns: 0 if Successful, 1 if errors occurred                             *'
                  PRINT '-- *                                                                            *'
                  PRINT '-- * Notes: IESEG        - Auto Generated Stored Procedure                      *'
                END
              PRINT '-- ******************************************************************************'
              PRINT 'SET NOCOUNT ON'
              PRINT ''
              PRINT '-- declare error/debug variables'
              PRINT 'DECLARE @proc_name sysname      -- procedure name'
              PRINT 'DECLARE @status    INT          -- return status'
              PRINT 'DECLARE @error     INT          -- saved error context'
              PRINT 'DECLARE @rowcount  INT          -- saved rowcount context'
              PRINT 'DECLARE @msg       VARCHAR(MAX) -- error message text'
              PRINT ''
              PRINT '-- initialise error/debug variables'
              PRINT 'SELECT @proc_name = OBJECT_NAME( @@PROCID ),'
              PRINT '       @status    = 0,'
              PRINT '       @error     = 0,'
              PRINT '       @rowcount  = 0'
              PRINT ''
              PRINT '-- declare local variables'
              --PRINT 'DECLARE @valueliststr VARCHAR(8000)'
              --PRINT 'DECLARE @mod_date     datetime'
              --PRINT 'DECLARE @mod_user     sysname'

              IF @script_username_ind = 1
                BEGIN
                  PRINT 'DECLARE @query        NVARCHAR(4000)'
                  PRINT 'DECLARE @validuser    CHAR(1)'
                  PRINT ''
                  PRINT '-- Assume database user if @user_name is not supplied'
                  PRINT 'IF @user_name IS NULL or @user_name = '''''
                  PRINT '  BEGIN'
                  PRINT '    SET @user_name = SYSTEM_USER'
                  PRINT '  END' 
                END

              --***************************************************************************************************************
              --* VALIDATION TESTS BASE ON THE TABLE FOREIGN KEY (FROM debugged SP_FKEYS)
              --***************************************************************************************************************
              INSERT INTO   #fkeysall
              SELECT r.rkeyid,
                     r.rkey1, r.rkey2, r.rkey3, r.rkey4,
                     r.rkey5, r.rkey6, r.rkey7, r.rkey8,
                     r.rkey9, r.rkey10, r.rkey11, r.rkey12,
                     r.rkey13, r.rkey14, r.rkey15, r.rkey16,
                     r.fkeyid,
                     r.fkey1, r.fkey2, r.fkey3, r.fkey4,
                     r.fkey5, r.fkey6, r.fkey7, r.fkey8,
                     r.fkey9, r.fkey10, r.fkey11, r.fkey12,
                     r.fkey13, r.fkey14, r.fkey15, r.fkey16,
                     r.constid,
                     i.name
              FROM sysreferences r
                   , sysobjects o
                   , sysindexes i
              WHERE r.fkeyid    = @table_id
              AND   i.id        = r.rkeyid
              AND   i.indid     = r.rkeyindid
              AND   o.id        = r.constid
              AND   o.xtype     = 'F'
              AND   r.fkeyid BETWEEN  0 AND  0x7fffffff
    
              INSERT INTO #fkeys
              SELECT rkeyid, rkey1, fkeyid, fkey1, 1, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey2, fkeyid, fkey2, 2, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey3, fkeyid, fkey3, 3, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey4, fkeyid, fkey4, 4, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey5, fkeyid, fkey5, 5, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey6, fkeyid, fkey6, 6, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey7, fkeyid, fkey7, 7, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey8, fkeyid, fkey8, 8, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey9, fkeyid, fkey9, 9, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey10, fkeyid, fkey10, 10, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey11, fkeyid, fkey11, 11, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey12, fkeyid, fkey12, 12, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey13, fkeyid, fkey13, 13, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey14, fkeyid, fkey14, 14, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey15, fkeyid, fkey15, 15, constid, name
              FROM #fkeysall
              UNION ALL
              SELECT rkeyid, rkey16, fkeyid, fkey16, 16, constid, name
              FROM #fkeysall
    
              INSERT INTO #fkeysout
              SELECT PKTABLE_QUALIFIER = CONVERT(sysname,db_name()),
                     PKTABLE_OWNER     = CONVERT(sysname,USER_NAME(o1.uid)),
                     PKTABLE_NAME      = CONVERT(sysname,o1.name),
                     PKCOLUMN_NAME     = CONVERT(sysname,c1.name),
                     FKTABLE_QUALIFIER = CONVERT(sysname,db_name()),
                     FKTABLE_OWNER     = CONVERT(sysname,USER_NAME(o2.uid)),
                     FKTABLE_NAME      = CONVERT(sysname,o2.name),
                     FKCOLUMN_NAME     = CONVERT(sysname,c2.name),
                     KEY_SEQ,
                     UPDATE_RULE       = CONVERT(smallint,1),
                     DELETE_RULE       = CONVERT(smallint,1),
                     FK_NAME           = CONVERT(sysname,OBJECT_NAME(fk_id)),
                     PK_NAME,
                     DEFERRABILITY = 7  /* SQL_NOT_DEFERRABLE */
              FROM #fkeys f,
              sysobjects o1, sysobjects o2,
              syscolumns c1, syscolumns c2
              WHERE o1.id    = f.pktable_id
              AND   o2.id    = f.fktable_id
              AND   c1.id    = f.pktable_id
              AND   c2.id    = f.fktable_id
              AND   c1.colid = f.pkcolid
              AND   c2.colid = f.fkcolid
    
              --IF (EXISTS(SELECT * FROM #fkeysout))
              --  BEGIN
              --    PRINT ''
              --    PRINT '-- Validation Tests based on ' + RTRIM(@table) + ' foreign keys'
              --  END
    
              PRINT ''
              PRINT '-- init local variables'
              --IF @script_username_ind = 1
              --  BEGIN
              --    PRINT 'SET @validuser = 0'
              --  END
              PRINT ''

              -- OPEN A CURSOR ON DISTINCT FOREIGN KEY TABLES
              -- declare and fill the cursor
--              DECLARE  FTCH_TABLES CURSOR
--                FOR SELECT DISTINCT FK_NAME
--                    FROM #fkeysout
--                    ORDER BY 1
    
--              -- open the cursor and load the first record into variables
--              OPEN FTCH_TABLES
--              FETCH NEXT FROM FTCH_TABLES INTO @fkkey
    
--              -- run through the cursor
--              WHILE (@@FETCH_STATUS = 0)
--                BEGIN
--                  PRINT '-- ******************************************************************************'
--                  PRINT '-- * Validation Tests based on t_sec_filter_item foreign keys                   *'
--                  PRINT '-- ******************************************************************************'
--                  PRINT ''
--                  PRINT '-- Validation based on Foreign Key :' + @fkkey
    
--                  SELECT @fkcount = 0
--                         , @msg = ''
--                         , @len = LEN('IF (NOT EXISTS(')
--                         , @list = '@proc_name, ''' + @table + ''', '''
--                         , @valuelist = ''

--                  SELECT @fkcount = @fkcount + 1
--                         , @msg = @msg 
--                                  + CASE WHEN @fkcount = 1 THEN 'IF (NOT EXISTS(SELECT 1 ' + CHAR(13) + CHAR(10)
--                                                                + SPACE(@len) + '  FROM ' + PKTABLE_NAME + CHAR(13) + CHAR(10)
--                                                                + SPACE(@len) + ' WHERE '  + PKCOLUMN_NAME  
--                                                                + ' = @' + FKCOLUMN_NAME
--                                                           ELSE SPACE (@len) + '   AND ' + PKCOLUMN_NAME 
--                                                                + ' = @' + FKCOLUMN_NAME
--                                                           END
--                                  + CHAR(13) + CHAR(10)
--                         , @list = @list + + CASE WHEN @fkcount = 1 THEN '' ELSE '/' END + FKCOLUMN_NAME
--                         , @valuelist = @valuelist + FKCOLUMN_NAME + '%'
--                    FROM #fkeysout ko
--                   WHERE FK_NAME = @fkkey

--                  PRINT @msg + SPACE(@len-1) + ')' + CHAR(13) + CHAR(10) + SPACE(3) + ')'

--                  SELECT @list = @list + ''''

--                  PRINT SPACE(2) + 'BEGIN'
----                      SELECT @msg = '%s : Foreign Key Violation with Table ' + @fktable + '. '          

--                  SELECT @valueliststr = ''
--                  IF LEN(@valuelist) > 0
--                    BEGIN
--                      SELECT @start = 1
--                             , @pos = 0
--                             , @len = LEN('SELECT @valueliststr = ') + 4
--                      WHILE (@pos >=0)
--                        BEGIN
--                          SELECT @pos = CHARINDEX('%',@valuelist,@start)
--                          IF (@pos > 0)
--                            BEGIN
--                              SELECT @column = SUBSTRING(@valuelist,@start, (@pos - @start))
   
--                              SELECT @type = st1.name 
--                              FROM syscolumns sc
--                              JOIN systypes st ON st.xusertype = sc.xusertype
--                              JOIN systypes st1 on st1.xusertype = st.xtype
--                              WHERE sc.id = @table_id
--                                AND sc.name = @column
    
--                              SELECT @valueliststr = @valueliststr 
--                                                     + SPACE(@len) 
--                                                     + ' + ''/' 
--                                                     + CASE WHEN LOWER(@type) IN ('datetime', 'smalldatetime') THEN ''' + CONVERT(VARCHAR, @' + @column + ', 113)'
--                                                            WHEN LOWER(@type) IN ('int','numeric','float','real','money','decimal','smallint','tinyint','bit','smallmoney' ) THEN ''' + CONVERT(VARCHAR, @' + @column + ')'
--                                                            ELSE ''' + @' + @column 
--                                                            END
--                                                     + CHAR(13) + CHAR(10)

--                              SELECT @start = @pos + 1
--                              IF (@pos = LEN(@valuelist) OR @start >= LEN(@valuelist))
--                                BEGIN
--                                  SELECT @pos = -1
--                                END
--                            END --IF (@pos > 0)
--                          ELSE
--                            BEGIN
--                              SELECT @pos = -1
--                            END
--                        END --WHILE (@pos >=0)
--                    END --IF LEN(@valuelist) > 0

--                  SELECT @msg = LEFT(@msg, LEN(@msg)-1)
--                  PRINT SPACE(4) + 'SELECT @valueliststr = ' + LTRIM( SUBSTRING(@valueliststr, CHARINDEX('+',@valueliststr,CHARINDEX('+',@valueliststr) + 1) + 1, LEN(@valueliststr)) )
--                  SELECT @list = @list + ', @valueliststr'
--                  -- Error Handling
--                  PRINT SPACE(4) + '-- Trying to insert invalid value in table %s, field %s, value %s'
--                  PRINT SPACE(4) + 'RAISERROR (''Related key not found'', 16, 1, ' + @list + ')'
--                  PRINT SPACE(4) + 'RETURN (1)'
--                  PRINT SPACE(2) + 'END'
--                  PRINT ''
    
--                  FETCH NEXT FROM FTCH_TABLES INTO @fkkey
    
--                END --WHILE (@@FETCH_STATUS = 0)
    
--              CLOSE FTCH_TABLES
--              DEALLOCATE FTCH_TABLES
    
            END --IF (@loop = 1)
        
          IF (@loop = 4)
            BEGIN
              PRINT SPACE(2) + 'BEGIN'
            END
    
          IF (@loop = 7 or @loop = 9)
            BEGIN
              -- build the error message
              SELECT @list = '@proc_name,''' + @table + ''''
               -- Error Handling
              PRINT ''
              PRINT SPACE(4) +  CASE WHEN (@loop = 9 AND @identcol IS NOT NULL)
                                    THEN 'SELECT @' + @identcol + ' = SCOPE_IDENTITY()'
                                    ELSE ''
                                    END
              PRINT ''
              --PRINT SPACE(4) + 'IF (@error <> 0)'
            END -- IF (@loop = 7 or @loop = 9)


          --IF (@loop = 7 or @loop = 9 or (@loop = 2 AND @script_username_ind = 1) OR (@loop = 3 AND @script_binary_checksum_ind = 1)) 
          --  BEGIN
          --    -- Build the error message
          --    PRINT SPACE(6) + 'BEGIN'
          --    SET @valueliststr = ''    
          --    IF (@where IS NOT NULL)
          --      BEGIN
          --        SELECT @start = 1
          --               , @pos = 0
          --               , @len = LEN('SELECT @valueliststr = ') + 8
          --        WHILE (@pos >=0)
          --          BEGIN
          --            SELECT @pos = CHARINDEX('%',@where,@start)
          --            IF (@pos >0)
          --              BEGIN
          --                SELECT @column = SUBSTRING(@where,@start, (@pos - @start))
       
          --                SELECT @type = st1.name 
          --                FROM syscolumns sc
          --                JOIN systypes st ON st.xusertype = sc.xusertype
          --                JOIN systypes st1 ON st1.xusertype = st.xtype
          --                WHERE sc.id = @table_id
          --                  AND sc.name = @column

          --                SELECT @valueliststr = @valueliststr 
          --                                       + SPACE(@len) 
          --                                       + ' + ''/' 
          --                                       + @column 
          --                                       + CASE WHEN LOWER(@type) IN ('datetime', 'smalldatetime') THEN '='' + CONVERT(VARCHAR, @' + @column + ', 113)'
          --                                              WHEN LOWER(@type) IN ('int','numeric','float','real','money','decimal','smallint','tinyint','bit','smallmoney' ) THEN '='' + CONVERT(VARCHAR, @' + @column + ')'
          --                                              ELSE '='' + @' + @column 
          --                                              END
          --                                       + CHAR(13) + CHAR(10)
    
          --                SELECT  @start = @pos +1
                              
          --                IF (@pos = LEN(@where) OR @start >= LEN(@where))
          --                  BEGIN
          --                    SELECT @pos = -1
          --                  END
          --              END
          --            ELSE  --@pos <=0
          --              BEGIN
          --                SELECT @pos = -1
          --              END
          --          END  --WHILE (@pos >=0)
          --      END --IF (@where IS NOT NULL)      
              
          --    PRINT SPACE(8) + 'SELECT @valueliststr = ''' + LTRIM( SUBSTRING(@valueliststr, CHARINDEX('/', @valueliststr)+1, LEN(@valueliststr)) )

          --    SELECT @list = @list + ', @valueliststr'

          --    PRINT SPACE(8) + CASE WHEN @loop = 7 THEN '-- Update failed in table %s'
          --                          WHEN @loop = 9 THEN '-- Insert failed in table %s'
          --                          WHEN @loop = 2 THEN '-- %s: User [%s] does not have permission on this row [%s].'
          --                                          ELSE '-- The record with Primary Key [%s] in table [%s] was changed by another process or user since you retrieve it. Your changes have been discarded. Please reload the record and try again.'
          --                                          END
          --    PRINT SPACE(8) + 'RAISERROR (' + CASE WHEN @loop = 7 THEN '''%s :Update failed in table %s''' + ', 16, 1, ' + @list + ', @error)'
          --                                          WHEN @loop = 9 THEN '''%s :Insert failed in table %s''' + ', 16, 1, ' + @list + ', @error)'
          --                                          WHEN @loop = 2 THEN '''No permissions for user''' + ', 16, 1, @proc_name, @user_name, @valueliststr)'
          --                                                          ELSE '''Row not found with expected values''' + ', 16, 1, @proc_name, @valueliststr, ''' + @table + ''')'
          --                                                          END
          --    PRINT SPACE(8) + 'RETURN (1)'
          --    PRINT SPACE(6) + 'END'
          --  END -- (@loop = 7 or @loop = 9 or (@loop = 2 AND @script_username_ind = 1) OR (@loop = 3 AND @script_binary_checksum_ind = 1)) 

          IF (@loop = 7 or @loop = 9)
            BEGIN
              --PRINT SPACE(4) + 'ELSE'
              --PRINT SPACE(6) + 'BEGIN'
              --PRINT SPACE(8) + 'SELECT ' + @fixed_param1 + ' = ' + CASE WHEN @loop = 7 THEN '1' ELSE '0' END
              --IF @output_audit_info_ind = 1
              --  BEGIN
              --    PRINT SPACE(13) + ', @last_modified = @mod_date'
              --    PRINT SPACE(13) + ', @modified_by = @mod_user'
              --  END
              --PRINT SPACE(6) + 'END'
              PRINT SPACE(2) + 'END'

              IF(@loop = 9)
                BEGIN
                  PRINT 'END TRY'
                  PRINT ''
                  PRINT 'BEGIN CATCH'
                  PRINT SPACE(2) + 'SELECT @msg = ERROR_MESSAGE()'
                  PRINT SPACE(2) + 'RAISERROR(''%s : Errors occurred when Update/Insert in table ' + QUOTENAME(@table) + ' with error [%s]'', 16,1,@proc_name, @msg)'
                  PRINT 'END CATCH'
                END

              IF (@loop = 7)
                BEGIN
                  PRINT 'ELSE'
                  PRINT SPACE(2) + 'BEGIN'
                END
            END --IF (@loop = 7 or @loop = 9)         

          SELECT @loop = @loop + 1
        END --WHILE (@loop <10)
    END
  ELSE  --@operation <> 2
    BEGIN
      --DETERMINE THE LARGEST WIDTH OF A COLUMNS NAME
      SELECT @width = MAX(LEN(RTRIM(COLUMN_NAME))) + 1 
      FROM #tmp_pkeys
 
      -- stored procedure parameters
      SELECT @msg = ''
      SELECT @msg = @msg + SPACE(@len) 
                    + '@' + RTRIM(sc.name) 
                    + SPACE(@width - LEN(RTRIM(sc.name))) 
                    + RTRIM(st.name)
                    + CASE WHEN st.name IN ('char', 'nchar', 'nvarchar','varbinary','varchar') THEN '(' + CONVERT(VARCHAR, sc.length) + ')'
                           WHEN st.name IN ('decimal', 'numeric') THEN '(' + CONVERT(VARCHAR,sc.xprec) + ',' + CONVERT(VARCHAR,sc.xscale)  + ')'
                           ELSE ''
                           END
                    + CASE WHEN @operation = 1 THEN ' = NULL' ELSE '' END
                    + ',' 
                    + CHAR(13) + CHAR(10)
      FROM syscolumns sc 
      JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
      JOIN systypes st ON st.xusertype = sc.xusertype
      WHERE sc.id = @table_id
      ORDER BY sc.colorder

      --cut off last comma and char(13)+char(10)
      IF (@operation IN (1,3))
        BEGIN
          SELECT @msg = LEFT(@msg, LEN(@msg) - CHARINDEX(',', REVERSE(@msg))) + ')'
        END

      --append output param
      IF (@operation = 3)
        BEGIN
          SELECT @fixed_param1 = ''
          --IF LEN(@fixed_param1) > @width
          --  BEGIN
          --    SET @width = LEN(@fixed_param1)
          --  END
          --SELECT @msg = @msg 
          --              + SPACE(@len) + @fixed_param1 + SPACE(@width - LEN(@fixed_param1))
                       -- + ' BIT = 1 OUTPUT)'
        END
      IF (@operation = 4)
        BEGIN
          SELECT @fixed_param1 = '@purge'
          SELECT @msg = @msg 
                        + SPACE(@len) + @fixed_param1 + SPACE(@width - LEN(@fixed_param1))
                        + ' BIT = 0,' 
                        + CHAR(13) + CHAR(10)

          SELECT @fixed_param1 = '@deleted'
          IF LEN(@fixed_param1) > @width
            BEGIN
              SET @width = LEN(@fixed_param1)
            END
          SELECT @msg = @msg 
                        + SPACE(@len) + @fixed_param1 + SPACE(@width - LEN(@fixed_param1))
                        + ' INT = 0 OUTPUT)'
        END

      PRINT @msg

      SELECT @msg = RTRIM(@table) + ' ' + (CASE WHEN @operation = 1 THEN 'Select'
                                                WHEN @operation = 3 THEN 'Validate_delete'
                                                WHEN @operation = 4 THEN 'Delete'
                                                ELSE 'unknown'
                                                END) + ' Stored Procedure.'

      PRINT 'AS'
      PRINT ''
      PRINT '-- ******************************************************************************'
      PRINT '-- * Purpose: ' + @msg + SPACE(66 - LEN(@msg))+ '*'
      PRINT '-- *                                                                            *'
      PRINT '-- * Inputs: Filled with Table PK Columns                                       *'
      PRINT '-- *                                                                            *'
      PRINT '-- * Returns: 0 if Successful, 1 if errors occurred                             *'
      PRINT '-- *                                                                            *'
      PRINT '-- * Notes: IESEG - Auto Generated Stored Procedure                             *'
      PRINT '-- ******************************************************************************'
      PRINT ''
      PRINT '-- declare error/debug variables'
      PRINT 'DECLARE @proc_name sysname         -- procedure name'
      PRINT 'DECLARE @status    INT             -- return status'
      PRINT 'DECLARE @error     INT             -- saved error context'
      PRINT 'DECLARE @rowcount  INT             -- saved rowcount context'
      PRINT 'DECLARE @msg       VARCHAR(MAX)    -- error message text'
      PRINT ''
      PRINT '-- initialise error/debug variables'
      PRINT 'SELECT @proc_name = OBJECT_NAME( @@PROCID ),'
      PRINT '       @status    = 0,'
      PRINT '       @error     = 0,'
      PRINT '       @rowcount  = 0'
      PRINT ''

      --IF (@operation IN (3,4))
      --  BEGIN
      --    SELECT @valueliststr = ''
      --           , @len = LEN('SELECT @valueliststr = ')

      --    SELECT @valueliststr = @valueliststr 
      --                           + SPACE(@len)
      --                           + ' + ''/' 
      --                           + RTRIM(COLUMN_NAME) 
      --                           + '='' + ' 
      --                           + CASE WHEN LOWER(st1.name) IN ('datetime', 'smalldatetime' ) THEN 'CONVERT(VARCHAR, @' + RTRIM(COLUMN_NAME) + ',113)'
      --                                  WHEN LOWER(st1.name) IN ('int','numeric','float','real','money','decimal','smallint','tinyint','bit','smallmoney' ) THEN 'CONVERT(VARCHAR, @' + RTRIM(COLUMN_NAME) + ')'
      --                                  ELSE '@' + COLUMN_NAME
      --                                  END
      --                           + CHAR(13) + CHAR(10)
      --      FROM #tmp_pkeys
      --      JOIN syscolumns sc ON sc.name = COLUMN_NAME
      --      JOIN systypes st ON st.xusertype = sc.xusertype
      --      JOIN systypes st1 on st1.xusertype = st.xtype
      --     WHERE sc.id = @table_id
    
      --    PRINT '-- declare local variables'
      --    PRINT 'DECLARE @valueliststr VARCHAR(8000)'
      --    PRINT ''
          PRINT '-- init local variables'
          PRINT 'SET NOCOUNT ON'
          PRINT ''
      --    PRINT 'SELECT @valueliststr = ''' + LTRIM( SUBSTRING(LTRIM(@valueliststr)
      --                                                         , 5
      --                                                         , LEN(@valueliststr))
      --                                             )
      --    PRINT ''
      --  END

      --IF (@operation = 4)
      --  BEGIN
      --    PRINT ''
      --    PRINT 'BEGIN TRANSACTION'
      --    PRINT ''
      --  END

      IF (@operation IN (3,4))
        BEGIN
              ----*************************************************
              ----* VALIDATION TESTS BASED ON THE TABLE FOREIGN KEY
              ----*************************************************
    
              --  INSERT INTO   #fkeysall
              --  SELECT r.rkeyid,
              --         r.rkey1, r.rkey2, r.rkey3, r.rkey4,
              --         r.rkey5, r.rkey6, r.rkey7, r.rkey8,
              --         r.rkey9, r.rkey10, r.rkey11, r.rkey12,
              --         r.rkey13, r.rkey14, r.rkey15, r.rkey16,
              --         r.fkeyid,
              --         r.fkey1, r.fkey2, r.fkey3, r.fkey4,
              --         r.fkey5, r.fkey6, r.fkey7, r.fkey8,
              --         r.fkey9, r.fkey10, r.fkey11, r.fkey12,
              --         r.fkey13, r.fkey14, r.fkey15, r.fkey16,
              --         r.constid,
              --         i.name
              --  FROM sysreferences r,
              --       sysobjects o,
              --       sysindexes i
              --  WHERE r.rkeyid    = @table_id
              --  AND   i.id        = r.rkeyid
              --  AND   i.indid     = r.rkeyindid
              --  AND   o.id        = r.constid
              --  AND   o.xtype     = 'F'
              --  AND   r.fkeyid BETWEEN  0 AND  0x7fffffff
    
              --INSERT INTO #fkeys
              --  SELECT rkeyid, rkey1, fkeyid, fkey1, 1, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey2, fkeyid, fkey2, 2, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey3, fkeyid, fkey3, 3, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey4, fkeyid, fkey4, 4, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey5, fkeyid, fkey5, 5, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey6, fkeyid, fkey6, 6, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey7, fkeyid, fkey7, 7, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey8, fkeyid, fkey8, 8, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey9, fkeyid, fkey9, 9, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey10, fkeyid, fkey10, 10, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey11, fkeyid, fkey11, 11, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey12, fkeyid, fkey12, 12, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey13, fkeyid, fkey13, 13, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey14, fkeyid, fkey14, 14, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey15, fkeyid, fkey15, 15, constid, name
              --  FROM #fkeysall
              --  UNION ALL
              --  SELECT rkeyid, rkey16, fkeyid, fkey16, 16, constid, name
              --  FROM #fkeysall
    
              --  INSERT INTO #fkeysout
              --  SELECT PKTABLE_QUALIFIER = CONVERT(sysname,db_name()),
              --         PKTABLE_OWNER     = CONVERT(sysname,USER_NAME(o1.uid)),
              --         PKTABLE_NAME      = CONVERT(sysname,o1.name),
              --         PKCOLUMN_NAME     = CONVERT(sysname,c1.name),
              --         FKTABLE_QUALIFIER = CONVERT(sysname,db_name()),
              --         FKTABLE_OWNER     = CONVERT(sysname,USER_NAME(o2.uid)),
              --         FKTABLE_NAME      = CONVERT(sysname,o2.name),
              --         FKCOLUMN_NAME     = CONVERT(sysname,c2.name),
              --         KEY_SEQ,
              --         UPDATE_RULE       = CONVERT(smallint,1),
              --         DELETE_RULE       = CONVERT(smallint,1),
              --         FK_NAME           = CONVERT(sysname,OBJECT_NAME(fk_id)),
              --         PK_NAME,
              --         DEFERRABILITY = 7        /* SQL_NOT_DEFERRABLE */
              --  FROM #fkeys f,
              --       sysobjects o1, sysobjects o2,
              --       syscolumns c1, syscolumns c2
              --  WHERE o1.id    = f.pktable_id
              --  AND   o2.id    = f.fktable_id
              --  AND   c1.id    = f.pktable_id
              --  AND   c2.id    = f.fktable_id
              --  AND   c1.colid = f.pkcolid
              --  AND   c2.colid = f.fkcolid

              --  --make where clause
              --  SELECT @innerwhere = ''
              --  SELECT @innerwhere = @innerwhere 
              --                       + CASE WHEN COLUMN_ORDER=1 THEN '' 
              --                                                  ELSE ' AND ' 
              --                                                  END 
              --                       + pk.COLUMN_NAME 
              --                       + ' = ISNULL(@' + pk.COLUMN_NAME + ', ' + pk.COLUMN_NAME + ')'
              --  FROM syscolumns sc 
              --  JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
              --  WHERE sc.id = @table_id
              --  ORDER BY sc.colorder

              --  IF (EXISTS(SELECT * FROM #fkeysout))
              --    BEGIN
              --      IF (@operation = 4)
              --        BEGIN
              --          PRINT 'IF (@purge = 0)'
              --          PRINT '  BEGIN'
              --        END
              --      ELSE
              --        BEGIN
              --          PRINT ''
              --          PRINT 'DELETE FROM ' + RTRIM(@table) 
              --          --PRINT ''
              --        END
              --    END
    

                -- OPEN A CURSOR ON DISTINCT FOREIGN KEY TABLES
                -- declare and fill the cursor
                PRINT 'BEGIN TRY'
                PRINT ''

                DECLARE  FTCH_TABLES CURSOR
                FOR SELECT DISTINCT COLUMN_NAME
                    FROM #tmp_pkeys
                    ORDER BY 1
    
                -- open the cursor and load the first record into variables
                OPEN FTCH_TABLES
                FETCH NEXT FROM FTCH_TABLES INTO @pkcolumn
    
                -- run through the cursor
                WHILE (@@FETCH_STATUS = 0)
                  BEGIN
                      --PRINT SPACE(4) + '--' + @fkkey
                      PRINT  'DELETE'
                      PRINT SPACE(2) + 'FROM ' + @table
                      SELECT @msg = ''
                      SELECT @msg = @msg 
                                    + SPACE(0)
                                    + CASE WHEN COLUMN_ORDER=1 THEN ' WHERE ' ELSE '   AND ' END 
                                    + COLUMN_NAME 
                                    + ' = @' + COLUMN_NAME 
                                    + CHAR(13) + CHAR(10)
                        FROM #tmp_pkeys pk 
                       WHERE COLUMN_NAME = @pkcolumn


                    PRINT @msg
                    PRINT ''
                    
                    FETCH NEXT FROM FTCH_TABLES INTO @pkcolumn
                    
                  END -- WHILE
                
                CLOSE FTCH_TABLES
                DEALLOCATE FTCH_TABLES

                PRINT ''
                PRINT 'END TRY'
                PRINT ''
                PRINT 'BEGIN CATCH'
                PRINT SPACE(2) + 'SELECT @msg = ERROR_MESSAGE()'
                PRINT SPACE(2) + 'RAISERROR(''%s : Errors occurred when deleting from table ' + QUOTENAME(@table) + ' with error [%s]'', 16,1,@proc_name, @msg)'
                PRINT SPACE(2) + 'RETURN(1)'
                PRINT 'END CATCH'

        END  --IF (@operation IN (3,4))

      IF (@operation = 1)
        BEGIN
          SELECT @msg = 'SELECT ',
                 @len = LEN(@msg) + 1

          --append column names
          SELECT @msg = @msg + 
                        CASE WHEN colid=1 THEN '' ELSE SPACE(@len) END + 
                        name + ',' + CHAR(13) + CHAR(10)
          FROM syscolumns
          WHERE id = @table_id
          ORDER BY colid

          --cut off last comma and char(13)+char(10)
          SELECT @msg = LEFT(@msg, LEN(@msg) - CHARINDEX(',', REVERSE(@msg)))
          PRINT @msg

          PRINT SPACE(2) + 'FROM ' + @table

          SELECT @msg = ''
          SELECT @msg = @msg 
                        + CASE WHEN COLUMN_ORDER=1 THEN ' WHERE ' ELSE '   AND ' END 
                        + pk.COLUMN_NAME 
                        + ' = ISNULL(@' + pk.COLUMN_NAME + ', ' + pk.COLUMN_NAME + ')' 
                        + CHAR(13) + CHAR(10)
          FROM syscolumns sc 
          JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
          WHERE id = @table_id
          ORDER BY colorder

          PRINT @msg
        END --IF (@operation = 1)

      IF (@operation = 4)
        BEGIN
          IF EXISTS(SELECT * FROM #fkeysout)
            BEGIN
              PRINT 'ELSE'
              PRINT SPACE(2) + 'BEGIN'
            END

          -- OPEN A CURSOR ON DISTINCT FOREIGN KEY TABLES
          -- declare and fill the cursor
          DECLARE  FTCH_TABLES CURSOR
          FOR SELECT DISTINCT FK_NAME
              FROM #fkeysout
              ORDER BY 1
    
          -- open the cursor and load the first record into variables
          OPEN FTCH_TABLES
          FETCH NEXT FROM FTCH_TABLES INTO @fkkey
    
          -- run through the cursor
          WHILE (@@FETCH_STATUS = 0)
            BEGIN
              -- check if all foreign key fields are part of primary key fields of foreign key table
              --if so, we can exec the purge proc for this foreign key table
              --if not, make delete
              SELECT @fktable = FKTABLE_NAME
                FROM #fkeysout
               WHERE FK_NAME = @fkkey

              IF EXISTS(SELECT *
                          FROM #fkeysout
                         WHERE FK_NAME = @fkkey
                           AND FKCOLUMN_NAME NOT IN ( SELECT c.name
                                                        FROM syscolumns c,
                                                             sysindexes i,
                                                             syscolumns c1
                                                       WHERE c.id               = OBJECT_ID(@fktable)
                                                         AND i.id               = c.id 
                                                         AND (i.status & 0x800) = 0x800
                                                         AND c.name             = INDEX_COL (@fktable, i.indid, c1.colid)
                                                         AND c1.colid           <= i.keycnt     
                                                         AND c1.id              = OBJECT_ID(@fktable)
                                                    )
                       )
                BEGIN
                  PRINT SPACE(4) + '--' + @fkkey
                  PRINT SPACE(4) + 'DELETE'
                  PRINT SPACE(6) + 'FROM ' + @fktable
                  SELECT @msg = ''
                  SELECT @msg = @msg 
                                + SPACE(4)
                                + CASE WHEN COLUMN_ORDER=1 THEN ' WHERE ' ELSE '   AND ' END 
                                + FKCOLUMN_NAME 
                                + ' = ISNULL(@' + pk.COLUMN_NAME + ', ' + FKCOLUMN_NAME + ')' 
                                + CHAR(13) + CHAR(10)
                    FROM #fkeysout ko
                    LEFT JOIN #tmp_pkeys pk ON ko.PKCOLUMN_NAME = COLUMN_NAME
                   WHERE FK_NAME = @fkkey

                  PRINT @msg
                  PRINT ''
                  -- Error Handling
                  SELECT @list = '@proc_name, ''' + @fktable + ''''
                  PRINT SPACE(4) + 'SELECT @error = @@error'
                  PRINT ''
                  PRINT SPACE(4) + 'IF (@error <> 0)'
                  PRINT SPACE(6) + 'BEGIN'
                  PRINT SPACE(8) + 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION'
                  PRINT SPACE(8) + '-- Delete failed from table %s'
                  PRINT SPACE(8) + 'RAISERROR (55164, 16, 1, ' + @list + ', @valueliststr, @error)'
                  PRINT SPACE(8) + 'RETURN (1)'
                  PRINT SPACE(6) + 'END'
                  PRINT ''
                END
              ELSE
                BEGIN
                  PRINT SPACE(4) + '--' + @fkkey
                  SELECT @len = 0
                         , @msg = ''
                         , @fkcount = 0
                  SELECT @fkcount = @fkcount + 1
                         , @msg = @msg 
                                  + CASE WHEN @fkcount = 1 THEN SPACE(4) ELSE '' END
                                  + CASE WHEN @fkcount = 1 THEN 'EXEC @status = p_' 
                                                                + @project 
                                                                + 'del_' 
                                                                + REPLACE(CASE WHEN LEFT(@fktable, 2) = 't_' THEN RIGHT(@fktable, LEN(@fktable) - 2)
                                                                                                             ELSE @fktable
                                                                                                             END
                                                                          , @projectfromtable
                                                                          , '')
                                                                + ' @'  + FKCOLUMN_NAME  
                                                                + CASE WHEN COLUMN_NAME IS NULL 
                                                                       THEN ' = NULL'
                                                                       ELSE ' = @' + COLUMN_NAME 
                                                                       END
                                                           ELSE ', @' + FKCOLUMN_NAME 
                                                                + CASE WHEN COLUMN_NAME IS NULL 
                                                                       THEN ' = NULL'
                                                                       ELSE ' = @' + COLUMN_NAME
                                                                       END
                                                           END
                  FROM ( SELECT c.name as FKCOLUMN_NAME
                           FROM syscolumns c,
                                sysindexes i,
                                syscolumns c1
                          WHERE c.id               = OBJECT_ID(@fktable)
                            AND i.id               = c.id 
                            AND (i.status & 0x800) = 0x800
                            AND c.name             = INDEX_COL (@fktable, i.indid, c1.colid)
                            AND c1.colid           <= i.keycnt  
                            AND c1.id              = OBJECT_ID(@fktable)
                       ) foreign_pks
                  LEFT JOIN #tmp_pkeys ON COLUMN_NAME = FKCOLUMN_NAME

                  SELECT @msg = @msg + ', @purge = 1'
                  PRINT @msg
                  SELECT @list = '@proc_name, ''' + @table + ''''
                    
                  -- Error Handling
                  PRINT SPACE(4) + 'SELECT @error = @@error'
                  PRINT ''
                  PRINT SPACE(4) + 'IF (@error <> 0 OR @status <> 0)'
                  PRINT SPACE(6) + 'BEGIN'
                  PRINT SPACE(8) + 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION'
                  PRINT SPACE(8) + '-- Delete failed from table %s'
                  PRINT SPACE(8) + 'RAISERROR (55164, 16, 1, ' + @list + ', @valueliststr, @error)'
                  PRINT SPACE(8) + 'RETURN (1)'
                  PRINT SPACE(6) + 'END'
                  PRINT ''
                END
                    
              FETCH NEXT FROM FTCH_TABLES INTO @fkkey
                    
            END -- WHILE
                
          CLOSE FTCH_TABLES
          DEALLOCATE FTCH_TABLES

          IF EXISTS(SELECT * FROM #fkeysout)
            BEGIN
              PRINT SPACE(2) + 'END'
            END

          PRINT ''
          PRINT 'DELETE'
          PRINT SPACE(2) + 'FROM ' + @table

          SELECT @msg = ''
          SELECT @msg = @msg 
                        + CASE WHEN COLUMN_ORDER=1 THEN ' WHERE ' ELSE '   AND ' END 
                        + pk.COLUMN_NAME 
                        + ' = ISNULL(@' + pk.COLUMN_NAME + ', ' + pk.COLUMN_NAME + ')' 
                        + CHAR(13) + CHAR(10)
          FROM syscolumns sc 
          JOIN #tmp_pkeys pk ON pk.COLUMN_NAME = sc.name
          WHERE id = @table_id
          ORDER BY colorder

          PRINT @msg
          PRINT ''
          -- Error Handling
          SELECT @list = '@proc_name, ''' + @table + ''''
          PRINT 'SELECT @error = @@error, @deleted=@@ROWCOUNT'
          PRINT ''
          PRINT 'IF (@error <> 0)'
          PRINT SPACE(2) + 'BEGIN'
          PRINT SPACE(4) + 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION'
          PRINT SPACE(4) + '-- Delete failed from table %s'
          PRINT SPACE(4) + 'RAISERROR (55164, 16, 1, ' + @list + ', @valueliststr, @error)'
          PRINT SPACE(4) + 'RETURN (1)'
          PRINT SPACE(2) + 'END'
          PRINT ''
          PRINT 'COMMIT TRANSACTION'
          PRINT ''
        END --IF (@operation = 4)
                
    END  --ELSE
  

PRINT ''
PRINT '-- return success'
PRINT 'RETURN(0)'
PRINT 'GO'
PRINT ''

PRINT 'IF OBJECT_ID(''' + @sp_proc_name + ''') IS NOT NULL'
PRINT '  PRINT ''PROCEDURE ' + @sp_proc_name + ' has been created...'''
PRINT 'ELSE'
PRINT '  PRINT ''PROCEDURE ' + @sp_proc_name + ' has NOT been created due to errors...'''

PRINT 'GO'

--PRINT '-- show stored procedure properties'
--PRINT 'sp_help ''dbo.' + @sp_proc_name + '''' 
--PRINT 'GO'

DROP TABLE #tmp_pkeys 
DROP TABLE #fkeys
DROP TABLE #fkeysall
DROP TABLE #fkeysout       
-- return success
RETURN(0)

GO


