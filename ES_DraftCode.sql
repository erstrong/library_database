-------------------
-- CREATE DATABASE
-------------------
create database EMILYSHAWN_ACADEMIC_LIBRARY;
go 
use EMILYSHAWN_ACADEMIC_LIBRARY;

-------------------
-- CREATE TABLES
-------------------
create table PatronType
(
  PatronTypeID varchar(3) not null primary key,
  BorrowingRule int not null
);

create table Patron
(
  PatronID varchar(9) not null primary key,
  PatronFirstName varchar(50),
  PatronLastName varchar(50),
  PatronTypeID varchar(3) not null foreign key references PatronType(PatronTypeID),
  PatronEmail varchar(50),
  PatronPhoneNo varchar(12),
);

create table Collection
(
  CollectionID varchar(12) not null primary key,
  CollectionName varchar(50),
  CollectionLocation varchar(50)
);

create table BorrowingPolicies
(
  PolicyID varchar(10) not null primary key,
  PolicyRule decimal(6,3) not null
);

create table Copy
(
  Barcode varchar(12) not null primary key,
  CallNo varchar(50) not null,-- foreign key references Edition(CallNo),
  Status varchar(20) not null,
  CreationDate date,
  PolicyID varchar(10) not null foreign key references BorrowingPolicies(PolicyID),
  CollectionID varchar(12) not null foreign key references Collection(CollectionID),
  CheckoutCount int, -- TODO update this count during a checkout
  DateLastCheckedOut date, -- TODO update this date during a checkout
  constraint CHK_CopyStatus CHECK (Status in
    ('AVAILABLE','ON HOLD','CHECKED OUT','OVERDUE','ON RESERVE','MISSING','IN REPAIR','ON ORDER'))
);  

create table Courses
(
  CourseID varchar(16) not null primary key,
  CourseName varchar(50),
  CourseDept varchar(4),
  CourseInstructor varchar(50),
  CourseTerm varchar(6),
  CollectionID varchar(12) foreign key references Collection(CollectionID),
  PolicyID varchar(10) foreign key references BorrowingPolicies(PolicyID)
);

create table CourseReserveList
(
  CourseID varchar(16) not null foreign key references Courses(CourseID),
  Barcode varchar(12) not null foreign key references Copy(Barcode),
  constraint PK_CourseReserveList primary key (CourseID,Barcode)
);

create table CheckoutTransaction
(
  PatronID varchar(9) not null foreign key references Patron(PatronID),
  Barcode varchar(12) not null foreign key references Copy(Barcode),
  CheckoutTimestamp datetime not null,
  DueDate datetime not null,
  RenewalCount int,
  constraint PK_CheckoutTransaction primary key (PatronID,Barcode)
);

create table Holds
(
  PatronID varchar(9) not null foreign key references Patron(PatronID),
  Barcode varchar(12) not null foreign key references Copy(Barcode),
  HoldPlacedDate datetime not null,
  HoldUntilDate datetime not null,
  Status varchar(20) not null,
  constraint CHK_Holds CHECK (Status in ('ON HOLD', 'READY FOR PICKUP', 'ON ORDER')),
  constraint PK_Holds primary key (PatronID,Barcode)
);

create table Fines
(
  PatronID varchar(9) not null foreign key references Patron(PatronID),
  Barcode varchar(12) not null foreign key references Copy(Barcode),
  DueDate datetime not null,
  DateReturned datetime,
  AmountDue varchar(6),
  constraint PK_Fines primary key (PatronID,Barcode,DueDate)
);

create table Address
(
  AddressID varchar(9) not null primary key,
  Street varchar(50),
  City varchar(20),
  State varchar(20),
  Country varchar(20),
  PostalCode varchar(6)
);

create table PatronAddresses
(
  AddressType varchar(6) not null,
  PatronID varchar(9) not null foreign key references Patron(PatronID),
  AddressID varchar(9) foreign key references Address(AddressID),
  constraint CHK_AdressType CHECK (AddressType in ('CAMPUS', 'HOME')),
  constraint PK_PatronAddresses primary key (AddressType,PatronID)
);

-------------------
-- ADD SAMPLE DATA
-------------------
insert into PatronType values
  ('FAC',10),('EMP',2),('STU',1),('ALM',1),('BLC',1),('XRG',1);

