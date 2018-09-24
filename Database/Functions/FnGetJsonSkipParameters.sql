
CREATE FUNCTION [dbo].[FnGetJsonSkipParameters](@JsonValues NVARCHAR(MAX))
RETURNS TABLE
AS RETURN
(
  SELECT  ParamName = LTRIM(RTRIM(ParamName))
    FROM OPENJSON(@JsonValues, '$.SkipParameters')
    WITH (
            ParamName VARCHAR(100)
          ) AS ParamValues
)
GO


