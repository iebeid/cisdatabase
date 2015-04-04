/*
Author : Islam A. Ebeid
Description : Creates required views:
- v_detailSchedule_fall2010: It displays or returns Subj, Num, Sec, Instructor, Days, BeginningTime, EndingTime, Building, and Room 
  of every class in fall 2010. Data are sorted by Subj, Num, and Sec.
- v_instructor_analysis: It analyzes the teaching load of every instructor in each semester by displaying or returning Instructor, 
  TotalTeachingClasses, TotalTeachingHours, and Semester.
*/
USE CIS;


GO
IF OBJECT_ID('dbo.v_detailSchedule_fall2010') IS NOT NULL
    DROP VIEW dbo.v_detailSchedule_fall2010;


GO
CREATE VIEW v_detailSchedule_fall2010
AS
    SELECT   distinct TOP (100) PERCENT Course.Subj,
                                        Course.Num,
                                        Schedule.Sec,
                                        Schedule.Instructor,
                                        Schedule.Days,
                                        Schedule.BeginningTime,
                                        Schedule.EndingTime,
                                        Rooms.Building,
                                        Rooms.Room
    FROM     Schedule
             INNER JOIN
             Semester
             ON Schedule.TID = Semester.TID
             INNER JOIN
             Rooms
             ON Schedule.RID = Rooms.RID
             INNER JOIN
             Instructor
             ON Schedule.Instructor = Instructor.InstName	------> There is no need to include Instructor table.
             INNER JOIN
             Course
             ON Schedule.CID = Course.CID
             INNER JOIN
             Schedule AS Schedule2
             ON (Schedule.TID <> Schedule2.TID
                 AND Schedule.CRN <> Schedule2.CRN)			------> (-2) This self join with Schedule is totally not necessary, which offers nothing but wastes system resources only. 
    WHERE Semester.Term = 'Fall'
    AND Semester.Year = '2010'
    ORDER BY Course.Subj, Course.Num, Schedule.Sec;

------> (-3) Your view missed at least 10 classes of fall 2010. 
--			 For instance, INFT6903-002, Dr. Fang's INFT6993-001, Dr. Moody's INFT5303-TC1 and TC2, etc.

GO
USE CIS;


GO
IF OBJECT_ID('dbo.v_instructor_analysis') IS NOT NULL
    DROP VIEW dbo.v_instructor_analysis;


GO
CREATE VIEW v_instructor_analysis
AS
    SELECT   TOP (100) PERCENT Schedule.Instructor,
                               (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR)) AS [SemesterName],
                               COUNT((Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR))) AS [TotalTeachingClasses],
                               sum(((DATEDIFF(MI, Schedule.BeginningTime, Schedule.EndingTime) * 1.0 / 60) * LEN(Schedule.Days) * (DATEDIFF(WK, Semester.StartDate, Semester.EndDate)))) AS [TotalTeachingHours]
    FROM     Schedule
             INNER JOIN
             Semester
             ON Schedule.TID = Semester.TID
    GROUP BY Schedule.Instructor, (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR))
    ORDER BY Schedule.Instructor, (Semester.Term + ' ' + CAST (Semester.Year AS VARCHAR));

------> OK


--v_detailSchedule_fall2010: It displays or returns Subj, Num, Sec, Instructor, Days, BeginningTime, EndingTime, Building, and Room 
-- of every class in fall 2010. Data are sorted by Subj, Num, and Sec.
use CIS;

select Course.Subj,Course.Num,ScheduleCopy.Sec,ScheduleCopy.Instructor,ScheduleCopy.Days,ScheduleCopy.BeginningTime,
ScheduleCopy.EndingTime,Rooms.Building,Rooms.Room
from ScheduleCopy join Course on ScheduleCopy.CID = Course.CID
left outer join Rooms on ScheduleCopy.RID = Rooms.RID
join Semester on ScheduleCopy.TID = Semester.TID
where Semester.Term = 'Fall'
AND Semester.Year = '2010'
ORDER BY Course.Subj, Course.Num, ScheduleCopy.Sec;



select * from ScheduleCopy join Semester on Schedule.TID = Semester.TID
join Rooms on Schedule.RID = Rooms.RID
where Semester.Term = 'Fall'
AND Semester.Year = '2010';

select * from CourseCopy;
select * from ScheduleCopy;