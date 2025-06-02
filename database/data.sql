USE QLdatve;
GO

-- Tắt tất cả các trigger
DISABLE TRIGGER ALL ON ThongTinDatVe;
DISABLE TRIGGER ALL ON ThanhToan;
GO

-- Bảng NguoiDung (at least 120 entries)
INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD, VaiTro) VALUES
('nguyenthanhnam', N'Nguyễn Thanh Nam', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'nam.nguyen@email.com', '0912345678', '1990-03-15', N'Nam', '012345678901', 'Customer'),
('lethithu', N'Lê Thị Thu', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'thu.le@email.com', '0987654321', '1985-07-20', N'Nữ', '012345678902', 'Customer'),
('phamvanlong', N'Phạm Văn Long', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'long.pham@email.com', '0901234567', '1992-11-01', N'Nam', '012345678903', 'Customer'),
('tranminhanh', N'Trần Minh Anh', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'minhanh.tran@email.com', '0976543210', '1995-01-25', N'Nữ', '012345678904', 'Customer'),
('hoangvietdung', N'Hoàng Việt Dũng', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'dung.hoang@email.com', '0934567890', '1988-09-10', N'Nam', '012345678905', 'Customer'),
('phanthibich', N'Phan Thị Bích', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'bich.phan@email.com', '0965432109', '1993-04-03', N'Nữ', '012345678906', 'Customer'),
('duongquanghuy', N'Dương Quang Huy', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'huy.duong@email.com', '0923456789', '1980-12-18', N'Nam', '012345678907', 'Customer'),
('ngovantruong', N'Ngô Văn Trường', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'truong.ngo@email.com', '0918765432', '1997-06-22', N'Nam', '012345678908', 'Customer'),
('tranhongngoc', N'Trần Hồng Ngọc', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'ngoc.tran@email.com', '0956789012', '1991-02-14', N'Nữ', '012345678909', 'Customer'),
('vuvanhai', N'Vũ Văn Hải', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'hai.vu@email.com', '0943210987', '1987-08-05', N'Nam', '012345678910', 'Customer'),
('dangthituyet', N'Đặng Thị Tuyết', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'tuyet.dang@email.com', '0909876543', '1994-05-19', N'Nữ', '012345678911', 'Customer'),
('lequangthanh', N'Lê Quang Thành', '$2b$10$abcdefghijklmnopqrstuvwxyza123456789012345678901234567890', 'thanh.le@email.com', '0977889900', '1983-01-08', N'Nam', '012345678912', 'Customer'),
('nguyenxuanloc', N'Nguyễn Xuân Lộc', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'loc.nguyen@example.com', '0912123123', '1990-05-10', 'Nam', '123456789011', 'Customer'),
('tranthithanh', N'Trần Thị Thanh', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'thanh.tran@example.com', '0987654321', '1988-11-22', 'Nữ', '123456789012', 'Customer'),
('levananh', N'Lê Văn Anh', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'anh.le@example.com', '0901234567', '1995-03-01', 'Nam', '123456789013', 'Customer'),
('phamthuha', N'Phạm Thu Hà', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'ha.pham@example.com', '0976543210', '1992-07-15', 'Nữ', '123456789014', 'Customer'),
('hoangminhdat', N'Hoàng Minh Đạt', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'dat.hoang@example.com', '0934567890', '1987-09-28', 'Nam', '123456789015', 'Customer'),
('nguyentrang', N'Nguyễn Thị Trang', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'trang.nguyen@example.com', '0965432109', '1998-02-03', 'Nữ', '123456789016', 'Customer'),
('vuhoangtung', N'Vũ Hoàng Tùng', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'tung.vu@example.com', '0923456789', '1985-04-12', 'Nam', '123456789017', 'Customer'),
('doanthuy', N'Đoàn Thị Thúy', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'thuy.doan@example.com', '0918765432', '1993-10-06', 'Nữ', '123456789018', 'Customer'),
('buiduccanh', N'Bùi Đức Cảnh', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'canh.bui@example.com', '0956789012', '1991-06-19', 'Nam', '123456789019', 'Customer'),
('phanthihoa', N'Phan Thị Hoa', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'hoa.phan@example.com', '0943210987', '1989-01-24', 'Nữ', '123456789020', 'Customer'),
('nguyenvanhieu', N'Nguyễn Văn Hiếu', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'hieu.nguyen@example.com', '0919998877', '1996-08-08', 'Nam', '123456789021', 'Customer'),
('tranthihuyen', N'Trần Thị Huyền', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'huyen.tran@example.com', '0981112233', '1994-11-03', 'Nữ', '123456789022', 'Customer'),
('levietlinh', N'Lê Việt Linh', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'linh.le@example.com', '0903334455', '1990-02-17', 'Nam', '123456789023', 'Customer'),
('nguyenthanhtung', N'Nguyễn Thanh Tùng', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'tung.nguyen@example.com', '0912123124', '1989-07-25', 'Nam', '123456789024', 'Customer'),
('tranthithanhnga', N'Trần Thị Thanh Nga', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'nga.tran@example.com', '0987654322', '1991-04-05', 'Nữ', '123456789025', 'Customer'),
('levanhung', N'Lê Văn Hùng', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'hung.le@example.com', '0901234568', '1986-09-18', 'Nam', '123456789026', 'Customer'),
('phamthithuylinh', N'Phạm Thị Thùy Linh', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'linh.pham@example.com', '0976543211', '1993-12-30', 'Nữ', '123456789027', 'Customer'),
('hoangvanquang', N'Hoàng Văn Quang', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'quang.hoang@example.com', '0934567891', '1984-06-07', 'Nam', '123456789028', 'Customer'),
('nguyenvana', N'Nguyễn Văn A', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'vana@example.com', '0900000001', '1990-01-01', 'Nam', '111111111111', 'Employee'),
('lethib', N'Lê Thị B', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'thib@example.com', '0900000002', '1992-02-02', 'Nữ', '222222222222', 'Employee'),
('tranvanx', N'Trần Văn X', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'vanx@example.com', '0900000003', '1985-03-03', 'Nam', '333333333333', 'Employee'),
('nguyentranh', N'Nguyễn Trấn H', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'tranh@example.com', '0900000004', '1993-04-04', 'Nam', '444444444444', 'Employee'),
('phamthik', N'Phạm Thị K', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'thik@example.com', '0900000005', '1988-05-05', 'Nữ', '555555555555', 'Employee');
-- Generate more NguoiDung data
DECLARE @i INT = 13;
WHILE @i <= 120
BEGIN
    DECLARE @TaiKhoan VARCHAR(50) = 'customer' + CAST(@i AS VARCHAR(3));
    DECLARE @Ten NVARCHAR(100) = N'Khách Hàng ' + CAST(@i AS NVARCHAR(10));
    DECLARE @MatKhau VARCHAR(255) = '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.'; -- Example hashed password
    DECLARE @Email VARCHAR(100) = 'customer' + CAST(@i AS VARCHAR(3)) + '@example.com';
    DECLARE @Sdt VARCHAR(15) = '09' + RIGHT('00000000' + CAST(@i * 100 + 12345 AS VARCHAR(10)), 8);
    DECLARE @NgaySinh DATE = DATEADD(day, -@i * 30, GETDATE());
    DECLARE @GioiTinh NVARCHAR(10) = CASE WHEN @i % 2 = 0 THEN N'Nữ' ELSE N'Nam' END;
    DECLARE @SoCCCD VARCHAR(20) = 'CCCD' + RIGHT('0000000000' + CAST(@i AS VARCHAR(10)), 10);
    DECLARE @VaiTro NVARCHAR(20) = 'Customer';

    INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD, VaiTro)
    VALUES (@TaiKhoan, @Ten, @MatKhau, @Email, @Sdt, @NgaySinh, @GioiTinh, @SoCCCD, @VaiTro);
    SET @i = @i + 1;
