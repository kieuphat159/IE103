BACKUP DATABASE QLdatve
TO DISK = 'C:\Backup\QLdatve_Diff.BAK'

ALTER DATABASE QLdatve
SET RECOVERY FULL;

BACKUP LOG QLdatve
TO DISK = 'C:\Backup\QLdatve_Log.TRN'
WITH NO_TRUNCATE;

USE msdb;
EXEC sp_add_job @job_name = 'DailyFullBackup';
EXEC sp_add_jobstep @job_name = 'DailyFullBackup', @step_name = 'Backup QLdatve',
    @subsystem = 'TSQL',
    @command = 'BACKUP DATABASE QLdatve TO DISK = ''C:\Backup\QLdatve.BAK'' WITH INIT;';
EXEC sp_add_jobschedule @job_name = 'DailyFullBackup', @name = 'DailySchedule',
    @freq_type = 4, @freq_interval = 1, @active_start_time = 20000;

