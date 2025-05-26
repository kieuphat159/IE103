CREATE USER [AppUser] FOR LOGIN [AppUser];
GO
-- Tạo các vai trò trong SQL Server
CREATE ROLE AdminRole;
CREATE ROLE EmployeeRole;
CREATE ROLE CustomerRole;

-- Cấp quyền cho AdminRole
GRANT SELECT, INSERT, UPDATE, DELETE ON NguoiDung TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON KhachHang TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON NhanVienKiemSoat TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON BaoCao TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON ChuyenBay TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON ThongTinGhe TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON ThongTinDatVe TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON ThanhToan TO AdminRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON HoaDon TO AdminRole;
GRANT EXECUTE ON sp_ThemNguoiDung TO AdminRole;
GRANT EXECUTE ON sp_XoaNguoiDung TO AdminRole;
GRANT EXECUTE ON sp_DangKyKhachHang TO AdminRole;
GRANT EXECUTE ON sp_ThemChuyenBay TO AdminRole;
GRANT EXECUTE ON sp_CapNhatChuyenBay TO AdminRole;
GRANT EXECUTE ON sp_ThemGhe TO AdminRole;
GRANT EXECUTE ON sp_ThemDatVe TO AdminRole;
GRANT EXECUTE ON sp_XoaDatVe TO AdminRole;
GRANT EXECUTE ON sp_ThemThanhToan TO AdminRole;
GRANT EXECUTE ON sp_ThemHoaDon TO AdminRole;
GRANT EXECUTE ON sp_KiemTraGheTrong TO AdminRole;

-- Cấp quyền cho EmployeeRole
GRANT SELECT, INSERT ON BaoCao TO EmployeeRole;
GRANT SELECT ON ChuyenBay TO EmployeeRole;
GRANT SELECT ON ThongTinGhe TO EmployeeRole;
GRANT SELECT ON ThongTinDatVe TO EmployeeRole;
GRANT EXECUTE ON sp_ThemDatVe TO EmployeeRole;
GRANT EXECUTE ON sp_KiemTraGheTrong TO EmployeeRole;

-- Cấp quyền cho CustomerRole
GRANT SELECT ON ChuyenBay TO CustomerRole;
GRANT SELECT ON ThongTinGhe TO CustomerRole;
GRANT SELECT, INSERT ON ThongTinDatVe TO CustomerRole;
GRANT SELECT, INSERT ON ThanhToan TO CustomerRole;
GRANT SELECT, INSERT ON HoaDon TO CustomerRole;
GRANT EXECUTE ON sp_ThemDatVe TO CustomerRole;
GRANT EXECUTE ON sp_KiemTraGheTrong TO CustomerRole;

EXEC sp_addrolemember 'AdminRole', 'AppUser'; 