END;
GO

-- Bảng KhachHang (at least 120 entries)
INSERT INTO KhachHang (MaKH, Passport, TaiKhoan) VALUES
('KH001', 'PAS001', 'nguyenthanhnam'),
('KH002', 'PAS002', 'lethithu'),
('KH003', 'PAS003', 'phamvanlong'),
('KH004', 'PAS004', 'tranminhanh'),
('KH005', 'PAS005', 'hoangvietdung'),
('KH006', 'PAS006', 'phanthibich'),
('KH007', 'PAS007', 'duongquanghuy'),
('KH008', 'PAS008', 'ngovantruong'),
('KH009', 'PAS009', 'tranhongngoc'),
('KH010', 'PAS010', 'vuvanhai'),
('KH011', 'PAS011', 'dangthituyet'),
('KH012', 'PAS012', 'lequangthanh'),
('KH013', 'PAS013', 'nguyenxuanloc'),
('KH014', 'PAS014', 'tranthithanh'),
('KH015', 'PAS015', 'levananh'),
('KH016', 'PAS016', 'phamthuha'),
('KH017', 'PAS017', 'hoangminhdat'),
('KH018', 'PAS018', 'nguyentrang'),
('KH019', 'PAS019', 'vuhoangtung'),
('KH020', 'PAS020', 'doanthuy'),
('KH021', 'PAS021', 'buiduccanh'),
('KH022', 'PAS022', 'phanthihoa'),
('KH023', 'PAS023', 'nguyenvanhieu'),
('KH024', 'PAS024', 'tranthihuyen'),
('KH025', 'PAS025', 'levietlinh'),
('KH026', 'PAS026', 'nguyenthanhtung'),
('KH027', 'PAS027', 'tranthithanhnga'),
('KH028', 'PAS028', 'levanhung'),
('KH029', 'PAS029', 'phamthithuylinh'),
('KH030', 'PAS030', 'hoangvanquang');
-- Generate more KhachHang data
DECLARE @j INT = 31;
WHILE @j <= 120
BEGIN
    DECLARE @MaKH VARCHAR(20) = 'KH' + RIGHT('00' + CAST(@j AS VARCHAR(3)), 3);
    DECLARE @Passport VARCHAR(20) = 'PASS' + RIGHT('000' + CAST(@j AS VARCHAR(4)), 4);
    DECLARE @TaiKhoanKH VARCHAR(50) = 'customer' + CAST(@j AS VARCHAR(3));
    INSERT INTO KhachHang (MaKH, Passport, TaiKhoan)
    VALUES (@MaKH, @Passport, @TaiKhoanKH);
    SET @j = @j + 1;
