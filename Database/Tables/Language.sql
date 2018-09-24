CREATE TABLE [dbo].[Language](
	[Culture] [dbo].[d_language] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[SequenceNr] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Table] PRIMARY KEY CLUSTERED 
(
	[Culture] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


