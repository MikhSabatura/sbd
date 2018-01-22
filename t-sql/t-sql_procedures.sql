USE s15711;

-- I. RESULT SET
-- 1. SELECT ALL PEOPLE WHO DIDN'T GET ANY HELP YET
-- CREATE PROCEDURE

-- II. OUTPUT
-- 1. Calculates how much money the client still needs // todo: used by
DROP PROCEDURE CALC_NEEDED_SUM;
CREATE PROCEDURE CALC_NEEDED_SUM
  @id_client INT,
  @needed_sum MONEY OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT @needed_sum = CL_NEEDEDMONEY - (SELECT SUM(size_donation)
                                         FROM HELP, DONATION
                                         WHERE CLIENT = CLIENT.ID_CLIENT AND DONATION.ID_HELP = HELP.ID_HELP)
  FROM CLIENT
  WHERE id_client = @id_client;
END;
-- testing
DECLARE @needed_sum MONEY;
EXECUTE CALC_NEEDED_SUM 2, @needed_sum OUTPUT;
PRINT 'NEEDED SUM IS ' + CAST(@needed_sum AS VARCHAR(20));

-- 2. Distributes the money among people who need monetary help // todo: used by
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

-- 2. moves all clients who got help into got_help table
DROP PROCEDURE REMOVE_HELPED_CLIENTS;

-- find how much monetary help is needed by the clients in general

-- DELETION:
-- deletes help associated with the given client
-- deletes donations associated with the given help
-- deletes volunteerings associated with the given help

-- donate to someone in need -- donates to the first one(the one who needs the most money)

-- equally distribute money in case someone received more than he needs


SELECT SUM(size_donation)
FROM HELP, DONATION
WHERE CLIENT = 3 AND DONATION.ID_HELP = HELP.ID_HELP;

SELECT cl_neededMoney
FROM CLIENT
WHERE id_client = 3;