insert into Patron values
  ('901234551','Susan','Raspberry','FAC','sraspberry@university.edu','555-555-5555'),
  ('901234562','Tyler','Tomato','EMP','ttomato@university.edu','555-555-5555'),
  ('901234565','Bonnie','Potato','ALM','bpotato@university.edu','555-555-5555'),
  ('901234567','Susie','Apple','FAC','sapple@university.edu','555-555-5555'),
  ('901224568','Peter','Banana','FAC','pbanana@university.edu','555-555-5555'),
  ('901237569','Charles','Pear','BLC','cpear@university.edu','555-555-5555'),
  ('912345677','Jane','Radish','STU','jradish@university.edu','555-555-5555'),
  ('912345678','John','Cherry','EMP','jcherry@university.edu','555-555-5555'),
  ('921234561','Mark','Carrot','FAC','mcarrot@university.edu','555-555-5555'),
  ('921234567','Darla','Grape','STU','dgrape@university.edu','555-555-5555');

insert into Collection values
  ('Snell','Snell Library','Snell Library'),
  ('Law','Law Library','Law Library'),
  ('Childrens','Favat Childrens Collection','Snell First Floor'),
  ('Periodicals','Periodicals','Snell Storage'),
  ('Reserves','Course Reserves','Snell First Floor'),
  ('Archives','Archives and Special Collections','Snell Fourth Floor'),
  ('Reference','Reference','Snell Second Floor'),
  ('The Hub','The Hub','Snell Second Floor'),
  ('Oversize','Oversize Books','Snell Third Floor'),
  ('Microform','Microform','Snell Storage'),
  ('GovDocs','Goverment Documents','Snell Storage'),
  ('Browsing','Browsing Collection','Snell Second Floor'),
  ('JDOAAI','John D OBryant African American Institute Archives','Snell Third Floor');

insert into BorrowingPolicies values
  ('BOOK',21),('MEDIA',5),('RESERVE',0.125),('GOVDOC',0),('PERIODICAL',0),('SPECIAL',1);

insert into Copy values
  ('728187260948','PR2807.A2 T46 2006','AVAILABLE','2007-10-13','BOOK','Snell','27','2016-03-07'),
  ('223880032392','PR2807.A2 T46 2006','OVERDUE','2015-09-14','RESERVE','Reserves','34','2017-04-02'),
  ('923941555344','QD478 .S53 2012','AVAILABLE','2012-10-11','BOOK','Snell','2','2013-02-03'),
  ('471424403122','HM251 .B437 2003','AVAILABLE','2003-04-03','RESERVE','Reserves','45','2014-05-07'),
  ('837556894200','M1001.B4 W5 1935','IN REPAIR','1997-04-03','BOOK','Oversize','7','2016-08-09'),
  ('529427240156','PR6023.E926 L5 1997','OVERDUE','1996-03-02','BOOK','Childrens','18','2013-04-07'),
  ('237131477359','DA950.7 .K45 2012','AVAILABLE','2005-04-19','BOOK','Snell','1','2008-08-09'),
  ('318656056758','PS3537.T3234 G8 1958','AVAILABLE','1993-04-16','BOOK','Snell','112','2012-01-05'),
  ('192868655016','PN1995.9.H5 G737 1992','CHECKED OUT','2010-02-19','BOOK','Snell','54','2017-04-05'),
  ('798287244823','E744 .M868 2013','CHECKED OUT','2014-07-03','RESERVE','Reserves','2','2015-09-10'),
  ('396144853426','HB241 .J67 2000','MISSING','2001-05-07','RESERVE','Reserves','19','2006-11-07'),
  ('850891785675','PR6060.A467 C48 1993','OVERDUE','2003-04-09','BOOK','Snell','10','2014-11-09'),
  ('638518606133','PR3330.A2 S47 1987','AVAILABLE','2000-01-01','BOOK','Snell','18','2014-02-12'),
  ('456022087476','PR3330.A2 S47 1987','AVAILABLE','1994-03-07','BOOK','Snell','14','2015-02-16'),
  ('454898933545','PE1408.S772 1999','AVAILABLE','1999-05-04','SPECIAL','Archives','53','2016-11-04');

