
CREATE TABLE [dbo].[SqlOperator](
	[Id] [int] NOT NULL,
	[CloseModulo] [bit] NOT NULL,
	[CloseParenthesis] [bit] NOT NULL,
	[Ddl] [varchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL,
	[Name] [varchar](1000) NOT NULL,
	[OpenModulo] [bit] NOT NULL,
	[OpenParenthesis] [bit] NOT NULL,
 CONSTRAINT [PK_SqlOperator] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


