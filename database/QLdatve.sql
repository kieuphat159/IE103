-- Tạo cơ sở dữ liệu

drop database QLdatve

CREATE DATABASE QLdatve;
GO

-- Sử dụng cơ sở dữ liệu
USE QLdatve;
GO

-- Bảng NguoiDung
CREATE TABLE NguoiDung (
    TaiKhoan VARCHAR(50) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    Email VARCHAR(100),
    Sdt VARCHAR(15),
    NgaySinh DATE,
    GioiTinh NVARCHAR(10),
    SoCCCD VARCHAR(20)
);
GO

-- Bảng KhachHang
CREATE TABLE KhachHang (
    MaKH VARCHAR(20) PRIMARY KEY,
    Passport VARCHAR(20),
    TaiKhoan VARCHAR(50) NOT NULL,
    CONSTRAINT FK_KhachHang_NguoiDung FOREIGN KEY (TaiKhoan) REFERENCES NguoiDung(TaiKhoan),
    CONSTRAINT UQ_KhachHang_TaiKhoan UNIQUE (TaiKhoan)
);
GO

-- Bảng NhanVienKiemSoat
CREATE TABLE NhanVienKiemSoat (
    MaNV VARCHAR(20) PRIMARY KEY,
    TaiKhoan VARCHAR(50) NOT NULL,
    CONSTRAINT FK_NhanVienKiemSoat_NguoiDung FOREIGN KEY (TaiKhoan) REFERENCES NguoiDung(TaiKhoan),
    CONSTRAINT UQ_NhanVienKiemSoat_TaiKhoan UNIQUE (TaiKhoan)
);
GO

-- Bảng BaoCao
CREATE TABLE BaoCao (
    MaBaoCao VARCHAR(20) PRIMARY KEY,
    NgayBaoCao DATE NOT NULL,
    NoiDungBaoCao NVARCHAR(MAX) NOT NULL,
    MaNV VARCHAR(20) NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL,
    CONSTRAINT FK_BaoCao_NhanVienKiemSoat FOREIGN KEY (MaNV) REFERENCES NhanVienKiemSoat(MaNV),
    CONSTRAINT CK_TrangThai_Valid CHECK (TrangThai IN (N'Đã xử lý', N'Chưa xử lý')) 
);
GO

-- Bảng ChuyenBay
CREATE TABLE ChuyenBay (
    MaChuyenBay VARCHAR(20) PRIMARY KEY,
    TinhTrangChuyenBay NVARCHAR(50),
    GioBay DATETIME NOT NULL,
    GioDen DATETIME NOT NULL,
    DiaDiemDau NVARCHAR(100) NOT NULL,
    DiaDiemCuoi NVARCHAR(100) NOT NULL,
    CONSTRAINT CK_GioBay_Before_GioDen CHECK (GioBay < GioDen)
);
GO

-- Bảng ThongTinGhe
CREATE TABLE ThongTinGhe (
    SoGhe INT NOT NULL,
    MaChuyenBay VARCHAR(20) NOT NULL,
    GiaGhe DECIMAL(18, 2) NOT NULL,
    HangGhe NVARCHAR(20) CHECK (HangGhe IN (N'Phổ thông', N'Thương gia', N'Hạng nhất')),
    TinhTrangGhe NVARCHAR(20) CHECK (TinhTrangGhe IN (N'có sẵn', N'đã đặt')),
    CONSTRAINT PK_ThongTinGhe PRIMARY KEY (SoGhe, MaChuyenBay),
    CONSTRAINT FK_ThongTinGhe_ChuyenBay FOREIGN KEY (MaChuyenBay) REFERENCES ChuyenBay(MaChuyenBay),
    CONSTRAINT CK_GiaGhe_Positive CHECK (GiaGhe > 0)
);
GO

-- Bảng ThongTinDatVe
CREATE TABLE ThongTinDatVe (
    MaDatVe VARCHAR(20) PRIMARY KEY,
    NgayDatVe DATE NOT NULL,
    NgayBay DATE NOT NULL,
    TrangThaiThanhToan NVARCHAR(50),
    SoGhe INT NOT NULL,
    SoTien DECIMAL(18, 2) NOT NULL,
    MaChuyenBay VARCHAR(20) NOT NULL,
    MaKH VARCHAR(20) NOT NULL,
    CONSTRAINT FK_ThongTinDatVe_ChuyenBay FOREIGN KEY (MaChuyenBay) REFERENCES ChuyenBay(MaChuyenBay),
    CONSTRAINT FK_ThongTinDatVe_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
    CONSTRAINT CK_SoTien_Positive CHECK (SoTien > 0),
    CONSTRAINT CK_TrangThaiThanhToan CHECK (TrangThaiThanhToan IN (N'Chưa thanh toán', N'Đã thanh toán'))
);
GO

-- Bảng ThanhToan
CREATE TABLE ThanhToan (
    MaTT VARCHAR(20) PRIMARY KEY,
    NgayTT DATE NOT NULL,
    SoTien DECIMAL(18, 2) NOT NULL,
    PTTT NVARCHAR(50) CHECK (PTTT IN (N'Tiền mặt', N'Thẻ tín dụng', N'Chuyển khoản')),
    MaDatVe VARCHAR(20) NOT NULL,
    CONSTRAINT FK_ThanhToan_ThongTinDatVe FOREIGN KEY (MaDatVe) REFERENCES ThongTinDatVe(MaDatVe),
    CONSTRAINT CK_SoTienThanhToan_Positive CHECK (SoTien > 0)
);
GO

-- Bảng HoaDon
CREATE TABLE HoaDon (
    MaHoaDon VARCHAR(20) PRIMARY KEY,
    NgayXuatHD DATE NOT NULL,
    PhuongThucTT NVARCHAR(50) CHECK (PhuongThucTT IN (N'Tiền mặt', N'Thẻ tín dụng', N'Chuyển khoản')),
    NgayThanhToan DATE NOT NULL,
    MaTT VARCHAR(20) NOT NULL,
    CONSTRAINT FK_HoaDon_ThanhToan FOREIGN KEY (MaTT) REFERENCES ThanhToan(MaTT),
    CONSTRAINT CK_NgayXuatHD_Before_NgayThanhToan CHECK (NgayXuatHD <= NgayThanhToan)
);
GO

-- Trigger kiểm tra ngày đặt vé phải trước ngày bay của chuyến bay
CREATE TRIGGER trg_NgayDatVe_Before_GioBay
ON ThongTinDatVe
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ChuyenBay cb ON i.MaChuyenBay = cb.MaChuyenBay
        WHERE i.NgayDatVe > CAST(cb.GioBay AS DATE)
    )
    BEGIN
        RAISERROR (N'Ngày đặt vé phải trước hoặc bằng ngày bay của chuyến bay!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER trg_Check_Flight_Status
ON ThongTinDatVe
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ChuyenBay cb ON i.MaChuyenBay = cb.MaChuyenBay
        WHERE cb.TinhTrangChuyenBay != N'Chưa khởi hành'
    )
    BEGIN
        RAISERROR (N'Chỉ có thể đặt vé cho các chuyến bay chưa khởi hành!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger kiểm tra số lượng ghế trống trước khi đặt vé
CREATE TRIGGER trg_Check_Available_Seats
ON ThongTinDatVe
AFTER INSERT
AS
BEGIN
    DECLARE @MaChuyenBay VARCHAR(20), @SoGhe INT, @AvailableSeats INT;

    SELECT @MaChuyenBay = MaChuyenBay, @SoGhe = SoGhe
    FROM inserted;

    SELECT @AvailableSeats = COUNT(*)
    FROM ThongTinGhe
    WHERE MaChuyenBay = @MaChuyenBay AND TinhTrangGhe = N'có sẵn';

    IF @SoGhe > @AvailableSeats
    BEGIN
        RAISERROR (N'Số lượng ghế yêu cầu vượt quá số ghế trống!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger cập nhật trạng thái ghế khi đặt vé
CREATE TRIGGER trg_Update_Seat_Status
ON ThongTinDatVe
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaChuyenBay VARCHAR(20), @SoGhe INT;

    SELECT @MaChuyenBay = MaChuyenBay, @SoGhe = SoGhe
    FROM inserted;

    -- Cập nhật trạng thái ghế thành 'đã đặt' cho số ghế tương ứng
    WITH AvailableSeats AS (
        SELECT TOP (@SoGhe) SoGhe
        FROM ThongTinGhe
        WHERE MaChuyenBay = @MaChuyenBay AND TinhTrangGhe = N'có sẵn'
        ORDER BY SoGhe
    )
    UPDATE tg
    SET TinhTrangGhe = N'đã đặt'
    FROM ThongTinGhe tg
    INNER JOIN AvailableSeats s ON tg.SoGhe = s.SoGhe AND tg.MaChuyenBay = @MaChuyenBay;
END;
GO

-- Trigger kiểm tra số tiền thanh toán khớp với số tiền đặt vé
CREATE TRIGGER trg_Check_Payment_Amount
ON ThanhToan
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ThongTinDatVe dv ON i.MaDatVe = dv.MaDatVe
        WHERE i.SoTien != dv.SoTien
    )
    BEGIN
        RAISERROR (N'Số tiền thanh toán phải khớp với số tiền đặt vé!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger cập nhật trạng thái thanh toán khi thêm thanh toán
CREATE TRIGGER trg_Update_Payment_Status
ON ThanhToan
AFTER INSERT
AS
BEGIN
    UPDATE ThongTinDatVe
    SET TrangThaiThanhToan = N'Đã thanh toán'
    FROM ThongTinDatVe dv
    INNER JOIN inserted i ON dv.MaDatVe = i.MaDatVe
    WHERE dv.TrangThaiThanhToan = N'Chưa thanh toán';
END;
GO

-- Stored Procedure thêm người dùng
CREATE PROCEDURE sp_ThemNguoiDung
    @TaiKhoan VARCHAR(50),
    @Ten NVARCHAR(100),
    @MatKhau VARCHAR(255),
    @Email VARCHAR(100),
    @Sdt VARCHAR(15),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(10),
    @SoCCCD VARCHAR(20)
AS
BEGIN
    INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD)
    VALUES (@TaiKhoan, @Ten, @MatKhau, @Email, @Sdt, @NgaySinh, @GioiTinh, @SoCCCD);
END;
GO

-- Stored Procedure xóa người dùng
CREATE PROCEDURE sp_XoaNguoiDung
    @TaiKhoan VARCHAR(50)
AS
BEGIN
    BEGIN TRANSACTION;
    DELETE FROM KhachHang WHERE TaiKhoan = @TaiKhoan;
    DELETE FROM NhanVienKiemSoat WHERE TaiKhoan = @TaiKhoan;
    DELETE FROM NguoiDung WHERE TaiKhoan = @TaiKhoan;
    COMMIT TRANSACTION;
END;
GO

-- Stored Procedure đăng ký khách hàng
CREATE PROCEDURE sp_DangKyKhachHang
    @TaiKhoan VARCHAR(50),
    @Ten NVARCHAR(100),
    @MatKhau VARCHAR(255),
    @Email VARCHAR(100),
    @Sdt VARCHAR(15),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(10),
    @SoCCCD VARCHAR(20),
    @MaKH VARCHAR(20),
    @Passport VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC sp_ThemNguoiDung @TaiKhoan, @Ten, @MatKhau, @Email, @Sdt, @NgaySinh, @GioiTinh, @SoCCCD;
        INSERT INTO KhachHang (MaKH, Passport, TaiKhoan)
        VALUES (@MaKH, @Passport, @TaiKhoan);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
--
--

CREATE PROCEDURE sp_ThemChuyenBay
    @MaChuyenBay VARCHAR(20),
    @TinhTrangChuyenBay NVARCHAR(50),
    @GioBay DATETIME,
    @GioDen DATETIME,
    @DiaDiemDau NVARCHAR(100),
    @DiaDiemCuoi NVARCHAR(100)
AS
BEGIN
    -- Thêm chuyến bay mới vào bảng ChuyenBay
    INSERT INTO ChuyenBay (MaChuyenBay, TinhTrangChuyenBay, GioBay, GioDen, DiaDiemDau, DiaDiemCuoi)
    VALUES (@MaChuyenBay, @TinhTrangChuyenBay, @GioBay, @GioDen, @DiaDiemDau, @DiaDiemCuoi);

    -- Khởi tạo biến đếm cho vòng lặp tạo ghế
    DECLARE @i INT = 1;
    -- Tổng số ghế cần tạo là 150 (15 hạng nhất + 35 thương gia + 100 phổ thông)
    DECLARE @TotalSeats INT = 150;

    -- Vòng lặp để tạo từng ghế cho chuyến bay
    WHILE @i <= @TotalSeats
    BEGIN
        -- Khai báo các biến để lưu thông tin ghế
        DECLARE @GiaGhe DECIMAL(18, 2);
        DECLARE @HangGhe NVARCHAR(50);
        -- Không cần @Prefix và @SeatNumInClass nữa vì SoGhe giờ là INT

        -- Logic phân loại ghế theo hạng và gán giá vé, hạng ghế
        IF @i <= 15 -- 15 ghế hạng nhất (từ 1 đến 15)
        BEGIN
            SET @GiaGhe = 3000000.00; -- Giá hạng nhất
            SET @HangGhe = N'Hạng nhất';
        END
        ELSE IF @i <= 50 -- 35 ghế thương gia (từ 16 đến 50)
        BEGIN
            SET @GiaGhe = 2000000.00; -- Giá thương gia
            SET @HangGhe = N'Thương gia';
        END
        ELSE -- 100 ghế phổ thông (từ 51 đến 150)
        BEGIN
            SET @GiaGhe = 1000000.00; -- Giá phổ thông
            SET @HangGhe = N'Phổ thông';
        END;

        -- Chèn thông tin ghế vào bảng ThongTinGhe
        -- Cột SoGhe sẽ nhận trực tiếp giá trị số nguyên từ biến @i
        INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe)
        VALUES (@i, @MaChuyenBay, @GiaGhe, @HangGhe, N'có sẵn');

        -- Tăng biến đếm để chuyển sang ghế tiếp theo
        SET @i = @i + 1;
    END;
END;
GO

-- Stored Procedure cập nhật chuyến bay
CREATE PROCEDURE sp_CapNhatChuyenBay
    @MaChuyenBay VARCHAR(20),
    @TinhTrangChuyenBay NVARCHAR(50),
    @GioBay DATETIME,
    @GioDen DATETIME,
    @DiaDiemDau NVARCHAR(100),
    @DiaDiemCuoi NVARCHAR(100)
AS
BEGIN
    UPDATE ChuyenBay
    SET TinhTrangChuyenBay = @TinhTrangChuyenBay,
        GioBay = @GioBay,
        GioDen = @GioDen,
        DiaDiemDau = @DiaDiemDau,
        DiaDiemCuoi = @DiaDiemCuoi
    WHERE MaChuyenBay = @MaChuyenBay;
END;
GO

-- Stored Procedure thêm ghế
CREATE PROCEDURE sp_ThemGhe
    @SoGhe VARCHAR(10),
    @MaChuyenBay VARCHAR(20),
    @GiaGhe DECIMAL(18, 2),
    @HangGhe NVARCHAR(20),
    @TinhTrangGhe NVARCHAR(20)
AS
BEGIN
    INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe)
    VALUES (@SoGhe, @MaChuyenBay, @GiaGhe, @HangGhe, @TinhTrangGhe);
END;
GO

-- Stored Procedure thêm đặt vé
CREATE PROCEDURE sp_ThemDatVe
    @MaDatVe VARCHAR(20),
    @NgayDatVe DATE,
    @NgayBay DATE,
    @TrangThaiThanhToan NVARCHAR(50),
    @SoGhe INT,
    @SoTien DECIMAL(18, 2),
    @MaChuyenBay VARCHAR(20),
    @MaKH VARCHAR(20)
AS
BEGIN
    INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH)
    VALUES (@MaDatVe, @NgayDatVe, @NgayBay, @TrangThaiThanhToan, @SoGhe, @SoTien, @MaChuyenBay, @MaKH);
END;
GO

-- Stored Procedure xóa đặt vé
CREATE PROCEDURE sp_XoaDatVe
    @MaDatVe VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Store the MaChuyenBay and SoGhe for updating seat status
        DECLARE @MaChuyenBay VARCHAR(20);
        DECLARE @SoGhe INT;

        SELECT @MaChuyenBay = MaChuyenBay, @SoGhe = SoGhe
        FROM ThongTinDatVe
        WHERE MaDatVe = @MaDatVe;

        -- Check if the booking exists
        IF @MaChuyenBay IS NULL
        BEGIN
            RAISERROR (N'Đặt vé không tồn tại!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Delete related HoaDon records
        DELETE FROM HoaDon
        WHERE MaTT IN (SELECT MaTT FROM ThanhToan WHERE MaDatVe = @MaDatVe);

        -- Delete related ThanhToan records
        DELETE FROM ThanhToan
        WHERE MaDatVe = @MaDatVe;

        -- Update seat status to 'có sẵn'
        WITH BookedSeats AS (
            SELECT TOP (@SoGhe) SoGhe
            FROM ThongTinGhe
            WHERE MaChuyenBay = @MaChuyenBay AND TinhTrangGhe = N'đã đặt'
            ORDER BY SoGhe
        )
        UPDATE tg
        SET TinhTrangGhe = N'có sẵn'
        FROM ThongTinGhe tg
        INNER JOIN BookedSeats s ON tg.SoGhe = s.SoGhe AND tg.MaChuyenBay = @MaChuyenBay;

        -- Delete the booking record
        DELETE FROM ThongTinDatVe
        WHERE MaDatVe = @MaDatVe;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Stored Procedure thêm thanh toán
CREATE PROCEDURE sp_ThemThanhToan
    @MaTT VARCHAR(20),
    @NgayTT DATE,
    @SoTien DECIMAL(18, 2),
    @PTTT NVARCHAR(50),
    @MaDatVe VARCHAR(20)
AS
BEGIN
    INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe)
    VALUES (@MaTT, @NgayTT, @SoTien, @PTTT, @MaDatVe);
END;
GO

-- Stored Procedure thêm hóa đơn
CREATE PROCEDURE sp_ThemHoaDon
    @MaHoaDon VARCHAR(20),
    @NgayXuatHD DATE,
    @PhuongThucTT NVARCHAR(50),
    @NgayThanhToan DATE,
    @MaTT VARCHAR(20)
AS
BEGIN
    INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT)
    VALUES (@MaHoaDon, @NgayXuatHD, @PhuongThucTT, @NgayThanhToan, @MaTT);
END;
GO

-- Stored Procedure kiểm tra ghế trống
CREATE PROCEDURE sp_KiemTraGheTrong
    @MaChuyenBay VARCHAR(20)
AS
BEGIN
    SELECT COUNT(*) AS SoGheTrong
    FROM ThongTinGhe
    WHERE MaChuyenBay = @MaChuyenBay AND TinhTrangGhe = N'có sẵn';
END;
GO

CREATE VIEW vw_BaoCaoDoanhThuTheoThang
AS
SELECT 
    YEAR(tt.NgayTT) AS Nam,
    MONTH(tt.NgayTT) AS Thang,
    SUM(tt.SoTien) AS TongDoanhThu,
    COUNT(tt.MaTT) AS SoGiaoDich
FROM ThanhToan tt
WHERE tt.SoTien > 0
GROUP BY YEAR(tt.NgayTT), MONTH(tt.NgayTT);

CREATE VIEW vw_BaoCaoTongDoanhThu
AS
SELECT 
    SUM(tt.SoTien) AS TongDoanhThu,
    COUNT(tt.MaTT) AS TongSoGiaoDich
FROM ThanhToan tt
WHERE tt.SoTien > 0;

-- View báo cáo ghế trống
CREATE VIEW vw_GheTrong AS
SELECT 
    tg.MaChuyenBay,
    cb.DiaDiemDau,
    cb.DiaDiemCuoi,
    COUNT(*) AS SoGheTrong
