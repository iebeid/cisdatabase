/*
Author : Islam A. Ebeid
Description : 
- This script contains statements that create the following user-defined functions in CIS:
*	f_instructor(): It uses four input values—Subj, Num, Sec, and Semester, and returns the instructor who teaches the class 
	specified by the four input values.
*	f_classTime(): It returns class Days, Times, and Sec in a table for all sections of a course specified by the three input values—
	Subj, Num, and Semester. For instance, if COMS, 1411, and Fall 2011 are given, this function returns the class days, times, and
	section number of all six sections of COMS 1411 in fall 2011.
*/
USE CIS;


GO
IF OBJECT_ID('f_instructor') IS NOT NULL
    DROP FUNCTION dbo.f_instructor;


GO
CREATE FUNCTION f_instructor
(@SUBJ CHAR (4), @NUM CHAR (4), @SEC VARCHAR (10), @SEMESTER VARCHAR (20))
RETURNS VARCHAR (70)
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @INSTRUCTOR AS VARCHAR (70);
    SET @INSTRUCTOR = (SELECT Instructor.InstName
                       FROM   Schedule
                              INNER JOIN
                              Instructor
                              ON Schedule.Instructor = Instructor.InstName
                              INNER JOIN
                              Course
                              ON Schedule.CID = Course.CID
                              INNER JOIN
                              Semester
                              ON Schedule.TID = Semester.TID
                       WHERE  Course.Subj = @SUBJ
                              AND Course.Num = @NUM
                              AND Schedule.Sec = @SEC
                              AND (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR)) = @SEMESTER);
    RETURN (@INSTRUCTOR);
END;

--------> OK


GO
USE CIS;

IF OBJECT_ID('f_classTime') IS NOT NULL
    DROP FUNCTION dbo.f_classTime;


GO
CREATE FUNCTION f_classTime
(@SUBJ CHAR (4), @NUM CHAR (4), @SEMESTER VARCHAR (20))
RETURNS TABLE 
AS
RETURN 
    (SELECT Days,
            BeginningTime,
            EndingTime,
            Sec
     FROM   Schedule
            INNER JOIN
            Course
            ON Schedule.CID = Course.CID
            INNER JOIN
            Semester
            ON Schedule.TID = Semester.TID
     WHERE  Course.Subj = @SUBJ
            AND Course.Num = @NUM
            AND Semester.Term = LEFT(@SEMESTER, charindex(' ', @SEMESTER))
            AND Semester.Year = RIGHT(@SEMESTER, 4));


--------> OK