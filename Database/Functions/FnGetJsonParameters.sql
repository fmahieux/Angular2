create FUNCTION [dbo].[FnGetJsonParameters](@JsonValues NVARCHAR(MAX))
RETURNS TABLE
AS RETURN
(
  SELECT  ParamName = LTRIM(RTRIM(ParamName))
         ,ParamValue = LTRIM(RTRIM(ParamValue))
    FROM OPENJSON(@JsonValues, '$.Parameters')
    WITH (
            ParamName VARCHAR(100)
            ,ParamValue VARCHAR(MAX)
          ) AS ParamValues
)
GO


