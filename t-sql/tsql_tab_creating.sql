USE s15711;

DROP TABLE DONATION;
DROP TABLE VOLUNTEERING;
DROP TABLE HELP;
DROP TABLE VOLUNTEER;
DROP TABLE DONOR;
DROP TABLE CLIENT;
DROP TABLE EX_CLIENT;

CREATE TABLE VOLUNTEER
(
  id_volunteer  INT         NOT NULL PRIMARY KEY,
  vol_name      VARCHAR(20) NOT NULL,
  vol_surname   VARCHAR(20) NOT NULL,
  vol_address   VARCHAR(40),
  vol_phone_num VARCHAR(40),
  vol_email     VARCHAR(40)
);

CREATE TABLE DONOR
(
  id_donor    INT NOT NULL PRIMARY KEY,
  d_name      VARCHAR(20),
  d_surname   VARCHAR(20),
  d_address   VARCHAR(40),
  d_phone_num VARCHAR(40),
  d_email     VARCHAR(40),
  d_total_sum MONEY
);

CREATE TABLE CLIENT
(
  id_client       INT         NOT NULL PRIMARY KEY,
  cl_name         VARCHAR(20) NOT NULL,
  cl_surname      VARCHAR(20) NOT NULL,
  cl_birth_date   DATE,
  cl_gender       VARCHAR(20) NOT NULL,
  cl_address      VARCHAR(40),
  cl_phone_num    VARCHAR(40),
  cl_email        VARCHAR(40),
  cl_bank_account VARCHAR(40),
  cl_neededMoney  MONEY,
  cl_gets_help    BIT DEFAULT 0
);

CREATE TABLE HELP
(
  id_help  INT NOT NULL PRIMARY KEY,
  client   INT NOT NULL,
  comments VARCHAR(70),
  FOREIGN KEY (client) REFERENCES CLIENT (id_client)
);

CREATE TABLE DONATION
(
  id_donation   INT   NOT NULL PRIMARY KEY,
  donor         INT   NOT NULL,
  size_donation MONEY NOT NULL,
  date_donation DATE,
  id_help       INT   NOT NULL,
  FOREIGN KEY (donor) REFERENCES DONOR (id_donor),
  FOREIGN KEY (id_help) REFERENCES HELP (id_help)
);

CREATE TABLE VOLUNTEERING
(
  id_volunteering   INT NOT NULL PRIMARY KEY,
  volunteer         INT NOT NULL,
  date_volunteering DATE,
  id_help           INT NOT NULL,
  FOREIGN KEY (volunteer) REFERENCES VOLUNTEER (id_volunteer),
  FOREIGN KEY (id_help) REFERENCES HELP (id_help)
);

CREATE TABLE EX_CLIENT
(
  id_ex_client          INT         NOT NULL PRIMARY KEY,
  ex_cl_name            VARCHAR(20) NOT NULL,
  ex_cl_surname         VARCHAR(20) NOT NULL,
  ex_cl_birth_date      DATE,
  ex_cl_gender          VARCHAR(20) NOT NULL,
  ex_cl_adress          VARCHAR(40),
  ex_cl_phone_num       VARCHAR(40),
  ex_cl_email           VARCHAR(40),
  ex_cl_bank_account    VARCHAR(40),
  ex_cl_total_donations MONEY,
  ex_cl_got_help        BIT,
  delete_date           DATE
);