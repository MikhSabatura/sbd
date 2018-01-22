USE s15711;

-- I. RESULT SET

-- 1. Shows people who need monetary help
DROP PROCEDURE CLIENTS_NEEDING_HELP;
CREATE PROCEDURE CLIENTS_NEEDING_HELP
AS
BEGIN
  SELECT
    ID_CLIENT,
    (SELECT SUM(size_donation)
     FROM HELP, DONATION
     WHERE CLIENT = CLIENT.ID_CLIENT AND
           DONATION.ID_HELP = HELP.ID_HELP) - cl_neededMoney NEEDED_SUM
  FROM CLIENT
  WHERE cl_neededMoney < (SELECT SUM(size_donation)
                          FROM HELP, DONATION
                          WHERE CLIENT = CLIENT.ID_CLIENT AND
                                DONATION.ID_HELP = HELP.ID_HELP)
  ORDER BY NEEDED_SUM DESC;

END;
-- testing
EXECUTE CLIENTS_NEEDING_HELP;

-- 2.

-- II. OUTPUT

-- 1. Distributes the money among people who need monetary help // used by REDISTRIBUTE_MONEY
DROP PROCEDURE DISTRIBUTE_DONATION;
CREATE PROCEDURE DISTRIBUTE_DONATION
    @id_donor INT,
    @total_donation MONEY,
    @affected_people INT OUTPUT,
    @money_left MONEY OUTPUT-- money left after everyone was helped
AS
BEGIN
  SET NOCOUNT ON;
  SELECT @affected_people = 0, @money_left = @total_donation;

  DECLARE people_in_need_curs CURSOR FOR SELECT
                                           ID_CLIENT,
                                           CL_NEEDEDMONEY - (SELECT SUM(size_donation)
                                                             FROM HELP, DONATION
                                                             WHERE CLIENT = CLIENT.ID_CLIENT AND
                                                                   DONATION.ID_HELP = HELP.ID_HELP) NEEDED_SUM
                                         FROM CLIENT
                                         WHERE CL_NEEDEDMONEY > (SELECT SUM(size_donation)
                                                                 FROM HELP, DONATION
                                                                 WHERE CLIENT = CLIENT.ID_CLIENT AND
                                                                       DONATION.ID_HELP = HELP.ID_HELP)
                                         ORDER BY NEEDED_SUM;
  DECLARE @curr_client INT,
          @curr_needed_sum MONEY;

  OPEN people_in_need_curs;
  FETCH NEXT FROM people_in_need_curs INTO @curr_client, @curr_needed_sum;
  WHILE @@FETCH_STATUS = 0
    BEGIN
      DECLARE @people_to_help INT = (SELECT COUNT(id_client)
                                     FROM CLIENT
                                     WHERE CL_NEEDEDMONEY > (SELECT SUM(size_donation)
                                                             FROM HELP, DONATION
                                                             WHERE CLIENT = CLIENT.ID_CLIENT AND
                                                                   DONATION.ID_HELP = HELP.ID_HELP));

      DECLARE @curr_donation MONEY = @money_left / @people_to_help;
      IF @curr_donation > @curr_needed_sum
        BEGIN
          SET @curr_donation = @curr_needed_sum;
        END;

      DECLARE @help_id INT = (SELECT ISNULL(MAX(id_help) + 1, 1) FROM HELP);
      INSERT INTO HELP(id_help, client) VALUES (@help_id, @curr_client);

      INSERT INTO DONATION (id_donation, donor, size_donation, date_donation, id_help)
      VALUES ((SELECT ISNULL(MAX(id_donation) + 1, 1) FROM DONATION), @id_donor, @curr_donation, getdate(), @help_id);

      SELECT
        @affected_people = @affected_people + 1,
        @money_left = @money_left - @curr_donation;
      FETCH NEXT FROM people_in_need_curs INTO @curr_client, @curr_needed_sum;
    END;
  CLOSE people_in_need_curs;
  DEALLOCATE people_in_need_curs;
END;
-- testing
DECLARE @count INT, @money MONEY;
EXECUTE DISTRIBUTE_DONATION 1, 2230, @count OUTPUT, @money OUTPUT;
PRINT CAST(@count AS VARCHAR(10)) + ' ' + CAST(@money AS VARCHAR(20));

-- 2. Takes money from clients who were donated too much and gives it to those who weren't donated enough
DROP PROCEDURE REDISTRIBUTE_MONEY;
CREATE PROCEDURE REDISTRIBUTE_MONEY
  @total_redistributed MONEY OUTPUT, -- the total sum of redistributed money
  @left MONEY OUTPUT, -- the sum of money still left after redistribution (in case there is any)
  @helped_people INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE overDonatedClients CURSOR FOR SELECT
                                          ID_CLIENT,
                                          cl_neededMoney,
                                          (SELECT SUM(size_donation)
                                           FROM HELP, DONATION
                                           WHERE CLIENT = CLIENT.ID_CLIENT AND
                                                 DONATION.ID_HELP = HELP.ID_HELP) DONATED
                                        FROM CLIENT
                                        WHERE cl_neededMoney < (SELECT SUM(size_donation)
                                                                FROM HELP, DONATION
                                                                WHERE CLIENT = CLIENT.ID_CLIENT AND
                                                                      DONATION.ID_HELP = HELP.ID_HELP);
  DECLARE @id_cl_overDonated INT, @needed_sum MONEY, @donated_sum MONEY;
  SELECT @total_redistributed = 0, @left = 0;

  OPEN overDonatedClients;
  FETCH NEXT FROM overDonatedClients INTO @id_cl_overDonated, @needed_sum, @donated_sum;
  WHILE @@FETCH_STATUS = 0
    BEGIN

      DECLARE @overDonated_sum MONEY = @donated_sum - @needed_sum;
      -- taking over-donated money
      UPDATE CLIENT
      SET cl_neededMoney = @needed_sum
      WHERE id_client = @id_cl_overDonated;

      DECLARE @top_donation INT, @top_donor INT, @top_sum MONEY;
      EXECUTE FIND_TOP_DONATION @id_cl_overDonated, @top_donation OUTPUT, @top_donor OUTPUT;

      SELECT @top_sum = size_donation
      FROM DONATION
      WHERE id_donation = @top_donation;

      UPDATE DONATION
      SET size_donation = @top_sum - @overDonated_sum
      WHERE id_donation = @top_donation;

      -- redistributing
      DECLARE @tmp_helped_people INT, @tmp_left MONEY;
      EXECUTE DISTRIBUTE_DONATION @top_donor, @overDonated_sum, @tmp_helped_people OUTPUT, @tmp_left OUTPUT;

      SELECT @total_redistributed = @total_redistributed + @overDonated_sum, @left = @left + @tmp_left;
      FETCH NEXT FROM overDonatedClients INTO @id_cl_overDonated, @needed_sum, @donated_sum;
    END;
  SET @total_redistributed = @total_redistributed - @left; -- used because total_redistributed is incremented after everyone was helped
  CLOSE overDonatedClients;
  DEALLOCATE overDonatedClients;
