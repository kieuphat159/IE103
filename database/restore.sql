RESTORE DATABASE QLdatve
FROM DISK = 'C:\Backup\QLdatve.BAK'
WITH REPLACE, RECOVERY;

-- Khôi phục sao lưu toàn phần với NORECOVERY
RESTORE DATABASE QLdatve
FROM DISK = 'C:\Backup\QLdatve.BAK'
WITH NORECOVERY;

-- Áp dụng sao lưu nhật ký giao dịch
RESTORE LOG QLdatve
FROM DISK = 'C:\Backup\QLdatve_Log.TRN'
WITH STOPAT = '2025-05-26 15:00:00', RECOVERY;