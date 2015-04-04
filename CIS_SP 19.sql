/*
Author: Islam A. Ebeid
Description:
* sp_classAnalysis: 
- This procedure accepts a semester as input 
- uses GROUPING SETS in a query to return 
- total number of classes of each room 
- total number of classes of each day (from Monday to Friday and online) 
- total number of classes of each instructor in the given semester

* sp_instructorSchedule:
- This procedure accepts four inputs: day (e.g., ‘M’ or ‘Mon’ or ‘Monday’ or ‘1’, depending on your design),
  semester, building, and room. 
- It returns a table that contains the room schedule on the given day of the semester. 
- This table should has five columns sorted by Times: Times, Subj, Num, Sec, and Instructor.
*/
USE CIS;


GO
IF OBJECT_ID('sp_classAnalysis') IS NOT NULL
    DROP PROCEDURE dbo.sp_classAnalysis;


GO
CREATE PROCEDURE sp_classAnalysis
@SEMESTER VARCHAR (20)
AS
SET NOCOUNT ON;
--Input Validation Check
IF @SEMESTER NOT IN (SELECT (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR)) AS [SEMESTER]
                     FROM   Semester)
    BEGIN
        RAISERROR ('Please check your input, example: Fall 2010', 1, 1);
    END
------------------------
DECLARE @SemesterTerm AS VARCHAR (10);
DECLARE @SemsterYear AS CHAR (4);
SET @SemesterTerm = (SELECT LEFT(@SEMESTER, CHARINDEX(' ', @SEMESTER)));
SET @SemsterYear = (SELECT RIGHT(@SEMESTER, 4));
SELECT   roomsTable.Rooms AS [Rooms],
         ' ' AS [Day],
         ' ' AS [Instructor],
         COUNT(roomsTable.Class) AS [Total Number of Classes]
FROM     (SELECT isnull(CAST (Rooms.Room AS VARCHAR), 'Classes with no rooms') AS [Rooms],
                 Class
          FROM   Schedule
                 LEFT OUTER JOIN
                 Rooms
                 ON Schedule.RID = Rooms.RID
                 INNER JOIN
                 Semester
                 ON Schedule.TID = Semester.TID
          WHERE  Semester.Term = @SemesterTerm
                 AND Semester.Year = @SemsterYear) AS roomsTable
GROUP BY GROUPING SETS(roomsTable.Rooms)
UNION
SELECT   ' ' AS [Rooms],
         daysTable.Days AS [Day],
         ' ' AS [Instructor],
         COUNT(daysTable.Class) AS [Total Number of Classes]
FROM     (SELECT CASE 
WHEN Days_M = 1 THEN 'Monday' 
WHEN Days_T = 1 THEN 'Tuesday' 
WHEN Days_W = 1 THEN 'Wednesday' 
WHEN Days_R = 1 THEN 'Thursday' 
WHEN Days_F = 1 THEN 'Friday' 
WHEN Schedule.Sec LIKE '%TC%' THEN 'Online' 
WHEN Schedule.Sec LIKE '%M%' THEN 'Others' 
WHEN Schedule.Sec LIKE '%L%' THEN 'Lab' ELSE '-' 
END AS [Days],
                 Class
          FROM   Schedule
                 INNER JOIN
                 Semester
                 ON Schedule.TID = Semester.TID
          WHERE  Semester.Term = @SemesterTerm
                 AND Semester.Year = @SemsterYear) AS daysTable
GROUP BY GROUPING SETS(daysTable.Days)
UNION
SELECT   ' ' AS [Rooms],
         ' ' AS [Day],
         Instructor AS [Instructor],
         COUNT(Class) AS [Total Number of Classes]
FROM     Schedule
         INNER JOIN
         Semester
         ON Schedule.TID = Semester.TID
WHERE    Semester.Term = @SemesterTerm
         AND Semester.Year = @SemsterYear
GROUP BY GROUPING SETS(Instructor);


GO

------> (-1) You should include Building as a part of room to avoid 
--			 incorrect summary for rooms of same number but in different building.


USE CIS;


GO
IF OBJECT_ID('sp_instructorSchedule') IS NOT NULL
    DROP PROCEDURE dbo.sp_instructorSchedule;


GO
CREATE PROCEDURE sp_instructorSchedule
@DAY VARCHAR (20), @SEMESTER VARCHAR (20), @BUILDING VARCHAR (30), @ROOM SMALLINT
AS
SET NOCOUNT ON;
--Input Validation Check
IF @DAY NOT IN ('M', 'T', 'W', 'R', 'F')
    BEGIN
        RAISERROR ('Please check your input, your input should be one of the following: (M,T,W,R,F)', 1, 1);
    END
IF @SEMESTER NOT IN (SELECT (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR)) AS [SEMESTER]
                     FROM   Semester)
    BEGIN
        RAISERROR ('Please check your input, example: Fall 2010', 1, 1);
    END
IF NOT EXISTS (SELECT Building
               FROM   Rooms
               WHERE  Building = @BUILDING)
    BEGIN
        RAISERROR ('Please check your input, your building name should be one of the building names in the Building colomn in the Rooms table', 1, 1);
    END
IF NOT EXISTS (SELECT Room
               FROM   Rooms
               WHERE  Room = @ROOM)
    BEGIN
        RAISERROR ('Please check your input, your room number should be one of the room numbers in Room colomn in Rooms table', 1, 1);
    END
------------------------
DECLARE @SemesterTerm AS VARCHAR (10);
DECLARE @SemsterYear AS CHAR (4);
DECLARE @SearchedString AS VARCHAR (10);
SET @SemesterTerm = (SELECT LEFT(@SEMESTER, CHARINDEX(' ', @SEMESTER)));
SET @SemsterYear = (SELECT RIGHT(@SEMESTER, 4));
IF @DAY = 'M'
    SET @SearchedString = 'M';
IF @DAY = 'T'
    SET @SearchedString = 'T';
IF @DAY = 'W'
    SET @SearchedString = 'W';
IF @DAY = 'R'
    SET @SearchedString = 'R';
IF @DAY = 'F'
    SET @SearchedString = 'F';
SELECT   (CAST (Schedule.BeginningTime AS VARCHAR) + ' - ' + CAST (Schedule.EndingTime AS VARCHAR)) AS [Times],
         Course.Subj,
         Course.Num,
         Schedule.Sec,
         Schedule.Instructor,
         Schedule.Days,
         Semester.Term,
         Semester.Year,
         Rooms.Building,
         Rooms.Room
FROM     Schedule
         INNER JOIN
         Rooms
         ON Schedule.RID = Rooms.RID
         INNER JOIN
         Course
         ON Schedule.CID = Course.CID
         INNER JOIN
         Semester
         ON Schedule.TID = Semester.TID
WHERE    Semester.Term = @SemesterTerm
         AND Semester.Year = @SemsterYear
         AND Schedule.Days LIKE '%' + @SearchedString + '%'
         AND Rooms.Building = @BUILDING
         AND Rooms.Room = @ROOM
ORDER BY 1;

--------> VERY GOOD