insert into Courses values
  ('ACCT1201-01-SP17','Financial Accounting and Reporting','ACCT','Fitzgerald','201730','Reserves','RESERVE'),
  ('ARAB1101-01-SP17','Elementary Arabic 1','ARAB','Bruce','201730','Reserves','RESERVE'),
  ('ARAB1101-02-SP17','Elementary Arabic 1','ARAB','Bruce','201730','Reserves','RESERVE'),
  ('ARAB1102-01-SP17','Elementary Arabic 2','ARAB','Mustafa','201730','Reserves','RESERVE'),
  ('ENVR1110-01-SP17','Global Climate Change','ENVR','Douglass','201730','Reserves','RESERVE'),
  ('INFO6210-01-SP17','Data Management and Database Design','INFO','Mutsalklisana','201730','Reserves','RESERVE'),
  ('INFO6210-02-SP17','Data Management and Database Design','INFO','Wang','201730','Reserves','RESERVE'),
  ('NRSG4604-01-SP17','Public Health Community Nursing','NRSG','Kim','201730','Reserves','RESERVE'),
  ('NRSG4604-02-SP17','Public Health Community Nursing','NRSG','Jovanovic','201730','Reserves','RESERVE'),
  ('NRSG6241-01-SP17','Acute-Care Concepts in Nursing Practice','NRSG','Connolly','201730','Reserves','RESERVE');

insert into CourseReserveList values
  ('ACCT1201-01-SP17','396144853426'),
  ('ARAB1101-01-SP17','223880032392'),
  ('ARAB1101-02-SP17','223880032392'),
  ('NRSG4604-01-SP17','471424403122'),
  ('NRSG4604-02-SP17','471424403122'),
  ('NRSG6241-01-SP17','471424403122'),
  ('NRSG6241-01-SP17','396144853426'),
  ('ENVR1110-01-SP17','798287244823'),
  ('INFO6210-01-SP17','798287244823'),
  ('ENVR1110-01-SP17','223880032392');

-- additional CheckoutTransactions through stored procedure
insert into CheckoutTransaction values
('921234561','192868655016','2017-04-05 13:30:00.000','2017-07-04 09:15:00.000',null),
('921234561','798287244823','2015-09-10 10:22:00.000','2015-12-09 09:15:00.000',null),
('901234562','223880032392','2017-04-02 20:17:00.000','2017-04-02 23:16:00.000',null),
('912345677','850891785675','2014-11-09 11:22:00.000','02-01-2015 09:15:00.000','2'),
('912345677','529427240156','2013-04-07 15:30:00.000','2013-05-05 09:15:00.000',null);

insert into Holds values
('912345677','192868655016','2017-04-07 10:11:00.000','2017-05-07 09:15:00.000','ON HOLD'),
('901234567','192868655016','2017-04-08 12:11:00.000','2017-05-08 09:15:00.000','ON HOLD'),
('912345677','223880032392','2017-04-09 13:33:00.000','2017-05-09 09:15:00.000','ON HOLD'),
('901234567','223880032392','2017-04-03 08:17:00.000','2017-05-03 09:15:00.000','ON HOLD'),
('921234561','223880032392','2017-04-07 15:22:00.000','2017-05-07 09:15:00.000','ON HOLD'),
('901234565','223880032392','2017-04-05 09:16:00.000','2017-05-05 09:15:00.000','ON HOLD'),
('921234567','223880032392','2017-04-08 08:22:00.000','2017-05-08 09:15:00.000','ON HOLD'),
('901234567','529427240156','2017-04-07 21:30:00.000','2017-05-07 09:15:00.000','ON HOLD'),
('921234561','529427240156','2017-04-08 16:23:00.000','2017-05-08 09:15:00.000','ON HOLD'),
('901234565','529427240156','2017-04-08 22:13:00.000','2017-05-08 09:15:00.000','ON HOLD');

insert into Fines values
('901234551','728187260948','2001-10-01 10:20:00.000','2006-10-01 09:15:00.000','100'),
('901234551','454898933545','2003-09-12 12:00:00.000','2006-10-01 09:15:00.000','100'),
('901234551','728187260948','2008-04-01 09:15:00.000','2008-04-02 09:14:00.000','1'),
('901234551','223880032392','2008-04-01 09:15:00.000','2008-04-02 09:14:00.000','1'),
('901234551','798287244823','2014-12-20 09:15:00.000','2015-01-07 9:14:00.000','18'),
('901234551','837556894200','2012-03-09 09:15:00.000','2013-01-01 08:30:00.000','100'),
('901237569','454898933545','2007-01-02 09:15:00.000','2007-01-12 08:20:00.000','10'),
('921234567','728187260948','2010-07-31 09:15:00.000','2010-08-01 08:30:00.000','1'),
('921234567','192868655016','2015-09-21 09:15:00.000','2015-09-30 09:15:00.000','100'),
('921234567','192868655016','2015-10-01 09:15:00.000','2015-10-01 12:14:00.000','3');

