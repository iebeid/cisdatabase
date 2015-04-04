/*
Author : Islam A. Ebeid
Description : 
- Executing this script will set an integer (starting from 1) in the Class column of each row of Schedule table. 
- If a set of Schedule rows have the same TID (i.e., semester) and CRN values, they should have the same Class value. 
- For example, the two rows with SID 210 and 211 are schedules of one class, therefore their Class value should be the same. 
*/

USE CIS;

IF OBJECT_ID('dbo.sp_incrementClass') IS NOT NULL
    DROP PROCEDURE dbo.sp_incrementClass;


GO
CREATE PROCEDURE sp_incrementClass
@ClassUpdatedValue SMALLINT, @sid INT
AS
UPDATE  Schedule
    SET Class = @ClassUpdatedValue
WHERE   SID = @sid;


GO
USE CIS;

IF OBJECT_ID('dbo.sp_updateClass') IS NOT NULL
    DROP PROCEDURE dbo.sp_updateClass;


GO
CREATE PROCEDURE sp_updateClass

AS
SET NOCOUNT ON;
DECLARE @n AS SMALLINT = 1;
DECLARE @sid_all AS INT;
DECLARE sid_cursor_all CURSOR
    FOR SELECT SID
        FROM   Schedule;
OPEN sid_cursor_all;
WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM sid_cursor_all INTO @sid_all;
        IF @sid_all IN (SELECT SID
                        FROM   Schedule
                               INNER JOIN
                               (SELECT   urSchedule.countTIDCRN AS [countTIDCRN],
                                         COUNT(urSchedule.SID) AS [countSID]
                                FROM     (SELECT s.SID,
                                                 (CAST (s.TID AS VARCHAR) + CAST (s.CRN AS VARCHAR)) AS countTIDCRN
                                          FROM   Schedule AS s) AS urSchedule
                                GROUP BY urSchedule.countTIDCRN
                                HAVING   COUNT(urSchedule.SID) > 1) AS countTable
                               ON (CAST (TID AS VARCHAR) + CAST (CRN AS VARCHAR)) = countTable.countTIDCRN)
            BEGIN
                SET @n = @n;
            END
        ELSE
            BEGIN
                SET @n = @n + 1;
            END
        EXECUTE dbo.sp_incrementClass @n, @sid_all;            
        IF @@FETCH_STATUS <> 0
            BEGIN
                BREAK;
            END
    END
CLOSE sid_cursor_all;
DEALLOCATE sid_cursor_all;


GO
EXECUTE dbo.sp_updateClass;

------> (-6) Incorrect class value assigned.
--			 Your process is too complicate and each of the following class numbers 
--			 contains a set of schedules that do not belong to a class. 

--				20	
--				24	
--				108	
--				194	
--				282	

use CIS;
select * from Sched ule;

update Schedule set CID = null;

SELECT SID,countTable.countSID,countTable.countTIDCRN
FROM   Schedule
INNER JOIN (SELECT   urSchedule.countTIDCRN AS [countTIDCRN],COUNT(urSchedule.SID) AS [countSID]
			FROM (SELECT s.SID,(CAST (s.TID AS VARCHAR) + CAST (s.CRN AS VARCHAR)) AS countTIDCRN FROM Schedule AS s) AS urSchedule
GROUP BY urSchedule.countTIDCRN
HAVING   COUNT(urSchedule.SID) > 1) AS countTable
ON (CAST (TID AS VARCHAR) + CAST (CRN AS VARCHAR)) = countTable.countTIDCRN;





GO
CREATE PROCEDURE sp_updateClass2
AS
SET NOCOUNT ON;
DECLARE @n AS SMALLINT = 0;
declare @sid int;
declare @tidcrn varchar;
declare mycursor cursor
for select sid,(CAST (TID AS VARCHAR) + CAST (CRN AS VARCHAR)) AS TIDCRN
from Schedule
open mycursor;
fetch next from mycursor into @sid,@tidcrn
while 1=1
begin
if exists (select (CAST (TID AS VARCHAR) + CAST (CRN AS VARCHAR)) AS TIDCRN,COUNT(*) from Schedule where SID=@sid group by (CAST (TID AS VARCHAR) + CAST (CRN AS VARCHAR)) having COUNT(*)>1)   
begin 
SET @n = @n;
end
else
begin
SET @n = @n + 1;
end
EXECUTE dbo.sp_incrementClass @n, @sid;
fetch next from mycursor into @sid,@tidcrn 
if @@FETCH_STATUS <> 0
begin
break;
end
end
Go
execute dbo.sp_updateClass2;
Go
select * from Schedule;