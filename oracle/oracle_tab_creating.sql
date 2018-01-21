DROP TABLE DONATION;
DROP TABLE VOLUNTEERING;
DROP TABLE HELP;
DROP TABLE VOLUNTEER;
DROP TABLE DONOR;
DROP TABLE CLIENT;
DROP TABLE EX_CLIENT;

CREATE TABLE VOLUNTEER
(
  id_volunteer  NUMBER       NOT NULL PRIMARY KEY,
  vol_name      VARCHAR2(20) NOT NULL,
  vol_surname   VARCHAR2(20) NOT NULL,
  vol_address   VARCHAR2(40),
  vol_phone_num VARCHAR2(40),
  vol_email     VARCHAR2(40)
);

CREATE TABLE DONOR
(
  id_donor    NUMBER NOT NULL PRIMARY KEY,
  d_name      VARCHAR2(20),
  d_surname   VARCHAR2(20),
  d_address   VARCHAR2(40),
  d_phone_num VARCHAR2(40),
  d_email     VARCHAR2(40)
);

CREATE TABLE CLIENT
(
  id_client       NUMBER       NOT NULL PRIMARY KEY,
  cl_name         VARCHAR2(20) NOT NULL,
  cl_surname      VARCHAR2(20) NOT NULL,
  cl_birth_date   DATE,
  cl_gender       VARCHAR2(20) NOT NULL,
  cl_address      VARCHAR2(40),
  cl_phone_num    VARCHAR2(40),
  cl_email        VARCHAR2(40),
  cl_bank_account VARCHAR2(40),
  cl_neededMoney  NUMBER(8)
);

CREATE TABLE HELP
(
  id_help  NUMBER NOT NULL PRIMARY KEY,
  client   NUMBER NOT NULL,
  comments VARCHAR2(70),
  FOREIGN KEY (client) REFERENCES CLIENT (id_client)
);

CREATE TABLE DONATION
(
  id_donation   NUMBER    NOT NULL PRIMARY KEY,
  donor         NUMBER    NOT NULL,
  size_donation NUMBER(8) NOT NULL,
  date_donation DATE,
  id_help       NUMBER    NOT NULL,
  FOREIGN KEY (donor) REFERENCES DONOR (id_donor),
  FOREIGN KEY (id_help) REFERENCES HELP (id_help)
);

CREATE TABLE VOLUNTEERING
(
  id_volunteering   NUMBER NOT NULL PRIMARY KEY,
  volunteer         NUMBER NOT NULL,
  date_volunteering DATE,
  id_help           NUMBER NOT NULL,
  FOREIGN KEY (volunteer) REFERENCES VOLUNTEER (id_volunteer),
  FOREIGN KEY (id_help) REFERENCES HELP (id_help)
);

CREATE TABLE EX_CLIENT
(
  id_ex_client       NUMBER       NOT NULL PRIMARY KEY,
  ex_cl_name         VARCHAR2(20) NOT NULL,
  ex_cl_surname      VARCHAR2(20) NOT NULL,
  ex_cl_birth_date   DATE,
  ex_cl_gender       VARCHAR2(20) NOT NULL,
  ex_cl_adress       VARCHAR2(40),
  ex_cl_phone_num    VARCHAR2(40),
  ex_cl_email        VARCHAR2(40),
  ex_cl_bank_account VARCHAR2(40),
  ex_cl_got_help     VARCHAR2(1),
  delete_date        DATE
);