----------
-- STEP 1
----------
-- create database
create database ACADEMIC_LIBRARY;
go 
use ACADEMIC_LIBRARY;

----------
-- STEP 2
----------
-- create tables
create table PatronType
(
  PatronType varchar(3) not null primary key,
  BorrowingRule int not null
);

create table Patron
(
  PatronID varchar(9) not null primary key,
  PatronFirstName varchar(50),
  PatronLastName varchar(50),
  PatronType varchar(3) not null foreign key references PatronType(PatronType),
  PatronEmail varchar(50),
  PatronPhoneNo varchar(10),
);

create table Collection
(
  CollectionID not null primary key,
  CollectionName varchar(50),
  CollectionLocation varchar(50)
);

create table BorrowingPolicies
(
  PolicyID varchar(3) not null primary key,
  PolicyRule int not null
);

create table Copy
(
  Barcode varchar(12) not null primary key,
  --CallNo varchar(20) not null foreign key references Edition(CallNo),
  Status varchar(12) not null,
  CreationDate date,
  PolicyID varchar(3) not null foreign key references BorrowingPolicies(PolicyID),
  CollectionID varchar(3) not null foreign key references Collection(CollectionID),
  CheckoutCount int, -- TODO update this count during a checkout
  DateLastCheckedOut date -- TODO update this date during a checkout
);  

create table Courses
(
  CourseID varchar(12) not null primary key,
  CourseName varchar(50),
  CourseDept varchar(4),
  CourseInstructor varchar(50),
  CourseTerm varchar(6),
  CollectionID foreign key references Collection(CollectionID),
  PolicyID foreign key references BorrowingPolicies(PolicyID)
);

create table CourseReserveList
(
  CourseID varchar(12) not null foreign key references Courses(CourseID),
  Barcode varchar(12) not null foreign key references Copy(Barcode),
  constraint PK_CourseReserveList pimary key (CourseID,Barcode)
);

create table CheckoutTransaction
(
);

create table Holds
(
);

create table Fines
(
);

create table Address
(
);

create table PatronAddresses
(
);