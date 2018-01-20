SET SERVEROUTPUT ON;

-- 1. shows information about help received by the given client
CREATE OR REPLACE PROCEDURE TOTAL_HELP_INFO
  (cl_id IN NUMBER)
AS
  count_1 NUMBER;
  count_2 NUMBER;

  no_such_client_exception EXCEPTION;
  no_help_exception EXCEPTION;
  donations_total NUMBER := 0;
  volunteerinngs_total NUMBER := 0;

  donation_size_temp NUMBER;
  help_id_temp NUMBER;
  CURSOR help_cursor IS
    SELECT id_help
    FROM HELP
    WHERE client = cl_id;

BEGIN
  SELECT COUNT(id_client) INTO count_1
  FROM CLIENT
  WHERE id_client = cl_id;
  IF count_1 < 1 THEN
    RAISE no_such_client_exception;
  END IF;

  SELECT COUNT(id_help) INTO count_2
  FROM HELP
  WHERE client = cl_id;
  IF count_2 < 1 THEN
    RAISE no_help_exception;
  END IF;

  OPEN help_cursor;
  LOOP
    FETCH help_cursor INTO help_id_temp;
    EXIT WHEN help_cursor%NOTFOUND;

    SELECT COUNT(id_donation) INTO count_1
    FROM DONATION
    WHERE id_help = help_id_temp;

    SELECT COUNT(id_volunteering) INTO count_2
    FROM VOLUNTEERING
    WHERE id_help = help_id_temp;

    IF count_1 > 0 THEN
      SELECT size_donation INTO donation_size_temp
      FROM DONATION
      WHERE id_help = help_id_temp;
      donations_total := donations_total + donation_size_temp;
    ELSIF count_2 > 0 THEN
      volunteerinngs_total := volunteerinngs_total + 1;
    END IF;
  END LOOP;
  CLOSE help_cursor;

  IF donations_total > 0 THEN
    DBMS_OUTPUT.PUT_LINE('In total the client received ' || donations_total || ' in donations');
  ELSE
    DBMS_OUTPUT.PUT_LINE('The client did not receive any donations');
  END IF;
  IF volunteerinngs_total > 0 THEN
    DBMS_OUTPUT.PUT_LINE('The client was helped by volunteers ' || volunteerinngs_total || ' times');
  ELSE
    DBMS_OUTPUT.PUT_LINE('The client was not helped by volunteers');
  END IF;
EXCEPTION
  WHEN no_such_client_exception THEN
  DBMS_OUTPUT.PUT_LINE('THERE IS NO CLIENT WITH ID ' || cl_id);
  WHEN no_help_exception THEN
  DBMS_OUTPUT.PUT_LINE('THE CLIENT WITH ID ' || cl_id || ' HAS NOT RECEIVED ANY HELP YET');
END;
/
--testing
INSERT INTO CLIENT(id_client, cl_name, cl_surname, cl_gender) VALUES(100, 'test', 'test', 'F');

INSERT INTO HELP(id_help, client) VALUES(100, 1);
INSERT INTO DONATION(id_donation, donor, id_help, size_donation) VALUES (100, 1, 100, 1000);
INSERT INTO VOLUNTEERING(ID_VOLUNTEERING, VOLUNTEER, id_help) VALUES (100, 1, 100);

SELECT * FROM VOLUNTEERING V
WHERE EXISTS (SELECT * FROM HELP WHERE id_help = V.id_help AND CLIENT = 1);

DELETE FROM VOLUNTEERING WHERE id_volunteering = 1;
DELETE FRM DONATION WHERE id_donation = 1;

ROLLBACK
EXECUTE TOTAL_HELP_INFO(1);

--2. equally distributes the donated money among people who need it
CREATE OR REPLACE PROCEDURE DONATE_TO_EVERYONE_IN_NEED
  (arg_id_donor NUMBER, total_donation_size NUMBER)
AS
  tmp_id_client NUMBER;
  tmp_donation_size NUMBER(10, 2);
  tmp_needed_money NUMBER; -- sum of money needed by the processed client, used to calculate donation size
  tmp_received_money NUMBER; -- sum of money already donated to the client
  donation_left NUMBER := total_donation_size; -- used for calculating avg donation
  people_count NUMBER; -- used for checking if anybody needs help
  people_left NUMBER; -- used for calculating avg donation
  no_people_in_need_exception EXCEPTION;

  donor_count NUMBER;-- to check if there is such donor

  CURSOR people_in_need_cursor IS
    SELECT ID_CLIENT, CL_NEEDEDMONEY
    FROM CLIENT
    WHERE CL_NEEDEDMONEY > (SELECT SUM(size_donation)
                            FROM HELP, DONATION
                            WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP)
    ORDER BY CL_NEEDEDMONEY - (SELECT SUM(size_donation)
              FROM HELP, DONATION
              WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP);
BEGIN
  -- check if anybody needs help
  SELECT COUNT(id_client) INTO people_count
  FROM CLIENT
  WHERE CL_NEEDEDMONEY > (SELECT SUM(size_donation)
                          FROM HELP, DONATION
                          WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP);
  IF people_count < 1 THEN
    RAISE no_people_in_need_exception;
  END IF;
  people_left := people_count;

  -- todo -- insert the donor record in case there's no one present yet
  OPEN people_in_need_cursor;
  LOOP
    FETCH people_in_need_cursor INTO tmp_id_client, tmp_needed_money;
    EXIT WHEN people_in_need_cursor%NOTFOUND;

    SELECT SUM(size_donation) INTO tmp_received_money
    FROM HELP, DONATION
    WHERE HELP.client = tmp_id_client AND DONATION.id_help = HELP.id_help;
    tmp_needed_money := tmp_needed_money - tmp_received_money;

    DBMS_OUTPUT.PUT_LINE(donation_left || ' LEFT');

    --debug
    DBMS_OUTPUT.PUT_LINE(tmp_id_client || ' id ' || tmp_received_money || ' received ' || tmp_needed_money || ' needed');
    --/debug

    tmp_donation_size := donation_left / people_left;
    --debug
    DBMS_OUTPUT.PUT_LINE(tmp_donation_size || ' before checking');
    --/debug

    IF tmp_donation_size > tmp_needed_money THEN
      tmp_donation_size := tmp_needed_money;
    END IF;

    DBMS_OUTPUT.PUT_LINE(tmp_donation_size || ' after checking');

    donation_left := donation_left - tmp_donation_size;
    people_left := people_left - 1;
  END LOOP;
  CLOSE people_in_need_cursor;

  -- outputing the result of procedure
  IF donation_left > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Everyone in need got necessary help, still ' || donation_left || ' left');
  ELSE
    DBMS_OUTPUT.PUT_LINE('All the donation was distributed among ' || people_count || ' clients');  
  END IF;

EXCEPTION
  WHEN no_people_in_need_exception THEN
  DBMS_OUTPUT.PUT_LINE('NO PEOPLE NEED MONETARY HELP AT THE MOMENT');
END;

-- testing
EXECUTE DONATE_TO_EVERYONE_IN_NEED(0, 1100);
SELECT *
  FROM CLIENT
  WHERE CL_NEEDEDMONEY < (SELECT SUM(size_donation)
                          FROM HELP, DONATION
                          WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP);

------------------ testing queries
SELECT ID_CLIENT
FROM CLIENT
WHERE CL_NEEDEDMONEY > (SELECT SUM(SIZE_DONATION)
                        FROM HELP, DONATION
                        WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP);

SELECT SUM(size_donation)
    FROM HELP, DONATION
    WHERE HELP.client = 5 AND DONATION.id_help = HELP.id_help;

select * FROM CLIENT;

SELECT ID_CLIENT, CL_NEEDEDMONEY
    FROM CLIENT
    WHERE CL_NEEDEDMONEY > (SELECT SUM(size_donation)
                            FROM HELP, DONATION
                            WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP)
    ORDER BY CL_NEEDEDMONEY - (SELECT SUM(size_donation)
              FROM HELP, DONATION
              WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP);
