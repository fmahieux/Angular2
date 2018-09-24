

CREATE TABLE [dbo].[SqlSource](
	[Id] [int] NOT NULL,
	[Description] [varchar](1000) NOT NULL,
	[Enabled] [bit] NOT NULL,
	[ForJson] [varchar](50) NOT NULL,
	[Name] [varchar](1000) NOT NULL,
	[SqlSourceTypeId] [int] NOT NULL,
	[Statement] [varchar](1000) NOT NULL,
 CONSTRAINT [PK_SqlSource] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SqlSource]  WITH CHECK ADD  CONSTRAINT [fk1_SqlSource] FOREIGN KEY([SqlSourceTypeId])
REFERENCES [dbo].[SqlSourceType] ([Id])
GO

ALTER TABLE [dbo].[SqlSource] CHECK CONSTRAINT [fk1_SqlSource]
GO