END;
GO

-- Bảng NhanVienKiemSoat (at least 5 entries, since there are 5 employee accounts)
INSERT INTO NhanVienKiemSoat (MaNV, TaiKhoan) VALUES
('NV001', 'nguyenvana'),
('NV002', 'lethib'),
('NV003', 'tranvanx'),
('NV004', 'nguyentranh'),
('NV005', 'phamthik');
-- Add more employee accounts to NguoiDung and then to NhanVienKiemSoat to reach 120 entries
DECLARE @k INT = 6;
WHILE @k <= 120
BEGIN
    DECLARE @TaiKhoanNV VARCHAR(50) = 'employee' + CAST(@k AS VARCHAR(3));
    DECLARE @TenNV NVARCHAR(100) = N'Nhân Viên ' + CAST(@k AS NVARCHAR(10));
    DECLARE @MatKhauNV VARCHAR(255) = '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.';
    DECLARE @EmailNV VARCHAR(100) = 'employee' + CAST(@k AS VARCHAR(3)) + '@example.com';
    DECLARE @SdtNV VARCHAR(15) = '09' + RIGHT('00000000' + CAST(@k * 100 + 54321 AS VARCHAR(10)), 8);
    DECLARE @NgaySinhNV DATE = DATEADD(day, -@k * 20, GETDATE());
    DECLARE @GioiTinhNV NVARCHAR(10) = CASE WHEN @k % 2 = 0 THEN N'Nam' ELSE N'Nữ' END;
    DECLARE @SoCCCDNV VARCHAR(20) = 'NVCCCD' + RIGHT('00000000' + CAST(@k AS VARCHAR(10)), 8);
    DECLARE @VaiTroNV NVARCHAR(20) = 'Employee';

    INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD, VaiTro)
    VALUES (@TaiKhoanNV, @TenNV, @MatKhauNV, @EmailNV, @SdtNV, @NgaySinhNV, @GioiTinhNV, @SoCCCDNV, @VaiTroNV);

    DECLARE @MaNV VARCHAR(20) = 'NV' + RIGHT('00' + CAST(@k AS VARCHAR(3)), 3);
    INSERT INTO NhanVienKiemSoat (MaNV, TaiKhoan)
    VALUES (@MaNV, @TaiKhoanNV);
    SET @k = @k + 1;
