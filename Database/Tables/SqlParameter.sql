
CREATE TABLE [dbo].[SqlParameter](
	[Id] [int] NOT NULL,
	[DatatypeId] [int] NOT NULL,
	[DefaultValue] [varchar](max) NULL,
	[Enabled] [bit] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[OperatorId] [int] NOT NULL,
	[SequenceNr] [int] NOT NULL,
	[SourceId] [int] NOT NULL,
 CONSTRAINT [PK_SqlParameter] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[SqlParameter]  WITH CHECK ADD  CONSTRAINT [fk1_SqlParameter] FOREIGN KEY([SourceId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlParameter] CHECK CONSTRAINT [fk1_SqlParameter]
GO

ALTER TABLE [dbo].[SqlParameter]  WITH CHECK ADD  CONSTRAINT [fk2_SqlParameter] FOREIGN KEY([DatatypeId])
REFERENCES [dbo].[SqlDatatype] ([Id])
GO

ALTER TABLE [dbo].[SqlParameter] CHECK CONSTRAINT [fk2_SqlParameter]
GO

ALTER TABLE [dbo].[SqlParameter]  WITH CHECK ADD  CONSTRAINT [fk3_SqlParameter] FOREIGN KEY([OperatorId])
REFERENCES [dbo].[SqlOperator] ([Id])
GO

ALTER TABLE [dbo].[SqlParameter] CHECK CONSTRAINT [fk3_SqlParameter]
GO