FROM ThongTinGhe tg
JOIN ChuyenBay cb ON tg.MaChuyenBay = cb.MaChuyenBay
WHERE tg.TinhTrangGhe = N'có sẵn'
GROUP BY tg.MaChuyenBay, cb.DiaDiemDau, cb.DiaDiemCuoi;
GO

-- Thêm dữ liệu mẫu
-- (Giữ nguyên dữ liệu mẫu như trong tệp gốc)

-- admin
insert into NguoiDung values('admin', N'Kiều Nguyễn Thành Phát', '$2b$10$eJCDxbyTqGrsX5YF1Iy6TOrMQUri4nGC1ltcF27XexNx9aC2pkYe.', 'kieuphat159@gmail.com', '0583016657', '07/11/2005', 'Nam', '000000000000')
-- nguoidung 
INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD) VALUES
('nguyenvana', N'Nguyễn Van A', '$2b$10$tD4h9t1j2n3m4l5k6j7i8OQd.zS2m.yA6fG7h8i9j0q1w2e3r4t5y6u7i8o9p0', 'nguyenvana@gmail.com', '0901234567', '1990-05-15', N'Nam', '001123456789'),
('tranthinga', N'Trần Thị Nga', '$2b$10$uV5i0o1p2q3w4e5r6t7y8.vW5b.xC7d.xE7f.xG7h.xI7j.xK7l.xM7n.xO7p.xQ7r.xS7t.xV7u.xX7v.xZ7w.yA8x.yB8y.yC8z', 'tranthinga@gmail.com', '0902345678', '1992-11-22', N'Nữ', '002234567890'),
('leminhhai', N'Lê Minh Hải', '$2b$10$wX6k1j2h3g4f5d6s7a8Qj.zP3n.yC7d.xM8n.xO8p.xQ8r.xS8t.xV8u.xX8v.xZ8w.yA9x.yB9y.yC9z', 'leminhhai@gmail.com', '0903456789', '1988-03-01', N'Nam', '003345678901'),
('phamthihuong', N'Phạm Thị Hương', '$2b$10$xY7l2k3j4h5g6f7d8s9Qk.zR4o.yD8e.xN9o.xP9q.xR9s.xT9u.xW9v.xY9w.xZ9x.yA0y.yB0z', 'phamhuong@gmail.com', '0904567890', '1995-07-30', N'Nữ', '004456789012'),
('hoanganhtuan', N'Hoàng Anh Tuấn', '$2b$10$zZ8m3l4k5j6h7g8f9d0Qi.zS5p.yE9f.xO0p.xQ0r.xS0s.xU0t.xW0u.xY0v.xZ0w.yA1x.yB1y.yC1z', 'hoanganhtuan@gmail.com', '0905678901', '1991-01-10', N'Nam', '005567890123'),
('nguyenthib', N'Nguyễn Thị B', '$2b$10$aA9n4m5l6k7j8h9g0Qh.zT6q.yF0g.xP1q.xR1s.xT1u.xV1v.xX1w.xY1x.yA2y.yB2z', 'nguyenthib@gmail.com', '0906789012', '1993-09-05', N'Nữ', '006678901234'),
('votuananh', N'Võ Tuấn Anh', '$2b$10$bB0o5n6m7l8k9j0h1Qg.zU7r.yG1h.xQ2r.xS2s.xU2t.xW2u.xY2v.xZ2w.yA3x.yB3y.yC3z', 'votuananh@gmail.com', '0907890123', '1987-04-18', N'Nam', '007789012345'),
('dangthuyduong', N'Đặng Thúy Dương', '$2b$10$cC1p6o7n8m9l0k1j2Qf.zV8s.yH2i.xR3s.xT3u.xV3v.xX3w.xY3x.yA4y.yB4z', 'dangduong@gmail.com', '0908901234', '1996-12-03', N'Nữ', '008890123456'),
('truongvanduc', N'Trương Văn Đức', '$2b$10$dD2q7p8o9n0m1l2k3Qe.zW9t.yI3j.xS4t.xU4u.xW4v.xX4w.xY4x.yA5y.yB5z', 'truongduc@gmail.com', '0909012345', '1990-06-25', N'Nam', '009901234567'),
('dothihuyen', N'Đỗ Thị Huyền', '$2b$10$eE3r8q9p0o1n2m3l4Qd.zX0u.yJ4k.xT5u.xV5v.xX5w.xY5x.yA6y.yB6z', 'dohuyen@gmail.com', '0910123456', '1994-02-14', N'Nữ', '010012345678'),
('phanvanduc', N'Phan Văn Đức', '$2b$10$fF4s9r0q1o2n3m4l5Qc.zY1v.yK5l.xU6v.xW6w.xX6x.xY6y.yA7z', 'ducphan@gmail.com', '0911234567', '1989-08-08', N'Nam', '011123456789'),
('nguyenquynhchi', N'Nguyễn Quỳnh Chi', '$2b$10$gG5t0s1r2q3o4n5m6Qb.zZ2w.yL6m.xV7w.xX7x.xY7y.yA8z', 'quynhchi@gmail.com', '0912345678', '1997-03-20', N'Nữ', '012234567890'),
('tranvietanh', N'Trần Việt Anh', '$2b$10$hH6u1t2s3r4q5o6n7Qa.z03x.yM7n.xW8x.xY8y.yA9z', 'vietanh@gmail.com', '0913456789', '1991-01-28', N'Nam', '013345678901'),
('lethithuy', N'Lê Thị Thúy', '$2b$10$iI7v2u3t4s5r6q7o8Q0.z14y.yN8o.xX9y.yA0z', 'thuynguyen@gmail.com', '0914567890', '1993-10-10', N'Nữ', '014456789012'),
('phamnhatminh', N'Phạm Nhật Minh', '$2b$10$jJ8w3v4u5t6s7r8q9Q1.z25z.yO9p.yB0z', 'nhatminh@gmail.com', '0915678901', '1986-05-05', N'Nam', '015567890123'),
('nguyenthanhhoa', N'Nguyễn Thanh Hòa', '$2b$10$kK9x4w5v6u7t8s9r0Q2.z36A.yP0q.yC1A', 'thanhhoa@gmail.com', '0916789012', '1995-04-01', N'Nữ', '016678901234'),
('vuvanhung', N'Vũ Văn Hùng', '$2b$10$lL0y5x6w7v8u9t0s1Q3.z47B.yQ1r.yD2B', 'vanhung@gmail.com', '0917890123', '1990-11-11', N'Nam', '017789012345'),
('hochithanh', N'Hồ Chí Thanh', '$2b$10$mM1z6y7x8w9v0u1t2Q4.z58C.yR2s.yE3C', 'chithanh@gmail.com', '0918901234', '1992-06-19', N'Nam', '018890123456'),
('maithuytrang', N'Mai Thúy Trang', '$2b$10$nN2A7z8y9x0w1v2u3Q5.z69D.yS3t.yF4D', 'thuytrang@gmail.com', '0919012345', '1996-08-28', N'Nữ', '019901234567'),
('nguyenvanc', N'Nguyễn Văn C', '$2b$10$oO3B8A9z0y1x2w3v4Q6.z70E.yT4u.yG5E', 'nguyenvanc@gmail.com', '0920123456', '1985-02-09', N'Nam', '020012345678'),
('tranvanquy', N'Trần Văn Quý', '$2b$10$pP4C9B0A1z2y3x4w5Q7.z81F.yU5v.yH6F', 'tranvanquy@gmail.com', '0921234567', '1994-07-07', N'Nam', '021123456789'),
('phanthidung', N'Phan Thị Dung', '$2b$10$qQ5D0C1B2A3z4y5x6Q8.z92G.yV6w.yI7G', 'phanthidung@gmail.com', '0922345678', '1991-03-17', N'Nữ', '022234567890'),
('dogiatuan', N'Đỗ Gia Tuấn', '$2b$10$rR6E1D2C3B4A5z6y7Q9.z03H.yW7x.yJ8H', 'dogiatuan@gmail.com', '0923456789', '1988-09-01', N'Nam', '023345678901'),
('nguyenthiminh', N'Nguyễn Thị Minh', '$2b$10$sS7F2E3D4C5B6A7z8Q0.z14I.yX8y.yK9I', 'nguyenthiminh@gmail.com', '0924567890', '1996-01-25', N'Nữ', '024456789012'),
('dinhtheanh', N'Đinh Thế Anh', '$2b$10$tT8G3F4E5D6C7B8A9Q1.z25J.yY9z.yL0J', 'dinhtheanh@gmail.com', '0925678901', '1990-04-12', N'Nam', '025567890123'),
('nguyenthuha', N'Nguyễn Thu Hà', '$2b$10$uU9H4G5F6E7D8C9B0Q2.z36K.yZ0A.yM1K', 'nguyenthuha@gmail.com', '0926789012', '1992-12-08', N'Nữ', '026678901234'),
('lehoangviet', N'Lê Hoàng Việt', '$2b$10$vV0I5H6G7F8E9D0C1Q3.z47L.y01B.yN2L', 'lehoangviet@gmail.com', '0927890123', '1987-06-03', N'Nam', '027789012345'),
('phamthithu', N'Phạm Thị Thu', '$2b$10$wW1J6I7H8G9F0E1D2Q4.z58M.y12C.yO3M', 'phamthithu@gmail.com', '0928901234', '1995-08-14', N'Nữ', '028890123456'),
('tranthanhlong', N'Trần Thanh Long', '$2b$10$xX2K7J8I9H0G1F2E3Q5.z69N.y23D.yP4N', 'tranthanhlong@gmail.com', '0929012345', '1991-02-23', N'Nam', '029901234567'),
('nguyenthuoc', N'Nguyễn Thu Ước', '$2b$10$yY3L8K9J0I1H2G3F4Q6.z70O.y34E.yQ5O', 'nguyenthuoc@gmail.com', '0930123456', '1993-09-09', N'Nữ', '030012345678'),
('hoangvanhuy', N'Hoàng Văn Huy', '$2b$10$zZ4M9L0K1I2H3G4F5Q7.z81P.y45F.yR6P', 'hoangvanhuy@gmail.com', '0931234567', '1989-05-18', N'Nam', '031123456789'),
('duongthithu', N'Dương Thị Thu', '$2b$10$aA5N0M1L2K3I4H5G6Q8.z92Q.y56G.yS7Q', 'duongthithu@gmail.com', '0932345678', '1997-01-05', N'Nữ', '032234567890'),
('nguyenvananh', N'Nguyễn Văn Ánh', '$2b$10$bB6O1N2M3L4K5I6H7Q9.z03R.y67H.yT8R', 'nguyenvananh@gmail.com', '0933456789', '1990-07-29', N'Nam', '033345678901'),
('tranvanthanh', N'Trần Văn Thanh', '$2b$10$cC7P2O3N4M5L6K7I8Q0.z14S.y78I.yU9S', 'tranvanthanh@gmail.com', '0934567890', '1992-03-02', N'Nam', '034456789012'),
('lethuhang', N'Lê Thu Hằng', '$2b$10$dD8Q3P4O5N6M7L8K9Q1.z25T.y89J.yV0T', 'lethuhang@gmail.com', '0935678901', '1994-11-21', N'Nữ', '035567890123'),
('nguyenthithuyduong', N'Nguyễn Thị Thùy Dương', '$2b$10$eE9R4Q5P6O7N8M9L0Q2.z36U.y90K.yW1U', 'thuyduong@gmail.com', '0936789012', '1996-06-15', N'Nữ', '036678901234'),
('phamanhvu', N'Phạm Anh Vũ', '$2b$10$fF0S5R6Q7P8O9N0M1Q3.z47V.y01L.yX2V', 'phamanhvu@gmail.com', '0937890123', '1988-08-04', N'Nam', '037789012345'),
('nguyenthihuong', N'Nguyễn Thị Hương', '$2b$10$gG1T6S7R8Q9O0N1M2Q4.z58W.y12M.yY3W', 'nguyenthihuong@gmail.com', '0938901234', '1993-01-19', N'Nữ', '038890123456'),
('dovanlong', N'Đỗ Văn Long', '$2b$10$hH2U7T8S9R0Q1O2N3Q5.z69X.y23N.yZ4X', 'dovanlong@gmail.com', '0939012345', '1990-04-27', N'Nam', '039901234567'),
('tranvanhao', N'Trần Văn Hào', '$2b$10$iI3V8U9T0S1R2Q3O4Q6.z70Y.y34O.yA5Y', 'tranvanhao@gmail.com', '0940123456', '1987-10-06', N'Nam', '040012345678'),
('nguyenductrung', N'Nguyễn Đức Trung', '$2b$10$jJ4W9V0U1T2S3R4Q5Q7.z81Z.y45P.yB6Z', 'nguyenductrung@gmail.com', '0941234567', '1991-12-12', N'Nam', '041123456789'),
('phamanhthu', N'Phạm Anh Thu', '$2b$10$kK5X0W1V2U3T4S5R6Q8.z920.y56Q.yC70', 'phamanhthu@gmail.com', '0942345678', '1995-05-23', N'Nữ', '042234567890'),
('lethanhhien', N'Lê Thanh Hiền', '$2b$10$lL6Y1X2W3V4U5T6S7Q9.z031.y67R.yD81', 'lethanhhien@gmail.com', '0943456789', '1994-02-01', N'Nữ', '043345678901'),
('nguyenthaithu', N'Nguyễn Thái Thu', '$2b$10$mM7Z2Y3X4W5U6T7S8Q0.z142.y78S.yE92', 'nguyenthaithu@gmail.com', '0944567890', '1997-07-16', N'Nữ', '044456789012'),
('tranhoangnam', N'Trần Hoàng Nam', '$2b$10$nN803Z4Y5X6W7U8T9Q1.z253.y89T.yF03', 'tranhoangnam@gmail.com', '0945678901', '1989-03-08', N'Nam', '045567890123'),
('vuthithuong', N'Vũ Thị Thương', '$2b$10$oO91405Z6Y7X8W9U0Q2.z364.y90U.yG14', 'vuthithuong@gmail.com', '0946789012', '1993-09-29', N'Nữ', '046678901234'),
('nguyenminhquan', N'Nguyễn Minh Quân', '$2b$10$pP0251607Z8Y9X0W1Q3.z475.y01V.yH25', 'nguyenminhquan@gmail.com', '0947890123', '1990-11-03', N'Nam', '047789012345'),
('phamthithuong', N'Phạm Thị Thường', '$2b$10$qQ136271809Z0Y1X2Q4.z586.y12W.yI36', 'phamthithuong@gmail.com', '0948901234', '1992-06-21', N'Nữ', '048890123456'),
('lehoanghai', N'Lê Hoàng Hải', '$2b$10$rR24738291001Z2Y3Q5.z697.y23X.yJ47', 'lehoanghai@gmail.com', '0949012345', '1986-08-10', N'Nam', '049901234567'),
('nguyenthanhnam', N'Nguyễn Thanh Nam', '$2b$10$sS35849302112Z3Y4Q6.z708.y34Y.yK58', 'nguyenthanhnam@gmail.com', '0950123456', '1995-04-14', N'Nam', '050012345678'),
('tranvanlinh', N'Trần Văn Linh', '$2b$10$tT46950413223Z4Y5Q7.z819.y45Z.yL69', 'tranvanlinh@gmail.com', '0951234567', '1988-01-07', N'Nam', '051123456789'),
('phamdanghuy', N'Phạm Đăng Huy', '$2b$10$uU57061524334Z5Y6Q8.z920.y560.yM70', 'phamdanghuy@gmail.com', '0952345678', '1996-03-22', N'Nam', '052234567890'),
('nguyentranthuy', N'Nguyễn Trần Thúy', '$2b$10$vV68172635445Z6Y7Q9.z031.y671.yN81', 'nguyentranthuy@gmail.com', '0953456789', '1994-10-09', N'Nữ', '053345678901'),
('dovuhoang', N'Đỗ Vũ Hoàng', '$2b$10$wW79283746556Z7Y8Q0.z142.y782.yO92', 'dovuhoang@gmail.com', '0954567890', '1991-05-01', N'Nam', '054456789012'),
('nguyenthidiem', N'Nguyễn Thị Diễm', '$2b$10$xX80394857667Z8Y9Q1.z253.y893.yP03', 'nguyenthidiem@gmail.com', '0955678901', '1997-02-18', N'Nữ', '055567890123'),
('lequanganh', N'Lê Quang Anh', '$2b$10$yY91405968778Z9Y0Q2.z364.y904.yQ14', 'lequanganh@gmail.com', '0956789012', '1989-07-25', N'Nam', '056678901234'),
('tranthiminhhien', N'Trần Thị Minh Hiền', '$2b$10$zZ02516079889Z0Y1Q3.z475.y015.yR25', 'tranthiminhhien@gmail.com', '0957890123', '1993-01-04', N'Nữ', '057789012345'),
('nguyenduckhoa', N'Nguyễn Đức Khoa', '$2b$10$aA13627180990Z1Y2Q4.z586.y126.yS36', 'nguyenduckhoa@gmail.com', '0958901234', '1990-11-20', N'Nam', '058890123456'),
('phambichhang', N'Phạm Bích Hằng', '$2b$10$bB24738291001Z2Y3Q5.z697.y237.yT47', 'phambichhang@gmail.com', '0959012345', '1995-06-08', N'Nữ', '059901234567'),
('tranminhduc', N'Trần Minh Đức', '$2b$10$cC35849302112Z3Y4Q6.z708.y348.yU58', 'tranminhduc@gmail.com', '0960123456', '1987-09-15', N'Nam', '060012345678'),
('nguyenthanhnga', N'Nguyễn Thanh Nga', '$2b$10$dD46950413223Z4Y5Q7.z819.y459.yV69', 'nguyenthanhnga@gmail.com', '0961234567', '1992-04-26', N'Nữ', '061123456789'),
('lequanghung', N'Lê Quang Hùng', '$2b$10$eE57061524334Z5Y6Q8.z920.y560.yW70', 'lequanghung@gmail.com', '0962345678', '1988-02-13', N'Nam', '062234567890'),
('nguyenthanhhuyen', N'Nguyễn Thanh Huyền', '$2b$10$fF68172635445Z6Y7Q9.z031.y671.yX81', 'nguyenthanhhuyen@gmail.com', '0963456789', '1996-12-05', N'Nữ', '063345678901'),
('phamquangtrung', N'Phạm Quang Trung', '$2b$10$gG79283746556Z7Y8Q0.z142.y782.yY92', 'phamquangtrung@gmail.com', '0964567890', '1991-07-30', N'Nam', '064456789012'),
('hoangthithao', N'Hoàng Thị Thảo', '$2b$10$hH80394857667Z8Y9Q1.z253.y893.yZ03', 'hoangthithao@gmail.com', '0965678901', '1993-03-07', N'Nữ', '065567890123'),
('dovanviet', N'Đỗ Văn Việt', '$2b$10$iI91405968778Z9Y0Q2.z364.y904.yA14', 'dovanviet@gmail.com', '0966789012', '1986-09-02', N'Nam', '066678901234'),
('nguyenthiyen', N'Nguyễn Thị Yến', '$2b$10$jJ02516079889Z0Y1Q3.z475.y015.yB25', 'nguyenthiyen@gmail.com', '0967890123', '1995-08-20', N'Nữ', '067789012345'),
('trandaiduong', N'Trần Đại Dương', '$2b$10$kK13627180990Z1Y2Q4.z586.y126.yC36', 'trandaiduong@gmail.com', '0968901234', '1989-04-11', N'Nam', '068890123456'),
('lethanhthao', N'Lê Thanh Thảo', '$2b$10$lL24738291001Z2Y3Q5.z697.y237.yD47', 'lethanhthao@gmail.com', '0969012345', '1997-01-13', N'Nữ', '069901234567'),
('nguyenbaoquang', N'Nguyễn Bảo Quang', '$2b$10$mM35849302112Z3Y4Q6.z708.y348.yE58', 'nguyenbaoquang@gmail.com', '0970123456', '1990-10-25', N'Nam', '070012345678'),
('phamthithuytrang', N'Phạm Thị Thùy Trang', '$2b$10$nN46950413223Z4Y5Q7.z819.y459.yF69', 'phamthithuytrang@gmail.com', '0971234567', '1992-05-09', N'Nữ', '071123456789'),
('nguyenvanthinh', N'Nguyễn Văn Thịnh', '$2b$10$oO57061524334Z5Y6Q8.z920.y560.yG70', 'nguyenvanthinh@gmail.com', '0972345678', '1988-03-16', N'Nam', '072234567890'),
('tranvanthang', N'Trần Văn Thắng', '$2b$10$pP68172635445Z6Y7Q9.z031.y671.yH81', 'tranvanthang@gmail.com', '0973456789', '1996-02-28', N'Nam', '073345678901'),
('lethianhdao', N'Lê Thị Anh Đào', '$2b$10$qQ79283746556Z7Y8Q0.z142.y782.yI92', 'lethianhdao@gmail.com', '0974567890', '1994-09-03', N'Nữ', '074456789012'),
('nguyenthanhhai', N'Nguyễn Thanh Hải', '$2b$10$rR80394857667Z8Y9Q1.z253.y893.yJ03', 'nguyenthanhhai@gmail.com', '0975678901', '1991-06-10', N'Nam', '075567890123'),
('tranvanhieu', N'Trần Văn Hiếu', '$2b$10$sS91405968778Z9Y0Q2.z364.y904.yK14', 'tranvanhieu@gmail.com', '0976789012', '1987-12-01', N'Nam', '076678901234'),
('phamthihuonggiang', N'Phạm Thị Hương Giang', '$2b$10$tT02516079889Z0Y1Q3.z475.y015.yL25', 'phamthihuonggiang@gmail.com', '0977890123', '1995-07-22', N'Nữ', '077789012345'),
('nguyenvantu', N'Nguyễn Văn Tú', '$2b$10$uU13627180990Z1Y2Q4.z586.y126.yM36', 'nguyenvantu@gmail.com', '0978901234', '1993-04-19', N'Nam', '078890123456'),
('dothimyanh', N'Đỗ Thị Mỹ Anh', '$2b$10$vV24738291001Z2Y3Q5.z697.y237.yN47', 'dothimyanh@gmail.com', '0979012345', '1997-03-06', N'Nữ', '079901234567'),
('hoangminhkhai', N'Hoàng Minh Khải', '$2b$10$wW35849302112Z3Y4Q6.z708.y348.yO58', 'hoangminhkhai@gmail.com', '0980123456', '1990-08-28', N'Nam', '080012345678'),
('nguyenthithanhtruyen', N'Nguyễn Thị Thanh Truyền', '$2b$10$xX46950413223Z4Y5Q7.z819.y459.yP69', 'nguyenthithanhtruyen@gmail.com', '0981234567', '1992-02-15', N'Nữ', '081123456789'),
('tranlehuu', N'Trần Lê Hữu', '$2b$10$yY57061524334Z5Y6Q8.z920.y560.yQ70', 'tranlehuu@gmail.com', '0982345678', '1989-06-04', N'Nam', '082234567890'),
('lethibichngoc', N'Lê Thị Bích Ngọc', '$2b$10$zZ68172635445Z6Y7Q9.z031.y671.yR81', 'lethibichngoc@gmail.com', '0983456789', '1996-10-18', N'Nữ', '083345678901'),
('nguyenthanhphong', N'Nguyễn Thanh Phong', '$2b$10$aA79283746556Z7Y8Q0.z142.y782.yS92', 'nguyenthanhphong@gmail.com', '0984567890', '1991-01-09', N'Nam', '084456789012'),
('phamvanquang', N'Phạm Văn Quang', '$2b$10$bB80394857667Z8Y9Q1.z253.y893.yT03', 'phamvanquang@gmail.com', '0985678901', '1988-11-27', N'Nam', '085567890123'),
('nguyenthingocthao', N'Nguyễn Thị Ngọc Thảo', '$2b$10$cC91405968778Z9Y0Q2.z364.y904.yU14', 'nguyenthingocthao@gmail.com', '0986789012', '1995-05-17', N'Nữ', '086678901234'),
('tranhuonggiang', N'Trần Hương Giang', '$2b$10$dD02516079889Z0Y1Q3.z475.y015.yV25', 'tranhuonggiang@gmail.com', '0987890123', '1993-12-02', N'Nữ', '087789012345'),
('lethanhdat', N'Lê Thanh Đạt', '$2b$10$eE13627180990Z1Y2Q4.z586.y126.yW36', 'lethanhdat@gmail.com', '0988901234', '1990-06-29', N'Nam', '088890123456'),
('nguyenthithanhtuyen', N'Nguyễn Thị Thanh Tuyến', '$2b$10$fF24738291001Z2Y3Q5.z697.y237.yX47', 'nguyenthithanhtuyen@gmail.com', '0989012345', '1994-02-08', N'Nữ', '089901234567'),
('phanvanthuan', N'Phan Văn Thuận', '$2b$10$gG35849302112Z3Y4Q6.z708.y348.yY58', 'phanvanthuan@gmail.com', '0990123456', '1987-07-20', N'Nam', '090012345678'),
('nguyenthuhoai', N'Nguyễn Thu Hoài', '$2b$10$hH46950413223Z4Y5Q7.z819.y459.yZ69', 'nguyenthuhoai@gmail.com', '0991234567', '1997-01-26', N'Nữ', '091123456789'),
('tranvanhai', N'Trần Văn Hải', '$2b$10$iI57061524334Z5Y6Q8.z920.y560.yA70', 'tranvanhai@gmail.com', '0992345678', '1989-09-05', N'Nam', '092234567890'),
('lethuytrang', N'Lê Thùy Trang', '$2b$10$jJ68172635445Z6Y7Q9.z031.y671.yB81', 'lethuytrang@gmail.com', '0993456789', '1993-04-01', N'Nữ', '093345678901'),
('nguyenhoangnam', N'Nguyễn Hoàng Nam', '$2b$10$kK79283746556Z7Y8Q0.z142.y782.yC92', 'nguyenhoangnam@gmail.com', '0994567890', '1990-11-19', N'Nam', '094456789012'),
('phamanhthao', N'Phạm Anh Thảo', '$2b$10$lL80394857667Z8Y9Q1.z253.y893.yD03', 'phamanhthao@gmail.com', '0995678901', '1992-06-27', N'Nữ', '095567890123'),
('nguyenthanhngoc', N'Nguyễn Thanh Ngọc', '$2b$10$mM91405968778Z9Y0Q2.z364.y904.yE14', 'nguyenthanhngoc@gmail.com', '0996789012', '1996-08-11', N'Nữ', '096678901234'),
('tranvannhan', N'Trần Văn Nhàn', '$2b$10$nN02516079889Z0Y1Q3.z475.y015.yF25', 'tranvannhan@gmail.com', '0997890123', '1986-12-08', N'Nam', '097789012345'),
('lethanhhieu', N'Lê Thanh Hiếu', '$2b$10$oO13627180990Z1Y2Q4.z586.y126.yG36', 'lethanhhieu@gmail.com', '0998901234', '1995-03-04', N'Nam', '098890123456'),
('nguyenthihaiduong', N'Nguyễn Thị Hải Đường', '$2b$10$pP24738291001Z2Y3Q5.z697.y237.yH47', 'nguyenthihaiduong@gmail.com', '0999012345', '1994-09-10', N'Nữ', '099901234567'),
('tranminhanh', N'Trần Minh Anh', '$2b$10$qQ35849302112Z3Y4Q6.z708.y348.yI58', 'tranminhanh@gmail.com', '0800123456', '1991-07-07', N'Nam', '100012345678'),
('nguyenthihoangyen', N'Nguyễn Thị Hoàng Yến', '$2b$10$rR46950413223Z4Y5Q7.z819.y459.yJ69', 'nguyenthihoangyen@gmail.com', '0801234567', '1993-02-28', N'Nữ', '101123456789'),
('phamanhlinh', N'Phạm Anh Linh', '$2b$10$sS57061524334Z5Y6Q8.z920.y560.yK70', 'phamanhlinh@gmail.com', '0802345678', '1988-05-13', N'Nam', '102234567890'),
('lethidieulinh', N'Lê Thị Diệu Linh', '$2b$10$tT68172635445Z6Y7Q9.z031.y671.yL81', 'lethidieulinh@gmail.com', '0803456789', '1996-01-02', N'Nữ', '103345678901'),
('nguyenvandat', N'Nguyễn Văn Đạt', '$2b$10$uU79283746556Z7Y8Q0.z142.y782.yM92', 'nguyenvandat@gmail.com', '0804567890', '1990-10-16', N'Nam', '104456789012'),
('tranvanhuy', N'Trần Văn Huy', '$2b$10$vV80394857667Z8Y9Q1.z253.y893.yN03', 'tranvanhuy@gmail.com', '0805678901', '1987-03-24', N'Nam', '105567890123'),
('nguyenthicamlinh', N'Nguyễn Thị Cẩm Linh', '$2b$10$wW91405968778Z9Y0Q2.z364.y904.yO14', 'nguyenthicamlinh@gmail.com', '0806789012', '1995-08-05', N'Nữ', '106678901234'),
('dovanminh', N'Đỗ Văn Minh', '$2b$10$xX02516079889Z0Y1Q3.z475.y015.yP25', 'dovanminh@gmail.com', '0807890123', '1993-11-14', N'Nam', '107789012345'),
('hoangthuyquynh', N'Hoàng Thùy Quỳnh', '$2b$10$yY13627180990Z1Y2Q4.z586.y126.yQ36', 'hoangthuyquynh@gmail.com', '0808901234', '1997-04-21', N'Nữ', '108890123456'),
('nguyenthehai', N'Nguyễn Thế Hải', '$2b$10$zZ24738291001Z2Y3Q5.z697.y237.yR47', 'nguyenthehai@gmail.com', '0809012345', '1989-09-09', N'Nam', '109901234567'),
('tranthingocanh', N'Trần Thị Ngọc Ánh', '$2b$10$aA35849302112Z3Y4Q6.z708.y348.yS58', 'tranthingocanh@gmail.com', '0810123456', '1994-01-01', N'Nữ', '110012345678'),
('phamhoanglong', N'Phạm Hoàng Long', '$2b$10$bB46950413223Z4Y5Q7.z819.y459.yT69', 'phamhoanglong@gmail.com', '0811234567', '1991-06-16', N'Nam', '111123456789'),
('nguyenthithanhmai', N'Nguyễn Thị Thanh Mai', '$2b$10$cC57061524334Z5Y6Q8.z920.y560.yU70', 'nguyenthithanhmai@gmail.com', '0812345678', '1992-12-25', N'Nữ', '112234567890'),
('leminhhoang', N'Lê Minh Hoàng', '$2b$10$dD68172635445Z6Y7Q9.z031.y671.yV81', 'leminhhoang@gmail.com', '0813456789', '1986-07-03', N'Nam', '113345678901'),
('nguyenthithuongthuong', N'Nguyễn Thị Thường Thường', '$2b$10$eE79283746556Z7Y8Q0.z142.y782.yW92', 'nguyenthithuongthuong@gmail.com', '0814567890', '1995-02-11', N'Nữ', '114456789012'),
('tranvanduy', N'Trần Văn Duy', '$2b$10$fF80394857667Z8Y9Q1.z253.y893.yX03', 'tranvanduy@gmail.com', '0815678901', '1988-04-29', N'Nam', '115567890123'),
('hoangthanhson', N'Hoàng Thanh Sơn', '$2b$10$gG91405968778Z9Y0Q2.z364.y904.yY14', 'hoangthanhson@gmail.com', '0816789012', '1996-09-19', N'Nam', '116678901234'),
('nguyenthithanhloan', N'Nguyễn Thị Thanh Loan', '$2b$10$hH02516079889Z0Y1Q3.z475.y015.yZ25', 'nguyenthithanhloan@gmail.com', '0817890123', '1994-05-24', N'Nữ', '117789012345'),
('phanminhduc', N'Phan Minh Đức', '$2b$10$iI13627180990Z1Y2Q4.z586.y126.yA36', 'phanminhduc@gmail.com', '0818901234', '1991-10-08', N'Nam', '118890123456'),
('nguyenthithanhtrang', N'Nguyễn Thị Thanh Trang', '$2b$10$jJ24738291001Z2Y3Q5.z697.y237.yB47', 'nguyenthithanhtrang@gmail.com', '0819012345', '1997-03-12', N'Nữ', '119901234567'),
('dovanhoa', N'Đỗ Văn Hòa', '$2b$10$kK35849302112Z3Y4Q6.z708.y348.yC58', 'dovanhoa@gmail.com', '0820123456', '1990-08-01', N'Nam', '120012345678'),
('tranvannguyen', N'Trần Văn Nguyên', '$2b$10$lL46950413223Z4Y5Q7.z819.y459.yD69', 'tranvannguyen@gmail.com', '0821234567', '1987-02-09', N'Nam', '121123456789'),
('lethithuyhang', N'Lê Thị Thùy Hằng', '$2b$10$mM57061524334Z5Y6Q8.z920.y560.yE70', 'lethithuyhang@gmail.com', '0822345678', '1995-11-20', N'Nữ', '122234567890'),
('nguyenthanhhaiyen', N'Nguyễn Thanh Hải Yến', '$2b$10$nN68172635445Z6Y7Q9.z031.y671.yF81', 'nguyenthanhhaiyen@gmail.com', '0823456789', '1993-06-25', N'Nữ', '123345678901'),
('phamanhdao', N'Phạm Anh Đào', '$2b$10$oO79283746556Z7Y8Q0.z142.y782.yG92', 'phamanhdao@gmail.com', '0824567890', '1989-01-14', N'Nam', '124456789012'),
('nguyenthidiemhuong', N'Nguyễn Thị Diễm Hương', '$2b$10$pP80394857667Z8Y9Q1.z253.y893.yH03', 'nguyenthidiemhuong@gmail.com', '0825678901', '1996-04-03', N'Nữ', '125567890123'),
('tranvanlam', N'Trần Văn Lâm', '$2b$10$qQ91405968778Z9Y0Q2.z364.y904.yI14', 'tranvanlam@gmail.com', '0826789012', '1990-09-17', N'Nam', '126678901234'),
('lethithuha', N'Lê Thị Thu Hà', '$2b$10$rR02516079889Z0Y1Q3.z475.y015.yJ25', 'lethithuha@gmail.com', '0827890123', '1992-07-07', N'Nữ', '127789012345'),
('nguyenthanhduy', N'Nguyễn Thanh Duy', '$2b$10$sS13627180990Z1Y2Q4.z586.y126.yK36', 'nguyenthanhduy@gmail.com', '0828901234', '1986-12-01', N'Nam', '128890123456'),
('phamvandai', N'Phạm Văn Đại', '$2b$10$tT24738291001Z2Y3Q5.z697.y237.yL47', 'phamvandai@gmail.com', '0829012345', '1995-03-29', N'Nam', '129901234567'),
('nguyenthikieuanh', N'Nguyễn Thị Kiều Anh', '$2b$10$uU35849302112Z3Y4Q6.z708.y348.yM58', 'nguyenthikieuanh@gmail.com', '0830123456', '1994-10-11', N'Nữ', '130012345678'),
('tranvanthanglong', N'Trần Văn Thắng Long', '$2b$10$vV46950413223Z4Y5Q7.z819.y459.yN69', 'tranvanthanglong@gmail.com', '0831234567', '1991-05-02', N'Nam', '131123456789'),
('lethithuongmai', N'Lê Thị Thương Mại', '$2b$10$wW57061524334Z5Y6Q8.z920.y560.yO70', 'lethithuongmai@gmail.com', '0832345678', '1997-02-23', N'Nữ', '132234567890'),
('nguyenthanhphuong', N'Nguyễn Thanh Phương', '$2b$10$xX68172635445Z6Y7Q9.z031.y671.yP81', 'nguyenthanhphuong@gmail.com', '0833456789', '1990-08-16', N'Nữ', '133345678901'),
('phamvanlinh', N'Phạm Văn Linh', '$2b$10$yY79283746556Z7Y8Q0.z142.y782.yQ92', 'phamvanlinh@gmail.com', '0834567890', '1987-01-05', N'Nam', '134456789012'),
('nguyenthithuonguyen', N'Nguyễn Thị Thu Uyên', '$2b$10$zZ80394857667Z8Y9Q1.z253.y893.yR03', 'nguyenthihuonguyen@gmail.com', '0835678901', '1995-12-09', N'Nữ', '135567890123'),
('tranvantuan', N'Trần Văn Tuấn', '$2b$10$aA91405968778Z9Y0Q2.z364.y904.yS14', 'tranvantuan@gmail.com', '0836789012', '1993-07-27', N'Nam', '136678901234'),
('lethithuhoa', N'Lê Thị Thu Hòa', '$2b$10$bB02516079889Z0Y1Q3.z475.y015.yT25', 'lethithuhoa@gmail.com', '0837890123', '1996-03-10', N'Nữ', '137789012345'),
('nguyenthanhkhoa', N'Nguyễn Thanh Khoa', '$2b$10$cC13627180990Z1Y2Q4.z586.y126.yU36', 'nguyenthanhkhoa@gmail.com', '0838901234', '1989-09-06', N'Nam', '138890123456'),
('phamthihuynhhuong', N'Phạm Thị Huỳnh Hương', '$2b$10$dD24738291001Z2Y3Q5.z697.y237.yV47', 'phamthihuynhhuong@gmail.com', '0839012345', '1994-04-15', N'Nữ', '139901234567'),
('nguyenvancuong', N'Nguyễn Văn Cường', '$2b$10$eE35849302112Z3Y4Q6.z708.y348.yW58', 'nguyenvancuong@gmail.com', '0840123456', '1991-08-08', N'Nam', '140012345678'),
('tranthingochuyen', N'Trần Thị Ngọc Huyền', '$2b$10$fF46950413223Z4Y5Q7.z819.y459.yX69', 'tranthingochuyen@gmail.com', '0841234567', '1992-01-21', N'Nữ', '141123456789'),
('lethanhhien_a', N'Lê Thanh Hiền', '$2b$10$gG57061524334Z5Y6Q8.z920.y560.yY70', 'lethanhhien@gmail.com', '0842345678', '1988-06-18', N'Nữ', '142234567890'),
('nguyenthanhtrung', N'Nguyễn Thanh Trung', '$2b$10$hH68172635445Z6Y7Q9.z031.y671.yZ81', 'nguyenthanhtrung@gmail.com', '0843456789', '1996-10-04', N'Nam', '143345678901'),
('phamvanminh_a', N'Phạm Văn Minh', '$2b$10$iI79283746556Z7Y8Q0.z142.y782.yA92', 'phamvanminh@gmail.com', '0844567890', '1993-05-30', N'Nam', '144456789012'),
('nguyenthihuongly', N'Nguyễn Thị Hương Ly', '$2b$10$jJ80394857667Z8Y9Q1.z253.y893.yB03', 'nguyenthihuongly@gmail.com', '0845678901', '1997-01-17', N'Nữ', '145567890123'),
('tranvanphuong_a', N'Trần Văn Phương', '$2b$10$kK91405968778Z9Y0Q2.z364.y904.yC14', 'tranvanphuong@gmail.com', '0846789012', '1990-04-20', N'Nam', '146678901234'),
('lethithuong', N'Lê Thị Thường', '$2b$10$lL02516079889Z0Y1Q3.z475.y015.yD25', 'lethithuong@gmail.com', '0847890123', '1992-09-02', N'Nữ', '147789012345'),
('nguyenthanhtam', N'Nguyễn Thanh Tâm', '$2b$10$mM13627180990Z1Y2Q4.z586.y126.yE36', 'nguyenthanhtam@gmail.com', '0848901234', '1987-03-11', N'Nam', '148890123456'),
('phamnhatnam', N'Phạm Nhật Nam', '$2b$10$nN24738291001Z2Y3Q5.z697.y237.yF47', 'phamnhatnam@gmail.com', '0849012345', '1995-06-06', N'Nam', '149901234567'),
('tranvanhieu_a', N'Trần Văn Hiếu', '$2b$10$oO35849302112Z3Y4Q6.z708.y348.yG58', 'tranvanhieu_a@gmail.com', '0850123456', '1994-01-28', N'Nam', '150012345678'),
('nguyenthibichloan', N'Nguyễn Thị Bích Loan', '$2b$10$pP46950413223Z4Y5Q7.z819.y459.yH69', 'nguyenthibichloan@gmail.com', '0851234567', '1993-08-19', N'Nữ', '151123456789'),
('levanlinh', N'Lê Văn Linh', '$2b$10$qQ57061524334Z5Y6Q8.z920.y560.yI70', 'levanlinh@gmail.com', '0852345678', '1989-02-12', N'Nam', '152234567890'),
('nguyenthihoangthao', N'Nguyễn Thị Hoàng Thảo', '$2b$10$rR68172635445Z6Y7Q9.z031.y671.yJ81', 'nguyenthihoangthao@gmail.com', '0853456789', '1996-05-01', N'Nữ', '153345678901'),
('phamvanduong', N'Phạm Văn Dương', '$2b$10$sS79283746556Z7Y8Q0.z142.y782.yK92', 'phamvanduong@gmail.com', '0854567890', '1990-10-09', N'Nam', '154456789012'),
('tranvandung', N'Trần Văn Dũng', '$2b$10$tT80394857667Z8Y9Q1.z253.y893.yL03', 'tranvandung@gmail.com', '0855678901', '1987-04-04', N'Nam', '155567890123'),
('nguyenthithuonglan', N'Nguyễn Thị Thường Lan', '$2b$10$uU91405968778Z9Y0Q2.z364.y904.yM14', 'nguyenthithuonglan@gmail.com', '0856789012', '1995-09-22', N'Nữ', '156678901234'),
('leminhquang', N'Lê Minh Quang', '$2b$10$vV02516079889Z0Y1Q3.z475.y015.yN25', 'leminhquang@gmail.com', '0857890123', '1993-01-31', N'Nam', '157789012345'),
('nguyenthanhhoa_a', N'Nguyễn Thanh Hòa', '$2b$10$wW13627180990Z1Y2Q4.z586.y126.yO36', 'nguyenthanhhoa_a@gmail.com', '0858901234', '1997-06-15', N'Nữ', '158890123456'),
('dovanloc', N'Đỗ Văn Lộc', '$2b$10$xX24738291001Z2Y3Q5.z697.y237.yP47', 'dovanloc@gmail.com', '0859012345', '1990-11-29', N'Nam', '159901234567'),
('tranvanthuy', N'Trần Văn Thúy', '$2b$10$yY35849302112Z3Y4Q6.z708.y348.yQ58', 'tranvanthuy@gmail.com', '0860123456', '1988-02-07', N'Nữ', '160012345678'),
('nguyenthithanhtuyen_a', N'Nguyễn Thị Thanh Tuyến', '$2b$10$zZ46950413223Z4Y5Q7.z819.y459.yR69', 'nguyenthihuonguyen@gmail.com', '0861234567', '1996-07-03', N'Nữ', '161123456789'),
('lethanhgiang', N'Lê Thanh Giang', '$2b$10$aA57061524334Z5Y6Q8.z920.y560.yS70', 'lethanhgiang@gmail.com', '0862345678', '1989-12-10', N'Nam', '162234567890'),
('nguyenthibichhang', N'Nguyễn Thị Bích Hằng', '$2b$10$bB68172635445Z6Y7Q9.z031.y671.yT81', 'nguyenthibichhang@gmail.com', '0863456789', '1994-05-25', N'Nữ', '163345678901'),
('phamvanhuy_a', N'Phạm Văn Huy', '$2b$10$cC79283746556Z7Y8Q0.z142.y782.yU92', 'phamvanhuy@gmail.com', '0864567890', '1991-03-18', N'Nam', '164456789012'),
('tranvannghia', N'Trần Văn Nghĩa', '$2b$10$dD80394857667Z8Y9Q1.z253.y893.yV03', 'tranvannghia@gmail.com', '0865678901', '1986-09-01', N'Nam', '165567890123'),
('nguyenthuhoai_a', N'Nguyễn Thu Hoài', '$2b$10$eE91405968778Z9Y0Q2.z364.y904.yW14', 'nguyenthuhoai_a@gmail.com', '0866789012', '1995-04-10', N'Nữ', '166678901234'),
('lethithanhanh', N'Lê Thị Thanh Anh', '$2b$10$fF02516079889Z0Y1Q3.z475.y015.yX25', 'lethithanhanh@gmail.com', '0867890123', '1993-01-07', N'Nữ', '167789012345'),
('nguyenvancuong_a', N'Nguyễn Văn Cường', '$2b$10$gG13627180990Z1Y2Q4.z586.y126.yY36', 'nguyenvancuong_a@gmail.com', '0868901234', '1990-10-23', N'Nam', '168890123456'),
('phamanhthao_a', N'Phạm Anh Thảo', '$2b$10$hH24738291001Z2Y3Q5.z697.y237.yZ47', 'phamanhthao_a@gmail.com', '0869012345', '1992-06-05', N'Nữ', '169901234567'),
('tranvanthang_b', N'Trần Văn Thắng', '$2b$10$iI35849302112Z3Y4Q6.z708.y348.yA58', 'tranvanthang_b@gmail.com', '0870123456', '1989-11-16', N'Nam', '170012345678'),
('nguyenthingoclinh', N'Nguyễn Thị Ngọc Linh', '$2b$10$jJ46950413223Z4Y5Q7.z819.y459.yB69', 'nguyenthingoclinh@gmail.com', '0871234567', '1996-08-27', N'Nữ', '171123456789'),
('lethanhlong', N'Lê Thanh Long', '$2b$10$kK57061524334Z5Y6Q8.z920.y560.yC70', 'lethanhlong@gmail.com', '0872345678', '1987-03-03', N'Nam', '172234567890'),
('nguyentranthuy_a', N'Nguyễn Trần Thúy', '$2b$10$lL68172635445Z6Y7Q9.z031.y671.yD81', 'nguyentranthuy_a@gmail.com', '0873456789', '1995-02-14', N'Nữ', '173345678901'),
('phamvanquang_a', N'Phạm Văn Quang', '$2b$10$mM79283746556Z7Y8Q0.z142.y782.yE92', 'phamvanquang_a@gmail.com', '0874567890', '1993-07-20', N'Nam', '174456789012'),
('tranvanquy_b', N'Trần Văn Quý', '$2b$10$nN80394857667Z8Y9Q1.z253.y893.yF03', 'tranvanquy_b@gmail.com', '0875678901', '1990-04-08', N'Nam', '175567890123'),
('nguyenthithanhbinh', N'Nguyễn Thị Thanh Bình', '$2b$10$oO91405968778Z9Y0Q2.z364.y904.yG14', 'nguyenthithanhbinh@gmail.com', '0876789012', '1997-01-05', N'Nữ', '176678901234'),
('leminhanh', N'Lê Minh Anh', '$2b$10$pP02516079889Z0Y1Q3.z475.y015.yH25', 'leminhanh@gmail.com', '0877890123', '1989-09-12', N'Nam', '177789012345'),
('nguyenthithuylinh', N'Nguyễn Thị Thùy Linh', '$2b$10$qQ13627180990Z1Y2Q4.z586.y126.yI36', 'nguyenthithuylinh@gmail.com', '0878901234', '1994-02-23', N'Nữ', '178890123456'),
('phamvanhung_a', N'Phạm Văn Hùng', '$2b$10$rR24738291001Z2Y3Q5.z697.y237.yJ47', 'phamvanhung_a@gmail.com', '0879012345', '1991-06-11', N'Nam', '179901234567'),
('tranvanthanh_b', N'Trần Văn Thanh', '$2b$10$sS35849302112Z3Y4Q6.z708.y348.yK58', 'tranvanthanh_b@gmail.com', '0880123456', '1986-12-04', N'Nam', '180012345678'),
('nguyenthibichhong', N'Nguyễn Thị Bích Hồng', '$2b$10$tT46950413223Z4Y5Q7.z819.y459.yL69', 'nguyenthibichhong@gmail.com', '0881234567', '1995-07-18', N'Nữ', '181123456789'),
('levanduc', N'Lê Văn Đức', '$2b$10$uU57061524334Z5Y6Q8.z920.y560.yM70', 'levanduc@gmail.com', '0882345678', '1993-03-09', N'Nam', '182234567890'),
('nguyenthanhhoa_b', N'Nguyễn Thanh Hòa', '$2b$10$vV68172635445Z6Y7Q9.z031.y671.yN81', 'nguyenthanhhoa_b@gmail.com', '0883456789', '1997-05-20', N'Nữ', '183345678901'),
('phamminhtrung', N'Phạm Minh Trung', '$2b$10$wW79283746556Z7Y8Q0.z142.y782.yO92', 'phamminhtrung@gmail.com', '0884567890', '1990-11-01', N'Nam', '184456789012'),
('tranvancuong_b', N'Trần Văn Cường', '$2b$10$xX80394857667Z8Y9Q1.z253.y893.yP03', 'tranvancuong_b@gmail.com', '0885678901', '1987-08-25', N'Nam', '185567890123'),
('nguyenthithanhnguyen', N'Nguyễn Thị Thanh Nguyên', '$2b$10$yY91405968778Z9Y0Q2.z364.y904.yQ14', 'nguyenthithanhnguyen@gmail.com', '0886789012', '1996-04-07', N'Nữ', '186678901234'),
('lehoanghai_a', N'Lê Hoàng Hải', '$2b$10$zZ02516079889Z0Y1Q3.z475.y015.yR25', 'lehoanghai_a@gmail.com', '0887890123', '1989-10-14', N'Nam', '187789012345'),
('nguyenthithuonghoai', N'Nguyễn Thị Thường Hoài', '$2b$10$aA13627180990Z1Y2Q4.z586.y126.yS36', 'nguyenthithuonghoai@gmail.com', '0888901234', '1994-09-08', N'Nữ', '188890123456'),
('phamanhthao_b', N'Phạm Anh Thảo', '$2b$10$bB24738291001Z2Y3Q5.z697.y237.yT47', 'phamanhthao_b@gmail.com', '0889012345', '1991-02-01', N'Nữ', '189901234567'),
('tranvanduy_b', N'Trần Văn Duy', '$2b$10$cC35849302112Z3Y4Q6.z708.y348.yU58', 'tranvanduy_b@gmail.com', '0890123456', '1986-06-20', N'Nam', '190012345678'),
('nguyenthibichthuy', N'Nguyễn Thị Bích Thúy', '$2b$10$dD46950413223Z4Y5Q7.z819.y459.yV69', 'nguyenthibichthuy@gmail.com', '0891234567', '1995-11-11', N'Nữ', '191123456789'),
('lehoangviet_a', N'Lê Hoàng Việt', '$2b$10$eE57061524334Z5Y6Q8.z920.y560.yW70', 'lehoangviet_a@gmail.com', '0892345678', '1993-08-03', N'Nam', '192234567890'),
('nguyenthanhhoa_c', N'Nguyễn Thanh Hòa', '$2b$10$fF68172635445Z6Y7Q9.z031.y671.yX81', 'nguyenthanhhoa_c@gmail.com', '0893456789', '1997-04-25', N'Nữ', '193345678901'),
('phamvanlam', N'Phạm Văn Lâm', '$2b$10$gG79283746556Z7Y8Q0.z142.y782.yY92', 'phamvanlam@gmail.com', '0894567890', '1990-12-19', N'Nam', '194456789012'),
('tranvanlong_b', N'Trần Văn Long', '$2b$10$hH80394857667Z8Y9Q1.z253.y893.yZ03', 'tranvanlong_b@gmail.com', '0895678901', '1987-05-08', N'Nam', '195567890123'),
('nguyenthithanhngoc_a', N'Nguyễn Thị Thanh Ngọc', '$2b$10$iI91405968778Z9Y0Q2.z364.y904.yA14', 'nguyenthihuonguyen@gmail.com', '0896789012', '1996-01-30', N'Nữ', '196678901234'),
('leminhquy', N'Lê Minh Quý', '$2b$10$jJ02516079889Z0Y1Q3.z475.y015.yB25', 'leminhquy@gmail.com', '0897890123', '1989-03-27', N'Nam', '197789012345'),
('nguyenthihuong_b', N'Nguyễn Thị Hương', '$2b$10$kK13627180990Z1Y2Q4.z586.y126.yC36', 'huong_b@gmail.com', '0898901234', '1994-10-06', N'Nữ', '198890123456'),
('phamvananh', N'Phạm Văn Anh', '$2b$10$lL24738291001Z2Y3Q5.z697.y237.yD47', 'vananh@gmail.com', '0899012345', '1991-07-14', N'Nam', '199901234567'),
('tranvanlinh_b', N'Trần Văn Linh', '$2b$10$mM35849302112Z3Y4Q6.z708.y348.yE58', 'tranvanlinh_b@gmail.com', '0900123456', '1988-04-02', N'Nam', '200012345678');
--
--
INSERT INTO KhachHang (MaKH, Passport, TaiKhoan) VALUES
('KH001', 'AB123456', 'nguyenvana'),
('KH002', 'CD789012', 'tranthinga'),
('KH003', 'EF345678', 'leminhhai'),
('KH004', 'GH901234', 'phamthihuong'),
('KH005', 'IJ567890', 'hoanganhtuan'),
('KH006', 'KL123457', 'nguyenthib'),
('KH007', 'MN789013', 'votuananh'),
('KH008', 'OP345679', 'dangthuyduong'),
('KH009', 'QR901235', 'truongvanduc'),
('KH010', 'ST567891', 'dothihuyen'),
('KH011', 'UV123458', 'phanvanduc'),
('KH012', 'WX789014', 'nguyenquynhchi'),
('KH013', 'YZ345680', 'tranvietanh'),
('KH014', 'AA901236', 'lethithuy'),
('KH015', 'BB567892', 'phamnhatminh'),
('KH016', 'CC123459', 'nguyenthanhhoa'),
('KH017', 'DD789015', 'vuvanhung'),
('KH018', 'EE345681', 'hochithanh'),
('KH019', 'FF901237', 'maithuytrang'),
('KH020', 'GG567893', 'nguyenvanc'),
('KH021', 'HH123460', 'tranvanquy'),
('KH022', 'II789016', 'phanthidung'),
('KH023', 'JJ345682', 'dogiatuan'),
('KH024', 'KK901238', 'nguyenthiminh'),
('KH025', 'LL567894', 'dinhtheanh'),
('KH026', 'MM123461', 'nguyenthuha'),
('KH027', 'NN789017', 'lehoangviet'),
('KH028', 'OO345683', 'phamthithu'),
('KH029', 'PP901239', 'tranthanhlong'),
('KH030', 'QQ567895', 'nguyenthuoc'),
('KH031', 'RR123462', 'hoangvanhuy'),
('KH032', 'SS789018', 'duongthithu'),
('KH033', 'TT345684', 'nguyenvananh'),
('KH034', 'UU901240', 'tranvanthanh'),
('KH035', 'VV567896', 'lethuhang'),
('KH036', 'WW123463', 'nguyenthithuyduong'),
('KH037', 'XX789019', 'phamanhvu'),
('KH038', 'YY345685', 'nguyenthihuong'),
('KH039', 'ZZ901241', 'dovanlong'),
('KH040', 'AC123464', 'tranvanhao'),
('KH041', 'BD789020', 'nguyenductrung'),
('KH042', 'CE345686', 'phamanhthu'),
('KH043', 'DF901242', 'lethanhhien'),
('KH044', 'EG567897', 'nguyenthaithu'),
('KH045', 'FH123465', 'tranhoangnam'),
('KH046', 'GI789021', 'vuthithuong'),
('KH047', 'HJ345687', 'nguyenminhquan'),
('KH048', 'IK901243', 'phamthithuong'),
('KH049', 'JL567898', 'lehoanghai'),
('KH050', 'KM123466', 'nguyenthanhnam'),
('KH051', 'LN789022', 'tranvanlinh'),
('KH052', 'MO345688', 'phamdanghuy'),
('KH053', 'NP901244', 'nguyentranthuy'),
('KH054', 'OQ567899', 'dovuhoang'),
('KH055', 'PR123467', 'nguyenthidiem'),
('KH056', 'QS789023', 'lequanganh'),
('KH057', 'RT345689', 'tranthiminhhien'),
('KH058', 'SU901245', 'nguyenduckhoa'),
('KH059', 'TV567900', 'phambichhang'),
('KH060', 'UW123468', 'tranminhduc'),
('KH061', 'VX789024', 'nguyenthanhnga'),
('KH062', 'WY345690', 'lequanghung'),
('KH063', 'XZ901246', 'nguyenthanhhuyen'),
('KH064', 'YA567901', 'phamquangtrung'),
('KH065', 'ZB123469', 'hoangthithao'),
('KH066', 'CC789025', 'dovanviet'),
('KH067', 'DD345691', 'nguyenthiyen'),
('KH068', 'EE901247', 'trandaiduong'),
('KH069', 'FF567902', 'lethanhthao'),
('KH070', 'GG123470', 'nguyenbaoquang'),
('KH071', 'HH789026', 'phamthithuytrang'),
('KH072', 'II345692', 'nguyenvanthinh'),
('KH073', 'JJ901248', 'tranvanthang'),
('KH074', 'KK567903', 'lethianhdao'),
('KH075', 'LL123471', 'nguyenthanhhai'),
('KH076', 'MM789027', 'tranvanhieu'),
('KH077', 'NN345693', 'phamthihuonggiang'),
('KH078', 'OO901249', 'nguyenvantu'),
('KH079', 'PP567904', 'dothimyanh'),
('KH080', 'QQ123472', 'hoangminhkhai'),
('KH081', 'RR789028', 'nguyenthithanhtruyen'),
('KH082', 'SS345694', 'tranlehuu'),
('KH083', 'TT901250', 'lethibichngoc'),
('KH084', 'UU567905', 'nguyenthanhphong'),
('KH085', 'VV123473', 'phamvanquang'),
('KH086', 'WW789029', 'nguyenthingocthao'),
('KH087', 'XX345695', 'tranhuonggiang'),
('KH088', 'YY901251', 'lethanhdat'),
('KH089', 'ZZ567906', 'nguyenthithanhtuyen'),
('KH090', 'AD123474', 'phanvanthuan'),
('KH091', 'BE789030', 'nguyenthuhoai'),
('KH092', 'CF345696', 'tranvanhai'),
('KH093', 'DG901252', 'lethuytrang'),
('KH094', 'EH567907', 'nguyenhoangnam'),
('KH095', 'FI123475', 'phamanhthao'),
('KH096', 'GJ789031', 'nguyenthanhngoc'),
('KH097', 'HK345697', 'tranvannhan'),
('KH098', 'IL901253', 'lethanhhieu'),
('KH099', 'JM567908', 'nguyenthihaiduong'),
('KH100', 'KN123476', 'tranminhanh');
--
--