END;
GO

-- Bảng BaoCao (at least 120 entries)
DECLARE @l INT = 1;
WHILE @l <= 120
BEGIN
    DECLARE @MaBaoCao VARCHAR(20) = 'BC' + RIGHT('000' + CAST(@l AS VARCHAR(3)), 3);
    DECLARE @NgayBaoCao DATE = DATEADD(day, -@l * 5, '2025-06-01');
    DECLARE @NoiDungBaoCao NVARCHAR(MAX) = N'Báo cáo kiểm soát chuyến bay số ' + CAST(@l AS NVARCHAR(10));
    DECLARE @MaNVBaoCao VARCHAR(20) = 'NV' + RIGHT('00' + CAST((@l % 120) + 1 AS VARCHAR(3)), 3); -- Cycle through available NhanVienKiemSoat
    DECLARE @TrangThaiBaoCao NVARCHAR(20) = CASE WHEN @l % 3 = 0 THEN N'Đã xử lý' ELSE N'Chưa xử lý' END;

    INSERT INTO BaoCao (MaBaoCao, NgayBaoCao, NoiDungBaoCao, MaNV, TrangThai)
    VALUES (@MaBaoCao, @NgayBaoCao, @NoiDungBaoCao, @MaNVBaoCao, @TrangThaiBaoCao);
    SET @l = @l + 1;
END;
GO

-- Bảng ChuyenBay (at least 120 entries)
DECLARE @m INT = 1;
WHILE @m <= 120
BEGIN
    DECLARE @MaChuyenBayCB VARCHAR(20) = 'CB' + RIGHT('000' + CAST(@m AS VARCHAR(3)), 3);
    DECLARE @TinhTrangChuyenBayCB NVARCHAR(50);
    DECLARE @GioBayCB DATETIME;
    DECLARE @GioDenCB DATETIME;
    DECLARE @DiaDiemDauCB NVARCHAR(100);
    DECLARE @DiaDiemCuoiCB NVARCHAR(100);

    -- Randomize departure/arrival locations
    DECLARE @Locations TABLE (ID INT IDENTITY(1,1), Name NVARCHAR(100));
    INSERT INTO @Locations (Name) VALUES
    (N'TP. Hồ Chí Minh'), (N'Hà Nội'), (N'Đà Nẵng'), (N'Phú Quốc'), (N'Nha Trang'),
    (N'Hải Phòng'), (N'Cần Thơ'), (N'Đà Lạt'), (N'Huế'), (N'Vinh');

    SELECT @DiaDiemDauCB = Name FROM @Locations WHERE ID = ((@m % 10) + 1);
    SELECT @DiaDiemCuoiCB = Name FROM @Locations WHERE ID = (((@m + 2) % 10) + 1);

    -- Ensure DiaDiemDau and DiaDiemCuoi are different
    IF @DiaDiemDauCB = @DiaDiemCuoiCB
    BEGIN
        SELECT @DiaDiemCuoiCB = Name FROM @Locations WHERE ID = (((@m + 3) % 10) + 1);
    END;

    -- Generate dates from Jan 2025 onwards, ensuring GioBay < GioDen
    SET @GioBayCB = DATEADD(hour, @m * 3, DATEADD(day, @m, '2025-01-01'));
    SET @GioDenCB = DATEADD(hour, 5, @GioBayCB); -- Assume 5 hour flight duration

    -- Randomize TinhTrangChuyenBay
    IF @m % 5 = 0
        SET @TinhTrangChuyenBayCB = N'Đã hủy';
    ELSE IF @m % 5 = 1
        SET @TinhTrangChuyenBayCB = N'Đã khởi hành';
    ELSE IF @m % 5 = 2
        SET @TinhTrangChuyenBayCB = N'Đã hạ cánh';
    ELSE
        SET @TinhTrangChuyenBayCB = N'Chưa khởi hành';

    -- Call sp_ThemChuyenBay to insert flight and generate seats
    EXEC sp_ThemChuyenBay @MaChuyenBayCB, @TinhTrangChuyenBayCB, @GioBayCB, @GioDenCB, @DiaDiemDauCB, @DiaDiemCuoiCB;

    SET @m = @m + 1;
