
CREATE TABLE [dbo].[Resource](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[d_name] NOT NULL,
	[LanguageId] [dbo].[d_language] NOT NULL,
	[Value] [dbo].[d_value] NOT NULL,
 CONSTRAINT [pk_Resource] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq1_Resource] UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[LanguageId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Resource]  WITH CHECK ADD  CONSTRAINT [fk1_Resource] FOREIGN KEY([Name])
REFERENCES [dbo].[ResourceKey] ([Name])
GO

ALTER TABLE [dbo].[Resource] CHECK CONSTRAINT [fk1_Resource]
GO

ALTER TABLE [dbo].[Resource]  WITH CHECK ADD  CONSTRAINT [fk2_Resource] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[Language] ([Culture])
GO

ALTER TABLE [dbo].[Resource] CHECK CONSTRAINT [fk2_Resource]
GO


