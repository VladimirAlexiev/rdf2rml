create table constituents (
  constituentid int,
  constituent   varchar(200),
  primary key(constituentid)
);

create table conaddress (
  conaddressid  int,
  constituentid int,
  address       varchar(200),
  primary key(conaddressid),
  foreign key(constituentid) references constituents(constituentid)
);

create table conxrefs (
  tableid       int,
  roleid        int,
  id            int,
  constituentid int,
  foreign key(constituentid) references constituents(constituentid)
);

create table exhibitions (
  exhibitionid  int,
  exhdepartment int,
  exhtitle      varchar(200),
  displaydate   varchar(20),
  beginisodate  char(10),
  endisodate    char(10),
  primary key(exhibitionid)
);

create table exhvenuesxrefs (
  exhvenuexrefid int,
  exhibitionid   int,
  constituentid  int,
  conaddressid   int,
  approved       int,
  displayorder   int,
  displaydate    varchar(20),
  beginisodate   char(10),
  endisodate     char(10),
  primary key(exhvenuexrefid),
  foreign key(exhibitionid) references exhibitions(exhibitionid),
  foreign key(constituentid) references constituents(constituentid),
  foreign key(conaddressid) references conaddress(conaddressid)
);

create table exhvenobjxrefs (
  exhvenuexrefid    int, 
  objectid          int,
  catalognumber     varchar(20),
  begindispldateiso char(10),
  enddispldateiso   char(10),
  displayed         int,
  foreign key(exhvenuexrefid) references exhvenuesxrefs(exhvenuexrefid)
);

insert into constituents (constituentid, constituent) values (1, 'Getty Museum');
insert into constituents (constituentid, constituent) values (2, 'MoMA');
insert into constituents (constituentid, constituent) values (3, 'LACMA');

insert into conaddress (conaddressid, constituentid, address) values (101, 1, 'Getty Drive');
insert into conaddress (conaddressid, constituentid, address) values (102, 2, 'MoMA Street');
insert into conaddress (conaddressid, constituentid, address) values (103, 3, 'LACMA County');

insert into conxrefs (tableid, roleid, id, constituentid) values (47, 286, 123, 1);

insert into exhibitions (exhibitionid, exhdepartment, exhtitle, displaydate, beginisodate, endisodate)
  values (123, 53, 'Getty through the ages', 'October 2016', '2016-10-01', '2016-10-30');

insert into exhvenuesxrefs (exhvenuexrefid, exhibitionid, constituentid, conaddressid, approved, displayorder, displaydate, beginisodate, endisodate)
  values (202, 123, 2, 102, 1, 1, 'Early Oct 2016', '2016-10-01', '2016-10-15');
insert into exhvenuesxrefs (exhvenuexrefid, exhibitionid, constituentid, conaddressid, approved, displayorder, displaydate, beginisodate, endisodate)
  values (203, 123, 3, 103, 1, 2, 'Late Oct 2016', '2016-10-16', '2016-10-30');

insert into exhvenobjxrefs (exhvenuexrefid, objectid, catalognumber, begindispldateiso, enddispldateiso, displayed)
  values (202,1001,'cat 1001','2016-10-01', '2016-10-15', 1);
insert into exhvenobjxrefs (exhvenuexrefid, objectid, catalognumber, begindispldateiso, enddispldateiso, displayed)
  values (203,1001,'cat 1001','2016-10-16', '2016-10-30', 1);
insert into exhvenobjxrefs (exhvenuexrefid, objectid, catalognumber, begindispldateiso, enddispldateiso, displayed)
  values (202,1002,'cat 1002','2016-10-01', '2016-10-15', 1);