END;
GO

-- Bảng ThongTinGhe (auto-generated by sp_ThemChuyenBay, so no need to insert manually here)
-- We should have 120 * 150 = 18000 rows in ThongTinGhe by now.

-- Bảng ThongTinDatVe (at least 120 entries)
DECLARE @n INT = 1;
WHILE @n <= 120
BEGIN
    DECLARE @MaDatVeTV VARCHAR(20) = 'DV' + RIGHT('000' + CAST(@n AS VARCHAR(3)), 3);
    DECLARE @NgayDatVeTV DATE = DATEADD(day, -@n, GETDATE()); -- Data from the past
    DECLARE @NgayBayTV DATE;
    DECLARE @TrangThaiThanhToanTV NVARCHAR(50) = CASE WHEN @n % 2 = 0 THEN N'Đã thanh toán' ELSE N'Chưa thanh toán' END;
    DECLARE @SoGheTV INT = 1; -- Always book 1 seat per booking for simplicity here
    DECLARE @SoTienTV DECIMAL(18, 2);
    DECLARE @MaChuyenBayTV VARCHAR(20);
    DECLARE @MaKHTV VARCHAR(20);

    -- Select a random flight that is 'Chưa khởi hành'
    SELECT TOP 1 @MaChuyenBayTV = MaChuyenBay, @NgayBayTV = CAST(GioBay AS DATE)
    FROM ChuyenBay
    WHERE TinhTrangChuyenBay = N'Chưa khởi hành'
    ORDER BY NEWID();

    -- Ensure NgayDatVe is before or on NgayBay
    IF @NgayDatVeTV > @NgayBayTV
    BEGIN
        SET @NgayDatVeTV = @NgayBayTV;
    END;
    
    -- Select a random customer
    SELECT TOP 1 @MaKHTV = MaKH
    FROM KhachHang
    ORDER BY NEWID();

    -- Get a random available seat and its price for the selected flight
    SELECT TOP 1 @SoGheTV = SoGhe, @SoTienTV = GiaGhe
    FROM ThongTinGhe
    WHERE MaChuyenBay = @MaChuyenBayTV AND TinhTrangGhe = N'có sẵn'
    ORDER BY NEWID();

    -- If no available seats, skip this iteration or handle it
    IF @SoGheTV IS NOT NULL
    BEGIN
        -- Update seat status directly since triggers are disabled
        UPDATE ThongTinGhe
        SET TinhTrangGhe = N'đã đặt'
        WHERE MaChuyenBay = @MaChuyenBayTV AND SoGhe = @SoGheTV;

        INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH)
        VALUES (@MaDatVeTV, @NgayDatVeTV, @NgayBayTV, @TrangThaiThanhToanTV, @SoGheTV, @SoTienTV, @MaChuyenBayTV, @MaKHTV);
    END
    ELSE
    BEGIN
        -- Handle case where no seats are available for the chosen flight
        -- For this script, we'll just increment @n and try again
        SET @n = @n - 1; -- Decrement to re-attempt this booking number
    END;

    SET @n = @n + 1;
