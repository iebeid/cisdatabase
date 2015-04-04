/*
Author: Islam A. Ebeid
Description: 
*	tg_deleteClasses: 
    - This is a trigger of your instructor table—there should be such a table to store instructor contact data. 
    - When it is fired after an instructor is deleted, it deletes schedules of all classes of every semester taught by the instructor.

*	tg_checkConflict: 
    - This trigger should belong to a table that stores days, times, and room data of classes. 
    - It is fired when an update of a class days and/or times and/or room are done. 
    - It checks if the updated schedule conflicts with other classes. 
    - That is if the room is totally free during the times on those days. 
    - If not, the trigger should roll back the update.

*/
USE CIS;


GO
IF OBJECT_ID('tg_deleteClasses') IS NOT NULL
    DROP TRIGGER tg_deleteClasses;


GO
CREATE TRIGGER tg_deleteClasses
    ON Instructor
    INSTEAD OF DELETE
    AS DELETE Schedule
       WHERE  Schedule.Instructor IN (SELECT deleted.Instructor
                                 FROM   deleted
                                        INNER JOIN
                                        Schedule
                                        ON deleted.InstName = Schedule.Instructor);
                                        
    print 'triggrt';


GO

select * from Instructor;
delete from Instructor where Email = 'hbrown11@atu.edu';

select * from Schedule where Instructor = 'Brown, Herbert E.';

-------->	(-6) Good try but this doesn't work.

--			According to p466-467 or Books Online, AFTER triggers are never executed 
--			if a constraint violation occurs. You should implement 6.1 by an INSTEAD OF
--		    trigger because "...(from Books Online)...They are executed before any constraints, 
--			so can perform preprocessing that supplements the constraint actions."

--			With the above rule, deleting instructors will cause an error due to the FK constraint
--			between dbo.Instructor and dbo.Schedule of CIS. In other words, your tg_deleteClasses
--			trigger never gets a chance to execute.

--			Try INSTEAD OF trigger.




IF OBJECT_ID('tg_checkConflict') IS NOT NULL
    DROP TRIGGER tg_checkConflict;


GO
CREATE TRIGGER tg_checkConflict
    ON Schedule
    AFTER UPDATE, INSERT
    AS IF EXISTS (SELECT *
                  FROM   inserted
                         INNER JOIN
                         Schedule
                         ON Schedule.Days = inserted.Days
                            AND Schedule.RID = inserted.RID
                            AND Schedule.SID <> inserted.SID
                  WHERE  (Schedule.BeginningTime <= inserted.BeginningTime
                          AND Schedule.EndingTime >= inserted.EndingTime)
                         OR (Schedule.BeginningTime >= inserted.BeginningTime
                             AND (Schedule.EndingTime >= inserted.EndingTime
                                  AND inserted.EndingTime > Schedule.BeginningTime))
                         OR ((inserted.BeginningTime > Schedule.BeginningTime
                              AND inserted.BeginningTime <= Schedule.EndingTime)
                             AND inserted.EndingTime >= Schedule.EndingTime)
                         OR (Schedule.BeginningTime >= inserted.BeginningTime
                             AND Schedule.EndingTime <= inserted.EndingTime))
           BEGIN
               RAISERROR ('Class time conflict', 1, 1);
               ROLLBACK;
           END
       ELSE
           BEGIN
               PRINT 'updated successfully';
           END


------> (-4) 1. You must check and compare TID. Time conflict occurs to classes of the same semester only.
--			 2. 'Schedule.Days = inserted.Days' does not cover many other cases. For example, a class of 
--				9:00-10:20am on MW actually conflicts with another class of 9:30-10:20 on MWF if they both 
--				are arranged in the same room in the same semester. Their Days are not equal but they still 
--				conflict.
--			 3. Time conflict occurs as long as two class times are overlapped. They don't have to begin 
--				at exactly the same time. Your WHERE expression is too complicated. It can be simplified as

				(inserted.BeginningTime BETWEEN Schedule.BeginningTime AND Schedule.EndingTime
				 OR inserted.EndingTime BETWEEN Schedule.BeginningTime AND Schedule.EndingTime)