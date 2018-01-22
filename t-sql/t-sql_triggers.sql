USE s15711;

-- todo: https://social.msdn.microsoft.com/Forums/sqlserver/en-US/40f5635c-9034-4e9b-8fd5-c02cec44ce86/how-to-let-trigger-act-for-each-row?forum=sqlgetstarted

-- 1. sums up donations made by a donor, updates the donor's total donations column
DROP TRIGGER DONATION_SUMMING;
CREATE TRIGGER DONATION_SUMMING
  ON DONATION
  FOR INSERT, UPDATE
AS
BEGIN
  DECLARE DONATION_CURS CURSOR FOR SELECT donor
                                   FROM inserted;
  DECLARE @curr_donor INT, @prev_donor INT, @donations_sum MONEY;

  OPEN DONATION_CURS;
  FETCH NEXT FROM DONATION_CURS INTO @curr_donor;
  WHILE @@FETCH_STATUS = 0
    BEGIN
      SELECT @donations_sum = SUM(size_donation)
      FROM DONATION
      WHERE donor = @curr_donor;

      -- not to print info about the same donor twice
      IF @curr_donor = @prev_donor
        BEGIN
          FETCH NEXT FROM DONATION_CURS INTO @curr_donor;
          CONTINUE;
        END;

      UPDATE DONOR
      SET d_total_sum = @donations_sum
      WHERE id_donor = @curr_donor;

      PRINT 'Donor ' + CAST(@curr_donor AS VARCHAR(10)) + ' donated ' + CAST(@donations_sum AS VARCHAR(20)) + ' in total';

      SELECT @prev_donor = @curr_donor;
      FETCH NEXT FROM DONATION_CURS
      INTO @curr_donor;
    END;
  CLOSE DONATION_CURS;
  DEALLOCATE DONATION_CURS;
END;
-- testing
INSERT INTO DONATION VALUES (101, 1, 99999, getdate(), 1);
INSERT INTO DONATION VALUES (102, 1, 1000, getdate(), 1);
INSERT INTO DONATION VALUES (103, 1, 1000, getdate(), 1);
INSERT INTO DONATION VALUES (104, 1, 1000, getdate(), 1);

UPDATE DONATION SET size_donation = 1000 WHERE donor = 1;

SELECT * FROM DONATION WHERE donor = 1;
SELECT * FROM DONOR WHERE id_donor = 1;

-- 2. backups deleted clients
DROP TRIGGER BACKUP_CLIENT;
CREATE TRIGGER BACKUP_CLIENT
  ON CLIENT
  FOR DELETE
AS
  BEGIN
    DECLARE DEL_CLIENT CURSOR FOR SELECT id_client
                                  FROM DELETED;
    DECLARE @curr_id_client INT;

    OPEN DEL_CLIENT;
    FETCH NEXT FROM DEL_CLIENT INTO @curr_id_client;
    WHILE @@FETCH_STATUS = 0
      BEGIN
        INSERT INTO EX_CLIENT (id_ex_client, ex_cl_name, ex_cl_surname, ex_cl_birth_date, ex_cl_gender, ex_cl_adress, ex_cl_phone_num, ex_cl_email, ex_cl_bank_account, ex_cl_total_donations, ex_cl_got_help, delete_date)
        SELECT * , getdate()
        FROM deleted
        WHERE deleted.id_client = @curr_id_client;

        FETCH NEXT FROM DEL_CLIENT INTO @curr_id_client;
      END;
    CLOSE DEL_CLIENT;
    DEALLOCATE DEL_CLIENT;
  END;
-- testing
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney, cl_gets_help)
VALUES (21, 'Hy', 'Fredi', '1989-08-16', 'Male', '12800 Jenna Park', 'hfredi0@biglobe.ne.jp', '350-980-1729', '5602238072231787', 1000, 1);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (22, 'Warden', 'Whitehouse', '2012-02-03', 'Male', '47 Farwell Way', 'wwhitehouse1@walmart.com', '537-815-1974', '30322563096330', 2000);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney, cl_gets_help)
VALUES (23, 'Reba', 'Padillo', '1984-08-21', 'Female', '263 Anderson Hill', 'rpadillo2@statcounter.com', '274-700-0712', '6759366897411997127', 3000, 1);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (24, 'Kali', 'Iacovone', '1961-08-07', 'Female', '1559 Blue Bill Park Lane', 'kiacovone3@nationalgeographic.com', '865-612-5782', '4017955963626237', 4000);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney, cl_gets_help)
VALUES (25, 'Pia', 'Stowte', '1997-02-03', 'Female', '88 Corben Road', 'pstowte4@accuweather.com', '163-198-6422', '3589757965933821', 5000, 1);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (26, 'Angelico', 'Cuff', '1950-06-16', 'Male', '120 Blue Bill Park Avenue', 'acuff5@posterous.com', '711-121-3303', '3578462532115662', 6000);

SELECT * FROM EX_CLIENT;
DELETE FROM CLIENT WHERE ID_CLIENT > 20;
SELECT * FROM EX_CLIENT;

