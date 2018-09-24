
CREATE TABLE [dbo].[ResourceCategory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[d_name] NOT NULL,
	[Description] [dbo].[d_description] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [pk_ResourceCategory] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq1_ResourceCategory] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ResourceCategory] ADD  CONSTRAINT [DF_ResourceCategory_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO


