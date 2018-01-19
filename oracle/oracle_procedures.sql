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

--2.
CREATE OR REPLACE PROCEDURE