SELECT * FROM CLIENT;

-- 3. doesn't allow to add a volunteering case the volunteer's already occupied that day
DROP TRIGGER BLOCK_VOLUNTEERING;
CREATE TRIGGER BLOCK_VOLUNTEERING
  ON VOLUNTEERING
  FOR INSERT, UPDATE
AS
BEGIN
  DECLARE VOLUNTEERING_CURS CURSOR FOR SELECT volunteer, date_volunteering
                                       FROM inserted;
  DECLARE @curr_volunteer INT, @curr_vol_date DATE;

  OPEN VOLUNTEERING_CURS;
  FETCH NEXT FROM VOLUNTEERING_CURS INTO @curr_volunteer, @curr_vol_date;

  WHILE @@FETCH_STATUS = 0
    BEGIN
      DECLARE @volunteering_count INT = (SELECT COUNT(volunteer)
                                         FROM VOLUNTEERING
                                         WHERE volunteer = @curr_volunteer AND date_volunteering = @curr_vol_date);
      IF @volunteering_count > 1
        BEGIN
          PRINT 'VOLUNTEER ' + CAST(@curr_volunteer AS VARCHAR(20)) + ' IS ALREADY OCCUPIED THAT DAY' ;
          ROLLBACK TRANSACTION;
        END;

      FETCH NEXT FROM VOLUNTEERING_CURS INTO @curr_volunteer, @curr_vol_date;
    END;

  CLOSE VOLUNTEERING_CURS;
  DEALLOCATE VOLUNTEERING_CURS;
END;
-- testing
UPDATE VOLUNTEERING SET date_volunteering = GETDATE() WHERE volunteer = 1;
INSERT INTO VOLUNTEERING (id_volunteering, volunteer, date_volunteering, id_help)
VALUES (21, 1, GETDATE(), 8);
INSERT INTO VOLUNTEERING (id_volunteering, volunteer, date_volunteering, id_help)
VALUES (21, 1, '2000/01/01', 9);
SELECT * FROM VOLUNTEER;

-- 4. updates client help status
DROP TRIGGER HELP_STATUS;
CREATE TRIGGER HELP_STATUS
  ON HELP
  FOR INSERT, UPDATE
AS
BEGIN
  DECLARE HELP_CURS CURSOR FOR SELECT client
                               FROM inserted;
  DECLARE @curr_client INT, @help_status BIT;

  OPEN HELP_CURS;
  FETCH NEXT FROM HELP_CURS INTO @curr_client;
  WHILE @@FETCH_STATUS = 0
    BEGIN
      SELECT @help_status = cl_gets_help
      FROM CLIENT
      WHERE id_client = @curr_client;

      IF @help_status = 0
        BEGIN
          UPDATE CLIENT
          SET cl_gets_help = 1
          WHERE id_client = @curr_client;

          PRINT 'Client #' + CAST(@curr_client AS VARCHAR(20)) + ' now gets help';
        END;

      FETCH NEXT FROM HELP_CURS INTO @curr_client;
    END;

  CLOSE HELP_CURS;
  DEALLOCATE HELP_CURS;
END;
-- testing
-- inserting clients
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (21, 'Warden', 'Whitehouse', '2012-02-03', 'Male', '47 Farwell Way', 'wwhitehouse1@walmart.com', '537-815-1974', '30322563096330', 2000);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney, cl_gets_help)
VALUES (22, 'Reba', 'Padillo', '1984-08-21', 'Female', '263 Anderson Hill', 'rpadillo2@statcounter.com', '274-700-0712', '6759366897411997127', 3000, 1);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (23, 'Kali', 'Iacovone', '1961-08-07', 'Female', '1559 Blue Bill Park Lane', 'kiacovone3@nationalgeographic.com', '865-612-5782', '4017955963626237', 4000);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney, cl_gets_help)
VALUES (24, 'Pia', 'Stowte', '1997-02-03', 'Female', '88 Corben Road', 'pstowte4@accuweather.com', '163-198-6422', '3589757965933821', 5000, 1);
INSERT INTO CLIENT (id_client, cl_name, cl_surname, cl_birth_date, cl_gender, cl_address, cl_email, cl_phone_num, cl_bank_account, cl_neededMoney)
VALUES (25, 'Angelico', 'Cuff', '1950-06-16', 'Male', '120 Blue Bill Park Avenue', 'acuff5@posterous.com', '711-121-3303', '3578462532115662', 6000);
--inserting help
INSERT INTO HELP (id_help, client)
VALUES (41, 21);
INSERT INTO HELP (id_help, client)
VALUES (42, 22);
INSERT INTO HELP (id_help, client)
VALUES (43, 23);
INSERT INTO HELP (id_help, client)
VALUES (44, 24);
INSERT INTO HELP (id_help, client)
VALUES (45, 25);

SELECT cl_gets_help FROM CLIENT WHERE id_client = 26;
SELECT cl_gets_help FROM CLIENT;



