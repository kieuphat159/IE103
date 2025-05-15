-- Tạo cơ sở dữ liệu
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
    SoGhe VARCHAR(10) NOT NULL,
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

-- Stored Procedure thêm chuyến bay
CREATE PROCEDURE sp_ThemChuyenBay
    @MaChuyenBay VARCHAR(20),
    @TinhTrangChuyenBay NVARCHAR(50),
    @GioBay DATETIME,
    @GioDen DATETIME,
    @DiaDiemDau NVARCHAR(100),
    @DiaDiemCuoi NVARCHAR(100)
AS
BEGIN
    INSERT INTO ChuyenBay (MaChuyenBay, TinhTrangChuyenBay, GioBay, GioDen, DiaDiemDau, DiaDiemCuoi)
    VALUES (@MaChuyenBay, @TinhTrangChuyenBay, @GioBay, @GioDen, @DiaDiemDau, @DiaDiemCuoi);
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

-- Function tính tổng doanh thu theo chuyến bay
CREATE FUNCTION fn_TongDoanhThuChuyenBay (@MaChuyenBay VARCHAR(20))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongDoanhThu DECIMAL(18, 2);
    SELECT @TongDoanhThu = SUM(t.SoTien)
    FROM ThongTinDatVe t
    JOIN ThanhToan tt ON t.MaDatVe = tt.MaDatVe
    WHERE t.MaChuyenBay = @MaChuyenBay AND t.TrangThaiThanhToan = 'Đã thanh toán';
    RETURN ISNULL(@TongDoanhThu, 0);
END;
GO

-- View báo cáo doanh thu theo chuyến bay
CREATE VIEW vw_BaoCaoDoanhThu AS
SELECT 
    cb.MaChuyenBay,
    cb.DiaDiemDau,
    cb.DiaDiemCuoi,
    cb.GioBay,
    cb.GioDen,
    COUNT(t.MaDatVe) AS SoVeDaDat,
    dbo.fn_TongDoanhThuChuyenBay(cb.MaChuyenBay) AS TongDoanhThu
FROM ChuyenBay cb
LEFT JOIN ThongTinDatVe t ON cb.MaChuyenBay = t.MaChuyenBay
GROUP BY cb.MaChuyenBay, cb.DiaDiemDau, cb.DiaDiemCuoi, cb.GioBay, cb.GioDen;
GO

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
--

EXEC sp_ThemNguoiDung 'user1', N'Nguyễn Văn A', 'hashed_password1', 'a@example.com', '0123456789', '1990-01-01', 'Nam', '123456789012';
EXEC sp_ThemNguoiDung 'user2', N'Trần Thị B', 'hashed_password2', 'b@example.com', '0987654321', '1995-05-15', N'Nữ', '098765432109';
EXEC sp_ThemNguoiDung 'nv1', N'Lê Văn C', 'hashed_password3', 'c@example.com', '0912345678', '1985-03-10', 'Nam', '112233445566';

INSERT INTO KhachHang (MaKH, Passport, TaiKhoan)
VALUES ('KH001', 'P123456', 'user1'), ('KH002', 'P654321', 'user2');

INSERT INTO NhanVienKiemSoat (MaNV, TaiKhoan)
VALUES ('NV001', 'nv1');

INSERT INTO BaoCao (MaBaoCao, NgayBaoCao, NoiDungBaoCao, MaNV, TrangThai)
VALUES ('BC001', '2025-04-12', N'Khách hàng không mang hộ chiếu', 'NV001', N'Đã xử lý'),
       ('BC002', '2025-04-14', N'Khách hàng yêu cầu đổi giờ bay', 'NV001', N'Chưa xử lý');

EXEC sp_ThemChuyenBay 'CB001', N'Chưa khởi hành', '2025-04-15 08:00:00', '2025-04-15 10:30:00', N'Hà Nội', N'Hồ Chí Minh';
EXEC sp_ThemChuyenBay 'CB002', N'Chưa khởi hành', '2025-04-16 10:30:00', '2025-04-16 12:15:00', N'Hồ Chí Minh', N'Đà Nẵng';

EXEC sp_ThemGhe '01', 'CB001', 1500000, N'Phổ thông', N'có sẵn';
EXEC sp_ThemGhe '02', 'CB001', 1500000, N'Phổ thông', N'có sẵn';
EXEC sp_ThemGhe '03', 'CB001', 2500000, N'Thương gia', N'có sẵn';
EXEC sp_ThemGhe '04', 'CB002', 1200000, N'Phổ thông', N'có sẵn';
EXEC sp_ThemGhe '05', 'CB002', 1200000, N'Phổ thông', N'có sẵn';

EXEC sp_ThemDatVe 'DV001', '2025-04-10', '2025-04-15', N'Chưa thanh toán', 1, 1500000, 'CB001', 'KH001';
EXEC sp_ThemDatVe 'DV002', '2025-04-11', '2025-04-16', N'Chưa thanh toán', 2, 2400000, 'CB002', 'KH002';

EXEC sp_ThemThanhToan 'TT001', '2025-04-10', 1500000, N'Thẻ tín dụng', 'DV001';
EXEC sp_ThemThanhToan 'TT002', '2025-04-12', 2400000, N'Chuyển khoản', 'DV002';

EXEC sp_ThemHoaDon 'HD001', '2025-04-10', N'Thẻ tín dụng', '2025-04-10', 'TT001';
EXEC sp_ThemHoaDon 'HD002', '2025-04-12', N'Chuyển khoản', '2025-04-12', 'TT002';
GO