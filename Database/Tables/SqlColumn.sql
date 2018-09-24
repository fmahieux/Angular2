
CREATE TABLE [dbo].[SqlColumn](
	[Id] [int] NOT NULL,
	[DataTypeId] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
	[IsKey] [bit] NOT NULL,
	[IsLocalized] [bit] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[OrderSequenceNr] [int] NOT NULL,
	[SequenceNr] [int] NOT NULL,
	[SourceId] [int] NOT NULL,
 CONSTRAINT [PK_SqlColumn] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SqlColumn]  WITH CHECK ADD  CONSTRAINT [fk1_SqlColumn] FOREIGN KEY([SourceId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlColumn] CHECK CONSTRAINT [fk1_SqlColumn]
GO

ALTER TABLE [dbo].[SqlColumn]  WITH CHECK ADD  CONSTRAINT [fk2_SqlColumn] FOREIGN KEY([DataTypeId])
REFERENCES [dbo].[SqlDatatype] ([Id])
GO

ALTER TABLE [dbo].[SqlColumn] CHECK CONSTRAINT [fk2_SqlColumn]
GO