INSERT INTO NhanVienKiemSoat (MaNV, TaiKhoan) VALUES
('NV001', 'nguyenthihoangyen'),
('NV002', 'phamanhlinh'),
('NV003', 'lethidieulinh'),
('NV004', 'nguyenvandat'),
('NV005', 'tranvanhuy'),
('NV006', 'nguyenthicamlinh'),
('NV007', 'dovanminh'),
('NV008', 'hoangthuyquynh'),
('NV009', 'nguyenthehai'),
('NV010', 'tranthingocanh'),
('NV011', 'phamhoanglong'),
('NV012', 'nguyenthithanhmai'),
('NV013', 'leminhhoang'),
('NV014', 'nguyenthithuongthuong'),
('NV015', 'tranvanduy'),
('NV016', 'hoangthanhson'),
('NV017', 'nguyenthithanhloan'),
('NV018', 'phanminhduc'),
('NV019', 'nguyenthithanhtrang'),
('NV020', 'dovanhoa'),
('NV021', 'tranvannguyen'),
('NV022', 'lethithuyhang'),
('NV023', 'nguyenthanhhaiyen'),
('NV024', 'phamanhdao'),
('NV025', 'nguyenthidiemhuong'),
('NV026', 'tranvanlam'),
('NV027', 'lethithuha'),
('NV028', 'nguyenthanhduy'),
('NV029', 'phamvandai'),
('NV030', 'nguyenthikieuanh'),
('NV031', 'tranvanthanglong'),
('NV032', 'lethithuongmai'),
('NV033', 'nguyenthanhphuong'),
('NV034', 'phamvanlinh'),
('NV035', 'nguyenthithuonguyen'),
('NV036', 'tranvantuan'),
('NV037', 'lethithuhoa'),
('NV038', 'nguyenthanhkhoa'),
('NV039', 'phamthihuynhhuong'),
('NV040', 'nguyenvancuong'),
('NV041', 'tranthingochuyen'),
('NV042', 'lethanhhien_a'),
('NV043', 'nguyenthanhtrung'),
('NV044', 'phamvanminh_a'),
('NV045', 'nguyenthihuongly'),
('NV046', 'tranvanphuong_a'),
('NV047', 'lethithuong'),
('NV048', 'nguyenthanhtam'),
('NV049', 'phamnhatnam'),
('NV050', 'tranvanhieu_a'),
('NV051', 'nguyenthibichloan'),
('NV052', 'levanlinh'),
('NV053', 'nguyenthihoangthao'),
('NV054', 'phamvanduong'),
('NV055', 'tranvandung'),
('NV056', 'nguyenthithuonglan'),
('NV057', 'leminhquang'),
('NV058', 'nguyenthanhhoa_a'),
('NV059', 'dovanloc'),
('NV060', 'tranvanthuy'),
('NV061', 'nguyenthithanhtuyen_a'),
('NV062', 'lethanhgiang'),
('NV063', 'nguyenthibichhang'),
('NV064', 'phamvanhuy_a'),
('NV065', 'tranvannghia'),
('NV066', 'nguyenthuhoai_a'),
('NV067', 'lethithanhanh'),
('NV068', 'nguyenvancuong_a'),
('NV069', 'phamanhthao_a'),
('NV070', 'tranvanthang_b'),
('NV071', 'nguyenthingoclinh'),
('NV072', 'lethanhlong'),
('NV073', 'nguyentranthuy_a'),
('NV074', 'phamvanquang_a'),
('NV075', 'tranvanquy_b'),
('NV076', 'nguyenthithanhbinh'),
('NV077', 'leminhanh'),
('NV078', 'nguyenthithuylinh'),
('NV079', 'phamvanhung_a'),
('NV080', 'tranvanthanh_b'),
('NV081', 'nguyenthibichhong'),
('NV082', 'levanduc'),
('NV083', 'nguyenthanhhoa_b'),
('NV084', 'phamminhtrung'),
('NV085', 'tranvancuong_b'),
('NV086', 'nguyenthithanhnguyen'),
('NV087', 'lehoanghai_a'),
('NV088', 'nguyenthithuonghoai'),
('NV089', 'phamanhthao_b'),
('NV090', 'tranvanduy_b'),
('NV091', 'nguyenthibichthuy'),
('NV092', 'lehoangviet_a'),
('NV093', 'nguyenthanhhoa_c'),
('NV094', 'phamvanlam'),
('NV095', 'tranvanlong_b'),
('NV096', 'nguyenthithanhngoc_a'),
('NV097', 'leminhquy'),
('NV098', 'nguyenthihuong_b'),
('NV099', 'phamvananh'),
('NV100', 'tranvanlinh_b');

