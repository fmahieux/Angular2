

CREATE TABLE [dbo].[SqlObject](
	[Id] [int] NOT NULL,
	[DeleteId] [int] NULL,
	[Description] [varchar](255) NOT NULL,
	[Enabled] [bit] NOT NULL,
	[InsertId] [int] NULL,
	[Name] [varchar](100) NOT NULL,
	[SelectId] [int] NOT NULL,
	[UpdateId] [int] NULL,
 CONSTRAINT [PK_SqlObject] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SqlObject]  WITH CHECK ADD  CONSTRAINT [fk1_SqlObject] FOREIGN KEY([SelectId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlObject] CHECK CONSTRAINT [fk1_SqlObject]
GO

ALTER TABLE [dbo].[SqlObject]  WITH CHECK ADD  CONSTRAINT [fk2_SqlObject] FOREIGN KEY([UpdateId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlObject] CHECK CONSTRAINT [fk2_SqlObject]
GO

ALTER TABLE [dbo].[SqlObject]  WITH CHECK ADD  CONSTRAINT [fk3_SqlObject] FOREIGN KEY([InsertId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlObject] CHECK CONSTRAINT [fk3_SqlObject]
GO

ALTER TABLE [dbo].[SqlObject]  WITH CHECK ADD  CONSTRAINT [fk4_SqlSource] FOREIGN KEY([DeleteId])
REFERENCES [dbo].[SqlSource] ([Id])
GO

ALTER TABLE [dbo].[SqlObject] CHECK CONSTRAINT [fk4_SqlSource]
GO


