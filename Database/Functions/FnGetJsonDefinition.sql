CREATE FUNCTION [dbo].[FnGetJsonDefinition](@JsonValues NVARCHAR(MAX))
RETURNS TABLE
AS RETURN
(
  SELECT ObjectId   = JSON_VALUE(@JsonValues, '$.ObjectId')
        ,ObjectName = JSON_VALUE(@JsonValues, '$.ObjectName')
        ,PageNumber = ISNULL(JSON_VALUE(@JsonValues, '$.PageNumber'), 0)
        ,PageSize   = ISNULL(JSON_VALUE(@JsonValues, '$.PageSize'), 0)
        ,AsJson     = ISNULL(JSON_VALUE(@JsonValues, '$.AsJson'), 0)
        ,LanguageId = ISNULL(JSON_VALUE(@JsonValues, '$.LanguageId'), 'fr-fr')
        ,GridMode   = ISNULL(JSON_VALUE(@JsonValues, '$.GridMode'), 0)
        ,JsonType   = ISNULL(JSON_VALUE(@JsonValues, '$.JsonType'), 0)
)
GO