END;
GO

-- Bảng ThanhToan (at least 120 entries)
DECLARE @p INT = 1;
WHILE @p <= 120
BEGIN
    DECLARE @MaTTTT VARCHAR(20) = 'TT' + RIGHT('000' + CAST(@p AS VARCHAR(3)), 3);
    DECLARE @NgayTTTT DATE;
    DECLARE @SoTienTT DECIMAL(18, 2);
    DECLARE @PTTTTT NVARCHAR(50);
    DECLARE @MaDatVeTT VARCHAR(20);

    -- Select a booking from ThongTinDatVe, prioritizing 'Chưa thanh toán'
    SELECT TOP 1 @MaDatVeTT = MaDatVe, @SoTienTT = SoTien, @NgayTTTT = NgayDatVe
    FROM ThongTinDatVe
    WHERE TrangThaiThanhToan = N'Chưa thanh toán'
    ORDER BY NEWID();

    IF @MaDatVeTT IS NULL
    BEGIN
        -- If all are paid, pick any booking
        SELECT TOP 1 @MaDatVeTT = MaDatVe, @SoTienTT = SoTien, @NgayTTTT = NgayDatVe
        FROM ThongTinDatVe
        ORDER BY NEWID();
    END;

    -- Randomize payment method
    SET @PTTTTT = CASE @p % 3
        WHEN 0 THEN N'Tiền mặt'
        WHEN 1 THEN N'Thẻ tín dụng'
        ELSE N'Chuyển khoản'
    END;

    -- Ensure NgayTT is not earlier than NgayDatVe
    IF @NgayTTTT < '2025-01-01'
    BEGIN
        SET @NgayTTTT = DATEADD(day, @p * 2, '2025-01-01');
    END;
    
    INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe)
    VALUES (@MaTTTT, @NgayTTTT, @SoTienTT, @PTTTTT, @MaDatVeTT);

    -- Manually update TrangThaiThanhToan since triggers are disabled
    UPDATE ThongTinDatVe
    SET TrangThaiThanhToan = N'Đã thanh toán'
    WHERE MaDatVe = @MaDatVeTT;

    SET @p = @p + 1;
END;
GO

-- Bảng HoaDon (at least 120 entries)
DECLARE @q INT = 1;
WHILE @q <= 120
BEGIN
    DECLARE @MaHoaDonHD VARCHAR(20) = 'HD' + RIGHT('000' + CAST(@q AS VARCHAR(3)), 3);
    DECLARE @NgayXuatHDHD DATE;
    DECLARE @PhuongThucTT_HD NVARCHAR(50);
    DECLARE @NgayThanhToanHD DATE;
    DECLARE @MaTTHD VARCHAR(20);

    -- Select a payment record
    SELECT TOP 1 @MaTTHD = MaTT, @PhuongThucTT_HD = PTTT, @NgayThanhToanHD = NgayTT
    FROM ThanhToan
    ORDER BY NEWID();

    -- Ensure NgayXuatHD <= NgayThanhToan
    SET @NgayXuatHDHD = DATEADD(day, -(@q % 5), @NgayThanhToanHD);
    IF @NgayXuatHDHD < '2025-01-01'
    BEGIN
        SET @NgayXuatHDHD = '2025-01-01';
    END;

    INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT)
    VALUES (@MaHoaDonHD, @NgayXuatHDHD, @PhuongThucTT_HD, @NgayThanhToanHD, @MaTTHD);

    SET @q = @q + 1;
END;
GO

-- Bật lại tất cả các trigger
ENABLE TRIGGER ALL ON ThongTinDatVe;
ENABLE TRIGGER ALL ON ThanhToan;
GO

PRINT 'Dữ liệu mẫu đã được thêm vào các bảng.';