insert into Address values
  ('000000001','360 Huntington Ave','Boston','MA','USA','02115'),
  ('000000002','416 Huntington Ave','Boston','MA','USA','02115'),
  ('000000003','236 Huntington Ave','Boston','MA','USA','02115'),
  ('000000004','177 Huntington Ave','Boston','MA','USA','02115'),
  ('000000005','250 Columbus Place','Boston','MA','USA','02116'),
  ('000000006','716 Columbus Avenue','Boston','MA','USA','02120'),
  ('000000007','40 Columbus Place','Boston','MA','USA','02116'),
  ('000000008','370 Common Street','Dedham','MA','USA','02026'),
  ('000000009','145 South Bedford St','Burlington','MA','USA','01803'),
  ('000000010','430 Nahant Road','Nahant','MA','USA','01908'),
  ('000000011','101 N. Tryon Street','Charlotte','NC','USA','28246'),
  ('000000012','401 Terry Avenue North','Seattle','WA','USA','98109');

insert into PatronAddresses values
  ('HOME','901234551','000000010'),
  ('CAMPUS','901234551','000000001'),
  ('HOME','901234562','000000010'),
  ('HOME','901234565','000000012'),
  ('HOME','901224568','000000012'),
  ('CAMPUS','912345677','000000002'),
  ('CAMPUS','912345678','000000004'),
  ('CAMPUS','921234561','000000007'),
  ('HOME','921234567','000000011'),
  ('CAMPUS','921234567','000000003');



-------------------
-- CREATE FUNCTIONS
-------------------
-- CheckOutItem
-- procedure called during check out
create procedure CheckOutItem
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

declare @PatronID1 varchar(9);
declare @Barcode1 varchar(12);
set @PatronID1='901234551';
set @Barcode1='471424403122';
exec CheckOutItem @PatronID1, @Barcode1;
select * from CheckoutTransaction where PatronID='901234551';
select * from Copy where Barcode='471424403122';

select * from CheckoutTransaction order by CheckoutTimestamp;
declare @PatronID2 varchar(9);
declare @Barcode2 varchar(12);
set @PatronID2='901234562';
set @Barcode2='923941555344';
exec CheckOutItem @PatronID2, @Barcode2;

declare @PatronID3 varchar(9);
declare @Barcode3 varchar(12);
set @Barcode3='237131477359';
set @PatronID3='901234565';
exec CheckOutItem @PatronID3, @Barcode3;

declare @PatronID4 varchar(9);
declare @Barcode4 varchar(12);
set @PatronID4='901234567';
set @Barcode4='318656056758';
exec CheckOutItem @PatronID4, @Barcode4;

declare @PatronID5 varchar(9);
declare @Barcode5 varchar(12);
set @PatronID5='901224568';
set @Barcode5='638518606133';
exec CheckOutItem @PatronID5, @Barcode5;

-- RenewItem
-- procedure called when patron attempts to renew
create procedure RenewItem
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

declare @PatronID6 varchar(9);
declare @Barcode6 varchar(12);
set @PatronID6='901234551';
set @Barcode6='471424403122';
exec RenewItem @PatronID6, @Barcode6;

-- CheckInItem
-- procedure called during checkin
create procedure CheckInItem
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

declare @PatronID varchar(9);
declare @Barcode varchar(12);
set @PatronID='901234567';
set @Barcode='318656056758';
exec CheckInItem @PatronID, @Barcode;

-- UpdateFines
-- this would be run nightly
-- charges $1/day
-- could be expanded to allow for different fine amounts based on material type, collection
create procedure UpdateFines
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

exec UpdateFines;

-- ExpiredHolds
-- this would be run nightly
create procedure ExpiredHolds
as
begin
    delete from Holds
   	 where HoldUntilDate < getdate()
   	 and Status='ON HOLD';
end

exec ExpiredHolds;


-------------------
-- CREATE VIEWS
-------------------
-- PatronFines
create view PatronFines as
select
p.PatronId,PatronFirstName,PatronLastName,PatronEmail,c.CallNo,t.TitleName,f.Barcode,f.DueDate,f.AmountDue
from Patron p,Fines f,Copy c,Title t
where p.PatronID=f.PatronID
and f.Barcode=c.Barcode
and t.TitleID =(select TitleID from edition e where e.CallNo=c.CallNo);
select * from PatronFines;



-- Shawn:
--To report on acquisition order statuses
--To report on outstanding acquisition orders
--To report on patrons with holds or overdue books

-- Save for BI reports
--To report on books that have not been checked out in a specified amount of time
--To report on books that are highly used
--To report on books that are damaged and need to be replaced
--To report on the content of collections
--To report on active or historical course reserve lists
--To report on collections of special interest

