
CREATE TABLE [dbo].[ResourceKey](
	[CategoryId] [int] NULL,
	[Name] [dbo].[d_name] NOT NULL,
 CONSTRAINT [pk_ResourceKey] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ResourceKey]  WITH CHECK ADD  CONSTRAINT [fk1_ResourceKey] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[ResourceCategory] ([Id])
GO

ALTER TABLE [dbo].[ResourceKey] CHECK CONSTRAINT [fk1_ResourceKey]
GO