--
INSERT INTO BaoCao (MaBaoCao, NgayBaoCao, NoiDungBaoCao, MaNV, TrangThai) VALUES
('BC001', '2025-01-01', N'Báo cáo kiểm tra an toàn chuyến bay VN101. Tình trạng tốt.', 'NV001', N'Đã xử lý'),
('BC002', '2025-01-02', N'Phát hiện lỗi nhỏ trên hệ thống giải trí chuyến bay VN102. Đã khắc phục.', 'NV002', N'Chưa xử lý'),
('BC003', '2025-01-03', N'Kiểm tra định kỳ trang thiết bị phòng cháy chữa cháy trên VN103. Đạt yêu cầu.', 'NV003', N'Đã xử lý'),
('BC004', '2025-01-04', N'Báo cáo sự cố mất điện tạm thời tại khu vực sảnh chờ A.', 'NV004', N'Chưa xử lý'),
('BC005', '2025-01-05', N'Kiểm tra vệ sinh buồng lái chuyến bay VN105. Hoàn thành.', 'NV005', N'Đã xử lý'),
('BC006', '2025-01-06', N'Báo cáo về việc thiếu tài liệu hướng dẫn an toàn trên một số ghế.', 'NV006', N'Chưa xử lý'),
('BC007', '2025-01-07', N'Kiểm tra hệ thống điều hòa không khí tại khu vực VIP. Hoạt động ổn định.', 'NV007', N'Đã xử lý'),
('BC008', '2025-01-08', N'Phát hiện vết nứt nhỏ trên cửa khoang hành lý VN108. Cần kiểm tra thêm.', 'NV008', N'Chưa xử lý'),
('BC009', '2025-01-09', N'Báo cáo về tình hình giám sát an ninh tại cổng B3. Bình thường.', 'NV009', N'Đã xử lý'),
('BC010', '2025-01-10', N'Kiểm tra hiệu suất đèn tín hiệu đường băng. Có một đèn cần thay thế.', 'NV010', N'Chưa xử lý'),
('BC011', '2025-01-11', N'Báo cáo kiểm tra hệ thống thông gió tại nhà ga T1. Đạt yêu cầu.', 'NV011', N'Đã xử lý'),
('BC012', '2025-01-12', N'Phát hiện ghế hành khách bị hỏng trên chuyến bay VN112. Đang chờ sửa chữa.', 'NV012', N'Chưa xử lý'),
('BC013', '2025-01-13', N'Kiểm tra độ bền của dây an toàn trên VN113. Tất cả đều tốt.', 'NV013', N'Đã xử lý'),
('BC014', '2025-01-14', N'Báo cáo về việc thiếu nước sạch tại một nhà vệ sinh công cộng.', 'NV014', N'Chưa xử lý'),
('BC015', '2025-01-15', N'Kiểm tra hệ thống thoát hiểm của máy bay VN115. Đã thử nghiệm thành công.', 'NV015', N'Đã xử lý'),
('BC016', '2025-01-16', N'Phát hiện lỗi hiển thị thông tin chuyến bay trên bảng điện tử.', 'NV016', N'Chưa xử lý'),
('BC017', '2025-01-17', N'Báo cáo kiểm tra thiết bị định vị trên VN117. Hoạt động chính xác.', 'NV017', N'Đã xử lý'),
('BC018', '2025-01-18', N'Kiểm tra hệ thống âm thanh thông báo tại khu vực chờ. Có tiếng rè.', 'NV018', N'Chưa xử lý'),
('BC019', '2025-01-19', N'Báo cáo về việc thực hiện quy trình kiểm tra hành lý xách tay.', 'NV019', N'Đã xử lý'),
('BC020', '2025-01-20', N'Phát hiện cửa thoát hiểm bị kẹt nhẹ trên máy bay VN120.', 'NV020', N'Chưa xử lý'),
('BC021', '2025-01-21', N'Kiểm tra hoạt động của thang cuốn tại khu vực sảnh đến. Bình thường.', 'NV021', N'Đã xử lý'),
('BC022', '2025-01-22', N'Báo cáo về việc thiếu nhân viên hướng dẫn tại khu vực làm thủ tục.', 'NV022', N'Chưa xử lý'),
('BC023', '2025-01-23', N'Kiểm tra chất lượng bữa ăn trên chuyến bay VN123. Đảm bảo vệ sinh.', 'NV023', N'Đã xử lý'),
('BC024', '2025-01-24', N'Phát hiện camera giám sát tại khu vực nhà ga bị lỗi.', 'NV024', N'Chưa xử lý'),
('BC025', '2025-01-25', N'Báo cáo kiểm tra hệ thống cấp nhiên liệu cho máy bay.', 'NV025', N'Đã xử lý'),
('BC026', '2025-01-26', N'Kiểm tra pin của thiết bị bộ đàm nhân viên. Một số pin yếu.', 'NV026', N'Chưa xử lý'),
('BC027', '2025-01-27', N'Báo cáo về việc tuân thủ quy định an toàn khi vận chuyển hàng hóa.', 'NV027', N'Đã xử lý'),
('BC028', '2025-01-28', N'Phát hiện lỗi trên hệ thống đèn chiếu sáng khu vực sân đỗ.', 'NV028', N'Chưa xử lý'),
('BC029', '2025-01-29', N'Kiểm tra áp suất lốp máy bay VN129. Đạt tiêu chuẩn.', 'NV029', N'Đã xử lý'),
('BC030', '2025-01-30', N'Báo cáo về việc xử lý rác thải tại sân bay. Cần cải thiện.', 'NV030', N'Chưa xử lý'),
('BC031', '2025-01-31', N'Kiểm tra hệ thống báo động cháy tại phòng điều khiển không lưu.', 'NV031', N'Đã xử lý'),
('BC032', '2025-02-01', N'Phát hiện vết bẩn lớn trên sàn nhà ga. Đã yêu cầu dọn dẹp.', 'NV032', N'Chưa xử lý'),
('BC033', '2025-02-02', N'Báo cáo kiểm tra hệ thống cấp oxy khẩn cấp trên VN133.', 'NV033', N'Đã xử lý'),
('BC034', '2025-02-03', N'Kiểm tra các biển báo thoát hiểm. Có một biển báo bị mờ.', 'NV034', N'Chưa xử lý'),
('BC035', '2025-02-04', N'Báo cáo về việc tuân thủ quy trình kiểm tra an ninh hành khách.', 'NV035', N'Đã xử lý'),
('BC036', '2025-02-05', N'Phát hiện lỗi trên hệ thống định vị GPS của xe phục vụ sân bay.', 'NV036', N'Chưa xử lý'),
('BC037', '2025-02-06', N'Kiểm tra hiệu chuẩn thiết bị đo tốc độ gió. Chính xác.', 'NV037', N'Đã xử lý'),
('BC038', '2025-02-07', N'Báo cáo về việc thiếu đồ dùng vệ sinh trong nhà vệ sinh máy bay.', 'NV038', N'Chưa xử lý'),
('BC039', '2025-02-08', N'Kiểm tra hoạt động của hệ thống liên lạc nội bộ.', 'NV039', N'Đã xử lý'),
('BC040', '2025-02-09', N'Phát hiện lỗi phần mềm trên máy tính kiểm soát không lưu.', 'NV040', N'Chưa xử lý'),
('BC041', '2025-02-10', N'Báo cáo kiểm tra hệ thống cấp phát thẻ lên máy bay tự động.', 'NV041', N'Đã xử lý'),
('BC042', '2025-02-11', N'Kiểm tra mức độ tiếng ồn tại khu vực bãi đỗ máy bay.', 'NV042', N'Chưa xử lý'),
('BC043', '2025-02-12', N'Báo cáo về việc kiểm tra chất lượng nước uống trên chuyến bay.', 'NV043', N'Đã xử lý'),
('BC044', '2025-02-13', N'Phát hiện lỗi trên hệ thống chiếu sáng khu vực nhà ga chính.', 'NV044', N'Chưa xử lý'),
('BC045', '2025-02-14', N'Kiểm tra độ chặt của ghế ngồi hành khách trên VN145. Tốt.', 'NV045', N'Đã xử lý'),
('BC046', '2025-02-15', N'Báo cáo về việc thiếu hướng dẫn viên hỗ trợ hành khách khuyết tật.', 'NV046', N'Chưa xử lý'),
('BC047', '2025-02-16', N'Kiểm tra hệ thống sưởi ấm tại khu vực chờ lạnh. Hoạt động hiệu quả.', 'NV047', N'Đã xử lý'),
('BC048', '2025-02-17', N'Phát hiện lỗi trên hệ thống điều khiển cửa ra vào sân bay.', 'NV048', N'Chưa xử lý'),
('BC049', '2025-02-18', N'Báo cáo kiểm tra tình trạng đường băng sau mưa lớn.', 'NV049', N'Đã xử lý'),
('BC050', '2025-02-19', N'Kiểm tra các thiết bị y tế khẩn cấp trên máy bay. Đầy đủ.', 'NV050', N'Chưa xử lý'),
('BC051', '2025-02-20', N'Báo cáo về việc tuân thủ quy định về vận chuyển chất lỏng.', 'NV051', N'Đã xử lý'),
('BC052', '2025-02-21', N'Phát hiện lỗi trên hệ thống âm thanh cabin máy bay.', 'NV052', N'Chưa xử lý'),
('BC053', '2025-02-22', N'Kiểm tra nhiệt độ phòng điều khiển. Đạt tiêu chuẩn.', 'NV053', N'Đã xử lý'),
('BC054', '2025-02-23', N'Báo cáo về việc thiếu xe đẩy hành lý tại khu vực nhận hành lý.', 'NV054', N'Chưa xử lý'),
('BC055', '2025-02-24', N'Kiểm tra hệ thống radar giám sát không phận. Hoạt động ổn định.', 'NV055', N'Đã xử lý'),
('BC056', '2025-02-25', N'Phát hiện rò rỉ nước nhỏ tại khu vực kỹ thuật sân bay.', 'NV056', N'Chưa xử lý'),
('BC057', '2025-02-26', N'Báo cáo về việc kiểm tra định kỳ các thiết bị bay không người lái.', 'NV057', N'Đã xử lý'),
('BC058', '2025-02-27', N'Kiểm tra đèn chiếu sáng tại các khu vực đậu xe sân bay. Có vài đèn hỏng.', 'NV058', N'Chưa xử lý'),
('BC059', '2025-02-28', N'Báo cáo về việc vệ sinh khu vực bếp trên máy bay.', 'NV059', N'Đã xử lý'),
('BC060', '2025-03-01', N'Phát hiện lỗi trên hệ thống liên lạc giữa phi công và đài kiểm soát.', 'NV060', N'Chưa xử lý'),
('BC061', '2025-03-02', N'Kiểm tra hệ thống báo động khói tại nhà ga T2. Đạt yêu cầu.', 'NV061', N'Đã xử lý'),
('BC062', '2025-03-03', N'Báo cáo về việc thiếu giấy vệ sinh trong một số nhà vệ sinh.', 'NV062', N'Chưa xử lý'),
('BC063', '2025-03-04', N'Kiểm tra chất lượng gối và chăn trên chuyến bay dài. Tốt.', 'NV063', N'Đã xử lý'),
('BC064', '2025-03-05', N'Phát hiện lỗi trên màn hình hiển thị thông tin chuyến bay tại quầy.', 'NV064', N'Chưa xử lý'),
('BC065', '2025-03-06', N'Báo cáo kiểm tra các thiết bị hỗ trợ người già và trẻ em.', 'NV065', N'Đã xử lý'),
('BC066', '2025-03-07', N'Kiểm tra độ an toàn của đường dành cho xe cộ trong sân bay.', 'NV066', N'Chưa xử lý'),
('BC067', '2025-03-08', N'Báo cáo về việc tuân thủ quy định về hành lý quá khổ.', 'NV067', N'Đã xử lý'),
('BC068', '2025-03-09', N'Phát hiện lỗi trên hệ thống nhận diện khuôn mặt tại cổng an ninh.', 'NV068', N'Chưa xử lý'),
('BC069', '2025-03-10', N'Kiểm tra tình trạng hoạt động của các xe cứu hỏa sân bay.', 'NV069', N'Đã xử lý'),
('BC070', '2025-03-11', N'Báo cáo về việc thiếu thông tin về các chuyến bay bị hoãn/hủy.', 'NV070', N'Chưa xử lý'),
('BC071', '2025-03-12', N'Kiểm tra hệ thống định vị của máy bay khi hạ cánh.', 'NV071', N'Đã xử lý'),
('BC072', '2025-03-13', N'Phát hiện mùi lạ tại khu vực nhà vệ sinh gần cổng C.', 'NV072', N'Chưa xử lý'),
('BC073', '2025-03-14', N'Báo cáo kiểm tra chất lượng không khí trong nhà ga.', 'NV073', N'Đã xử lý'),
('BC074', '2025-03-15', N'Kiểm tra các thiết bị tập thể dục tại phòng chờ hạng sang.', 'NV074', N'Chưa xử lý'),
('BC075', '2025-03-16', N'Báo cáo về việc tuân thủ quy định về vận chuyển động vật cảnh.', 'NV075', N'Đã xử lý'),
('BC076', '2025-03-17', N'Phát hiện lỗi trên hệ thống cổng tự động lên máy bay.', 'NV076', N'Chưa xử lý'),
('BC077', '2025-03-18', N'Kiểm tra hiệu chuẩn thiết bị đo độ ẩm không khí.', 'NV077', N'Đã xử lý'),
('BC078', '2025-03-19', N'Báo cáo về việc thiếu ổ cắm sạc điện thoại tại khu vực chờ.', 'NV078', N'Chưa xử lý'),
('BC079', '2025-03-20', N'Kiểm tra hoạt động của hệ thống báo động xâm nhập.', 'NV079', N'Đã xử lý'),
('BC080', '2025-03-21', N'Phát hiện lỗi trên hệ thống điều khiển ánh sáng đường băng.', 'NV080', N'Chưa xử lý'),
('BC081', '2025-03-22', N'Báo cáo kiểm tra các xe bus vận chuyển hành khách nội bộ.', 'NV081', N'Đã xử lý'),
('BC082', '2025-03-23', N'Kiểm tra độ chắc chắn của lan can tại khu vực cầu thang.', 'NV082', N'Chưa xử lý'),
('BC083', '2025-03-24', N'Báo cáo về việc kiểm tra chất lượng đồ uống tại quầy bar sân bay.', 'NV083', N'Đã xử lý'),
('BC084', '2025-03-25', N'Phát hiện lỗi trên hệ thống thang máy khu vực hành chính.', 'NV084', N'Chưa xử lý'),
('BC085', '2025-03-26', N'Kiểm tra các tủ thuốc y tế khẩn cấp tại các điểm.', 'NV085', N'Đã xử lý'),
('BC086', '2025-03-27', N'Báo cáo về việc thiếu bản đồ sân bay tại một số vị trí.', 'NV086', N'Chưa xử lý'),
('BC087', '2025-03-28', N'Kiểm tra hệ thống camera giám sát khu vực bãi đỗ xe.', 'NV087', N'Đã xử lý'),
('BC088', '2025-03-29', N'Phát hiện lỗi trên hệ thống phát thanh khẩn cấp.', 'NV088', N'Chưa xử lý'),
('BC089', '2025-03-30', N'Báo cáo kiểm tra tình trạng các phương tiện cứu hộ sân bay.', 'NV089', N'Đã xử lý'),
('BC090', '2025-03-31', N'Kiểm tra nhiệt độ của các tủ lạnh bảo quản thực phẩm.', 'NV090', N'Chưa xử lý'),
('BC091', '2025-04-01', N'Báo cáo về việc tuân thủ quy định về trang phục nhân viên.', 'NV091', N'Đã xử lý'),
('BC092', '2025-04-02', N'Phát hiện lỗi trên hệ thống cung cấp điện dự phòng.', 'NV092', N'Chưa xử lý'),
('BC093', '2025-04-03', N'Kiểm tra các biển chỉ dẫn trong nhà ga. Tất cả rõ ràng.', 'NV093', N'Đã xử lý'),
('BC094', '2025-04-04', N'Báo cáo về việc thiếu thùng rác tại khu vực ăn uống.', 'NV094', N'Chưa xử lý'),
('BC095', '2025-04-05', N'Kiểm tra độ sạch của thảm trải sàn tại khu vực chờ.', 'NV095', N'Đã xử lý'),
('BC096', '2025-04-06', N'Phát hiện lỗi trên hệ thống khóa cửa phòng điều hành.', 'NV096', N'Chưa xử lý'),
('BC097', '2025-04-07', N'Báo cáo kiểm tra chất lượng dịch vụ WiFi miễn phí tại sân bay.', 'NV097', N'Đã xử lý'),
('BC098', '2025-04-08', N'Kiểm tra các lối đi dành cho người khuyết tật. Đảm bảo tiếp cận.', 'NV098', N'Chưa xử lý'),
('BC099', '2025-04-09', N'Báo cáo về việc tuân thủ quy định về giới hạn tốc độ xe.', 'NV099', N'Đã xử lý'),
('BC100', '2025-04-10', N'Phát hiện lỗi trên hệ thống hiển thị giờ bay quốc tế.', 'NV100', N'Chưa xử lý');