END;
-- testing
DECLARE @redistributed MONEY, @left MONEY, @helped_people INT;
EXECUTE REDISTRIBUTE_MONEY @redistributed OUTPUT, @left OUTPUT, @helped_people OUTPUT;
PRINT 'redistributed ' + CAST(@redistributed AS VARCHAR(25)) + ' | left ' + CAST(@left AS VARCHAR(20));

-- 3. Finds the biggest donation made to the given client // used by REDISTRIBUTE_MONEY
DROP PROCEDURE FIND_TOP_DONATION;
CREATE PROCEDURE FIND_TOP_DONATION
  @id_client INT,
  @top_donation_id INT OUTPUT,
  @top_donor_id INT OUTPUT
AS
BEGIN
  SELECT @top_donation_id = id_donation, @top_donor_id = donor
  FROM HELP, DONATION
  WHERE HELP.client = @id_client AND DONATION.id_help = HELP.id_help
        AND size_donation = (SELECT MAX(size_donation)
                             FROM DONATION, HELP
                             WHERE DONATION.id_help = HELP.id_help AND HELP.client = @id_client);
END;
-- testing
DECLARE @donor INT, @donation INT;
EXECUTE FIND_TOP_DONATION 5, @donor OUTPUT, @donation OUTPUT;
PRINT CAST(@donor as VARCHAR(20)) + ' ' + cast(@donation as VARCHAR(20));

-- III. RETURN
-- 1. Changes help status for all clients who have associated help, outputs the number of updated records
DROP PROCEDURE UPD_HELP_STATUS;
CREATE PROCEDURE UPD_HELP_STATUS
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE not_helped_clients_curs CURSOR FOR SELECT id_client
                                             FROM CLIENT
                                             WHERE cl_gets_help = 0;
  DECLARE @curr_client INT,
          @count_changed INT;
  SET @count_changed = 0;

  OPEN not_helped_clients_curs;
  FETCH NEXT FROM not_helped_clients_curs INTO @curr_client;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    DECLARE @count_help INT = (SELECT COUNT(client)
                               FROM HELP
                               WHERE client = @curr_client);
    IF @count_help > 0
      BEGIN
        UPDATE CLIENT
        SET cl_gets_help = 1
        WHERE id_client = @curr_client;
        SET @count_changed = @count_changed + 1;
      END;
    FETCH NEXT FROM not_helped_clients_curs INTO @curr_client;
  END;
  CLOSE not_helped_clients_curs;
  DEALLOCATE not_helped_clients_curs;

  RETURN @count_changed;
END;
-- testing
DECLARE @updated INT;
EXECUTE @updated = UPD_HELP_STATUS;
PRINT @updated;
SELECT id_client FROM CLIENT WHERE cl_gets_help = 1;

-- 2. Calculates how much money the client still needs
DROP PROCEDURE CALC_NEEDED_SUM;
CREATE PROCEDURE CALC_NEEDED_SUM
  @id_client INT
AS
BEGIN
  SET NOCOUNT ON;
  RETURN (SELECT CL_NEEDEDMONEY - (SELECT SUM(size_donation)
                                         FROM HELP, DONATION
                                         WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP)
  FROM CLIENT
  WHERE id_client = @id_client);
END;
-- testing
DECLARE @needed_sum MONEY;
EXECUTE @needed_sum = CALC_NEEDED_SUM 1;
PRINT 'NEEDED SUM IS ' + CAST(@needed_sum AS VARCHAR(20));



------------ IDEAS:

-- 3. moves all clients who got help into got_help table

-- find how much monetary help is needed by the clients in general

-- DELETION:
-- deletes help associated with the given client
-- deletes donations associated with the given help
-- deletes volunteerings associated with the given help


SELECT SUM(size_donation)
FROM HELP, DONATION
WHERE CLIENT = 3 AND DONATION.ID_HELP = HELP.ID_HELP;

SELECT cl_neededMoney
FROM CLIENT
WHERE id_client = 3;

SELECT donor
FROM DONATION, help, CLIENT C
WHERE HELP.id_help = DONATION.id_help AND HELP.client = C.id_client
      AND size_donation = (SELECT MAX(size_donation)
                           FROM DONATION, HELP
                           WHERE DONATION.id_help = HELP.id_help AND HELP.client = C.id_client);

SELECT SUM(cl_neededMoney) FROM CLIENT;
SELECT SUM(size_donation) FROM DONATION;
