USE s15711;

-- todo: https://social.msdn.microsoft.com/Forums/sqlserver/en-US/40f5635c-9034-4e9b-8fd5-c02cec44ce86/how-to-let-trigger-act-for-each-row?forum=sqlgetstarted

-- 1. sums up donations made by a donor, updates the donor's total donations column
drop TRIGGER DONATION_SUMMING;
CREATE TRIGGER DONATION_SUMMING
  ON DONATION
  FOR INSERT, UPDATE
AS
BEGIN
  DECLARE @donation_sum MONEY,
    @inserted_donor INT = (SELECT donor FROM inserted);

  SELECT @donation_sum = SUM(DONATION.size_donation)
  FROM DONATION, inserted
  WHERE DONATION.donor = inserted.donor;

  UPDATE DONOR
  SET d_total_sum = @donation_sum
  WHERE id_donor = (SELECT donor FROM inserted);

  PRINT 'Donor ' + CAST(@inserted_donor AS VARCHAR(10)) + ' donated ' + CAST(@donation_sum AS VARCHAR(20)) + ' in total';
END;

insert into DONATION VALUES (100, 1, 99999, getdate(), 1);

update DONATION set size_donation = 0 WHERE donor = 1;

-- 2. backups deleted clients -- todo -- should use cursors, bcz there's no for each row
CREATE TRIGGER BACKUP_CLIENT
  ON CLIENT
  FOR DELETE
AS
  BEGIN

  END;

-- 3. doesn't let a volunteering for the volunteer in case he's already occupied that day




-- 4. updates client help status