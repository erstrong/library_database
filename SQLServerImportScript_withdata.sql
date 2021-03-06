USE [master]
GO
/****** Object:  Database [EMILYSHAWN_ACADEMIC_LIBRARY]    Script Date: 4/9/2017 11:23:09 PM ******/
CREATE DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'EMILYSHAWN_ACADEMIC_LIBRARY', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\EMILYSHAWN_ACADEMIC_LIBRARY.mdf' , SIZE = 3136KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'EMILYSHAWN_ACADEMIC_LIBRARY_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\EMILYSHAWN_ACADEMIC_LIBRARY_log.ldf' , SIZE = 784KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [EMILYSHAWN_ACADEMIC_LIBRARY].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ARITHABORT OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET  ENABLE_BROKER 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET RECOVERY FULL 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET  MULTI_USER 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET DB_CHAINING OFF 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'EMILYSHAWN_ACADEMIC_LIBRARY', N'ON'
GO
USE [EMILYSHAWN_ACADEMIC_LIBRARY]
GO
/****** Object:  StoredProcedure [dbo].[CheckInItem]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[CheckInItem]
	@PatronID varchar(9),
	@Barcode varchar(12)
as
begin
	declare @DateReturned datetime;
	set @DateReturned = getdate();
	update Fines set DateReturned=@DateReturned 
		where @PatronID = PatronID
		and @Barcode = Barcode 
		and DueDate = 
			(select DueDate from CheckoutTransaction 
				where PatronID=@PatronID and Barcode=@Barcode);
	update Holds set Status='READY FOR PICKUP'
		where Barcode=@Barcode 
		and HoldPlacedDate=
			(select min(HoldPlacedDate) 
			from Holds where Barcode=@Barcode);
	delete from CheckoutTransaction 
		where PatronID=@PatronID 
		and Barcode=@Barcode;
end
GO
/****** Object:  StoredProcedure [dbo].[CheckOutItem]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[CheckOutItem]
	@PatronID varchar(9),
	@Barcode varchar(12)
as
begin
	declare @CheckoutTimestamp datetime;
	set @CheckoutTimestamp = sysdatetime();
	declare @Rule1 int;
	set @Rule1 = (select t.BorrowingRule 
		from dbo.PatronType t,dbo.Patron p
		where t.PatronTypeID = p.PatronTypeID 
		and p.PatronID = @PatronID);
	declare @Rule2 int;
	set @Rule2 = (select b.PolicyRule 
		from dbo.BorrowingPolicies b,dbo.Copy c
		where b.PolicyID=c.PolicyID 
		and c.Barcode = @Barcode);
	declare @DueDate datetime; 
	set @DueDate =
	 case @Rule2 
		when 0.125
			then DateAdd(hour,3,@CheckoutTimestamp)
		when 21
			then DateAdd(day,21,@CheckoutTimestamp)
		when 5
			then DateAdd(day,5,@CheckoutTimestamp)
		else 
			DateAdd(day,1,@CheckoutTimestamp)
		end;
	insert into CheckoutTransaction values
		(@PatronID,@Barcode,@CheckoutTimestamp,@DueDate,null);
	update Copy set 
		DateLastCheckedOut=convert(date, getdate()) 
		where Barcode=@Barcode;
	update Copy set 
		CheckoutCount = (1 + (
			select CheckoutCount 
			from Copy 
			where Barcode=@Barcode))
		where Barcode=@Barcode;
end

GO
/****** Object:  StoredProcedure [dbo].[ExpiredHolds]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ExpiredHolds]
as
begin
	delete from Holds 
		where HoldUntilDate < getdate()
		and Status='ON HOLD';
end
GO
/****** Object:  StoredProcedure [dbo].[RenewItem]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- renew item
	-- holds
	-- clear fines
create procedure [dbo].[RenewItem]
	@PatronID varchar(9),
	@Barcode varchar(12)
as
begin
	declare @Count int;
	set @Count = (select RenewalCount from CheckoutTransaction
	where Barcode=@Barcode and PatronID=@PatronID);
	if exists (select * from Holds where Barcode=@Barcode)
	  print 'Renewal denied. Item is on hold.';
	else if @Count=2
	 print 'Renewal denied. Maximum renewals reached.';
	else
	begin
		declare @RenewalTimestamp datetime;
		set @RenewalTimestamp = sysdatetime();
		declare @Rule1 int;
		set @Rule1 = (select t.BorrowingRule 
			from dbo.PatronType t,dbo.Patron p
			where t.PatronTypeID = p.PatronTypeID 
			and p.PatronID = @PatronID);
		declare @Rule2 int;
		set @Rule2 = (select b.PolicyRule 
			from dbo.BorrowingPolicies b,dbo.Copy c
			where b.PolicyID=c.PolicyID 
			and c.Barcode = @Barcode);
		declare @DueDate datetime; 
	set @DueDate =
	 case @Rule2 
		when 0.125
			then DateAdd(hour,3,@RenewalTimestamp)
		when 21
			then DateAdd(day,21,@RenewalTimestamp)
		when 5
			then DateAdd(day,5,@RenewalTimestamp)
		else 
			DateAdd(day,1,@RenewalTimestamp)
		end;
		update CheckoutTransaction 
			set DueDate= @DueDate
			where PatronID=@PatronID and Barcode=@Barcode;
		update CheckoutTransaction
			set RenewalCount = @Count+1
			where PatronID=@PatronID and Barcode=@Barcode;
		delete from Fines
			where PatronID=@PatronID 
			and Barcode=@Barcode 
			and DueDate is null;
	end
end
GO
/****** Object:  StoredProcedure [dbo].[UpdateFines]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[UpdateFines]
as
begin
	insert into Fines (PatronID,Barcode,DueDate)
		(select PatronID, Barcode, DueDate
		from CheckoutTransaction
		where DueDate < getdate());
	update Fines
		set AmountDue = datediff(day,DueDate,getdate())
		where DateReturned is null;
end
GO
/****** Object:  Table [dbo].[AcquisitionOrders]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AcquisitionOrders](
	[Status] [varchar](15) NOT NULL,
	[CallNo] [varchar](50) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[VendorID] [varchar](5) NOT NULL,
	[Barcode] [varchar](12) NULL,
	[PatronID] [varchar](9) NULL,
PRIMARY KEY CLUSTERED 
(
	[CallNo] ASC,
	[DateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Address]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Address](
	[AddressID] [varchar](9) NOT NULL,
	[Street] [varchar](50) NULL,
	[City] [varchar](20) NULL,
	[State] [varchar](20) NULL,
	[Country] [varchar](20) NULL,
	[PostalCode] [varchar](6) NULL,
PRIMARY KEY CLUSTERED 
(
	[AddressID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Author]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Author](
	[AuthorID] [int] NOT NULL,
	[AuthorFirstName] [varchar](25) NOT NULL,
	[AuthorLastName] [varchar](25) NOT NULL,
	[AuthorDOB] [date] NULL,
	[AuthorDOD] [date] NULL,
	[AuthorBio] [varchar](5000) NULL,
PRIMARY KEY CLUSTERED 
(
	[AuthorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BorrowingPolicies]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BorrowingPolicies](
	[PolicyID] [varchar](10) NOT NULL,
	[PolicyRule] [decimal](6, 3) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PolicyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CheckoutTransaction]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CheckoutTransaction](
	[PatronID] [varchar](9) NOT NULL,
	[Barcode] [varchar](12) NOT NULL,
	[CheckoutTimestamp] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[RenewalCount] [int] NULL,
 CONSTRAINT [PK_CheckoutTransaction] PRIMARY KEY CLUSTERED 
(
	[PatronID] ASC,
	[Barcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Collection]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Collection](
	[CollectionID] [varchar](12) NOT NULL,
	[CollectionName] [varchar](50) NULL,
	[CollectionLocation] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[CollectionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Copy]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Copy](
	[Barcode] [varchar](12) NOT NULL,
	[CallNo] [varchar](50) NULL,
	[Status] [varchar](20) NOT NULL,
	[CreationDate] [date] NULL,
	[PolicyID] [varchar](10) NOT NULL,
	[CollectionID] [varchar](12) NOT NULL,
	[CheckoutCount] [int] NULL,
	[DateLastCheckedOut] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Barcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CourseReserveList]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CourseReserveList](
	[CourseID] [varchar](16) NOT NULL,
	[Barcode] [varchar](12) NOT NULL,
 CONSTRAINT [PK_CourseReserveList] PRIMARY KEY CLUSTERED 
(
	[CourseID] ASC,
	[Barcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Courses]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Courses](
	[CourseID] [varchar](16) NOT NULL,
	[CourseName] [varchar](50) NULL,
	[CourseDept] [varchar](4) NULL,
	[CourseInstructor] [varchar](50) NULL,
	[CourseTerm] [varchar](6) NULL,
	[CollectionID] [varchar](12) NULL,
	[PolicyID] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[CourseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[edition]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[edition](
	[CallNo] [varchar](50) NOT NULL,
	[ISBN10] [char](10) NOT NULL,
	[ISBN13] [char](13) NOT NULL,
	[ImprintID] [int] NOT NULL,
	[format] [varchar](15) NOT NULL,
	[DatePublished] [date] NOT NULL,
	[City] [varchar](20) NULL,
	[Language] [varchar](20) NULL,
	[Pages] [int] NULL,
	[TitleID] [varchar](10) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CallNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Fines]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Fines](
	[PatronID] [varchar](9) NOT NULL,
	[Barcode] [varchar](12) NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[DateReturned] [datetime] NULL,
	[AmountDue] [varchar](6) NULL,
 CONSTRAINT [PK_Fines] PRIMARY KEY CLUSTERED 
(
	[PatronID] ASC,
	[Barcode] ASC,
	[DueDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Holds]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Holds](
	[PatronID] [varchar](9) NOT NULL,
	[Barcode] [varchar](12) NOT NULL,
	[HoldPlacedDate] [datetime] NOT NULL,
	[HoldUntilDate] [datetime] NOT NULL,
	[Status] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Holds] PRIMARY KEY CLUSTERED 
(
	[PatronID] ASC,
	[Barcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Patron]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Patron](
	[PatronID] [varchar](9) NOT NULL,
	[PatronFirstName] [varchar](50) NULL,
	[PatronLastName] [varchar](50) NULL,
	[PatronTypeID] [varchar](3) NOT NULL,
	[PatronEmail] [varchar](50) NULL,
	[PatronPhoneNo] [varchar](12) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatronID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PatronAddresses]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PatronAddresses](
	[AddressType] [varchar](6) NOT NULL,
	[PatronID] [varchar](9) NOT NULL,
	[AddressID] [varchar](9) NULL,
 CONSTRAINT [PK_PatronAddresses] PRIMARY KEY CLUSTERED 
(
	[AddressType] ASC,
	[PatronID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PatronType]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PatronType](
	[PatronTypeID] [varchar](3) NOT NULL,
	[BorrowingRule] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PatronTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PublisherImprint]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PublisherImprint](
	[ImprintID] [int] NOT NULL,
	[PublisherName] [varchar](40) NOT NULL,
	[ImprintName] [varchar](40) NOT NULL,
	[AddressID] [varchar](9) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ImprintID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Subjects]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Subjects](
	[SubjectName] [varchar](40) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[SubjectName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SubjectTitle]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SubjectTitle](
	[SubjectName] [varchar](40) NOT NULL,
	[TitleID] [varchar](10) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[SubjectName] ASC,
	[TitleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Title]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Title](
	[TitleID] [varchar](10) NOT NULL,
	[AuthorID] [int] NOT NULL,
	[TitleName] [varchar](500) NOT NULL,
	[Description] [varchar](5000) NULL,
	[FirstPublishedDate] [date] NULL,
	[TitleOriginalLanguage] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[TitleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TitlesAuthors]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TitlesAuthors](
	[TitleID] [varchar](10) NOT NULL,
	[AuthorID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AuthorID] ASC,
	[TitleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Vendors]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Vendors](
	[VendorID] [varchar](5) NOT NULL,
	[VendorName] [varchar](100) NOT NULL,
	[VendorEmail] [varchar](50) NULL,
	[VendorPhoneNo] [varchar](30) NULL,
	[AddressID] [varchar](9) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[VendorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[Open_Orders]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Open_Orders] as select g.VendorName, g.VendorPhoneNo, g.VendorEmail, h.Street, h.City, h.[State], h.PostalCode, d.[status], d.CallNo, d.[DateTime], c.DatePublished, e.TitleName, f.PublisherName from AcquisitionOrders d
join edition c
on c.CallNo=d.CallNo
join Title e
on c.TitleID=e.TitleID
join PublisherImprint f
on c.ImprintID=f.ImprintID
join Vendors g
on d.VendorID=g.VendorID
join [address] h
on g.AddressID=h.AddressID
where d.[status]='Open';
GO
/****** Object:  View [dbo].[Overdue]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Overdue] as select a.TitleName, b.CallNo, c.PatronFirstName, c.PatronLastName, c.PatronEmail, d.DueDate, d.Barcode from CheckoutTransaction d
join Patron c
on d.PatronID=c.PatronID
join [copy] e
on d.Barcode=e.Barcode
join Edition b
on e.CallNo=b.CallNo
join Title a
on b.TitleID=a.TitleID
where d.DueDate<CURRENT_TIMESTAMP;
GO
/****** Object:  View [dbo].[PatronFines]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[PatronFines] as
select 
p.PatronId,PatronFirstName,PatronLastName,PatronEmail,c.CallNo,t.TitleName,f.Barcode,f.DueDate,f.AmountDue
from Patron p,Fines f,Copy c,Title t
where p.PatronID=f.PatronID
and f.Barcode=c.Barcode
and t.TitleID =(select TitleID from edition e where e.CallNo=c.CallNo);
GO
/****** Object:  View [dbo].[Ready_For_Pickup]    Script Date: 4/9/2017 11:23:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Ready_For_Pickup] as select a.TitleName, b.CallNo, c.PatronFirstName, c.PatronLastName, c.PatronEmail, d.[Status], d.HoldPlacedDate, d.HoldUntilDate, d.Barcode from Holds d
join Patron c
on d.PatronID=c.PatronID
join [copy] e
on d.Barcode=e.Barcode
join Edition b
on e.CallNo=b.CallNo
join Title a
on b.TitleID=a.TitleID
where d.[Status]='ON HOLD';
GO
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'DA950.7 .K45 2012', CAST(N'2013-05-05 11:15:11.000' AS DateTime), N'33333', N'237131477359', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'E744 .M868 2013', CAST(N'2014-05-05 11:11:11.000' AS DateTime), N'22222', N'798287244823', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'HB241 .J67 2000', CAST(N'1998-05-05 11:11:11.000' AS DateTime), N'55555', N'396144853426', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'HM251 .B437 2003', CAST(N'2004-05-05 11:11:11.000' AS DateTime), N'88888', N'471424403122', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'M1001.B4 W5 1935', CAST(N'1988-05-05 11:11:11.000' AS DateTime), N'44444', N'837556894200', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PE1408.S772 1999', CAST(N'2000-05-05 11:11:11.000' AS DateTime), N'66666', N'454898933545', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PN1995.9.H5 G737 1992', CAST(N'2000-05-05 11:11:11.000' AS DateTime), N'11111', N'192868655016', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Open', N'PN1995.9.H5 G737 1992', CAST(N'2016-05-05 11:11:11.000' AS DateTime), N'11111', NULL, N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR2807.A2 T46 2006', CAST(N'2000-01-05 11:11:11.000' AS DateTime), N'22222', N'223880032392', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR2807.A2 T46 2006', CAST(N'2014-05-05 11:11:11.000' AS DateTime), N'00100', N'728187260948', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR3330.A2 S47 1987', CAST(N'1992-05-05 11:11:11.000' AS DateTime), N'00100', N'638518606133', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR3330.A2 S47 1987', CAST(N'2013-05-05 11:11:11.000' AS DateTime), N'77777', N'456022087476', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR6023.E926 L5 1997', CAST(N'1999-05-05 11:11:11.000' AS DateTime), N'99999', N'529427240156', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PR6060.A467 C48 1993', CAST(N'1999-05-05 11:11:11.000' AS DateTime), N'66666', N'850891785675', N'912345678')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'PS3537.T3234 G8 1958', CAST(N'1993-05-05 11:11:11.000' AS DateTime), N'44444', N'318656056758', N'901234551')
INSERT [dbo].[AcquisitionOrders] ([Status], [CallNo], [DateTime], [VendorID], [Barcode], [PatronID]) VALUES (N'Closed', N'QD478 .S53 2012', CAST(N'2013-05-05 11:11:11.000' AS DateTime), N'88888', N'923941555344', N'912345678')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000001', N'360 Huntington Ave', N'Boston', N'MA', N'USA', N'02115')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000002', N'416 Huntington Ave', N'Boston', N'MA', N'USA', N'02115')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000003', N'236 Huntington Ave', N'Boston', N'MA', N'USA', N'02115')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000004', N'177 Huntington Ave', N'Boston', N'MA', N'USA', N'02115')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000005', N'250 Columbus Place', N'Boston', N'MA', N'USA', N'02116')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000006', N'716 Columbus Avenue', N'Boston', N'MA', N'USA', N'02120')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000007', N'40 Columbus Place', N'Boston', N'MA', N'USA', N'02116')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000008', N'370 Common Street', N'Dedham', N'MA', N'USA', N'02026')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000009', N'145 South Bedford St', N'Burlington', N'MA', N'USA', N'01803')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000010', N'430 Nahant Road', N'Nahant', N'MA', N'USA', N'01908')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000011', N'101 N. Tryon Street', N'Charlotte', N'NC', N'USA', N'28246')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000012', N'401 Terry Avenue North', N'Seattle', N'WA', N'USA', N'98109')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000020', N'45 Queensboro Lane', N'London', N'Surrey', N'England', N'38590A')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000021', N'56 North Lane', N'Boston', N'MA', N'USA', N'02134')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000022', N'43 South Lane', N'New York', N'NY', N'USA', N'01143')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000023', N'58 Jerry Avenue', N'Dallas', N'Texas', N'USA', N'94832')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000024', N'89 Surrey Highway', N'London', N'Surrey', N'England', N'93843B')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000025', N'56 12th Street NW', N'New York', N'NY', N'USA', N'01143')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000026', N'574 Republican Boulevard', N'Dublin', N'Meade', N'Ireland', N'4839VW')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000027', N'483 Maryland Avenue', N'Washington', N'DC', N'USA', N'39423')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000028', N'34 West Street SW', N'Baltimore', N'MD', N'USA', N'34928')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000029', N'48 Revere Road', N'Boston', N'MA', N'USA', N'38492')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000030', N'483 North Street', N'Los Angeles', N'CA', N'USA', N'83928')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000031', N'240 North Avenue', N'Manchester', N'NH', N'USA', N'23849')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000032', N'300 Americas Avenue', N'Nashua', N'NH', N'USA', N'48394')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000033', N'600 Williams Street', N'Baltimore', N'MD', N'USA', N'39204')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000034', N'839 Westville Avenue', N'Washington', N'DC', N'USA', N'49304')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000035', N'938 Coleville Street', N'Philadelphia', N'PN', N'USA', N'39203')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000036', N'9999 Eastville Lane', N'Indianapolis', N'IN', N'USA', N'39203')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000037', N'392 Silicon Street', N'Miami', N'FL', N'USA', N'99893')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000038', N'939 Lima Lane', N'Houston', N'TX', N'USA', N'99483')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000039', N'9483 Louisville Lane', N'Los Angeles', N'CA', N'USA', N'39283')
INSERT [dbo].[Address] ([AddressID], [Street], [City], [State], [Country], [PostalCode]) VALUES (N'000000040', N'818 Dallas Lane', N'Dallas', N'TX', N'USA', N'39293')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (1, N'William', N'Shakespeare', CAST(N'1564-01-26' AS Date), CAST(N'1616-04-23' AS Date), N'[William Shakespeare (/''?e?ksp??r/;[1] 26 April 1564 (baptised) – 23 April 1616)[nb 1] was an English poet, playwright, and actor, widely regarded as the greatest writer in the English language and the worlds pre-eminent dramatist.[2] He is often called Englands national poet, and the "Bard of Avon".[3][nb 2] His extant works, including collaborations, consist of approximately 38 plays,[nb 3] 154 sonnets, two long narrative poems, and a few other verses, some of uncertain authorship. His plays have been translated into every major living language and are performed more often than those of any other playwright]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (2, N'Lesley', N'Smart', CAST(N'1960-01-01' AS Date), NULL, N'A preeminent chemist with over 30 years of experience in industry and academia.')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (3, N'Robert', N'Baron', CAST(N'1972-01-01' AS Date), NULL, NULL)
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (4, N'Ludwig', N'Van Beethoven', CAST(N'1770-12-17' AS Date), CAST(N'1827-03-26' AS Date), N'Born in Bonn, then the capital of the Electorate of Cologne and part of the Holy Roman Empire, Beethoven displayed his musical talents at an early age and was taught by his father Johann van Beethoven and by composer and conductor Christian Gottlob Neefe. At the age of 21 he moved to Vienna, where he began studying composition with Joseph Haydn, and gained a reputation as a virtuoso pianist. He lived in Vienna until his death. By his late 20s his hearing began to deteriorate, and by the last decade of his life he was almost completely deaf. In 1811 he gave up conducting and performing in public but continued to compose; many of his most admired works come from these last 15 years of his life.')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (5, N'C.S.', N'Lewis', CAST(N'1898-11-28' AS Date), CAST(N'1963-11-22' AS Date), N'[Lewiss works have been translated into more than 30 languages and have sold millions of copies. The books that make up The Chronicles of Narnia have sold the most and have been popularised on stage, TV, radio, and cinema. His works entered the public domain in 2014 in countries where copyright expires 50 years after the death of the creator, such as Canada.]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (6, N'John', N'Kelly', CAST(N'1945-01-01' AS Date), NULL, N'A noted Irish historian from the University of Dublin. His many works include histories of the Catholic church, English imperialism, and the great famine.')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (7, N'John', N'Steinbeck', CAST(N'1902-02-27' AS Date), CAST(N'1968-12-20' AS Date), N'[The winner of the 1962 Nobel Prize in Literature, he has been called "a giant of American letters". His works are widely read abroad and many of his works are considered classics of Western literature.]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (8, N'Peter', N'Munson', CAST(N'1975-01-01' AS Date), NULL, NULL)
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (9, N'Dale', N'Jorgenson', CAST(N'1933-01-05' AS Date), NULL, N'[A nobel prize winning econonomist from the University of Stockholm with years of experience teaching and writing for beginning students in the field]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (10, N'P.D.', N'James', CAST(N'1920-08-20' AS Date), CAST(N'2014-11-27' AS Date), N'[Phyllis Dorothy James, Baroness James of Holland Park, OBE, FRSA, FRSL (3 August 1920 – 27 November 2014), known as P. D. James, was an English crime writer. She rose to fame for her series of detective novels starring police commander and poet Adam Dalgliesh.]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (11, N'John', N'Bunyan', CAST(N'1628-11-30' AS Date), CAST(N'1688-08-31' AS Date), N'[John Bunyan was an English writer and Puritan preacher best remembered as the author of the Christian allegory The Pilgrims Progress. In addition to The Pilgrims Progress, Bunyan wrote nearly sixty titles, many of them expanded sermons.]')
INSERT [dbo].[Author] ([AuthorID], [AuthorFirstName], [AuthorLastName], [AuthorDOB], [AuthorDOD], [AuthorBio]) VALUES (12, N'William', N'Strunk', CAST(N'1869-01-02' AS Date), CAST(N'1946-02-01' AS Date), N'The famous rhetorician from England most famous for publishing the primer elements of style')
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'BOOK', CAST(21.000 AS Decimal(6, 3)))
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'GOVDOC', CAST(0.000 AS Decimal(6, 3)))
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'MEDIA', CAST(5.000 AS Decimal(6, 3)))
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'PERIODICAL', CAST(0.000 AS Decimal(6, 3)))
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'RESERVE', CAST(0.125 AS Decimal(6, 3)))
INSERT [dbo].[BorrowingPolicies] ([PolicyID], [PolicyRule]) VALUES (N'SPECIAL', CAST(1.000 AS Decimal(6, 3)))
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'901224568', N'638518606133', CAST(N'2017-04-09 18:37:00.840' AS DateTime), CAST(N'2017-04-30 18:37:00.840' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'901234551', N'471424403122', CAST(N'2017-04-09 18:06:21.477' AS DateTime), CAST(N'2017-04-10 19:46:14.927' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'901234562', N'223880032392', CAST(N'2017-04-02 20:17:00.000' AS DateTime), CAST(N'2017-04-02 23:16:00.000' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'901234562', N'923941555344', CAST(N'2017-04-09 18:07:50.107' AS DateTime), CAST(N'2017-04-11 18:07:50.107' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'901234565', N'237131477359', CAST(N'2017-04-09 18:36:15.553' AS DateTime), CAST(N'2017-04-30 18:36:15.553' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'912345677', N'529427240156', CAST(N'2013-04-07 15:30:00.000' AS DateTime), CAST(N'2013-05-05 09:15:00.000' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'912345677', N'850891785675', CAST(N'2014-11-09 11:22:00.000' AS DateTime), CAST(N'2015-02-01 09:15:00.000' AS DateTime), 2)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'921234561', N'192868655016', CAST(N'2017-04-05 13:30:00.000' AS DateTime), CAST(N'2017-07-04 09:15:00.000' AS DateTime), NULL)
INSERT [dbo].[CheckoutTransaction] ([PatronID], [Barcode], [CheckoutTimestamp], [DueDate], [RenewalCount]) VALUES (N'921234561', N'798287244823', CAST(N'2015-09-10 10:22:00.000' AS DateTime), CAST(N'2015-12-09 09:15:00.000' AS DateTime), NULL)
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Archives', N'Archives and Special Collections', N'Snell Fourth Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Browsing', N'Browsing Collection', N'Snell Second Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Childrens', N'Favat Childrens Collection', N'Snell First Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'GovDocs', N'Goverment Documents', N'Snell Storage')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'JDOAAI', N'John D OBryant African American Institute Archives', N'Snell Third Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Law', N'Law Library', N'Law Library')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Microform', N'Microform', N'Snell Storage')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Oversize', N'Oversize Books', N'Snell Third Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Periodicals', N'Periodicals', N'Snell Storage')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Reference', N'Reference', N'Snell Second Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Reserves', N'Course Reserves', N'Snell First Floor')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'Snell', N'Snell Library', N'Snell Library')
INSERT [dbo].[Collection] ([CollectionID], [CollectionName], [CollectionLocation]) VALUES (N'The Hub', N'The Hub', N'Snell Second Floor')
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'192868655016', N'PN1995.9.H5 G737 1992', N'CHECKED OUT', CAST(N'2010-02-19' AS Date), N'BOOK', N'Snell', 54, CAST(N'2017-04-05' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'223880032392', N'PR2807.A2 T46 2006', N'OVERDUE', CAST(N'2015-09-14' AS Date), N'RESERVE', N'Reserves', 34, CAST(N'2017-04-02' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'237131477359', N'DA950.7 .K45 2012', N'AVAILABLE', CAST(N'2005-04-19' AS Date), N'BOOK', N'Snell', 3, CAST(N'2017-04-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'318656056758', N'PS3537.T3234 G8 1958', N'AVAILABLE', CAST(N'1993-04-16' AS Date), N'BOOK', N'Snell', 114, CAST(N'2017-04-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'396144853426', N'HB241 .J67 2000', N'MISSING', CAST(N'2001-05-07' AS Date), N'RESERVE', N'Reserves', 19, CAST(N'2006-11-07' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'454898933545', N'PE1408.S772 1999', N'AVAILABLE', CAST(N'1999-05-04' AS Date), N'SPECIAL', N'Archives', 53, CAST(N'2016-11-04' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'456022087476', N'PR3330.A2 S47 1987', N'AVAILABLE', CAST(N'1994-03-07' AS Date), N'BOOK', N'Snell', 14, CAST(N'2015-02-16' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'471424403122', N'HM251 .B437 2003', N'AVAILABLE', CAST(N'2003-04-03' AS Date), N'RESERVE', N'Reserves', 46, CAST(N'2017-04-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'529427240156', N'PR6023.E926 L5 1997', N'OVERDUE', CAST(N'1996-03-02' AS Date), N'BOOK', N'Childrens', 18, CAST(N'2013-04-07' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'638518606133', N'PR3330.A2 S47 1987', N'AVAILABLE', CAST(N'2000-01-01' AS Date), N'BOOK', N'Snell', 21, CAST(N'2017-04-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'728187260948', N'PR2807.A2 T46 2006', N'AVAILABLE', CAST(N'2007-10-13' AS Date), N'BOOK', N'Snell', 27, CAST(N'2016-03-07' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'798287244823', N'E744 .M868 2013', N'CHECKED OUT', CAST(N'2014-07-03' AS Date), N'RESERVE', N'Reserves', 2, CAST(N'2015-09-10' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'837556894200', N'M1001.B4 W5 1935', N'IN REPAIR', CAST(N'1997-04-03' AS Date), N'BOOK', N'Oversize', 7, CAST(N'2016-08-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'850891785675', N'PR6060.A467 C48 1993', N'OVERDUE', CAST(N'2003-04-09' AS Date), N'BOOK', N'Snell', 10, CAST(N'2014-11-09' AS Date))
INSERT [dbo].[Copy] ([Barcode], [CallNo], [Status], [CreationDate], [PolicyID], [CollectionID], [CheckoutCount], [DateLastCheckedOut]) VALUES (N'923941555344', N'QD478 .S53 2012', N'AVAILABLE', CAST(N'2012-10-11' AS Date), N'BOOK', N'Snell', 3, CAST(N'2017-04-09' AS Date))
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'ACCT1201-01-SP17', N'396144853426')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'ARAB1101-01-SP17', N'223880032392')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'ARAB1101-02-SP17', N'223880032392')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'ENVR1110-01-SP17', N'223880032392')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'ENVR1110-01-SP17', N'798287244823')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'INFO6210-01-SP17', N'798287244823')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'NRSG4604-01-SP17', N'471424403122')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'NRSG4604-02-SP17', N'471424403122')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'NRSG6241-01-SP17', N'396144853426')
INSERT [dbo].[CourseReserveList] ([CourseID], [Barcode]) VALUES (N'NRSG6241-01-SP17', N'471424403122')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'ACCT1201-01-SP17', N'Financial Accounting and Reporting', N'ACCT', N'Fitzgerald', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'ARAB1101-01-SP17', N'Elementary Arabic 1', N'ARAB', N'Bruce', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'ARAB1101-02-SP17', N'Elementary Arabic 1', N'ARAB', N'Bruce', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'ARAB1102-01-SP17', N'Elementary Arabic 2', N'ARAB', N'Mustafa', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'ENVR1110-01-SP17', N'Global Climate Change', N'ENVR', N'Douglass', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'INFO6210-01-SP17', N'Data Management and Database Design', N'INFO', N'Mutsalklisana', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'INFO6210-02-SP17', N'Data Management and Database Design', N'INFO', N'Wang', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'NRSG4604-01-SP17', N'Public Health Community Nursing', N'NRSG', N'Kim', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'NRSG4604-02-SP17', N'Public Health Community Nursing', N'NRSG', N'Jovanovic', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[Courses] ([CourseID], [CourseName], [CourseDept], [CourseInstructor], [CourseTerm], [CollectionID], [PolicyID]) VALUES (N'NRSG6241-01-SP17', N'Acute-Care Concepts in Nursing Practice', N'NRSG', N'Connolly', N'201730', N'Reserves', N'RESERVE')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'DA950.7 .K45 2012', N'1805091842', N'9781805091845', 6, N'Paperback', CAST(N'2012-01-01' AS Date), N'New York', N'English', 397, N'867498776')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'E744 .M868 2013', N'1612345395', N'9781612345390', 9, N'Paperback', CAST(N'2013-01-01' AS Date), N'Washington', N'English', 231, N'987234876')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'HB241 .J67 2000', N'1262100827', N'9781262100825', 10, N'Paperback', CAST(N'2000-01-01' AS Date), N'Cambridge', N'English', 400, N'987555726')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'HM251 .B437 2003', N'1205349773', N'9781205349775', 3, N'Hardcopy', CAST(N'2003-01-01' AS Date), N'Boston', N'English', 672, N'757394766')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'M1001.B4 W5 1935', N'8473908732', N'9788473908735', 4, N'Paperback', CAST(N'1935-01-01' AS Date), N'New York', N'English', 351, N'749305932')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PE1408.S772 1999', N'1205309021', N'9781205309022', 3, N'Paperback', CAST(N'1999-01-01' AS Date), N'Boston', N'English', 105, N'887345098')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PN1995.9.H5 G737 1992', N'1140186409', N'9781140186409', 8, N'Hardcopy', CAST(N'1992-01-01' AS Date), N'New York', N'English', 619, N'837444987')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PR2807.A2 T46 2006', N'1904271332', N'9781904271338', 1, N'Paperback', CAST(N'1995-01-01' AS Date), N'London', N'English', 613, N'768435987')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PR3330.A2 S47 1987', N'1140430040', N'9781140430041', 8, N'Paperback', CAST(N'1987-01-01' AS Date), N'New York', N'English', 294, N'224876553')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PR6023.E926 L5 1997', N'2060277246', N'9782060277245', 5, N'Hardcopy', CAST(N'1997-01-01' AS Date), N'New York', N'English', 174, N'876987234')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PR6060.A467 C48 1993', N'1679418733', N'9781679418732', 11, N'Hardcopy', CAST(N'1993-01-01' AS Date), N'New York', N'English', 241, N'887987123')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'PS3537.T3234 G8 1958', N'6372930412', N'9786372930412', 7, N'Paperback', CAST(N'1958-01-01' AS Date), N'New York', N'English', 619, N'837444987')
INSERT [dbo].[edition] ([CallNo], [ISBN10], [ISBN13], [ImprintID], [format], [DatePublished], [City], [Language], [Pages], [TitleID]) VALUES (N'QD478 .S53 2012', N'1439847908', N'9781439847909', 2, N'Paperback', CAST(N'2010-01-01' AS Date), N'Boca Raton', N'English', 465, N'768435977')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'223880032392', CAST(N'2008-04-01 09:15:00.000' AS DateTime), CAST(N'2008-04-02 09:14:00.000' AS DateTime), N'1')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'454898933545', CAST(N'2003-09-12 12:00:00.000' AS DateTime), CAST(N'2006-10-01 09:15:00.000' AS DateTime), N'100')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'728187260948', CAST(N'2001-10-01 10:20:00.000' AS DateTime), CAST(N'2006-10-01 09:15:00.000' AS DateTime), N'100')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'728187260948', CAST(N'2008-04-01 09:15:00.000' AS DateTime), CAST(N'2008-04-02 09:14:00.000' AS DateTime), N'1')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'798287244823', CAST(N'2014-12-20 09:15:00.000' AS DateTime), CAST(N'2015-01-07 09:14:00.000' AS DateTime), N'18')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234551', N'837556894200', CAST(N'2012-03-09 09:15:00.000' AS DateTime), CAST(N'2013-01-01 08:30:00.000' AS DateTime), N'100')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901234562', N'223880032392', CAST(N'2017-04-02 23:16:00.000' AS DateTime), NULL, N'7')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'901237569', N'454898933545', CAST(N'2007-01-02 09:15:00.000' AS DateTime), CAST(N'2007-01-12 08:20:00.000' AS DateTime), N'10')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'912345677', N'529427240156', CAST(N'2013-05-05 09:15:00.000' AS DateTime), NULL, N'1435')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'912345677', N'850891785675', CAST(N'2015-02-01 09:15:00.000' AS DateTime), NULL, N'798')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'921234561', N'798287244823', CAST(N'2015-12-09 09:15:00.000' AS DateTime), NULL, N'487')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'921234567', N'192868655016', CAST(N'2015-09-21 09:15:00.000' AS DateTime), CAST(N'2015-09-30 09:15:00.000' AS DateTime), N'100')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'921234567', N'192868655016', CAST(N'2015-10-01 09:15:00.000' AS DateTime), CAST(N'2015-10-01 12:14:00.000' AS DateTime), N'3')
INSERT [dbo].[Fines] ([PatronID], [Barcode], [DueDate], [DateReturned], [AmountDue]) VALUES (N'921234567', N'728187260948', CAST(N'2010-07-31 09:15:00.000' AS DateTime), CAST(N'2010-08-01 08:30:00.000' AS DateTime), N'1')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'901234565', N'223880032392', CAST(N'2017-04-05 09:16:00.000' AS DateTime), CAST(N'2017-05-05 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'901234565', N'529427240156', CAST(N'2017-04-08 22:13:00.000' AS DateTime), CAST(N'2017-05-08 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'901234567', N'192868655016', CAST(N'2017-04-08 12:11:00.000' AS DateTime), CAST(N'2017-05-08 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'901234567', N'223880032392', CAST(N'2017-04-03 08:17:00.000' AS DateTime), CAST(N'2017-05-03 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'901234567', N'529427240156', CAST(N'2017-04-07 21:30:00.000' AS DateTime), CAST(N'2017-05-07 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'912345677', N'192868655016', CAST(N'2017-04-07 10:11:00.000' AS DateTime), CAST(N'2017-05-07 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'912345677', N'223880032392', CAST(N'2017-04-09 13:33:00.000' AS DateTime), CAST(N'2017-05-09 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'921234561', N'223880032392', CAST(N'2017-04-07 15:22:00.000' AS DateTime), CAST(N'2017-05-07 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'921234561', N'529427240156', CAST(N'2017-04-08 16:23:00.000' AS DateTime), CAST(N'2017-05-08 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Holds] ([PatronID], [Barcode], [HoldPlacedDate], [HoldUntilDate], [Status]) VALUES (N'921234567', N'223880032392', CAST(N'2017-04-08 08:22:00.000' AS DateTime), CAST(N'2017-05-08 09:15:00.000' AS DateTime), N'ON HOLD')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901224568', N'Peter', N'Banana', N'FAC', N'pbanana@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901234551', N'Susan', N'Raspberry', N'FAC', N'sraspberry@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901234562', N'Tyler', N'Tomato', N'EMP', N'ttomato@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901234565', N'Bonnie', N'Potato', N'ALM', N'bpotato@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901234567', N'Susie', N'Apple', N'FAC', N'sapple@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'901237569', N'Charles', N'Pear', N'BLC', N'cpear@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'912345677', N'Jane', N'Radish', N'STU', N'jradish@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'912345678', N'John', N'Cherry', N'EMP', N'jcherry@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'921234561', N'Mark', N'Carrot', N'FAC', N'mcarrot@university.edu', N'555-555-5555')
INSERT [dbo].[Patron] ([PatronID], [PatronFirstName], [PatronLastName], [PatronTypeID], [PatronEmail], [PatronPhoneNo]) VALUES (N'921234567', N'Darla', N'Grape', N'STU', N'dgrape@university.edu', N'555-555-5555')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'CAMPUS', N'901234551', N'000000001')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'CAMPUS', N'912345677', N'000000002')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'CAMPUS', N'912345678', N'000000004')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'CAMPUS', N'921234561', N'000000007')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'CAMPUS', N'921234567', N'000000003')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'HOME', N'901224568', N'000000012')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'HOME', N'901234551', N'000000010')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'HOME', N'901234562', N'000000010')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'HOME', N'901234565', N'000000012')
INSERT [dbo].[PatronAddresses] ([AddressType], [PatronID], [AddressID]) VALUES (N'HOME', N'921234567', N'000000011')
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'ALM', 1)
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'BLC', 1)
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'EMP', 2)
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'FAC', 10)
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'STU', 1)
INSERT [dbo].[PatronType] ([PatronTypeID], [BorrowingRule]) VALUES (N'XRG', 1)
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (1, N'Arden Shakespeare', N'Arden Shakespeare', N'000000020')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (2, N'CRC Press', N'New Division LLC', N'000000021')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (3, N'Allyn & Baron', N'Baron Educational', N'000000022')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (4, N'Harcourt, Brace and Co.', N'Harcourt Imprint Div', N'000000023')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (5, N'HarperCollinsPublishers', N'HarperCollinsPublishers', N'000000024')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (6, N'Henry Holt and Co.', N'Holt Division', N'000000025')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (7, N'The Viking Press', N'The Viking Press', N'000000026')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (8, N'Penguin Books', N'Penguin Classics', N'000000027')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (9, N'Potomac Books', N'Potomac Budget Editions', N'000000028')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (10, N'MIT Press', N'MIT Academic Imprint', N'000000029')
INSERT [dbo].[PublisherImprint] ([ImprintID], [PublisherName], [ImprintName], [AddressID]) VALUES (11, N'A.A. Knopf', N'A.A. Double Books', N'000000030')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Economics- Math')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Americana')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Ancient')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Fantasy')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Foreign')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Historical')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Horror')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Religion')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Romance')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Fiction- Tragedy')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'History- Ireland')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Instruction- Chemistry')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Instruction- Computers')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Instruction- Psychology')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Instruction- Repair')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Instruction- Writing')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Music- Scores')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Nonfiction- Astronomy')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Nonfiction- Paleontology')
INSERT [dbo].[Subjects] ([SubjectName]) VALUES (N'Political Science- Modern')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Economics- Math', N'987555726')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Fiction- Americana', N'837444987')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Fiction- Fantasy', N'876987234')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Fiction- Horror', N'887987123')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Fiction- Religion', N'224876553')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Fiction- Tragedy', N'768435987')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'History- Ireland', N'867498776')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Instruction- Chemistry', N'768435977')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Instruction- Psychology', N'757394766')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Instruction- Writing', N'887345098')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Music- Scores', N'749305932')
INSERT [dbo].[SubjectTitle] ([SubjectName], [TitleID]) VALUES (N'Political Science- Modern', N'987234876')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'224876553', 11, N'The pilgrims progress', N'The classic tale of a humble pilgrims redemption and search for truth along the road of life', CAST(N'1640-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'749305932', 4, N'The nine symphonies of Beethoven in score', N'With an entirely original system of signals for identifying themes as they appear, are developed and recur ... . Each symphony is preceded by historical and critical comment', CAST(N'1830-01-01' AS Date), N'German')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'757394766', 3, N'Social Psychology', N'An introductory course in the basics of social psychology in this easy to understand edition. Covers all the basic materials found in a typical introductory college course', CAST(N'2003-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'768435977', 2, N'Solid State Chemistry: An Introduction', N'An introduction to crystal structures -- Physical methods for characterising solids -- Synthesis of solids -- Solids: their bonding and electronic properties -- Defects and nonstoichiometry -- Microporous and mesoporous solids -- Optical properties of solids -- Magnetic and electrical properties -- Superconductivity -- Nanostructures and solids with low-dimensional properties.', CAST(N'2012-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'768435987', 1, N'Hamlet', N'The Tragical History of Hamlet, Prince of Denmark The Second Quarto (1604-5) by Englands venerated bard William Shakespeare', CAST(N'1606-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'837444987', 7, N'The Grapes of Wrath', N'The Grapes of Wrath is an American realist novel written by John Steinbeck and published in 1939.[2] The book won the National Book Award[3] and Pulitzer Prize[4] for fiction, and it was cited prominently when Steinbeck was awarded the Nobel Prize in 1962', CAST(N'1962-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'867498776', 6, N'The graves are walking : the great famine and the saga of the Irish people', N'This compelling new look at one of the worst disasters to strike humankind--the Great Irish Potato Famine--provides fresh material and analysis on the role that nineteenth-century evangelical Protestantism played in shaping British policies and on Britain', CAST(N'2012-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'876987234', 5, N'The lion, the witch, and the wardrobe', N'Four English school children enter the magic land of Narnia through the back of a wardrobe and assist Aslan, the golden lion, in defeating the White Witch who has cursed the land with eternal winter.', CAST(N'1960-01-05' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'887345098', 12, N'The elements of style', N'Classic book on proper rhetoric and writing style which has shaped the style of millions of writers both great and humble', CAST(N'1940-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'887987123', 10, N'The children of men', N'The harrowing tale of mankinds last stand after a devastating plague destroys fertility threatening our species with extinction', CAST(N'1993-01-01' AS Date), N'French')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'987234876', 8, N'[War, welfare & democracy : rethinking Americas quest for the end of history]', N'A systematic review of Americas challenges in the 21st century from a noted political scientist', CAST(N'2013-01-01' AS Date), N'English')
INSERT [dbo].[Title] ([TitleID], [AuthorID], [TitleName], [Description], [FirstPublishedDate], [TitleOriginalLanguage]) VALUES (N'987555726', 9, N'Econometrics', N'[v. 1. Econometric modeling of producer behavior -- v. 2. Econometrics and the cost of capital -- v.3. Economic growth in the information age.]', CAST(N'1998-01-01' AS Date), N'Swedish')
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'768435987', 1)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'768435977', 2)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'757394766', 3)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'749305932', 4)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'876987234', 5)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'867498776', 6)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'837444987', 7)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'987234876', 8)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'987555726', 9)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'887987123', 10)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'224876553', 11)
INSERT [dbo].[TitlesAuthors] ([TitleID], [AuthorID]) VALUES (N'887345098', 12)
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'00100', N'Bork Big Books', N'queries@bbb.com', N'939-009-2910', N'000000040')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'11111', N'Northshore Wholesale LLC', N'Northshore@outlook.com', N'938-291-3920', N'000000031')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'22222', N'Northwind Library Books', N'Inquiries@Northwind.com', N'382-382-1023', N'000000032')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'33333', N'Davis Wholesale Library Solutions', N'purchasing@daviswholesale.com', N'382-448-9827', N'000000033')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'44444', N'Yellowstone Big Books', N'purchasing@yellowstonbooks.com', N'392-888-1029', N'000000034')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'55555', N'T-Rex Kickass Books', N'purchasing@trexbooks.com', N'392-999-2834', N'000000035')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'66666', N'Rapidfire Wholesale Solutions', N'queries@rapidfirebooks.com', N'392-000-2934', N'000000036')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'77777', N'Fast Media Book Solutions', N'queries@fastmedia.com', N'392-999-2222', N'000000037')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'88888', N'Digital Wholesale Books', N'purchasing@digitalwholesale.com', N'800-392-3920', N'000000038')
INSERT [dbo].[Vendors] ([VendorID], [VendorName], [VendorEmail], [VendorPhoneNo], [AddressID]) VALUES (N'99999', N'Metis Media Solutions', N'help@metismedia.com', N'392-392-4939', N'000000039')
ALTER TABLE [dbo].[AcquisitionOrders]  WITH CHECK ADD FOREIGN KEY([Barcode])
REFERENCES [dbo].[Copy] ([Barcode])
GO
ALTER TABLE [dbo].[AcquisitionOrders]  WITH CHECK ADD FOREIGN KEY([CallNo])
REFERENCES [dbo].[edition] ([CallNo])
GO
ALTER TABLE [dbo].[AcquisitionOrders]  WITH CHECK ADD FOREIGN KEY([PatronID])
REFERENCES [dbo].[Patron] ([PatronID])
GO
ALTER TABLE [dbo].[AcquisitionOrders]  WITH CHECK ADD FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendors] ([VendorID])
GO
ALTER TABLE [dbo].[CheckoutTransaction]  WITH CHECK ADD FOREIGN KEY([Barcode])
REFERENCES [dbo].[Copy] ([Barcode])
GO
ALTER TABLE [dbo].[CheckoutTransaction]  WITH CHECK ADD FOREIGN KEY([PatronID])
REFERENCES [dbo].[Patron] ([PatronID])
GO
ALTER TABLE [dbo].[Copy]  WITH CHECK ADD FOREIGN KEY([CallNo])
REFERENCES [dbo].[edition] ([CallNo])
GO
ALTER TABLE [dbo].[Copy]  WITH CHECK ADD FOREIGN KEY([CollectionID])
REFERENCES [dbo].[Collection] ([CollectionID])
GO
ALTER TABLE [dbo].[Copy]  WITH CHECK ADD FOREIGN KEY([PolicyID])
REFERENCES [dbo].[BorrowingPolicies] ([PolicyID])
GO
ALTER TABLE [dbo].[CourseReserveList]  WITH CHECK ADD FOREIGN KEY([Barcode])
REFERENCES [dbo].[Copy] ([Barcode])
GO
ALTER TABLE [dbo].[CourseReserveList]  WITH CHECK ADD FOREIGN KEY([CourseID])
REFERENCES [dbo].[Courses] ([CourseID])
GO
ALTER TABLE [dbo].[Courses]  WITH CHECK ADD FOREIGN KEY([CollectionID])
REFERENCES [dbo].[Collection] ([CollectionID])
GO
ALTER TABLE [dbo].[Courses]  WITH CHECK ADD FOREIGN KEY([PolicyID])
REFERENCES [dbo].[BorrowingPolicies] ([PolicyID])
GO
ALTER TABLE [dbo].[edition]  WITH CHECK ADD FOREIGN KEY([ImprintID])
REFERENCES [dbo].[PublisherImprint] ([ImprintID])
GO
ALTER TABLE [dbo].[edition]  WITH CHECK ADD FOREIGN KEY([TitleID])
REFERENCES [dbo].[Title] ([TitleID])
GO
ALTER TABLE [dbo].[Fines]  WITH CHECK ADD FOREIGN KEY([Barcode])
REFERENCES [dbo].[Copy] ([Barcode])
GO
ALTER TABLE [dbo].[Fines]  WITH CHECK ADD FOREIGN KEY([PatronID])
REFERENCES [dbo].[Patron] ([PatronID])
GO
ALTER TABLE [dbo].[Holds]  WITH CHECK ADD FOREIGN KEY([Barcode])
REFERENCES [dbo].[Copy] ([Barcode])
GO
ALTER TABLE [dbo].[Holds]  WITH CHECK ADD FOREIGN KEY([PatronID])
REFERENCES [dbo].[Patron] ([PatronID])
GO
ALTER TABLE [dbo].[Patron]  WITH CHECK ADD FOREIGN KEY([PatronTypeID])
REFERENCES [dbo].[PatronType] ([PatronTypeID])
GO
ALTER TABLE [dbo].[PatronAddresses]  WITH CHECK ADD FOREIGN KEY([AddressID])
REFERENCES [dbo].[Address] ([AddressID])
GO
ALTER TABLE [dbo].[PatronAddresses]  WITH CHECK ADD FOREIGN KEY([PatronID])
REFERENCES [dbo].[Patron] ([PatronID])
GO
ALTER TABLE [dbo].[PublisherImprint]  WITH CHECK ADD FOREIGN KEY([AddressID])
REFERENCES [dbo].[Address] ([AddressID])
GO
ALTER TABLE [dbo].[SubjectTitle]  WITH CHECK ADD FOREIGN KEY([SubjectName])
REFERENCES [dbo].[Subjects] ([SubjectName])
GO
ALTER TABLE [dbo].[SubjectTitle]  WITH CHECK ADD FOREIGN KEY([TitleID])
REFERENCES [dbo].[Title] ([TitleID])
GO
ALTER TABLE [dbo].[Title]  WITH CHECK ADD FOREIGN KEY([AuthorID])
REFERENCES [dbo].[Author] ([AuthorID])
GO
ALTER TABLE [dbo].[TitlesAuthors]  WITH CHECK ADD FOREIGN KEY([AuthorID])
REFERENCES [dbo].[Author] ([AuthorID])
GO
ALTER TABLE [dbo].[TitlesAuthors]  WITH CHECK ADD FOREIGN KEY([AuthorID])
REFERENCES [dbo].[Author] ([AuthorID])
GO
ALTER TABLE [dbo].[TitlesAuthors]  WITH CHECK ADD FOREIGN KEY([TitleID])
REFERENCES [dbo].[Title] ([TitleID])
GO
ALTER TABLE [dbo].[TitlesAuthors]  WITH CHECK ADD FOREIGN KEY([TitleID])
REFERENCES [dbo].[Title] ([TitleID])
GO
ALTER TABLE [dbo].[Vendors]  WITH CHECK ADD FOREIGN KEY([AddressID])
REFERENCES [dbo].[Address] ([AddressID])
GO
ALTER TABLE [dbo].[Copy]  WITH CHECK ADD  CONSTRAINT [CHK_CopyStatus] CHECK  (([Status]='ON ORDER' OR [Status]='IN REPAIR' OR [Status]='MISSING' OR [Status]='ON RESERVE' OR [Status]='OVERDUE' OR [Status]='CHECKED OUT' OR [Status]='ON HOLD' OR [Status]='AVAILABLE'))
GO
ALTER TABLE [dbo].[Copy] CHECK CONSTRAINT [CHK_CopyStatus]
GO
ALTER TABLE [dbo].[Holds]  WITH CHECK ADD  CONSTRAINT [CHK_Holds] CHECK  (([Status]='ON ORDER' OR [Status]='READY FOR PICKUP' OR [Status]='ON HOLD'))
GO
ALTER TABLE [dbo].[Holds] CHECK CONSTRAINT [CHK_Holds]
GO
ALTER TABLE [dbo].[PatronAddresses]  WITH CHECK ADD  CONSTRAINT [CHK_AdressType] CHECK  (([AddressType]='HOME' OR [AddressType]='CAMPUS'))
GO
ALTER TABLE [dbo].[PatronAddresses] CHECK CONSTRAINT [CHK_AdressType]
GO
USE [master]
GO
ALTER DATABASE [EMILYSHAWN_ACADEMIC_LIBRARY] SET  READ_WRITE 
GO