--

INSERT INTO ChuyenBay (MaChuyenBay, TinhTrangChuyenBay, GioBay, GioDen, DiaDiemDau, DiaDiemCuoi) VALUES
('VN201', N'Đúng giờ', '2025-07-10 08:00:00', '2025-07-10 10:00:00', N'Thành phố Hồ Chí Minh', N'Hà Nội'),
('VN202', N'Đã khởi hành', '2025-07-10 11:30:00', '2025-07-10 13:30:00', N'Hà Nội', N'Đà Nẵng'),
('VN203', N'Chưa khởi hành', '2025-07-11 15:00:00', '2025-07-11 17:00:00', N'Thành phố Hồ Chí Minh', N'Phú Quốc'),
('VN204', N'Đúng giờ', '2025-07-11 19:00:00', '2025-07-11 21:30:00', N'Đà Nẵng', N'Thành phố Hồ Chí Minh'),
('VN205', N'Đã hạ cánh', '2025-07-12 09:00:00', '2025-07-12 11:00:00', N'Hà Nội', N'Cần Thơ');

--
--
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN201
-- Hạng nhất (15 ghế: 1-15)
(1, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(2, 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
(3, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(4, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(5, 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
(6, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(7, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(8, 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
(9, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(10, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(11, 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
(12, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(13, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
(14, 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
(15, 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế: 16-50)
(16, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(17, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(18, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(19, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(20, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(21, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(22, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(23, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(24, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(25, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(26, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(27, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(28, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(29, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(30, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(31, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(32, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(33, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(34, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(35, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(36, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(37, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(38, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(39, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(40, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(41, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(42, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(43, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(44, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(45, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(46, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(47, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
(48, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(49, 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
(50, 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
-- Phổ thông (100 ghế: 51-150)
(51, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(52, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(53, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(54, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(55, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(56, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(57, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(58, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(59, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(60, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(61, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(62, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(63, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(64, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(65, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(66, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(67, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(68, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(69, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(70, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(71, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(72, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(73, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(74, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(75, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(76, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(77, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(78, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(79, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(80, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(81, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(82, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(83, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(84, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(85, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(86, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(87, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(88, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(89, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(90, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(91, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(92, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(93, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(94, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(95, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(96, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(97, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(98, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(99, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(100, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(101, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(102, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(103, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(104, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(105, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(106, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(107, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(108, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(109, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(110, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(111, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(112, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(113, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(114, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(115, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(116, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(117, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(118, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(119, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(120, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(121, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(122, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(123, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(124, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(125, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(126, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(127, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(128, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(129, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(130, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(131, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(132, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(133, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(134, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(135, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(136, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(137, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(138, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(139, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(140, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(141, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(142, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(143, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(144, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(145, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(146, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(147, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(148, 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
(149, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
(150, 'VN201', 1000000.00, N'Phổ thông', N'có sẵn');
----
----
INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH) VALUES
-- Hạng nhất (5 ghế đã đặt)
('DV001', '2025-05-18', '2025-07-11', N'Đã thanh toán', 2, 3000000.00, 'VN201', 'KH001'),
('DV002', '2025-05-03', '2025-07-11', N'Đã thanh toán', 5, 3000000.00, 'VN201', 'KH002'),
('DV003', '2025-05-11', '2025-07-11', N'Đã thanh toán', 8, 3000000.00, 'VN201', 'KH003'),
('DV004', '2025-05-07', '2025-07-11', N'Đã thanh toán', 11, 3000000.00, 'VN201', 'KH004'),
('DV005', '2025-05-20', '2025-07-11', N'Đã thanh toán', 14, 3000000.00, 'VN201', 'KH005'),

-- Thương gia (9 ghế đã đặt)
('DV006', '2025-05-02', '2025-07-11', N'Đã thanh toán', 17, 2000000.00, 'VN201', 'KH006'),
('DV007', '2025-05-15', '2025-07-11', N'Đã thanh toán', 20, 2000000.00, 'VN201', 'KH007'),
('DV008', '2025-05-09', '2025-07-11', N'Đã thanh toán', 23, 2000000.00, 'VN201', 'KH008'),
('DV009', '2025-05-01', '2025-07-11', N'Đã thanh toán', 26, 2000000.00, 'VN201', 'KH009'),
('DV010', '2025-05-17', '2025-07-11', N'Đã thanh toán', 29, 2000000.00, 'VN201', 'KH010'),
('DV011', '2025-05-06', '2025-07-11', N'Đã thanh toán', 32, 2000000.00, 'VN201', 'KH011'),
('DV012', '2025-05-13', '2025-07-11', N'Đã thanh toán', 35, 2000000.00, 'VN201', 'KH012'),
('DV013', '2025-05-04', '2025-07-11', N'Đã thanh toán', 38, 2000000.00, 'VN201', 'KH013'),
('DV014', '2025-05-19', '2025-07-11', N'Đã thanh toán', 41, 2000000.00, 'VN201', 'KH014'),

-- Phổ thông (28 ghế đã đặt)
('DV015', '2025-05-08', '2025-07-11', N'Đã thanh toán', 52, 1000000.00, 'VN201', 'KH015'),
('DV016', '2025-05-21', '2025-07-11', N'Đã thanh toán', 55, 1000000.00, 'VN201', 'KH016'),
('DV017', '2025-05-05', '2025-07-11', N'Đã thanh toán', 58, 1000000.00, 'VN201', 'KH017'),
('DV018', '2025-05-12', '2025-07-11', N'Đã thanh toán', 61, 1000000.00, 'VN201', 'KH018'),
('DV019', '2025-05-10', '2025-07-11', N'Đã thanh toán', 64, 1000000.00, 'VN201', 'KH019'),
('DV020', '2025-05-03', '2025-07-11', N'Đã thanh toán', 67, 1000000.00, 'VN201', 'KH020'),
('DV021', '2025-05-16', '2025-07-11', N'Đã thanh toán', 70, 1000000.00, 'VN201', 'KH021'),
('DV022', '2025-05-07', '2025-07-11', N'Đã thanh toán', 73, 1000000.00, 'VN201', 'KH022'),
('DV023', '2025-05-22', '2025-07-11', N'Đã thanh toán', 76, 1000000.00, 'VN201', 'KH023'),
('DV024', '2025-05-01', '2025-07-11', N'Đã thanh toán', 79, 1000000.00, 'VN201', 'KH024'),
('DV025', '2025-05-18', '2025-07-11', N'Đã thanh toán', 82, 1000000.00, 'VN201', 'KH025'),
('DV026', '2025-05-02', '2025-07-11', N'Đã thanh toán', 85, 1000000.00, 'VN201', 'KH026'),
('DV027', '2025-05-15', '2025-07-11', N'Đã thanh toán', 88, 1000000.00, 'VN201', 'KH027'),
('DV028', '2025-05-09', '2025-07-11', N'Đã thanh toán', 91, 1000000.00, 'VN201', 'KH028'),
('DV029', '2025-05-04', '2025-07-11', N'Đã thanh toán', 94, 1000000.00, 'VN201', 'KH029'),
('DV030', '2025-05-19', '2025-07-11', N'Đã thanh toán', 97, 1000000.00, 'VN201', 'KH030'),
('DV031', '2025-05-08', '2025-07-11', N'Đã thanh toán', 100, 1000000.00, 'VN201', 'KH031'),
('DV032', '2025-05-21', '2025-07-11', N'Đã thanh toán', 103, 1000000.00, 'VN201', 'KH032'),
('DV033', '2025-05-05', '2025-07-11', N'Đã thanh toán', 106, 1000000.00, 'VN201', 'KH033'),
('DV034', '2025-05-12', '2025-07-11', N'Đã thanh toán', 109, 1000000.00, 'VN201', 'KH034'),
('DV035', '2025-05-10', '2025-07-11', N'Đã thanh toán', 112, 1000000.00, 'VN201', 'KH035'),
('DV036', '2025-05-03', '2025-07-11', N'Đã thanh toán', 115, 1000000.00, 'VN201', 'KH036'),
('DV037', '2025-05-16', '2025-07-11', N'Đã thanh toán', 118, 1000000.00, 'VN201', 'KH037'),
('DV038', '2025-05-07', '2025-07-11', N'Đã thanh toán', 121, 1000000.00, 'VN201', 'KH038'),
('DV039', '2025-05-22', '2025-07-11', N'Đã thanh toán', 124, 1000000.00, 'VN201', 'KH039'),
('DV040', '2025-05-01', '2025-07-11', N'Đã thanh toán', 133, 1000000.00, 'VN201', 'KH040'),
('DV041', '2025-05-18', '2025-07-11', N'Đã thanh toán', 136, 1000000.00, 'VN201', 'KH041'),
('DV042', '2025-05-02', '2025-07-11', N'Đã thanh toán', 148, 1000000.00, 'VN201', 'KH042');
-- Ghế cho chuyến bay VN202
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN202
-- Hạng nhất (15 ghế)
(1, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(2, 'VN202', 3000000.00, N'Hạng nhất', N'đã đặt'),
(3, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(4, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(5, 'VN202', 3000000.00, N'Hạng nhất', N'đã đặt'),
(6, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(7, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(8, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(9, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(10, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(11, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(12, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(13, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(14, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
(15, 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế)
(16, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(17, 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
(18, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(19, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(20, 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
(21, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(22, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(23, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(24, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(25, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(26, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(27, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(28, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(29, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(30, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(31, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(32, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(33, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(34, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(35, 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
(36, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(37, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(38, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(39, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(40, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(41, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(42, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(43, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(44, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(45, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(46, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(47, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(48, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(49, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
(50, 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
-- Phổ thông (100 ghế)
(51, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(52, 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
(53, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(54, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(55, 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
(56, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(57, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(58, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(59, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(60, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(61, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(62, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(63, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(64, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(65, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(66, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(67, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(68, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(69, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(70, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(71, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(72, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(73, 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
(74, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(75, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(76, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(77, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(78, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(79, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(80, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(81, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(82, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(83, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(84, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(85, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(86, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(87, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(88, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(89, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(90, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(91, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(92, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(93, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(94, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(95, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(96, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(97, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(98, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(99, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(100, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(101, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(102, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(103, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(104, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(105, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(106, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(107, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(108, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(109, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(110, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(111, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(112, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(113, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(114, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(115, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(116, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(117, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(118, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(119, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(120, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(121, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(122, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(123, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(124, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(125, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(126, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(127, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(128, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(129, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(130, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(131, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(132, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(133, 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
(134, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(135, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(136, 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
(137, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(138, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(139, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(140, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(141, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(142, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(143, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(144, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(145, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(146, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(147, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(148, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(149, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
(150, 'VN202', 1000000.00, N'Phổ thông', N'có sẵn');

INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH) VALUES
-- Hạng nhất (2 ghế đã đặt)
('DV043', '2025-05-14', '2025-07-11', N'Đã thanh toán', 2, 3000000.00, 'VN202', 'KH001'),
('DV044', '2025-05-09', '2025-07-11', N'Đã thanh toán', 5, 3000000.00, 'VN202', 'KH002'),

-- Thương gia (3 ghế đã đặt)
('DV045', '2025-05-03', '2025-07-11', N'Đã thanh toán', 17, 2000000.00, 'VN202', 'KH003'),
('DV046', '2025-05-17', '2025-07-11', N'Đã thanh toán', 20, 2000000.00, 'VN202', 'KH004'),
('DV047', '2025-05-06', '2025-07-11', N'Đã thanh toán', 35, 2000000.00, 'VN202', 'KH005'),

-- Phổ thông (5 ghế đã đặt)
('DV048', '2025-05-11', '2025-07-11', N'Đã thanh toán', 52, 1000000.00, 'VN202', 'KH006'),
('DV049', '2025-05-02', '2025-07-11', N'Đã thanh toán', 55, 1000000.00, 'VN202', 'KH007'),
('DV050', '2025-05-20', '2025-07-11', N'Đã thanh toán', 73, 1000000.00, 'VN202', 'KH008'),
('DV051', '2025-05-08', '2025-07-11', N'Đã thanh toán', 133, 1000000.00, 'VN202', 'KH009'),
('DV052', '2025-05-13', '2025-07-11', N'Đã thanh toán', 136, 1000000.00, 'VN202', 'KH010');
---
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN203
-- Hạng nhất (15 ghế)
(1, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(2, 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
(3, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(4, 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
(5, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(6, 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
(7, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(8, 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
(9, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(10, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(11, 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
(12, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(13, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(14, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
(15, 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế)
(16, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-01
(17, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-02
(18, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-03
(19, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(20, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-05
(21, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-06
(22, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(23, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-08
(24, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-09
(25, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(26, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-11
(27, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-12
(28, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(29, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-14
(30, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-15
(31, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(32, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-17
(33, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-18
(34, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(35, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-20
(36, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-21
(37, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(38, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-23
(39, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-24
(40, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(41, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-26
(42, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-27
(43, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(44, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-29
(45, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-30
(46, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(47, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-32
(48, 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
(49, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-34
(50, 'VN203', 2000000.00, N'Thương gia', N'đã đặt'), -- B-35
-- Phổ thông (100 ghế)
(51, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-01
(52, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-02
(53, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-03
(54, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(55, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-05
(56, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-06
(57, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(58, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-08
(59, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-09
(60, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(61, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-11
(62, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-12
(63, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(64, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-14
(65, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-15
(66, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(67, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-17
(68, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-18
(69, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(70, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- C-20
(71, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-01
(72, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(73, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-03
(74, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-04
(75, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(76, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-06
(77, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-07
(78, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(79, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-09
(80, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-10
(81, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(82, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-12
(83, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-13
(84, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(85, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-15
(86, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-16
(87, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(88, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-18
(89, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- D-19
(90, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(91, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-01
(92, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-02
(93, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(94, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-04
(95, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-05
(96, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(97, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-07
(98, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-08
(99, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(100, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-10
(101, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-11
(102, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(103, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-13
(104, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-14
(105, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(106, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-16
(107, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-17
(108, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(109, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-19
(110, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- E-20
(111, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-01
(112, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-02
(113, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(114, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(115, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-05
(116, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(117, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(118, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-08
(119, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(120, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(121, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-11
(122, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(123, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(124, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-14
(125, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(126, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(127, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-17
(128, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(129, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(130, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- F-20
(131, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(132, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(133, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-03
(134, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(135, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(136, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-06
(137, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(138, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(139, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-09
(140, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(141, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(142, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-12
(143, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(144, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(145, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-15
(146, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(147, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(148, 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'), -- G-18
(149, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
(150, 'VN203', 1000000.00, N'Phổ thông', N'có sẵn');

---

INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH)
VALUES
-- Hạng nhất (5 ghế đã đặt)
('DV053', '2025-05-19', '2025-06-15', N'Đã thanh toán', 2, 3000000.00, 'VN203', 'KH001'),
('DV054', '2025-05-04', '2025-06-15', N'Đã thanh toán', 4, 3000000.00, 'VN203', 'KH002'),
('DV055', '2025-05-12', '2025-06-15', N'Đã thanh toán', 6, 3000000.00, 'VN203', 'KH003'),
('DV056', '2025-05-07', '2025-06-15', N'Đã thanh toán', 8, 3000000.00, 'VN203', 'KH004'),
('DV057', '2025-05-21', '2025-06-15', N'Đã thanh toán', 11, 3000000.00, 'VN203', 'KH005'),

-- Thương gia (25 ghế đã đặt)
('DV058', '2025-05-03', '2025-06-15', N'Đã thanh toán', 16, 2000000.00, 'VN203', 'KH006'),
('DV059', '2025-05-16', '2025-06-15', N'Đã thanh toán', 17, 2000000.00, 'VN203', 'KH007'),
('DV060', '2025-05-10', '2025-06-15', N'Đã thanh toán', 18, 2000000.00, 'VN203', 'KH008'),
('DV061', '2025-05-01', '2025-06-15', N'Đã thanh toán', 20, 2000000.00, 'VN203', 'KH009'),
('DV062', '2025-05-18', '2025-06-15', N'Đã thanh toán', 21, 2000000.00, 'VN203', 'KH010'),
('DV063', '2025-05-05', '2025-06-15', N'Đã thanh toán', 23, 2000000.00, 'VN203', 'KH011'),
('DV064', '2025-05-13', '2025-06-15', N'Đã thanh toán', 24, 2000000.00, 'VN203', 'KH012'),
('DV065', '2025-05-08', '2025-06-15', N'Đã thanh toán', 26, 2000000.00, 'VN203', 'KH013'),
('DV066', '2025-05-22', '2025-06-15', N'Đã thanh toán', 27, 2000000.00, 'VN203', 'KH014'),
('DV067', '2025-05-02', '2025-06-15', N'Đã thanh toán', 29, 2000000.00, 'VN203', 'KH015'),
('DV068', '2025-05-15', '2025-06-15', N'Đã thanh toán', 30, 2000000.00, 'VN203', 'KH016'),
('DV069', '2025-05-09', '2025-06-15', N'Đã thanh toán', 32, 2000000.00, 'VN203', 'KH017'),
('DV070', '2025-05-04', '2025-06-15', N'Đã thanh toán', 33, 2000000.00, 'VN203', 'KH018'),
('DV071', '2025-05-17', '2025-06-15', N'Đã thanh toán', 35, 2000000.00, 'VN203', 'KH019'),
('DV072', '2025-05-06', '2025-06-15', N'Đã thanh toán', 36, 2000000.00, 'VN203', 'KH020'),
('DV073', '2025-05-11', '2025-06-15', N'Đã thanh toán', 38, 2000000.00, 'VN203', 'KH021'),
('DV074', '2025-05-03', '2025-06-15', N'Đã thanh toán', 39, 2000000.00, 'VN203', 'KH022'),
('DV075', '2025-05-20', '2025-06-15', N'Đã thanh toán', 41, 2000000.00, 'VN203', 'KH023'),
('DV076', '2025-05-07', '2025-06-15', N'Đã thanh toán', 42, 2000000.00, 'VN203', 'KH024'),
('DV077', '2025-05-14', '2025-06-15', N'Đã thanh toán', 44, 2000000.00, 'VN203', 'KH025'),
('DV078', '2025-05-09', '2025-06-15', N'Đã thanh toán', 45, 2000000.00, 'VN203', 'KH026'),
('DV079', '2025-05-01', '2025-06-15', N'Đã thanh toán', 47, 2000000.00, 'VN203', 'KH027'),
('DV080', '2025-05-18', '2025-06-15', N'Đã thanh toán', 49, 2000000.00, 'VN203', 'KH028'),
('DV081', '2025-05-02', '2025-06-15', N'Đã thanh toán', 50, 2000000.00, 'VN203', 'KH029'),

-- Phổ thông (40 ghế đã đặt)
('DV082', '2025-05-15', '2025-06-15', N'Đã thanh toán', 51, 1000000.00, 'VN203', 'KH030'),
('DV083', '2025-05-09', '2025-06-15', N'Đã thanh toán', 52, 1000000.00, 'VN203', 'KH031'),
('DV084', '2025-05-04', '2025-06-15', N'Đã thanh toán', 53, 1000000.00, 'VN203', 'KH032'),
('DV085', '2025-05-17', '2025-06-15', N'Đã thanh toán', 55, 1000000.00, 'VN203', 'KH033'),
('DV086', '2025-05-06', '2025-06-15', N'Đã thanh toán', 56, 1000000.00, 'VN203', 'KH034'),
('DV087', '2025-05-11', '2025-06-15', N'Đã thanh toán', 58, 1000000.00, 'VN203', 'KH035'),
('DV088', '2025-05-03', '2025-06-15', N'Đã thanh toán', 59, 1000000.00, 'VN203', 'KH036'),
('DV089', '2025-05-20', '2025-06-15', N'Đã thanh toán', 61, 1000000.00, 'VN203', 'KH037'),
('DV090', '2025-05-07', '2025-06-15', N'Đã thanh toán', 62, 1000000.00, 'VN203', 'KH038'),
('DV091', '2025-05-14', '2025-06-15', N'Đã thanh toán', 64, 1000000.00, 'VN203', 'KH039'),
('DV092', '2025-05-09', '2025-06-15', N'Đã thanh toán', 65, 1000000.00, 'VN203', 'KH040'),
('DV093', '2025-05-01', '2025-06-15', N'Đã thanh toán', 67, 1000000.00, 'VN203', 'KH041'),
('DV094', '2025-05-18', '2025-06-15', N'Đã thanh toán', 68, 1000000.00, 'VN203', 'KH042'),
('DV095', '2025-05-02', '2025-06-15', N'Đã thanh toán', 70, 1000000.00, 'VN203', 'KH043'),
('DV096', '2025-05-15', '2025-06-15', N'Đã thanh toán', 71, 1000000.00, 'VN203', 'KH044'),
('DV097', '2025-05-09', '2025-06-15', N'Đã thanh toán', 73, 1000000.00, 'VN203', 'KH045'),
('DV098', '2025-05-04', '2025-06-15', N'Đã thanh toán', 74, 1000000.00, 'VN203', 'KH046'),
('DV099', '2025-05-17', '2025-06-15', N'Đã thanh toán', 76, 1000000.00, 'VN203', 'KH047'),
('DV100', '2025-05-06', '2025-06-15', N'Đã thanh toán', 77, 1000000.00, 'VN203', 'KH048'),
('DV101', '2025-05-11', '2025-06-15', N'Đã thanh toán', 79, 1000000.00, 'VN203', 'KH049'),
('DV102', '2025-05-03', '2025-06-15', N'Đã thanh toán', 80, 1000000.00, 'VN203', 'KH050'),
('DV103', '2025-05-20', '2025-06-15', N'Đã thanh toán', 82, 1000000.00, 'VN203', 'KH051'),
('DV104', '2025-05-07', '2025-06-15', N'Đã thanh toán', 83, 1000000.00, 'VN203', 'KH052'),
('DV105', '2025-05-14', '2025-06-15', N'Đã thanh toán', 85, 1000000.00, 'VN203', 'KH053'),
('DV106', '2025-05-09', '2025-06-15', N'Đã thanh toán', 86, 1000000.00, 'VN203', 'KH054'),
('DV107', '2025-05-01', '2025-06-15', N'Đã thanh toán', 88, 1000000.00, 'VN203', 'KH055'),
('DV108', '2025-05-18', '2025-06-15', N'Đã thanh toán', 89, 1000000.00, 'VN203', 'KH056'),
('DV109', '2025-05-02', '2025-06-15', N'Đã thanh toán', 91, 1000000.00, 'VN203', 'KH057'),
('DV110', '2025-05-15', '2025-06-15', N'Đã thanh toán', 92, 1000000.00, 'VN203', 'KH058'),
('DV111', '2025-05-09', '2025-06-15', N'Đã thanh toán', 94, 1000000.00, 'VN203', 'KH059'),
('DV112', '2025-05-04', '2025-06-15', N'Đã thanh toán', 95, 1000000.00, 'VN203', 'KH060'),
('DV113', '2025-05-17', '2025-06-15', N'Đã thanh toán', 97, 1000000.00, 'VN203', 'KH061'),
('DV114', '2025-05-06', '2025-06-15', N'Đã thanh toán', 98, 1000000.00, 'VN203', 'KH062'),
('DV115', '2025-05-11', '2025-06-15', N'Đã thanh toán', 100, 1000000.00, 'VN203', 'KH063'),
('DV116', '2025-05-03', '2025-06-15', N'Đã thanh toán', 101, 1000000.00, 'VN203', 'KH064'),
('DV117', '2025-05-20', '2025-06-15', N'Đã thanh toán', 103, 1000000.00, 'VN203', 'KH065'),
('DV118', '2025-05-07', '2025-06-15', N'Đã thanh toán', 104, 1000000.00, 'VN203', 'KH066'),
('DV119', '2025-05-14', '2025-06-15', N'Đã thanh toán', 106, 1000000.00, 'VN203', 'KH067'),
('DV120', '2025-05-09', '2025-06-15', N'Đã thanh toán', 107, 1000000.00, 'VN203', 'KH068'),
('DV121', '2025-05-01', '2025-06-15', N'Đã thanh toán', 109, 1000000.00, 'VN203', 'KH069'),
('DV122', '2025-05-18', '2025-06-15', N'Đã thanh toán', 110, 1000000.00, 'VN203', 'KH070'),
('DV123', '2025-05-02', '2025-06-15', N'Đã thanh toán', 111, 1000000.00, 'VN203', 'KH071'),
('DV124', '2025-05-15', '2025-06-15', N'Đã thanh toán', 112, 1000000.00, 'VN203', 'KH072'),
('DV125', '2025-05-09', '2025-06-15', N'Đã thanh toán', 115, 1000000.00, 'VN203', 'KH073'),
('DV126', '2025-05-04', '2025-06-15', N'Đã thanh toán', 118, 1000000.00, 'VN203', 'KH074'),
('DV127', '2025-05-17', '2025-06-15', N'Đã thanh toán', 121, 1000000.00, 'VN203', 'KH075'),
('DV128', '2025-05-06', '2025-06-15', N'Đã thanh toán', 124, 1000000.00, 'VN203', 'KH076'),
('DV129', '2025-05-11', '2025-06-15', N'Đã thanh toán', 127, 1000000.00, 'VN203', 'KH077'),
('DV130', '2025-05-03', '2025-06-15', N'Đã thanh toán', 130, 1000000.00, 'VN203', 'KH078'),
('DV131', '2025-05-20', '2025-06-15', N'Đã thanh toán', 133, 1000000.00, 'VN203', 'KH079'),
('DV132', '2025-05-07', '2025-06-15', N'Đã thanh toán', 136, 1000000.00, 'VN203', 'KH080'),
('DV133', '2025-05-14', '2025-06-15', N'Đã thanh toán', 139, 1000000.00, 'VN203', 'KH081'),
('DV134', '2025-05-09', '2025-06-15', N'Đã thanh toán', 142, 1000000.00, 'VN203', 'KH082'),
('DV135', '2025-05-01', '2025-06-15', N'Đã thanh toán', 145, 1000000.00, 'VN203', 'KH083'),
('DV136', '2025-05-18', '2025-06-15', N'Đã thanh toán', 148, 1000000.00, 'VN203', 'KH084');
----
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN204
-- Hạng nhất (15 ghế)
(1, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(2, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(3, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(4, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(5, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(6, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(7, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(8, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(9, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(10, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(11, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(12, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(13, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(14, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
(15, 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),

-- Thương gia (35 ghế)
(16, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(17, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(18, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(19, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(20, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(21, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(22, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(23, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(24, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(25, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(26, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(27, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(28, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(29, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(30, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(31, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(32, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(33, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(34, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(35, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(36, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(37, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(38, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(39, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(40, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(41, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(42, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(43, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(44, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(45, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(46, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(47, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(48, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(49, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
(50, 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),

-- Phổ thông (100 ghế)
(51, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(52, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(53, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(54, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(55, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(56, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(57, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(58, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(59, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(60, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(61, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(62, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(63, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(64, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(65, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(66, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(67, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(68, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(69, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(70, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(71, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(72, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(73, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(74, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(75, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(76, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(77, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(78, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(79, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(80, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(81, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(82, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(83, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(84, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(85, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(86, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(87, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(88, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(89, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(90, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(91, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(92, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(93, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(94, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(95, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(96, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(97, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(98, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(99, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(100, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(101, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(102, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(103, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(104, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(105, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(106, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(107, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(108, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(109, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(110, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(111, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(112, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(113, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(114, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(115, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(116, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(117, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(118, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(119, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(120, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(121, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(122, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(123, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(124, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(125, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(126, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(127, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(128, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(129, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(130, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(131, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(132, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(133, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(134, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(135, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(136, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(137, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(138, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(139, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(140, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(141, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(142, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(143, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(144, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(145, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(146, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(147, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(148, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(149, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
(150, 'VN204', 1000000.00, N'Phổ thông', N'có sẵn');
----
----
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Hạng nhất (15 ghế) - 3 ghế đã đặt
(1, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(2, 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
(3, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(4, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(5, 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
(6, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(7, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(8, 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
(9, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(10, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(11, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(12, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(13, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(14, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
(15, 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế) - 7 ghế đã đặt
(16, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(17, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(18, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(19, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(20, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(21, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(22, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(23, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(24, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(25, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(26, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(27, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(28, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(29, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(30, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(31, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(32, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(33, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(34, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(35, 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
(36, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(37, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(38, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(39, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(40, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(41, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(42, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(43, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(44, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(45, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(46, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(47, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(48, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(49, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
(50, 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
-- Phổ thông (100 ghế) - 20 ghế đã đặt
(51, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(52, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(53, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(54, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(55, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(56, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(57, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(58, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(59, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(60, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(61, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(62, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(63, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(64, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(65, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(66, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(67, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(68, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(69, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(70, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(71, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(72, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(73, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(74, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(75, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(76, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(77, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(78, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(79, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(80, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(81, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(82, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(83, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(84, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(85, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(86, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(87, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(88, 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
(89, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(90, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(91, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(92, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(93, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(94, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(95, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(96, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(97, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(98, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(99, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(100, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(101, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(102, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(103, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(104, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(105, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(106, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(107, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(108, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(109, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(110, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(111, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(112, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(113, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(114, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(115, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(116, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(117, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(118, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(119, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(120, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(121, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(122, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(123, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(124, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(125, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(126, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(127, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(128, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(129, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(130, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(131, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(132, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(133, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(134, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(135, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(136, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(137, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(138, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(139, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(140, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(141, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(142, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(143, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(144, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(145, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(146, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(147, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(148, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(149, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
(150, 'VN205', 1000000.00, N'Phổ thông', N'có sẵn');

INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES
-- Hạng nhất (5 ghế đã đặt)
('TT203-001', '2025-05-19', 3000000.00, N'Thẻ tín dụng', 'DV053'),
('TT203-002', '2025-05-04', 3000000.00, N'Tiền mặt', 'DV054'),
('TT203-003', '2025-05-12', 3000000.00, N'Chuyển khoản', 'DV055'),
('TT203-004', '2025-05-07', 3000000.00, N'Thẻ tín dụng', 'DV056'),
('TT203-005', '2025-05-21', 3000000.00, N'Tiền mặt', 'DV057'),

-- Thương gia (25 ghế đã đặt)
('TT203-006', '2025-05-03', 2000000.00, N'Chuyển khoản', 'DV058'),
('TT203-007', '2025-05-16', 2000000.00, N'Thẻ tín dụng', 'DV059'),
('TT203-008', '2025-05-10', 2000000.00, N'Tiền mặt', 'DV060'),
('TT203-009', '2025-05-01', 2000000.00, N'Chuyển khoản', 'DV061'),
('TT203-010', '2025-05-18', 2000000.00, N'Thẻ tín dụng', 'DV062'),
('TT203-011', '2025-05-05', 2000000.00, N'Tiền mặt', 'DV063'),
('TT203-012', '2025-05-13', 2000000.00, N'Chuyển khoản', 'DV064'),
('TT203-013', '2025-05-08', 2000000.00, N'Thẻ tín dụng', 'DV065'),
('TT203-014', '2025-05-22', 2000000.00, N'Tiền mặt', 'DV066'),
('TT203-015', '2025-05-02', 2000000.00, N'Chuyển khoản', 'DV067'),
('TT203-016', '2025-05-15', 2000000.00, N'Thẻ tín dụng', 'DV068'),
('TT203-017', '2025-05-09', 2000000.00, N'Tiền mặt', 'DV069'),
('TT203-018', '2025-05-04', 2000000.00, N'Chuyển khoản', 'DV070'),
('TT203-019', '2025-05-17', 2000000.00, N'Thẻ tín dụng', 'DV071'),
('TT203-020', '2025-05-06', 2000000.00, N'Tiền mặt', 'DV072'),
('TT203-021', '2025-05-11', 2000000.00, N'Chuyển khoản', 'DV073'),
('TT203-022', '2025-05-03', 2000000.00, N'Thẻ tín dụng', 'DV074'),
('TT203-023', '2025-05-20', 2000000.00, N'Tiền mặt', 'DV075'),
('TT203-024', '2025-05-07', 2000000.00, N'Chuyển khoản', 'DV076'),
('TT203-025', '2025-05-14', 2000000.00, N'Thẻ tín dụng', 'DV077'),
('TT203-026', '2025-05-09', 2000000.00, N'Tiền mặt', 'DV078'),
('TT203-027', '2025-05-01', 2000000.00, N'Chuyển khoản', 'DV079'),
('TT203-028', '2025-05-18', 2000000.00, N'Thẻ tín dụng', 'DV080'),
('TT203-029', '2025-05-02', 2000000.00, N'Tiền mặt', 'DV081'),

-- Phổ thông (40 ghế đã đặt)
('TT203-030', '2025-05-15', 1000000.00, N'Chuyển khoản', 'DV082'),
('TT203-031', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV083'),
('TT203-032', '2025-05-04', 1000000.00, N'Tiền mặt', 'DV084'),
('TT203-033', '2025-05-17', 1000000.00, N'Chuyển khoản', 'DV085'),
('TT203-034', '2025-05-06', 1000000.00, N'Thẻ tín dụng', 'DV086'),
('TT203-035', '2025-05-11', 1000000.00, N'Tiền mặt', 'DV087'),
('TT203-036', '2025-05-03', 1000000.00, N'Chuyển khoản', 'DV088'),
('TT203-037', '2025-05-20', 1000000.00, N'Thẻ tín dụng', 'DV089'),
('TT203-038', '2025-05-07', 1000000.00, N'Tiền mặt', 'DV090'),
('TT203-039', '2025-05-14', 1000000.00, N'Chuyển khoản', 'DV091'),
('TT203-040', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV092'),
('TT203-041', '2025-05-01', 1000000.00, N'Tiền mặt', 'DV093'),
('TT203-042', '2025-05-18', 1000000.00, N'Chuyển khoản', 'DV094'),
('TT203-043', '2025-05-02', 1000000.00, N'Thẻ tín dụng', 'DV095'),
('TT203-044', '2025-05-15', 1000000.00, N'Tiền mặt', 'DV096'),
('TT203-045', '2025-05-09', 1000000.00, N'Chuyển khoản', 'DV097'),
('TT203-046', '2025-05-04', 1000000.00, N'Thẻ tín dụng', 'DV098'),
('TT203-047', '2025-05-17', 1000000.00, N'Tiền mặt', 'DV099'),
('TT203-048', '2025-05-06', 1000000.00, N'Chuyển khoản', 'DV100'),
('TT203-049', '2025-05-11', 1000000.00, N'Thẻ tín dụng', 'DV101'),
('TT203-050', '2025-05-03', 1000000.00, N'Tiền mặt', 'DV102'),
('TT203-051', '2025-05-20', 1000000.00, N'Chuyển khoản', 'DV103'),
('TT203-052', '2025-05-07', 1000000.00, N'Thẻ tín dụng', 'DV104'),
('TT203-053', '2025-05-14', 1000000.00, N'Tiền mặt', 'DV105'),
('TT203-054', '2025-05-09', 1000000.00, N'Chuyển khoản', 'DV106'),
('TT203-055', '2025-05-01', 1000000.00, N'Thẻ tín dụng', 'DV107'),
('TT203-056', '2025-05-18', 1000000.00, N'Tiền mặt', 'DV108'),
('TT203-057', '2025-05-02', 1000000.00, N'Chuyển khoản', 'DV109'),
('TT203-058', '2025-05-15', 1000000.00, N'Thẻ tín dụng', 'DV110'),
('TT203-059', '2025-05-09', 1000000.00, N'Tiền mặt', 'DV111'),
('TT203-060', '2025-05-04', 1000000.00, N'Chuyển khoản', 'DV112'),
('TT203-061', '2025-05-17', 1000000.00, N'Thẻ tín dụng', 'DV113'),
('TT203-062', '2025-05-06', 1000000.00, N'Tiền mặt', 'DV114'),
('TT203-063', '2025-05-11', 1000000.00, N'Chuyển khoản', 'DV115'),
('TT203-064', '2025-05-03', 1000000.00, N'Thẻ tín dụng', 'DV116'),
('TT203-065', '2025-05-20', 1000000.00, N'Tiền mặt', 'DV117'),
('TT203-066', '2025-05-07', 1000000.00, N'Chuyển khoản', 'DV118'),
('TT203-067', '2025-05-14', 1000000.00, N'Thẻ tín dụng', 'DV119'),
('TT203-068', '2025-05-09', 1000000.00, N'Tiền mặt', 'DV120'),
('TT203-069', '2025-05-01', 1000000.00, N'Chuyển khoản', 'DV121'),
('TT203-070', '2025-05-18', 1000000.00, N'Thẻ tín dụng', 'DV122'),
('TT203-071', '2025-05-02', 1000000.00, N'Tiền mặt', 'DV123'),
('TT203-072', '2025-05-15', 1000000.00, N'Chuyển khoản', 'DV124'),
('TT203-073', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV125'),
('TT203-074', '2025-05-04', 1000000.00, N'Tiền mặt', 'DV126'),
('TT203-075', '2025-05-17', 1000000.00, N'Chuyển khoản', 'DV127'),
('TT203-076', '2025-05-06', 1000000.00, N'Thẻ tín dụng', 'DV128'),
('TT203-077', '2025-05-11', 1000000.00, N'Tiền mặt', 'DV129'),
('TT203-078', '2025-05-03', 1000000.00, N'Chuyển khoản', 'DV130'),
('TT203-079', '2025-05-20', 1000000.00, N'Thẻ tín dụng', 'DV131'),
('TT203-080', '2025-05-07', 1000000.00, N'Tiền mặt', 'DV132'),
('TT203-081', '2025-05-14', 1000000.00, N'Chuyển khoản', 'DV133'),
('TT203-082', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV134'),
('TT203-083', '2025-05-01', 1000000.00, N'Tiền mặt', 'DV135'),
('TT203-084', '2025-05-18', 1000000.00, N'Chuyển khoản', 'DV136');

INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES
-- Hạng nhất (2 ghế đã đặt)
('TT202-001', '2025-05-14', 3000000.00, N'Thẻ tín dụng', 'DV043'),
('TT202-002', '2025-05-09', 3000000.00, N'Tiền mặt', 'DV044'),

-- Thương gia (3 ghế đã đặt)
('TT202-003', '2025-05-03', 2000000.00, N'Chuyển khoản', 'DV045'),
('TT202-004', '2025-05-17', 2000000.00, N'Thẻ tín dụng', 'DV046'),
('TT202-005', '2025-05-06', 2000000.00, N'Tiền mặt', 'DV047'),

-- Phổ thông (5 ghế đã đặt)
('TT202-006', '2025-05-11', 1000000.00, N'Chuyển khoản', 'DV048'),
('TT202-007', '2025-05-02', 1000000.00, N'Thẻ tín dụng', 'DV049'),
('TT202-008', '2025-05-20', 1000000.00, N'Tiền mặt', 'DV050'),
('TT202-009', '2025-05-08', 1000000.00, N'Chuyển khoản', 'DV051'),
('TT202-010', '2025-05-13', 1000000.00, N'Thẻ tín dụng', 'DV052');

INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES
-- Hạng nhất (5 ghế đã đặt)
('TT201-001', '2025-05-18', 3000000.00, N'Thẻ tín dụng', 'DV001'),
('TT201-002', '2025-05-03', 3000000.00, N'Tiền mặt', 'DV002'),
('TT201-003', '2025-05-11', 3000000.00, N'Chuyển khoản', 'DV003'),
('TT201-004', '2025-05-07', 3000000.00, N'Thẻ tín dụng', 'DV004'),
('TT201-005', '2025-05-20', 3000000.00, N'Tiền mặt', 'DV005'),

-- Thương gia (9 ghế đã đặt)
('TT201-006', '2025-05-02', 2000000.00, N'Chuyển khoản', 'DV006'),
('TT201-007', '2025-05-15', 2000000.00, N'Thẻ tín dụng', 'DV007'),
('TT201-008', '2025-05-09', 2000000.00, N'Tiền mặt', 'DV008'),
('TT201-009', '2025-05-01', 2000000.00, N'Chuyển khoản', 'DV009'),
('TT201-010', '2025-05-17', 2000000.00, N'Thẻ tín dụng', 'DV010'),
('TT201-011', '2025-05-06', 2000000.00, N'Tiền mặt', 'DV011'),
('TT201-012', '2025-05-13', 2000000.00, N'Chuyển khoản', 'DV012'),
('TT201-013', '2025-05-04', 2000000.00, N'Thẻ tín dụng', 'DV013'),
('TT201-014', '2025-05-19', 2000000.00, N'Tiền mặt', 'DV014'),

-- Phổ thông (28 ghế đã đặt)
('TT201-015', '2025-05-08', 1000000.00, N'Chuyển khoản', 'DV015'),
('TT201-016', '2025-05-21', 1000000.00, N'Thẻ tín dụng', 'DV016'),
('TT201-017', '2025-05-05', 1000000.00, N'Tiền mặt', 'DV017'),
('TT201-018', '2025-05-12', 1000000.00, N'Chuyển khoản', 'DV018'),
('TT201-019', '2025-05-10', 1000000.00, N'Thẻ tín dụng', 'DV019'),
('TT201-020', '2025-05-03', 1000000.00, N'Tiền mặt', 'DV020'),
('TT201-021', '2025-05-16', 1000000.00, N'Chuyển khoản', 'DV021'),
('TT201-022', '2025-05-07', 1000000.00, N'Thẻ tín dụng', 'DV022'),
('TT201-023', '2025-05-22', 1000000.00, N'Tiền mặt', 'DV023'),
('TT201-024', '2025-05-01', 1000000.00, N'Chuyển khoản', 'DV024'),
('TT201-025', '2025-05-18', 1000000.00, N'Thẻ tín dụng', 'DV025'),
('TT201-026', '2025-05-02', 1000000.00, N'Tiền mặt', 'DV026'),
('TT201-027', '2025-05-15', 1000000.00, N'Chuyển khoản', 'DV027'),
('TT201-028', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV028'),
('TT201-029', '2025-05-04', 1000000.00, N'Tiền mặt', 'DV029'),
('TT201-030', '2025-05-19', 1000000.00, N'Chuyển khoản', 'DV030'),
('TT201-031', '2025-05-08', 1000000.00, N'Thẻ tín dụng', 'DV031'),
('TT201-032', '2025-05-21', 1000000.00, N'Tiền mặt', 'DV032'),
('TT201-033', '2025-05-05', 1000000.00, N'Chuyển khoản', 'DV033'),
('TT201-034', '2025-05-12', 1000000.00, N'Thẻ tín dụng', 'DV034'),
('TT201-035', '2025-05-10', 1000000.00, N'Tiền mặt', 'DV035'),
('TT201-036', '2025-05-03', 1000000.00, N'Chuyển khoản', 'DV036'),
('TT201-037', '2025-05-16', 1000000.00, N'Thẻ tín dụng', 'DV037'),
('TT201-038', '2025-05-07', 1000000.00, N'Tiền mặt', 'DV038'),
('TT201-039', '2025-05-22', 1000000.00, N'Chuyển khoản', 'DV039'),
('TT201-040', '2025-05-01', 1000000.00, N'Thẻ tín dụng', 'DV040'),
('TT201-041', '2025-05-18', 1000000.00, N'Tiền mặt', 'DV041'),
('TT201-042', '2025-05-02', 1000000.00, N'Chuyển khoản', 'DV042');

INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES
-- Các thanh toán cho vé Hạng nhất (SoTien = 3000000.00)
('TT205-001', '2025-05-10', 3000000.00, N'Thẻ tín dụng', 'DV137'),
('TT205-002', '2025-05-05', 3000000.00, N'Tiền mặt', 'DV138'),
('TT205-003', '2025-05-13', 3000000.00, N'Chuyển khoản', 'DV139'),

-- Các thanh toán cho vé Thương gia (SoTien = 2000000.00)
('TT205-004', '2025-05-08', 2000000.00, N'Thẻ tín dụng', 'DV140'),
('TT205-005', '2025-05-22', 2000000.00, N'Chuyển khoản', 'DV141'),
('TT205-006', '2025-05-01', 2000000.00, N'Tiền mặt', 'DV142'),
('TT205-007', '2025-05-18', 2000000.00, N'Thẻ tín dụng', 'DV143'),
('TT205-008', '2025-05-02', 2000000.00, N'Chuyển khoản', 'DV144'),
('TT205-009', '2025-05-15', 2000000.00, N'Tiền mặt', 'DV145'),
('TT205-010', '2025-05-09', 2000000.00, N'Thẻ tín dụng', 'DV146'),

-- Các thanh toán cho vé Phổ thông (SoTien = 1000000.00)
('TT205-011', '2025-05-04', 1000000.00, N'Chuyển khoản', 'DV147'),
('TT205-012', '2025-05-17', 1000000.00, N'Tiền mặt', 'DV148'),
('TT205-013', '2025-05-06', 1000000.00, N'Thẻ tín dụng', 'DV149'),
('TT205-014', '2025-05-11', 1000000.00, N'Chuyển khoản', 'DV150'),
('TT205-015', '2025-05-03', 1000000.00, N'Tiền mặt', 'DV151'),
('TT205-016', '2025-05-20', 1000000.00, N'Thẻ tín dụng', 'DV152'),
('TT205-017', '2025-05-07', 1000000.00, N'Chuyển khoản', 'DV153'),
('TT205-018', '2025-05-14', 1000000.00, N'Tiền mặt', 'DV154'),
('TT205-019', '2025-05-09', 1000000.00, N'Thẻ tín dụng', 'DV155'),
('TT205-020', '2025-05-01', 1000000.00, N'Chuyển khoản', 'DV156');

------
INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT) VALUES
('HD205-001', '2025-05-10', N'Thẻ tín dụng', '2025-05-10', 'TT205-001'),
('HD205-002', '2025-05-05', N'Tiền mặt', '2025-05-05', 'TT205-002'),
('HD205-003', '2025-05-13', N'Chuyển khoản', '2025-05-13', 'TT205-003'),
('HD205-004', '2025-05-08', N'Thẻ tín dụng', '2025-05-08', 'TT205-004'),
('HD205-005', '2025-05-22', N'Chuyển khoản', '2025-05-22', 'TT205-005'),
('HD205-006', '2025-05-01', N'Tiền mặt', '2025-05-01', 'TT205-006'),
('HD205-007', '2025-05-18', N'Thẻ tín dụng', '2025-05-18', 'TT205-007'),
('HD205-008', '2025-05-02', N'Chuyển khoản', '2025-05-02', 'TT205-008'),
('HD205-009', '2025-05-15', N'Tiền mặt', '2025-05-15', 'TT205-009'),
('HD205-010', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT205-010'),
('HD205-011', '2025-05-04', N'Chuyển khoản', '2025-05-04', 'TT205-011'),
('HD205-012', '2025-05-17', N'Tiền mặt', '2025-05-17', 'TT205-012'),
('HD205-013', '2025-05-06', N'Thẻ tín dụng', '2025-05-06', 'TT205-013'),
('HD205-014', '2025-05-11', N'Chuyển khoản', '2025-05-11', 'TT205-014'),
('HD205-015', '2025-05-03', N'Tiền mặt', '2025-05-03', 'TT205-015'),
('HD205-016', '2025-05-20', N'Thẻ tín dụng', '2025-05-20', 'TT205-016'),
('HD205-017', '2025-05-07', N'Chuyển khoản', '2025-05-07', 'TT205-017'),
('HD205-018', '2025-05-14', N'Tiền mặt', '2025-05-14', 'TT205-018'),
('HD205-019', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT205-019'),
('HD205-020', '2025-05-01', N'Chuyển khoản', '2025-05-01', 'TT205-020');

INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT) VALUES
('HD203-001', '2025-05-19', N'Thẻ tín dụng', '2025-05-19', 'TT203-001'),
('HD203-002', '2025-05-04', N'Tiền mặt', '2025-05-04', 'TT203-002'),
('HD203-003', '2025-05-12', N'Chuyển khoản', '2025-05-12', 'TT203-003'),
('HD203-004', '2025-05-07', N'Thẻ tín dụng', '2025-05-07', 'TT203-004'),
('HD203-005', '2025-05-21', N'Tiền mặt', '2025-05-21', 'TT203-005'),
('HD203-006', '2025-05-03', N'Chuyển khoản', '2025-05-03', 'TT203-006'),
('HD203-007', '2025-05-16', N'Thẻ tín dụng', '2025-05-16', 'TT203-007'),
('HD203-008', '2025-05-10', N'Tiền mặt', '2025-05-10', 'TT203-008'),
('HD203-009', '2025-05-01', N'Chuyển khoản', '2025-05-01', 'TT203-009'),
('HD203-010', '2025-05-18', N'Thẻ tín dụng', '2025-05-18', 'TT203-010'),
('HD203-011', '2025-05-05', N'Tiền mặt', '2025-05-05', 'TT203-011'),
('HD203-012', '2025-05-13', N'Chuyển khoản', '2025-05-13', 'TT203-012'),
('HD203-013', '2025-05-08', N'Thẻ tín dụng', '2025-05-08', 'TT203-013'),
('HD203-014', '2025-05-22', N'Tiền mặt', '2025-05-22', 'TT203-014'),
('HD203-015', '2025-05-02', N'Chuyển khoản', '2025-05-02', 'TT203-015'),
('HD203-016', '2025-05-15', N'Thẻ tín dụng', '2025-05-15', 'TT203-016'),
('HD203-017', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT203-017'),
('HD203-018', '2025-05-04', N'Chuyển khoản', '2025-05-04', 'TT203-018'),
('HD203-019', '2025-05-17', N'Thẻ tín dụng', '2025-05-17', 'TT203-019'),
('HD203-020', '2025-05-06', N'Tiền mặt', '2025-05-06', 'TT203-020'),
('HD203-021', '2025-05-11', N'Chuyển khoản', '2025-05-11', 'TT203-021'),
('HD203-022', '2025-05-03', N'Thẻ tín dụng', '2025-05-03', 'TT203-022'),
('HD203-023', '2025-05-20', N'Tiền mặt', '2025-05-20', 'TT203-023'),
('HD203-024', '2025-05-07', N'Chuyển khoản', '2025-05-07', 'TT203-024'),
('HD203-025', '2025-05-14', N'Thẻ tín dụng', '2025-05-14', 'TT203-025'),
('HD203-026', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT203-026'),
('HD203-027', '2025-05-01', N'Chuyển khoản', '2025-05-01', 'TT203-027'),
('HD203-028', '2025-05-18', N'Thẻ tín dụng', '2025-05-18', 'TT203-028'),
('HD203-029', '2025-05-02', N'Tiền mặt', '2025-05-02', 'TT203-029'),
('HD203-030', '2025-05-15', N'Chuyển khoản', '2025-05-15', 'TT203-030'),
('HD203-031', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT203-031'),
('HD203-032', '2025-05-04', N'Tiền mặt', '2025-05-04', 'TT203-032'),
('HD203-033', '2025-05-17', N'Chuyển khoản', '2025-05-17', 'TT203-033'),
('HD203-034', '2025-05-06', N'Thẻ tín dụng', '2025-05-06', 'TT203-034'),
('HD203-035', '2025-05-11', N'Tiền mặt', '2025-05-11', 'TT203-035'),
('HD203-036', '2025-05-03', N'Chuyển khoản', '2025-05-03', 'TT203-036'),
('HD203-037', '2025-05-20', N'Thẻ tín dụng', '2025-05-20', 'TT203-037'),
('HD203-038', '2025-05-07', N'Tiền mặt', '2025-05-07', 'TT203-038'),
('HD203-039', '2025-05-14', N'Chuyển khoản', '2025-05-14', 'TT203-039'),
('HD203-040', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT203-040'),
('HD203-041', '2025-05-01', N'Tiền mặt', '2025-05-01', 'TT203-041'),
('HD203-042', '2025-05-18', N'Chuyển khoản', '2025-05-18', 'TT203-042'),
('HD203-043', '2025-05-02', N'Thẻ tín dụng', '2025-05-02', 'TT203-043'),
('HD203-044', '2025-05-15', N'Tiền mặt', '2025-05-15', 'TT203-044'),
('HD203-045', '2025-05-09', N'Chuyển khoản', '2025-05-09', 'TT203-045'),
('HD203-046', '2025-05-04', N'Thẻ tín dụng', '2025-05-04', 'TT203-046'),
('HD203-047', '2025-05-17', N'Tiền mặt', '2025-05-17', 'TT203-047'),
('HD203-048', '2025-05-06', N'Chuyển khoản', '2025-05-06', 'TT203-048'),
('HD203-049', '2025-05-11', N'Thẻ tín dụng', '2025-05-11', 'TT203-049'),
('HD203-050', '2025-05-03', N'Tiền mặt', '2025-05-03', 'TT203-050'),
('HD203-051', '2025-05-20', N'Chuyển khoản', '2025-05-20', 'TT203-051'),
('HD203-052', '2025-05-07', N'Thẻ tín dụng', '2025-05-07', 'TT203-052'),
('HD203-053', '2025-05-14', N'Tiền mặt', '2025-05-14', 'TT203-053'),
('HD203-054', '2025-05-09', N'Chuyển khoản', '2025-05-09', 'TT203-054'),
('HD203-055', '2025-05-01', N'Thẻ tín dụng', '2025-05-01', 'TT203-055'),
('HD203-056', '2025-05-18', N'Tiền mặt', '2025-05-18', 'TT203-056'),
('HD203-057', '2025-05-02', N'Chuyển khoản', '2025-05-02', 'TT203-057'),
('HD203-058', '2025-05-15', N'Thẻ tín dụng', '2025-05-15', 'TT203-058'),
('HD203-059', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT203-059'),
('HD203-060', '2025-05-04', N'Chuyển khoản', '2025-05-04', 'TT203-060'),
('HD203-061', '2025-05-17', N'Thẻ tín dụng', '2025-05-17', 'TT203-061'),
('HD203-062', '2025-05-06', N'Tiền mặt', '2025-05-06', 'TT203-062'),
('HD203-063', '2025-05-11', N'Chuyển khoản', '2025-05-11', 'TT203-063'),
('HD203-064', '2025-05-03', N'Thẻ tín dụng', '2025-05-03', 'TT203-064'),
('HD203-065', '2025-05-20', N'Tiền mặt', '2025-05-20', 'TT203-065'),
('HD203-066', '2025-05-07', N'Chuyển khoản', '2025-05-07', 'TT203-066'),
('HD203-067', '2025-05-14', N'Thẻ tín dụng', '2025-05-14', 'TT203-067'),
('HD203-068', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT203-068'),
('HD203-069', '2025-05-01', N'Chuyển khoản', '2025-05-01', 'TT203-069'),
('HD203-070', '2025-05-18', N'Thẻ tín dụng', '2025-05-18', 'TT203-070'),
('HD203-071', '2025-05-02', N'Tiền mặt', '2025-05-02', 'TT203-071'),
('HD203-072', '2025-05-15', N'Chuyển khoản', '2025-05-15', 'TT203-072'),
('HD203-073', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT203-073'),
('HD203-074', '2025-05-04', N'Tiền mặt', '2025-05-04', 'TT203-074'),
('HD203-075', '2025-05-17', N'Chuyển khoản', '2025-05-17', 'TT203-075'),
('HD203-076', '2025-05-06', N'Thẻ tín dụng', '2025-05-06', 'TT203-076'),
('HD203-077', '2025-05-11', N'Tiền mặt', '2025-05-11', 'TT203-077'),
('HD203-078', '2025-05-03', N'Chuyển khoản', '2025-05-03', 'TT203-078'),
('HD203-079', '2025-05-20', N'Thẻ tín dụng', '2025-05-20', 'TT203-079'),
('HD203-080', '2025-05-07', N'Tiền mặt', '2025-05-07', 'TT203-080'),
('HD203-081', '2025-05-14', N'Chuyển khoản', '2025-05-14', 'TT203-081'),
('HD203-082', '2025-05-09', N'Thẻ tín dụng', '2025-05-09', 'TT203-082'),
('HD203-083', '2025-05-01', N'Tiền mặt', '2025-05-01', 'TT203-083'),
('HD203-084', '2025-05-18', N'Chuyển khoản', '2025-05-18', 'TT203-084');


INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT) VALUES
('HD202-001', '2025-05-14', N'Thẻ tín dụng', '2025-05-14', 'TT202-001'),
('HD202-002', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT202-002'),
('HD202-003', '2025-05-03', N'Chuyển khoản', '2025-05-03', 'TT202-003'),
('HD202-004', '2025-05-17', N'Thẻ tín dụng', '2025-05-17', 'TT202-004'),
('HD202-005', '2025-05-06', N'Tiền mặt', '2025-05-06', 'TT202-005'),
('HD202-006', '2025-05-11', N'Chuyển khoản', '2025-05-11', 'TT202-006'),
('HD202-007', '2025-05-02', N'Thẻ tín dụng', '2025-05-02', 'TT202-007'),
('HD202-008', '2025-05-20', N'Tiền mặt', '2025-05-20', 'TT202-008'),
('HD202-009', '2025-05-08', N'Chuyển khoản', '2025-05-08', 'TT202-009'),
('HD202-010', '2025-05-13', N'Thẻ tín dụng', '2025-05-13', 'TT202-010');

INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT) VALUES
('HD202-001', '2025-05-14', N'Thẻ tín dụng', '2025-05-14', 'TT202-001'),
('HD202-002', '2025-05-09', N'Tiền mặt', '2025-05-09', 'TT202-002'),
('HD202-003', '2025-05-03', N'Chuyển khoản', '2025-05-03', 'TT202-003'),
('HD202-004', '2025-05-17', N'Thẻ tín dụng', '2025-05-17', 'TT202-004'),
('HD202-005', '2025-05-06', N'Tiền mặt', '2025-05-06', 'TT202-005'),
('HD202-006', '2025-05-11', N'Chuyển khoản', '2025-05-11', 'TT202-006'),
('HD202-007', '2025-05-02', N'Thẻ tín dụng', '2025-05-02', 'TT202-007'),
('HD202-008', '2025-05-20', N'Tiền mặt', '2025-05-20', 'TT202-008'),
('HD202-009', '2025-05-08', N'Chuyển khoản', '2025-05-08', 'TT202-009'),
('HD202-010', '2025-05-13', N'Thẻ tín dụng', '2025-05-13', 'TT202-010');