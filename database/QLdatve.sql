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
    -- Thêm chuy?n bay m?i vào b?ng ChuyenBay
    INSERT INTO ChuyenBay (MaChuyenBay, TinhTrangChuyenBay, GioBay, GioDen, DiaDiemDau, DiaDiemCuoi)
    VALUES (@MaChuyenBay, @TinhTrangChuyenBay, @GioBay, @GioDen, @DiaDiemDau, @DiaDiemCuoi);

    -- Kh?i t?o bi?n d?m cho vòng l?p t?o gh?
    DECLARE @i INT = 1;
    -- T?ng s? gh? c?n t?o là 150 (15 h?ng nh?t + 35 thuong gia + 100 ph? thông)
    DECLARE @TotalSeats INT = 150;

    -- Vòng l?p d? t?o t?ng gh? cho chuy?n bay
    WHILE @i <= @TotalSeats
    BEGIN
        -- Khai báo các bi?n d? luu thông tin gh?
        DECLARE @MaGhe VARCHAR(MAX);
        DECLARE @GiaVe DECIMAL(18, 2);
        DECLARE @HangGhe NVARCHAR(50);
        DECLARE @Prefix CHAR(1);
        DECLARE @SeatNumInClass INT;

        -- Logic phân lo?i gh? theo h?ng và gán giá vé, ti?n t? mã gh?
        IF @i <= 15 -- 15 gh? h?ng nh?t
        BEGIN
            SET @GiaVe = 3000000.00; -- Giá h?ng nh?t
            SET @HangGhe = N'Hạng nhất';
            SET @Prefix = 'A';
            SET @SeatNumInClass = @i;
        END
        ELSE IF @i <= 50 -- 35 gh? thuong gia (t? gh? 16 d?n 50)
        BEGIN
            SET @GiaVe = 2000000.00; -- Giá thuong gia
            SET @HangGhe = N'Thương gia';
            SET @Prefix = 'B';
            SET @SeatNumInClass = @i - 15; -- Ðánh s? l?i t? 1 cho h?ng này
        END
        ELSE -- 100 gh? ph? thông (t? gh? 51 d?n 150)
        BEGIN
            SET @GiaVe = 1000000.00; -- Giá ph? thông
            SET @HangGhe = N'Phổ thông';

            -- Tính toán ti?n t? ch? cái và s? gh? trong h?ng ph? thông
            DECLARE @SeatNumInEconomy INT = @i - 50; -- Ðánh s? l?i t? 1 cho h?ng ph? thông

            IF @SeatNumInEconomy <= 20
            BEGIN
                SET @Prefix = 'C';
                SET @SeatNumInClass = @SeatNumInEconomy;
            END
            ELSE IF @SeatNumInEconomy <= 40
            BEGIN
                SET @Prefix = 'D';
                SET @SeatNumInClass = @SeatNumInEconomy - 20;
            END
            ELSE IF @SeatNumInEconomy <= 60
            BEGIN
                SET @Prefix = 'E';
                SET @SeatNumInClass = @SeatNumInEconomy - 40;
            END
            ELSE IF @SeatNumInEconomy <= 80
            BEGIN
                SET @Prefix = 'F';
                SET @SeatNumInClass = @SeatNumInEconomy - 60;
            END
            ELSE
            BEGIN
                SET @Prefix = 'G';
                SET @SeatNumInClass = @SeatNumInEconomy - 80;
            END;
        END;

        -- T?o mã gh? hoàn ch?nh (ví d?: A01, B10, C05)
        SET @MaGhe = @Prefix + FORMAT(@SeatNumInClass, '00');

        -- Chèn thông tin gh? vào b?ng Ghe
        INSERT INTO Ghe (MaGhe, MaChuyenBay, GiaVe, HangGhe, TinhTrang)
        VALUES (@MaGhe, @MaChuyenBay, @GiaVe, @HangGhe, N'có sẵn');

        -- Tang bi?n d?m d? chuy?n sang gh? ti?p theo
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
-- nguoidung 
INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD) VALUES
('nguyenvana', N'Nguy?n Van A', 'matkhau123', 'nguyenvana@gmail.com', '0901234567', '1990-05-15', N'Nam', '001123456789'),
('tranthinga', N'Tr?n Th? Nga', 'pass456', 'tranthinga@gmail.com', '0902345678', '1992-11-22', N'N?', '002234567890'),
('leminhhai', N'Lê Minh H?i', 'securepwd789', 'leminhhai@gmail.com', '0903456789', '1988-03-01', N'Nam', '003345678901'),
('phamthihuong', N'Ph?m Th? Huong', 'huongbui@123', 'phamhuong@gmail.com', '0904567890', '1995-07-30', N'N?', '004456789012'),
('hoanganhtuan', N'Hoàng Anh Tu?n', 'tuananh99', 'hoanganhtuan@gmail.com', '0905678901', '1991-01-10', N'Nam', '005567890123'),
('nguyenthib', N'Nguy?n Th? B', 'buitran@2024', 'nguyenthib@gmail.com', '0906789012', '1993-09-05', N'N?', '006678901234'),
('votuananh', N'Võ Tu?n Anh', 'anhtuan@abc', 'votuananh@gmail.com', '0907890123', '1987-04-18', N'Nam', '007789012345'),
('dangthuyduong', N'Ð?ng Thúy Duong', 'duongtk@xyz', 'dangduong@gmail.com', '0908901234', '1996-12-03', N'N?', '008890123456'),
('truongvanduc', N'Truong Van Ð?c', 'ducpham@111', 'truongduc@gmail.com', '0909012345', '1990-06-25', N'Nam', '009901234567'),
('dothihuyen', N'Ð? Th? Huy?n', 'huyenhuyen@789', 'dohuyen@gmail.com', '0910123456', '1994-02-14', N'N?', '010012345678'),
('phanvanduc', N'Phan Van Ð?c', 'ducphan001', 'ducphan@gmail.com', '0911234567', '1989-08-08', N'Nam', '011123456789'),
('nguyenquynhchi', N'Nguy?n Qu?nh Chi', 'chichi2023', 'quynhchi@gmail.com', '0912345678', '1997-03-20', N'N?', '012234567890'),
('tranvietanh', N'Tr?n Vi?t Anh', 'vietanhnguyen', 'vietanh@gmail.com', '0913456789', '1991-01-28', N'Nam', '013345678901'),
('lethithuy', N'Lê Th? Thúy', 'thuythuy@abc', 'thuynguyen@gmail.com', '0914567890', '1993-10-10', N'N?', '014456789012'),
('phamnhatminh', N'Ph?m Nh?t Minh', 'minhnhat_123', 'nhatminh@gmail.com', '0915678901', '1986-05-05', N'Nam', '015567890123'),
('nguyenthanhhoa', N'Nguy?n Thanh Hòa', 'hoahoa@xyz', 'thanhhoa@gmail.com', '0916789012', '1995-04-01', N'N?', '016678901234'),
('vuvanhung', N'Vu Van Hùng', 'hungvu@007', 'vanhung@gmail.com', '0917890123', '1990-11-11', N'Nam', '017789012345'),
('hochithanh', N'H? Chí Thanh', 'thanhho@2024', 'chithanh@gmail.com', '0918901234', '1992-06-19', N'Nam', '018890123456'),
('maithuytrang', N'Mai Thúy Trang', 'trangmai@abc', 'thuytrang@gmail.com', '0919012345', '1996-08-28', N'N?', '019901234567'),
('nguyenvanc', N'Nguy?n Van C', 'pass123c', 'nguyenvanc@gmail.com', '0920123456', '1985-02-09', N'Nam', '020012345678'),
('tranvanquy', N'Tr?n Van Quý', 'quyquy123', 'tranvanquy@gmail.com', '0921234567', '1994-07-07', N'Nam', '021123456789'),
('phanthidung', N'Phan Th? Dung', 'dungtran456', 'phanthidung@gmail.com', '0922345678', '1991-03-17', N'N?', '022234567890'),
('dogiatuan', N'Ð? Gia Tu?n', 'giatuan789', 'dogiatuan@gmail.com', '0923456789', '1988-09-01', N'Nam', '023345678901'),
('nguyenthiminh', N'Nguy?n Th? Minh', 'minhminh_a', 'nguyenthiminh@gmail.com', '0924567890', '1996-01-25', N'N?', '024456789012'),
('dinhtheanh', N'Ðinh Th? Anh', 'theanh_pass', 'dinhtheanh@gmail.com', '0925678901', '1990-04-12', N'Nam', '025567890123'),
('nguyenthuha', N'Nguy?n Thu Hà', 'thuha@abc', 'nguyenthuha@gmail.com', '0926789012', '1992-12-08', N'N?', '026678901234'),
('lehoangviet', N'Lê Hoàng Vi?t', 'vietle@xyz', 'lehoangviet@gmail.com', '0927890123', '1987-06-03', N'Nam', '027789012345'),
('phamthithu', N'Ph?m Th? Thu', 'thuthu@111', 'phamthithu@gmail.com', '0928901234', '1995-08-14', N'N?', '028890123456'),
('tranthanhlong', N'Tr?n Thanh Long', 'longtran@789', 'tranthanhlong@gmail.com', '0929012345', '1991-02-23', N'Nam', '029901234567'),
('nguyenthuoc', N'Nguy?n Thu U?c', 'uocnguyen@777', 'nguyenthuoc@gmail.com', '0930123456', '1993-09-09', N'N?', '030012345678'),
('hoangvanhuy', N'Hoàng Van Huy', 'huyhoang001', 'hoangvanhuy@gmail.com', '0931234567', '1989-05-18', N'Nam', '031123456789'),
('duongthithu', N'Duong Th? Thu', 'thuthu@xyz', 'duongthithu@gmail.com', '0932345678', '1997-01-05', N'N?', '032234567890'),
('nguyenvananh', N'Nguy?n Van Ánh', 'anhnguyen@123', 'nguyenvananh@gmail.com', '0933456789', '1990-07-29', N'Nam', '033345678901'),
('tranvanthanh', N'Tr?n Van Thanh', 'thanhthanh@abc', 'tranvanthanh@gmail.com', '0934567890', '1992-03-02', N'Nam', '034456789012'),
('lethuhang', N'Lê Thu H?ng', 'hanghang@2023', 'lethuhang@gmail.com', '0935678901', '1994-11-21', N'N?', '035567890123'),
('nguyenthithuyduong', N'Nguy?n Th? Thùy Duong', 'duongduong@007', 'thuyduong@gmail.com', '0936789012', '1996-06-15', N'N?', '036678901234'),
('phamanhvu', N'Ph?m Anh Vu', 'vuvuva@123', 'phamanhvu@gmail.com', '0937890123', '1988-08-04', N'Nam', '037789012345'),
('nguyenthihuong', N'Nguy?n Th? Huong', 'huongnguyen@pass', 'nguyenthihuong@gmail.com', '0938901234', '1993-01-19', N'N?', '038890123456'),
('dovanlong', N'Ð? Van Long', 'longdo@abc', 'dovanlong@gmail.com', '0939012345', '1990-04-27', N'Nam', '039901234567'),
('tranvanhao', N'Tr?n Van H?o', 'hao_hao_001', 'tranvanhao@gmail.com', '0940123456', '1987-10-06', N'Nam', '040012345678'),
('nguyenductrung', N'Nguy?n Ð?c Trung', 'trung_nguyen@xyz', 'nguyenductrung@gmail.com', '0941234567', '1991-12-12', N'Nam', '041123456789'),
('phamanhthu', N'Ph?m Anh Thu', 'thuthu@111', 'phamanhthu@gmail.com', '0942345678', '1995-05-23', N'N?', '042234567890'),
('lethanhhien', N'Lê Thanh Hi?n', 'hienhien@2024', 'lethanhhien@gmail.com', '0943456789', '1994-02-01', N'N?', '043345678901'),
('nguyenthaithu', N'Nguy?n Thái Thu', 'thaithu@pass', 'nguyenthaithu@gmail.com', '0944567890', '1997-07-16', N'N?', '044456789012'),
('tranhoangnam', N'Tr?n Hoàng Nam', 'namtran@abc', 'tranhoangnam@gmail.com', '0945678901', '1989-03-08', N'Nam', '045567890123'),
('vuthithuong', N'Vu Th? Thuong', 'thuongvu@xyz', 'vuthithuong@gmail.com', '0946789012', '1993-09-29', N'N?', '046678901234'),
('nguyenminhquan', N'Nguy?n Minh Quân', 'quanminh@007', 'nguyenminhquan@gmail.com', '0947890123', '1990-11-03', N'Nam', '047789012345'),
('phamthithuong', N'Ph?m Th? Thu?ng', 'thuongpham@pass', 'phamthithuong@gmail.com', '0948901234', '1992-06-21', N'N?', '048890123456'),
('lehoanghai', N'Lê Hoàng H?i', 'hai_le_123', 'lehoanghai@gmail.com', '0949012345', '1986-08-10', N'Nam', '049901234567'),
('nguyenthanhnam', N'Nguy?n Thanh Nam', 'namnguyen@abc', 'nguyenthanhnam@gmail.com', '0950123456', '1995-04-14', N'Nam', '050012345678'),
('tranvanlinh', N'Tr?n Van Linh', 'linhtran001', 'tranvanlinh@gmail.com', '0951234567', '1988-01-07', N'Nam', '051123456789'),
('phamdanghuy', N'Ph?m Ðang Huy', 'huyhuy@xyz', 'phamdanghuy@gmail.com', '0952345678', '1996-03-22', N'Nam', '052234567890'),
('nguyentranthuy', N'Nguy?n Tr?n Thúy', 'thuythuy@2023', 'nguyentranthuy@gmail.com', '0953456789', '1994-10-09', N'N?', '053345678901'),
('dovuhoang', N'Ð? Vu Hoàng', 'hoanghoang@pass', 'dovuhoang@gmail.com', '0954567890', '1991-05-01', N'Nam', '054456789012'),
('nguyenthidiem', N'Nguy?n Th? Di?m', 'diemdiem@abc', 'nguyenthidiem@gmail.com', '0955678901', '1997-02-18', N'N?', '055567890123'),
('lequanganh', N'Lê Quang Anh', 'quanganh@xyz', 'lequanganh@gmail.com', '0956789012', '1989-07-25', N'Nam', '056678901234'),
('tranthiminhhien', N'Tr?n Th? Minh Hi?n', 'hientran@007', 'tranthiminhhien@gmail.com', '0957890123', '1993-01-04', N'N?', '057789012345'),
('nguyenduckhoa', N'Nguy?n Ð?c Khoa', 'khoanguyen@pass', 'nguyenduckhoa@gmail.com', '0958901234', '1990-11-20', N'Nam', '058890123456'),
('phambichhang', N'Ph?m Bích H?ng', 'hangpham@123', 'phambichhang@gmail.com', '0959012345', '1995-06-08', N'N?', '059901234567'),
('tranminhduc', N'Tr?n Minh Ð?c', 'duc_tran_001', 'tranminhduc@gmail.com', '0960123456', '1987-09-15', N'Nam', '060012345678'),
('nguyenthanhnga', N'Nguy?n Thanh Nga', 'nganguyen@abc', 'nguyenthanhnga@gmail.com', '0961234567', '1992-04-26', N'N?', '061123456789'),
('lequanghung', N'Lê Quang Hung', 'hunghung@xyz', 'lequanghung@gmail.com', '0962345678', '1988-02-13', N'Nam', '062234567890'),
('nguyenthanhhuyen', N'Nguy?n Thanh Huy?n', 'huyennguyen@2024', 'nguyenthanhhuyen@gmail.com', '0963456789', '1996-12-05', N'N?', '063345678901'),
('phamquangtrung', N'Ph?m Quang Trung', 'trungpham@pass', 'phamquangtrung@gmail.com', '0964567890', '1991-07-30', N'Nam', '064456789012'),
('hoangthithao', N'Hoàng Th? Th?o', 'thaothao@abc', 'hoangthithao@gmail.com', '0965678901', '1993-03-07', N'N?', '065567890123'),
('dovanviet', N'Ð? Van Vi?t', 'vietdo@007', 'dovanviet@gmail.com', '0966789012', '1986-09-02', N'Nam', '066678901234'),
('nguyenthiyen', N'Nguy?n Th? Y?n', 'yennguyen@xyz', 'nguyenthiyen@gmail.com', '0967890123', '1995-08-20', N'N?', '067789012345'),
('trandaiduong', N'Tr?n Ð?i Duong', 'duongtran@123', 'trandaiduong@gmail.com', '0968901234', '1989-04-11', N'Nam', '068890123456'),
('lethanhthao', N'Lê Thanh Th?o', 'thaole@pass', 'lethanhthao@gmail.com', '0969012345', '1997-01-13', N'N?', '069901234567'),
('nguyenbaoquang', N'Nguy?n B?o Quang', 'quangnguyen@001', 'nguyenbaoquang@gmail.com', '0970123456', '1990-10-25', N'Nam', '070012345678'),
('phamthithuytrang', N'Ph?m Th? Thùy Trang', 'trangpham@abc', 'phamthithuytrang@gmail.com', '0971234567', '1992-05-09', N'N?', '071123456789'),
('nguyenvanthinh', N'Nguy?n Van Th?nh', 'thinhnguyen@xyz', 'nguyenvanthinh@gmail.com', '0972345678', '1988-03-16', N'Nam', '072234567890'),
('tranvanthang', N'Tr?n Van Th?ng', 'thangtran@pass', 'tranvanthang@gmail.com', '0973456789', '1996-02-28', N'Nam', '073345678901'),
('lethianhdao', N'Lê Th? Anh Ðào', 'anhdao@2023', 'lethianhdao@gmail.com', '0974567890', '1994-09-03', N'N?', '074456789012'),
('nguyenthanhhai', N'Nguy?n Thanh H?i', 'hainguyen@007', 'nguyenthanhhai@gmail.com', '0975678901', '1991-06-10', N'Nam', '075567890123'),
('tranvanhieu', N'Tr?n Van Hi?u', 'hieutran@abc', 'tranvanhieu@gmail.com', '0976789012', '1987-12-01', N'Nam', '076678901234'),
('phamthihuonggiang', N'Ph?m Th? Huong Giang', 'giangpham@xyz', 'phamthihuonggiang@gmail.com', '0977890123', '1995-07-22', N'N?', '077789012345'),
('nguyenvantu', N'Nguy?n Van Tú', 'tunguyen@pass', 'nguyenvantu@gmail.com', '0978901234', '1993-04-19', N'Nam', '078890123456'),
('dothimyanh', N'Ð? Th? M? Anh', 'myanhdo@123', 'dothimyanh@gmail.com', '0979012345', '1997-03-06', N'N?', '079901234567'),
('hoangminhkhai', N'Hoàng Minh Kh?i', 'khaipham@001', 'hoangminhkhai@gmail.com', '0980123456', '1990-08-28', N'Nam', '080012345678'),
('nguyenthithanhtruyen', N'Nguy?n Th? Thanh Truy?n', 'truyennguyen@abc', 'nguyenthithanhtruyen@gmail.com', '0981234567', '1992-02-15', N'N?', '081123456789'),
('tranlehuu', N'Tr?n Lê H?u', 'huutran@xyz', 'tranlehuu@gmail.com', '0982345678', '1989-06-04', N'Nam', '082234567890'),
('lethibichngoc', N'Lê Th? Bích Ng?c', 'ngocle@pass', 'lethibichngoc@gmail.com', '0983456789', '1996-10-18', N'N?', '083345678901'),
('nguyenthanhphong', N'Nguy?n Thanh Phong', 'phongnguyen@007', 'nguyenthanhphong@gmail.com', '0984567890', '1991-01-09', N'Nam', '084456789012'),
('phamvanquang', N'Ph?m Van Quang', 'quangpham@123', 'phamvanquang@gmail.com', '0985678901', '1988-11-27', N'Nam', '085567890123'),
('nguyenthingocthao', N'Nguy?n Th? Ng?c Th?o', 'thaonguyen@abc', 'nguyenthingocthao@gmail.com', '0986789012', '1995-05-17', N'N?', '086678901234'),
('tranhuonggiang', N'Tr?n Huong Giang', 'giangtran@xyz', 'tranhuonggiang@gmail.com', '0987890123', '1993-12-02', N'N?', '087789012345'),
('lethanhdat', N'Lê Thanh Ð?t', 'datle@pass', 'lethanhdat@gmail.com', '0988901234', '1990-06-29', N'Nam', '088890123456'),
('nguyenthithanhtuyen', N'Nguy?n Th? Thanh Tuy?n', 'tuyennguyen@001', 'nguyenthithanhtuyen@gmail.com', '0989012345', '1994-02-08', N'N?', '089901234567'),
('phanvanthuan', N'Phan Van Thu?n', 'thuanphan@abc', 'phanvanthuan@gmail.com', '0990123456', '1987-07-20', N'Nam', '090012345678'),
('nguyenthuhoai', N'Nguy?n Thu Hoài', 'hoainguyen@xyz', 'nguyenthuhoai@gmail.com', '0991234567', '1997-01-26', N'N?', '091123456789'),
('tranvanhai', N'Tr?n Van H?i', 'haitran@pass', 'tranvanhai@gmail.com', '0992345678', '1989-09-05', N'Nam', '092234567890'),
('lethuytrang', N'Lê Thùy Trang', 'trangle@007', 'lethuytrang@gmail.com', '0993456789', '1993-04-01', N'N?', '093345678901'),
('nguyenhoangnam', N'Nguy?n Hoàng Nam', 'namnguyen@123', 'nguyenhoangnam@gmail.com', '0994567890', '1990-11-19', N'Nam', '094456789012'),
('phamanhthao', N'Ph?m Anh Th?o', 'thaopham@abc', 'phamanhthao@gmail.com', '0995678901', '1992-06-27', N'N?', '095567890123'),
('nguyenthanhngoc', N'Nguy?n Thanh Ng?c', 'ngocnguyen@xyz', 'nguyenthanhngoc@gmail.com', '0996789012', '1996-08-11', N'N?', '096678901234'),
('tranvannhan', N'Tr?n Van Nh?n', 'nhantran@pass', 'tranvannhan@gmail.com', '0997890123', '1986-12-08', N'Nam', '097789012345'),
('lethanhhieu', N'Lê Thanh Hi?u', 'hieule@001', 'lethanhhieu@gmail.com', '0998901234', '1995-03-04', N'Nam', '098890123456'),
('nguyenthihaiduong', N'Nguy?n Th? H?i Ðu?ng', 'haiduong@2024', 'nguyenthihaiduong@gmail.com', '0999012345', '1994-09-10', N'N?', '099901234567'),
('tranminhanh', N'Tr?n Minh Anh', 'minhanh@abc', 'tranminhanh@gmail.com', '0800123456', '1991-07-07', N'Nam', '100012345678'),
('nguyenthihoangyen', N'Nguy?n Th? Hoàng Y?n', 'hoangyen@xyz', 'nguyenthihoangyen@gmail.com', '0801234567', '1993-02-28', N'N?', '101123456789'),
('phamanhlinh', N'Ph?m Anh Linh', 'linhpham@pass', 'phamanhlinh@gmail.com', '0802345678', '1988-05-13', N'Nam', '102234567890'),
('lethidieulinh', N'Lê Th? Di?u Linh', 'dieulinh@007', 'lethidieulinh@gmail.com', '0803456789', '1996-01-02', N'N?', '103345678901'),
('nguyenvandat', N'Nguy?n Van Ð?t', 'datnguyen@123', 'nguyenvandat@gmail.com', '0804567890', '1990-10-16', N'Nam', '104456789012'),
('tranvanhuy', N'Tr?n Van Huy', 'huytran@abc', 'tranvanhuy@gmail.com', '0805678901', '1987-03-24', N'Nam', '105567890123'),
('nguyenthicamlinh', N'Nguy?n Th? C?m Linh', 'camlinh@xyz', 'nguyenthicamlinh@gmail.com', '0806789012', '1995-08-05', N'N?', '106678901234'),
('dovanminh', N'Ð? Van Minh', 'minhdo@pass', 'dovanminh@gmail.com', '0807890123', '1993-11-14', N'Nam', '107789012345'),
('hoangthuyquynh', N'Hoàng Thùy Qu?nh', 'quynhhoang@001', 'hoangthuyquynh@gmail.com', '0808901234', '1997-04-21', N'N?', '108890123456'),
('nguyenthehai', N'Nguy?n Th? H?i', 'hai_nguyen_001', 'nguyenthehai@gmail.com', '0809012345', '1989-09-09', N'Nam', '109901234567'),
('tranthingocanh', N'Tr?n Th? Ng?c Ánh', 'ngocanh@abc', 'tranthingocanh@gmail.com', '0810123456', '1994-01-01', N'N?', '110012345678'),
('phamhoanglong', N'Ph?m Hoàng Long', 'longpham@xyz', 'phamhoanglong@gmail.com', '0811234567', '1991-06-16', N'Nam', '111123456789'),
('nguyenthithanhmai', N'Nguy?n Th? Thanh Mai', 'thanhmai@pass', 'nguyenthithanhmai@gmail.com', '0812345678', '1992-12-25', N'N?', '112234567890'),
('leminhhoang', N'Lê Minh Hoàng', 'hoangle@007', 'leminhhoang@gmail.com', '0813456789', '1986-07-03', N'Nam', '113345678901'),
('nguyenthithuongthuong', N'Nguy?n Th? Thuong Thuong', 'thuongthuong@123', 'nguyenthithuongthuong@gmail.com', '0814567890', '1995-02-11', N'N?', '114456789012'),
('tranvanduy', N'Tr?n Van Duy', 'duytran@abc', 'tranvanduy@gmail.com', '0815678901', '1988-04-29', N'Nam', '115567890123'),
('hoangthanhson', N'Hoàng Thanh Son', 'sontran@xyz', 'hoangthanhson@gmail.com', '0816789012', '1996-09-19', N'Nam', '116678901234'),
('nguyenthithanhloan', N'Nguy?n Th? Thanh Loan', 'loannguyen@pass', 'nguyenthithanhloan@gmail.com', '0817890123', '1994-05-24', N'N?', '117789012345'),
('phanminhduc', N'Phan Minh Ð?c', 'ducphan@007', 'phanminhduc@gmail.com', '0818901234', '1991-10-08', N'Nam', '118890123456'),
('nguyenthithanhtrang', N'Nguy?n Th? Thanh Trang', 'trangnguyen@123', 'nguyenthithanhtrang@gmail.com', '0819012345', '1997-03-12', N'N?', '119901234567'),
('dovanhoa', N'Ð? Van Hòa', 'hoado@abc', 'dovanhoa@gmail.com', '0820123456', '1990-08-01', N'Nam', '120012345678'),
('tranvannguyen', N'Tr?n Van Nguyên', 'nguyentran@xyz', 'tranvannguyen@gmail.com', '0821234567', '1987-02-09', N'Nam', '121123456789'),
('lethithuyhang', N'Lê Th? Thùy H?ng', 'thuyhang@pass', 'lethithuyhang@gmail.com', '0822345678', '1995-11-20', N'N?', '122234567890'),
('nguyenthanhhaiyen', N'Nguy?n Thanh H?i Y?n', 'haiyen@001', 'nguyenthanhhaiyen@gmail.com', '0823456789', '1993-06-25', N'N?', '123345678901'),
('phamanhdao', N'Ph?m Anh Ðào', 'anhdao@abc', 'phamanhdao@gmail.com', '0824567890', '1989-01-14', N'Nam', '124456789012'),
('nguyenthidiemhuong', N'Nguy?n Th? Di?m Huong', 'diemhuong@xyz', 'nguyenthidiemhuong@gmail.com', '0825678901', '1996-04-03', N'N?', '125567890123'),
('tranvanlam', N'Tr?n Van Lâm', 'lamtran@pass', 'tranvanlam@gmail.com', '0826789012', '1990-09-17', N'Nam', '126678901234'),
('lethithuha', N'Lê Th? Thu Hà', 'thuha@007', 'lethithuha@gmail.com', '0827890123', '1992-07-07', N'N?', '127789012345'),
('nguyenthanhduy', N'Nguy?n Thanh Duy', 'duynguyen@123', 'nguyenthanhduy@gmail.com', '0828901234', '1986-12-01', N'Nam', '128890123456'),
('phamvandai', N'Ph?m Van Ð?i', 'daipham@abc', 'phamvandai@gmail.com', '0829012345', '1995-03-29', N'Nam', '129901234567'),
('nguyenthikieuanh', N'Nguy?n Th? Ki?u Anh', 'kieuanh@xyz', 'nguyenthikieuanh@gmail.com', '0830123456', '1994-10-11', N'N?', '130012345678'),
('tranvanthanglong', N'Tr?n Van Thang Long', 'thanglong@pass', 'tranvanthanglong@gmail.com', '0831234567', '1991-05-02', N'Nam', '131123456789'),
('lethithuongmai', N'Lê Th? Thuong M?i', 'thuongmai@001', 'lethithuongmai@gmail.com', '0832345678', '1997-02-23', N'N?', '132234567890'),
('nguyenthanhphuong', N'Nguy?n Thanh Phuong', 'phuongnguyen@abc', 'nguyenthanhphuong@gmail.com', '0833456789', '1990-08-16', N'N?', '133345678901'),
('phamvanlinh', N'Ph?m Van Linh', 'linhpham@xyz', 'phamvanlinh@gmail.com', '0834567890', '1987-01-05', N'Nam', '134456789012'),
('nguyenthithuonguyen', N'Nguy?n Th? Thu Uyên', 'thuuyen@pass', 'nguyenthithuonguyen@gmail.com', '0835678901', '1995-12-09', N'N?', '135567890123'),
('tranvantuan', N'Tr?n Van Tu?n', 'tuan_tran@007', 'tranvantuan@gmail.com', '0836789012', '1993-07-27', N'Nam', '136678901234'),
('lethithuhoa', N'Lê Th? Thu Hòa', 'thuhoa@123', 'lethithuhoa@gmail.com', '0837890123', '1996-03-10', N'N?', '137789012345'),
('nguyenthanhkhoa', N'Nguy?n Thanh Khoa', 'khoanguyen@abc', 'nguyenthanhkhoa@gmail.com', '0838901234', '1989-09-06', N'Nam', '138890123456'),
('phamthihuynhhuong', N'Ph?m Th? Hu?nh Huong', 'huongpham@xyz', 'phamthihuynhhuong@gmail.com', '0839012345', '1994-04-15', N'N?', '139901234567'),
('nguyenvancuong', N'Nguy?n Van Cu?ng', 'cuongnguyen@pass', 'nguyenvancuong@gmail.com', '0840123456', '1991-08-08', N'Nam', '140012345678'),
('tranthingochuyen', N'Tr?n Th? Ng?c Huy?n', 'ngochuyen@001', 'tranthingochuyen@gmail.com', '0841234567', '1992-01-21', N'N?', '141123456789'),
('lethanhhien_a', N'Lê Thanh Hi?n', 'hienle@abc', 'lethanhhien@gmail.com', '0842345678', '1988-06-18', N'N?', '142234567890'),
('nguyenthanhtrung', N'Nguy?n Thanh Trung', 'trungnguyen@xyz', 'nguyenthanhtrung@gmail.com', '0843456789', '1996-10-04', N'Nam', '143345678901'),
('phamvanminh_a', N'Ph?m Van Minh', 'minhpham@pass', 'phamvanminh@gmail.com', '0844567890', '1993-05-30', N'Nam', '144456789012'),
('nguyenthihuongly', N'Nguy?n Th? Huong Ly', 'huongly@007', 'nguyenthihuongly@gmail.com', '0845678901', '1997-01-17', N'N?', '145567890123'),
('tranvanphuong_a', N'Tr?n Van Phuong', 'phuongtran@123', 'tranvanphuong@gmail.com', '0846789012', '1990-04-20', N'Nam', '146678901234'),
('lethithuong', N'Lê Th? Thuong', 'thuongle@abc', 'lethithuong@gmail.com', '0847890123', '1992-09-02', N'N?', '147789012345'),
('nguyenthanhtam', N'Nguy?n Thanh Tâm', 'tamnguyen@xyz', 'nguyenthanhtam@gmail.com', '0848901234', '1987-03-11', N'Nam', '148890123456'),
('phamnhatnam', N'Ph?m Nh?t Nam', 'nampham@pass', 'phamnhatnam@gmail.com', '0849012345', '1995-06-06', N'Nam', '149901234567'),
('tranvanhieu_a', N'Tr?n Van Hi?u', 'hieutran@001', 'tranvanhieu_a@gmail.com', '0850123456', '1994-01-28', N'Nam', '150012345678'),
('nguyenthibichloan', N'Nguy?n Th? Bích Loan', 'bichloan@gmail.com', 'nguyenthibichloan@gmail.com', '0851234567', '1993-08-19', N'N?', '151123456789'),
('levanlinh', N'Lê Van Linh', 'linhle@gmail.com', 'levanlinh@gmail.com', '0852345678', '1989-02-12', N'Nam', '152234567890'),
('nguyenthihoangthao', N'Nguy?n Th? Hoàng Th?o', 'hoangthao@gmail.com', 'nguyenthihoangthao@gmail.com', '0853456789', '1996-05-01', N'N?', '153345678901'),
('phamvanduong', N'Ph?m Van Duong', 'vanduong@gmail.com', 'phamvanduong@gmail.com', '0854567890', '1990-10-09', N'Nam', '154456789012'),
('tranvandung', N'Tr?n Van Dung', 'vandung@gmail.com', 'tranvandung@gmail.com', '0855678901', '1987-04-04', N'Nam', '155567890123'),
('nguyenthithuonglan', N'Nguy?n Th? Thuong Lan', 'thuonglan@gmail.com', 'nguyenthithuonglan@gmail.com', '0856789012', '1995-09-22', N'N?', '156678901234'),
('leminhquang', N'Lê Minh Quang', 'minhquang@gmail.com', 'leminhquang@gmail.com', '0857890123', '1993-01-31', N'Nam', '157789012345'),
('nguyenthanhhoa_a', N'Nguy?n Thanh Hòa', 'thanhhoa@gmail.com', 'nguyenthanhhoa_a@gmail.com', '0858901234', '1997-06-15', N'N?', '158890123456'),
('dovanloc', N'Ð? Van L?c', 'vanloc@gmail.com', 'dovanloc@gmail.com', '0859012345', '1990-11-29', N'Nam', '159901234567'),
('tranvanthuy', N'Tr?n Van Thúy', 'vanthuy@gmail.com', 'tranvanthuy@gmail.com', '0860123456', '1988-02-07', N'N?', '160012345678'),
('nguyenthithanhtuyen_a', N'Nguy?n Th? Thanh Tuy?n', 'thanhtuyen@gmail.com', 'nguyenthihuonguyen@gmail.com', '0861234567', '1996-07-03', N'N?', '161123456789'),
('lethanhgiang', N'Lê Thanh Giang', 'thanhgiang@gmail.com', 'lethanhgiang@gmail.com', '0862345678', '1989-12-10', N'Nam', '162234567890'),
('nguyenthibichhang', N'Nguy?n Th? Bích H?ng', 'bichhang@gmail.com', 'nguyenthibichhang@gmail.com', '0863456789', '1994-05-25', N'N?', '163345678901'),
('phamvanhuy_a', N'Ph?m Van Huy', 'vanhuy@gmail.com', 'phamvanhuy@gmail.com', '0864567890', '1991-03-18', N'Nam', '164456789012'),
('tranvannghia', N'Tr?n Van Nghia', 'vannghia@gmail.com', 'tranvannghia@gmail.com', '0865678901', '1986-09-01', N'Nam', '165567890123'),
('nguyenthuhoai_a', N'Nguy?n Thu Hoài', 'thuhoai@gmail.com', 'nguyenthuhoai_a@gmail.com', '0866789012', '1995-04-10', N'N?', '166678901234'),
('lethithanhanh', N'Lê Th? Thanh Anh', 'thanhanh@gmail.com', 'lethithanhanh@gmail.com', '0867890123', '1993-01-07', N'N?', '167789012345'),
('nguyenvancuong_a', N'Nguy?n Van Cu?ng', 'vancuong@gmail.com', 'nguyenvancuong_a@gmail.com', '0868901234', '1990-10-23', N'Nam', '168890123456'),
('phamanhthao_a', N'Ph?m Anh Th?o', 'anhthao@gmail.com', 'phamanhthao_a@gmail.com', '0869012345', '1992-06-05', N'N?', '169901234567'),
('tranvanthang_b', N'Tr?n Van Th?ng', 'vanthang@gmail.com', 'tranvanthang_b@gmail.com', '0870123456', '1989-11-16', N'Nam', '170012345678'),
('nguyenthingoclinh', N'Nguy?n Th? Ng?c Linh', 'ngoclinh@gmail.com', 'nguyenthingoclinh@gmail.com', '0871234567', '1996-08-27', N'N?', '171123456789'),
('lethanhlong', N'Lê Thanh Long', 'thanhlong@gmail.com', 'lethanhlong@gmail.com', '0872345678', '1987-03-03', N'Nam', '172234567890'),
('nguyentranthuy_a', N'Nguy?n Tr?n Thúy', 'tranthuy@gmail.com', 'nguyentranthuy_a@gmail.com', '0873456789', '1995-02-14', N'N?', '173345678901'),
('phamvanquang_a', N'Ph?m Van Quang', 'vanquang@gmail.com', 'phamvanquang_a@gmail.com', '0874567890', '1993-07-20', N'Nam', '174456789012'),
('tranvanquy_b', N'Tr?n Van Quý', 'vanquy@gmail.com', 'tranvanquy_b@gmail.com', '0875678901', '1990-04-08', N'Nam', '175567890123'),
('nguyenthithanhbinh', N'Nguy?n Th? Thanh Bình', 'thanhbinh@gmail.com', 'nguyenthithanhbinh@gmail.com', '0876789012', '1997-01-05', N'N?', '176678901234'),
('leminhanh', N'Lê Minh Anh', 'minhanh_le@gmail.com', 'leminhanh@gmail.com', '0877890123', '1989-09-12', N'Nam', '177789012345'),
('nguyenthithuylinh', N'Nguy?n Th? Thùy Linh', 'thuylinh@gmail.com', 'nguyenthithuylinh@gmail.com', '0878901234', '1994-02-23', N'N?', '178890123456'),
('phamvanhung_a', N'Ph?m Van Hùng', 'vanhung@gmail.com', 'phamvanhung_a@gmail.com', '0879012345', '1991-06-11', N'Nam', '179901234567'),
('tranvanthanh_b', N'Tr?n Van Thanh', 'vanthanh@gmail.com', 'tranvanthanh_b@gmail.com', '0880123456', '1986-12-04', N'Nam', '180012345678'),
('nguyenthibichhong', N'Nguy?n Th? Bích H?ng', 'bichhong@gmail.com', 'nguyenthibichhong@gmail.com', '0881234567', '1995-07-18', N'N?', '181123456789'),
('levanduc', N'Lê Van Ð?c', 'vanduc@gmail.com', 'levanduc@gmail.com', '0882345678', '1993-03-09', N'Nam', '182234567890'),
('nguyenthanhhoa_b', N'Nguy?n Thanh Hòa', 'thanhhoa_b@gmail.com', 'nguyenthanhhoa_b@gmail.com', '0883456789', '1997-05-20', N'N?', '183345678901'),
('phamminhtrung', N'Ph?m Minh Trung', 'minhtrung@gmail.com', 'phamminhtrung@gmail.com', '0884567890', '1990-11-01', N'Nam', '184456789012'),
('tranvancuong_b', N'Tr?n Van Cu?ng', 'vancuong_b@gmail.com', 'tranvancuong_b@gmail.com', '0885678901', '1987-08-25', N'Nam', '185567890123'),
('nguyenthithanhnguyen', N'Nguy?n Th? Thanh Nguyên', 'thanhnguyen@gmail.com', 'nguyenthithanhnguyen@gmail.com', '0886789012', '1996-04-07', N'N?', '186678901234'),
('lehoanghai_a', N'Lê Hoàng H?i', 'hoanghai@gmail.com', 'lehoanghai_a@gmail.com', '0887890123', '1989-10-14', N'Nam', '187789012345'),
('nguyenthithuonghoai', N'Nguy?n Th? Thuong Hoài', 'thuonghoai@gmail.com', 'nguyenthithuonghoai@gmail.com', '0888901234', '1994-09-08', N'N?', '188890123456'),
('phamanhthao_b', N'Ph?m Anh Th?o', 'anhthao_b@gmail.com', 'phamanhthao_b@gmail.com', '0889012345', '1991-02-01', N'N?', '189901234567'),
('tranvanduy_b', N'Tr?n Van Duy', 'vanduy@gmail.com', 'tranvanduy_b@gmail.com', '0890123456', '1986-06-20', N'Nam', '190012345678'),
('nguyenthibichthuy', N'Nguy?n Th? Bích Thúy', 'bichthuy@gmail.com', 'nguyenthibichthuy@gmail.com', '0891234567', '1995-11-11', N'N?', '191123456789'),
('lehoangviet_a', N'Lê Hoàng Vi?t', 'hoangviet@gmail.com', 'lehoangviet_a@gmail.com', '0892345678', '1993-08-03', N'Nam', '192234567890'),
('nguyenthanhhoa_c', N'Nguy?n Thanh Hòa', 'thanhhoa_c@gmail.com', 'nguyenthanhhoa_c@gmail.com', '0893456789', '1997-04-25', N'N?', '193345678901'),
('phamvanlam', N'Ph?m Van Lâm', 'vanlam@gmail.com', 'phamvanlam@gmail.com', '0894567890', '1990-12-19', N'Nam', '194456789012'),
('tranvanlong_b', N'Tr?n Van Long', 'vanlong@gmail.com', 'tranvanlong_b@gmail.com', '0895678901', '1987-05-08', N'Nam', '195567890123'),
('nguyenthithanhngoc_a', N'Nguy?n Th? Thanh Ng?c', 'thanhngoc@gmail.com', 'nguyenthithanhngoc_a@gmail.com', '0896789012', '1996-01-30', N'N?', '196678901234'),
('leminhquy', N'Lê Minh Quý', 'minhquy@gmail.com', 'leminhquy@gmail.com', '0897890123', '1989-03-27', N'Nam', '197789012345'),
('nguyenthihuong_b', N'Nguy?n Th? Huong', 'huong_b@gmail.com', 'nguyenthihuong_b@gmail.com', '0898901234', '1994-10-06', N'N?', '198890123456'),
('phamvananh', N'Ph?m Van Anh', 'vananh@gmail.com', 'phamvananh@gmail.com', '0899012345', '1991-07-14', N'Nam', '199901234567'),
('tranvanlinh_b', N'Tr?n Van Linh', 'vanlinh@gmail.com', 'tranvanlinh_b@gmail.com', '0900123456', '1988-04-02', N'Nam', '200012345678');
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
-- Hạng nhất (15 ghế)
('A-01', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-02', 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-03', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-04', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-05', 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-06', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-07', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-08', 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-09', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-10', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-11', 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-12', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-13', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-14', 'VN201', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-15', 'VN201', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế)
('B-01', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-02', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-03', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-04', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-05', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-06', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-07', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-08', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-09', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-10', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-11', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-12', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-13', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-14', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-15', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-16', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-17', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-18', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-19', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-20', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-21', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-22', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-23', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-24', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-25', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-26', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-27', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-28', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-29', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-30', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-31', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-32', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
('B-33', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-34', 'VN201', 2000000.00, N'Thương gia', N'có sẵn'),
('B-35', 'VN201', 2000000.00, N'Thương gia', N'đã đặt'),
-- Phổ thông (100 ghế)
('C-01', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-02', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-03', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-04', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-05', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-06', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-07', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-08', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-09', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-10', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-11', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-12', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-13', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-14', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-15', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-16', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-17', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-18', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-19', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-20', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-01', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-02', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-03', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-04', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-05', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-06', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-07', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-08', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-09', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-10', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-11', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-12', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-13', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-14', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-15', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-16', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-17', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-18', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-19', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-20', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-01', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-02', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-03', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-04', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-05', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-06', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-07', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-08', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-09', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-10', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-11', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-12', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-13', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-14', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-15', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-16', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-17', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-18', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-19', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-20', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-01', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-02', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-03', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-04', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-05', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-06', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-07', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-08', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-09', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-10', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-11', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-12', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-13', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-14', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-15', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-16', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-17', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-18', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-19', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-20', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-01', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-02', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-03', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-04', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-05', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-06', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-07', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-08', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-09', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-10', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-11', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-12', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-13', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-14', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-15', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-16', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-17', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-18', 'VN201', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-19', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-20', 'VN201', 1000000.00, N'Phổ thông', N'có sẵn');
----
----
INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH) VALUES
-- H?ng nh?t (5 gh? dã d?t)
('DV001', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN201', 'KH001'), -- A02
('DV002', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN201', 'KH002'), -- A05
('DV003', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN201', 'KH003'), -- A08
('DV004', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN201', 'KH004'), -- A11
('DV005', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN201', 'KH005'), -- A14

-- Thuong gia (9 gh? dã d?t)
('DV006', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH006'), -- B02
('DV007', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH007'), -- B05
('DV008', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH008'), -- B08
('DV009', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH009'), -- B11
('DV010', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH010'), -- B14
('DV011', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH011'), -- B17
('DV012', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH012'), -- B20
('DV013', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH013'), -- B23
('DV014', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN201', 'KH014'), -- B26

-- Ph? thông (28 gh? dã d?t)
('DV015', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH015'), -- C02
('DV016', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH016'), -- C05
('DV017', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH017'), -- C08
('DV018', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH018'), -- C11
('DV019', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH019'), -- C14
('DV020', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH020'), -- C17
('DV021', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH021'), -- C20
('DV022', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH022'), -- D03
('DV023', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH023'), -- D06
('DV024', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH024'), -- D09
('DV025', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH025'), -- D12
('DV026', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH026'), -- D15
('DV027', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH027'), -- D18
('DV028', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH028'), -- E01
('DV029', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH029'), -- E04
('DV030', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH030'), -- E07
('DV031', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH031'), -- E10
('DV032', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH032'), -- E13
('DV033', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH033'), -- E16
('DV034', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH034'), -- E19
('DV035', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH035'), -- F02
('DV036', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH036'), -- F05
('DV037', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH037'), -- F08
('DV038', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH038'), -- F11
('DV039', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH039'), -- F14
('DV040', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH040'), -- G03
('DV041', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH041'), -- G06
('DV042', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN201', 'KH042'); -- G18

---
---
-- Ghế cho chuyến bay VN202
-- Hạng nhất (15 ghế) - 2 ghế đã đặt
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
('A-01', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-02', 'VN202', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-03', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-04', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-05', 'VN202', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-06', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-07', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-08', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-09', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-10', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-11', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-12', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-13', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-14', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-15', 'VN202', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế) - 3 ghế đã đặt
('B-01', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-02', 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
('B-03', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-04', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-05', 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
('B-06', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-07', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-08', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-09', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-10', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-11', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-12', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-13', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-14', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-15', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-16', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-17', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-18', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-19', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-20', 'VN202', 2000000.00, N'Thương gia', N'đã đặt'),
('B-21', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-22', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-23', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-24', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-25', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-26', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-27', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-28', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-29', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-30', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-31', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-32', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-33', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-34', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
('B-35', 'VN202', 2000000.00, N'Thương gia', N'có sẵn'),
-- Phổ thông (100 ghế) - 5 ghế đã đặt
('C-01', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-02', 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-03', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-04', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-05', 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-06', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-07', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-08', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-09', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-10', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-11', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-12', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-13', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-14', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-15', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-16', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-17', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-18', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-19', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-20', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-01', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-02', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-03', 'VN202', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-04', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-05', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-06', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-07', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-08', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-09', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-10', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-11', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-12', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-13', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-14', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-15', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-16', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-17', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-18', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-19', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-20', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-01', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-02', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-03', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-04', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-05', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-06', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-07', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-08', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-09', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-10', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-11', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-12', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-13', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-14', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-15', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-16', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-17', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-18', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-19', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-20', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-01', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-02', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-03', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-04', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-05', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-06', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-07', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-08', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-09', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-10', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-11', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-12', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-13', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-14', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-15', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-16', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-17', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-18', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-19', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-20', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-01', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-02', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-03', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-04', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-05', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-06', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-07', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-08', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-09', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-10', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-11', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-12', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-13', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-14', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-15', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-16', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-17', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-18', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-19', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-20', 'VN202', 1000000.00, N'Phổ thông', N'có sẵn');
---
---
INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH) VALUES
-- H?ng nh?t (2 gh? dã d?t)
('DV043', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN202', 'KH001'), -- A02
('DV044', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 3000000.00, 'VN202', 'KH002'), -- A05

-- Thuong gia (3 gh? dã d?t)
('DV045', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN202', 'KH003'), -- B02
('DV046', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN202', 'KH004'), -- B05
('DV047', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 2000000.00, 'VN202', 'KH005'), -- B20

-- Ph? thông (5 gh? dã d?t)
('DV048', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN202', 'KH006'), -- C02
('DV049', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN202', 'KH007'), -- C05
('DV050', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN202', 'KH008'), -- D03
('DV051', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN202', 'KH009'), -- G03
('DV052', '2025-05-22', '2025-07-11', N'Ðã thanh toán', 1, 1000000.00, 'VN202', 'KH010'); -- G06
---
---
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN203
-- Hạng nhất (15 ghế) - 5 ghế đã đặt
('A-01', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-02', 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-03', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-04', 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-05', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-06', 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-07', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-08', 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-09', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-10', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-11', 'VN203', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-12', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-13', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-14', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-15', 'VN203', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế) - 25 ghế đã đặt
('B-01', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-02', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-03', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-04', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-05', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-06', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-07', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-08', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-09', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-10', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-11', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-12', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-13', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-14', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-15', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-16', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-17', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-18', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-19', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-20', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-21', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-22', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-23', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-24', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-25', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-26', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-27', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-28', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-29', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-30', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-31', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-32', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-33', 'VN203', 2000000.00, N'Thương gia', N'có sẵn'),
('B-34', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
('B-35', 'VN203', 2000000.00, N'Thương gia', N'đã đặt'),
-- Phổ thông (100 ghế) - 40 ghế đã đặt
('C-01', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-02', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-03', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-04', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-05', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-06', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-07', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-08', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-09', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-10', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-11', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-12', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-13', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-14', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-15', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-16', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-17', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-18', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-19', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-20', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-01', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-02', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-03', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-04', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-05', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-06', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-07', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-08', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-09', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-10', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-11', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-12', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-13', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-14', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-15', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-16', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-17', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-18', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-19', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-20', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-01', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-02', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-03', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-04', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-05', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-06', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-07', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-08', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-09', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-10', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-11', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-12', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-13', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-14', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-15', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-16', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-17', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-18', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-19', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('E-20', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-01', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-02', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-03', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-04', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-05', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-06', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-07', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-08', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-09', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-10', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-11', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-12', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-13', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-14', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-15', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-16', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-17', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('F-18', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-19', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-20', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-01', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-02', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-03', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-04', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-05', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-06', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-07', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-08', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-09', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-10', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-11', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-12', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-13', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-14', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-15', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-16', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-17', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-18', 'VN203', 1000000.00, N'Phổ thông', N'đã đặt'),
('G-19', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-20', 'VN203', 1000000.00, N'Phổ thông', N'có sẵn');

---
---
INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH)
VALUES
('DV001', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 3000000.00, 'VN203', 'KH001'), -- A02
('DV002', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 3000000.00, 'VN203', 'KH002'), -- A04
('DV003', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 3000000.00, 'VN203', 'KH003'), -- A06
('DV004', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 3000000.00, 'VN203', 'KH004'), -- A08
('DV005', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 3000000.00, 'VN203', 'KH005'), -- A11
-- Thuong gia (25 gh? dã d?t)
('DV006', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH006'), -- B01
('DV007', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH007'), -- B02
('DV008', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH008'), -- B03
('DV009', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH009'), -- B05
('DV010', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH010'), -- B06
('DV011', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH011'), -- B08
('DV012', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH012'), -- B09
('DV013', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH013'), -- B11
('DV014', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH014'), -- B12
('DV015', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH015'), -- B14
('DV016', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH016'), -- B15
('DV017', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH017'), -- B17
('DV018', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH018'), -- B18
('DV019', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH019'), -- B20
('DV020', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH020'), -- B21
('DV021', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH021'), -- B23
('DV022', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH022'), -- B24
('DV023', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH023'), -- B26
('DV024', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH024'), -- B27
('DV025', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH025'), -- B29
('DV026', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH026'), -- B30
('DV027', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH027'), -- B32
('DV028', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH028'), -- B34
('DV029', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 2000000.00, 'VN203', 'KH029'), -- B35
-- Ph? thông (40 gh? dã d?t)
('DV030', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH030'), -- C01
('DV031', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH031'), -- C02
('DV032', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH032'), -- C03
('DV033', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH033'), -- C05
('DV034', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH034'), -- C06
('DV035', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH035'), -- C08
('DV036', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH036'), -- C09
('DV037', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH037'), -- C11
('DV038', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH038'), -- C12
('DV039', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH039'), -- C14
('DV040', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH040'), -- C15
('DV041', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH041'), -- C17
('DV042', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH042'), -- C18
('DV043', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH043'), -- C20
('DV044', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH044'), -- D01
('DV045', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH045'), -- D03
('DV046', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH046'), -- D04
('DV047', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH047'), -- D06
('DV048', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH048'), -- D07
('DV049', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH049'), -- D09
('DV050', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH050'), -- D10
('DV051', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH051'), -- D12
('DV052', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH052'), -- D13
('DV053', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH053'), -- D15
('DV054', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH054'), -- D16
('DV055', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH055'), -- D18
('DV056', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH056'), -- D19
('DV057', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH057'), -- E01
('DV058', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH058'), -- E02
('DV059', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH059'), -- E04
('DV060', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH060'), -- E05
('DV061', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH061'), -- E07
('DV062', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH062'), -- E08
('DV063', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH063'), -- E10
('DV064', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH064'), -- E11
('DV065', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH065'), -- E13
('DV066', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH066'), -- E14
('DV067', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH067'), -- E16
('DV068', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH068'), -- E17
('DV069', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH069'), -- E19
('DV070', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH070'), -- E20
('DV071', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH071'), -- F01
('DV072', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH072'), -- F02
('DV073', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH073'), -- F05
('DV074', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH074'), -- F08
('DV075', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH075'), -- F11
('DV076', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH076'), -- F14
('DV077', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH077'), -- F17
('DV078', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH078'), -- F20
('DV079', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH079'), -- G03
('DV080', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH080'), -- G06
('DV081', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH081'), -- G09
('DV082', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH082'), -- G12
('DV083', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH083'), -- G15
('DV084', '2025-05-22', '2025-06-15', N'Ðã thanh toán', 1, 1000000.00, 'VN203', 'KH084'); -- G18
----
----
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN204
-- Dữ liệu ghế đã được cập nhật trạng thái
-- Hạng nhất (15 ghế)
('A-01', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-02', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-03', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-04', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-05', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-06', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-07', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-08', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-09', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-10', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-11', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-12', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-13', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-14', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-15', 'VN204', 3000000.00, N'Hạng nhất', N'có sẵn'),

-- Thương gia (35 ghế)
('B-01', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-02', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-03', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-04', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-05', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-06', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-07', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-08', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-09', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-10', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-11', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-12', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-13', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-14', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-15', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-16', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-17', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-18', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-19', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-20', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-21', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-22', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-23', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-24', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-25', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-26', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-27', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-28', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-29', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-30', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-31', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-32', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-33', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-34', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),
('B-35', 'VN204', 2000000.00, N'Thương gia', N'có sẵn'),

-- Phổ thông (100 ghế)
('C-01', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-02', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-03', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-04', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-05', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-06', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-07', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-08', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-09', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-10', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-11', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-12', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-13', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-14', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-15', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-16', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-17', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-18', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-19', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-20', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-01', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-02', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-03', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-04', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-05', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-06', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-07', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-08', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-09', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-10', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-11', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-12', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-13', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-14', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-15', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-16', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-17', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-18', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-19', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-20', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-01', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-02', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-03', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-04', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-05', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-06', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-07', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-08', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-09', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-10', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-11', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-12', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-13', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-14', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-15', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-16', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-17', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-18', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-19', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-20', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-01', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-02', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-03', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-04', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-05', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-06', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-07', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-08', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-09', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-10', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-11', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-12', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-13', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-14', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-15', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-16', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-17', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-18', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-19', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-20', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-01', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-02', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-03', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-04', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-05', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-06', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-07', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-08', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-09', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-10', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-11', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-12', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-13', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-14', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-15', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-16', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-17', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-18', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-19', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-20', 'VN204', 1000000.00, N'Phổ thông', N'có sẵn');
----
----
INSERT INTO ThongTinGhe (SoGhe, MaChuyenBay, GiaGhe, HangGhe, TinhTrangGhe) VALUES
-- Ghế cho chuyến bay VN205
-- Hạng nhất (15 ghế) - 3 ghế đã đặt
('A-01', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-02', 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-03', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-04', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-05', 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-06', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-07', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-08', 'VN205', 3000000.00, N'Hạng nhất', N'đã đặt'),
('A-09', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-10', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-11', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-12', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-13', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-14', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
('A-15', 'VN205', 3000000.00, N'Hạng nhất', N'có sẵn'),
-- Thương gia (35 ghế) - 7 ghế đã đặt
('B-01', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-02', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-03', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-04', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-05', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-06', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-07', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-08', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-09', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-10', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-11', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-12', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-13', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-14', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-15', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-16', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-17', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-18', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-19', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-20', 'VN205', 2000000.00, N'Thương gia', N'đã đặt'),
('B-21', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-22', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-23', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-24', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-25', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-26', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-27', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-28', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-29', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-30', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-31', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-32', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-33', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-34', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
('B-35', 'VN205', 2000000.00, N'Thương gia', N'có sẵn'),
-- Phổ thông (100 ghế) - 20 ghế đã đặt
('C-01', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-02', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-03', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-04', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-05', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-06', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-07', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-08', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-09', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-10', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-11', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-12', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-13', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-14', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-15', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-16', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-17', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('C-18', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-19', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('C-20', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-01', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-02', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-03', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-04', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-05', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-06', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-07', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-08', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-09', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-10', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-11', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-12', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-13', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-14', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-15', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-16', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-17', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-18', 'VN205', 1000000.00, N'Phổ thông', N'đã đặt'),
('D-19', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('D-20', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-01', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-02', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-03', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-04', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-05', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-06', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-07', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-08', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-09', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-10', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-11', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-12', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-13', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-14', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-15', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-16', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-17', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-18', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-19', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('E-20', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-01', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-02', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-03', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-04', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-05', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-06', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-07', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-08', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-09', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-10', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-11', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-12', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-13', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-14', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-15', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-16', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-17', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-18', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-19', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('F-20', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-01', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-02', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-03', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-04', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-05', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-06', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-07', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-08', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-09', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-10', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-11', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-12', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-13', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-14', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-15', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-16', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-17', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-18', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-19', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn'),
('G-20', 'VN205', 1000000.00, N'Phổ thông', N'có sẵn');


INSERT INTO ThongTinDatVe (MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH)
VALUES
-- Hạng nhất (3 ghế đã đặt)
('DV085', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'A-02', 3000000.00, 'VN205', 'KH085'),
('DV086', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'A-05', 3000000.00, 'VN205', 'KH086'),
('DV087', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'A-08', 3000000.00, 'VN205', 'KH087'),
-- Thương gia (7 ghế đã đặt)
('DV088', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-02', 2000000.00, 'VN205', 'KH088'),
('DV089', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-05', 2000000.00, 'VN205', 'KH089'),
('DV090', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-08', 2000000.00, 'VN205', 'KH090'),
('DV091', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-11', 2000000.00, 'VN205', 'KH091'),
('DV092', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-14', 2000000.00, 'VN205', 'KH092'),
('DV093', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-17', 2000000.00, 'VN205', 'KH093'),
('DV094', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'B-20', 2000000.00, 'VN205', 'KH094'),
-- Phổ thông (10 ghế đã đặt)
('DV095', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-02', 1000000.00, 'VN205', 'KH095'),
('DV096', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-05', 1000000.00, 'VN205', 'KH096'),
('DV097', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-08', 1000000.00, 'VN205', 'KH097'),
('DV098', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-11', 1000000.00, 'VN205', 'KH098'),
('DV099', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-14', 1000000.00, 'VN205', 'KH099'),
('DV100', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-17', 1000000.00, 'VN205', 'KH100'),
('DV101', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'C-20', 1000000.00, 'VN205', 'KH101'),
('DV102', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'D-03', 1000000.00, 'VN205', 'KH102'),
('DV103', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'D-06', 1000000.00, 'VN205', 'KH103'),
('DV104', '2025-05-22', '2025-06-15', N'Đã thanh toán', 'D-09', 1000000.00, 'VN205', 'KH104');


---
----

INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES
('TT001', '2025-03-15', 2000000.00, N'Thẻ tín dụng', 'DV087'),
('TT002', '2025-01-20', 1000000.00, N'Tiền mặt', 'DV023'),
('TT003', '2025-05-01', 3000000.00, N'Chuyển khoản', 'DV055'),
('TT004', '2025-02-28', 1000000.00, N'Thẻ tín dụng', 'DV012'),
('TT005', '2025-04-05', 2000000.00, N'Chuyển khoản', 'DV101'),
('TT006', '2025-03-22', 3000000.00, N'Tiền mặt', 'DV076'),
('TT007', '2025-01-08', 1000000.00, N'Thẻ tín dụng', 'DV039'),
('TT008', '2025-05-11', 2000000.00, N'Chuyển khoản', 'DV092'),
('TT009', '2025-02-14', 3000000.00, N'Tiền mặt', 'DV005'),
('TT010', '2025-04-19', 1000000.00, N'Thẻ tín dụng', 'DV068'),
('TT011', '2025-03-03', 2000000.00, N'Chuyển khoản', 'DV041'),
('TT012', '2025-01-25', 3000000.00, N'Tiền mặt', 'DV110'),
('TT013', '2025-05-07', 1000000.00, N'Thẻ tín dụng', 'DV073'),
('TT014', '2025-02-09', 2000000.00, N'Chuyển khoản', 'DV018'),
('TT015', '2025-04-14', 3000000.00, N'Tiền mặt', 'DV099'),
('TT016', '2025-03-18', 1000000.00, N'Thẻ tín dụng', 'DV031'),
('TT017', '2025-01-02', 2000000.00, N'Chuyển khoản', 'DV065'),
('TT018', '2025-05-20', 3000000.00, N'Tiền mặt', 'DV105'),
('TT019', '2025-02-23', 1000000.00, N'Thẻ tín dụng', 'DV047'),
('TT020', '2025-04-28', 2000000.00, N'Chuyển khoản', 'DV080'),
('TT021', '2025-03-07', 3000000.00, N'Tiền mặt', 'DV009'),
('TT022', '2025-01-11', 1000000.00, N'Thẻ tín dụng', 'DV059'),
('TT023', '2025-05-16', 2000000.00, N'Chuyển khoản', 'DV096'),
('TT024', '2025-02-04', 3000000.00, N'Tiền mặt', 'DV027'),
('TT025', '2025-04-10', 1000000.00, N'Thẻ tín dụng', 'DV113'),
('TT026', '2025-03-29', 2000000.00, N'Chuyển khoản', 'DV044'),
('TT027', '2025-01-17', 3000000.00, N'Tiền mặt', 'DV078'),
('TT028', '2025-05-03', 1000000.00, N'Thẻ tín dụng', 'DV015'),
('TT029', '2025-02-19', 2000000.00, N'Chuyển khoản', 'DV090'),
('TT030', '2025-04-24', 3000000.00, N'Tiền mặt', 'DV036'),
('TT031', '2025-03-12', 1000000.00, N'Thẻ tín dụng', 'DV062'),
('TT032', '2025-01-05', 2000000.00, N'Chuyển khoản', 'DV108'),
('TT033', '2025-05-09', 3000000.00, N'Tiền mặt', 'DV050'),
('TT034', '2025-02-10', 1000000.00, N'Thẻ tín dụng', 'DV083'),
('TT035', '2025-04-16', 2000000.00, N'Chuyển khoản', 'DV021'),
('TT036', '2025-03-25', 3000000.00, N'Tiền mặt', 'DV094'),
('TT037', '2025-01-13', 1000000.00, N'Thẻ tín dụng', 'DV034'),
('TT038', '2025-05-18', 2000000.00, N'Chuyển khoản', 'DV060'),
('TT039', '2025-02-06', 3000000.00, N'Tiền mặt', 'DV102'),
('TT040', '2025-04-22', 1000000.00, N'Thẻ tín dụng', 'DV045'),
('TT041', '2025-03-01', 2000000.00, N'Chuyển khoản', 'DV071'),
('TT042', '2025-01-28', 3000000.00, N'Tiền mặt', 'DV003'),
('TT043', '2025-05-05', 1000000.00, N'Thẻ tín dụng', 'DV085'),
('TT044', '2025-02-12', 2000000.00, N'Chuyển khoản', 'DV025'),
('TT045', '2025-04-08', 3000000.00, N'Tiền mặt', 'DV098'),
('TT046', '2025-03-20', 1000000.00, N'Thẻ tín dụng', 'DV038'),
('TT047', '2025-01-09', 2000000.00, N'Chuyển khoản', 'DV069'),
('TT048', '2025-05-14', 3000000.00, N'Tiền mặt', 'DV111'),
('TT049', '2025-02-01', 1000000.00, N'Thẻ tín dụng', 'DV049'),
('TT050', '2025-04-26', 2000000.00, N'Chuyển khoản', 'DV081'),
('TT051', '2025-03-06', 3000000.00, N'Tiền mặt', 'DV010'),
('TT052', '2025-01-10', 1000000.00, N'Thẻ tín dụng', 'DV058'),
('TT053', '2025-05-15', 2000000.00, N'Chuyển khoản', 'DV095'),
('TT054', '2025-02-03', 3000000.00, N'Tiền mặt', 'DV026'),
('TT055', '2025-04-09', 1000000.00, N'Thẻ tín dụng', 'DV112'),
('TT056', '2025-03-28', 2000000.00, N'Chuyển khoản', 'DV043'),
('TT057', '2025-01-16', 3000000.00, N'Tiền mặt', 'DV077'),
('TT058', '2025-05-02', 1000000.00, N'Thẻ tín dụng', 'DV014'),
('TT059', '2025-02-18', 2000000.00, N'Chuyển khoản', 'DV089'),
('TT060', '2025-04-23', 3000000.00, N'Tiền mặt', 'DV035'),
('TT061', '2025-03-11', 1000000.00, N'Thẻ tín dụng', 'DV061'),
('TT062', '2025-01-04', 2000000.00, N'Chuyển khoản', 'DV107'),
('TT063', '2025-05-08', 3000000.00, N'Tiền mặt', 'DV048'),
('TT064', '2025-02-09', 1000000.00, N'Thẻ tín dụng', 'DV082'),
('TT065', '2025-04-15', 2000000.00, N'Chuyển khoản', 'DV020'),
('TT066', '2025-03-24', 3000000.00, N'Tiền mặt', 'DV093'),
('TT067', '2025-01-12', 1000000.00, N'Thẻ tín dụng', 'DV033'),
('TT068', '2025-05-17', 2000000.00, N'Chuyển khoản', 'DV057'),
('TT069', '2025-02-05', 3000000.00, N'Tiền mặt', 'DV100'),
('TT070', '2025-04-21', 1000000.00, N'Thẻ tín dụng', 'DV046'),
('TT071', '2025-03-02', 2000000.00, N'Chuyển khoản', 'DV070'),
('TT072', '2025-01-27', 3000000.00, N'Tiền mặt', 'DV002'),
('TT073', '2025-05-04', 1000000.00, N'Thẻ tín dụng', 'DV084'),
('TT074', '2025-02-11', 2000000.00, N'Chuyển khoản', 'DV024'),
('TT075', '2025-04-07', 3000000.00, N'Tiền mặt', 'DV097'),
('TT076', '2025-03-19', 1000000.00, N'Thẻ tín dụng', 'DV037'),
('TT077', '2025-01-07', 2000000.00, N'Chuyển khoản', 'DV067'),
('TT078', '2025-05-13', 3000000.00, N'Tiền mặt', 'DV109'),
('TT079', '2025-02-28', 1000000.00, N'Thẻ tín dụng', 'DV040'),
('TT080', '2025-04-25', 2000000.00, N'Chuyển khoản', 'DV079'),
('TT081', '2025-03-05', 3000000.00, N'Tiền mặt', 'DV008'),
('TT082', '2025-01-06', 1000000.00, N'Thẻ tín dụng', 'DV056'),
('TT083', '2025-05-12', 2000000.00, N'Chuyển khoản', 'DV091'),
('TT084', '2025-02-02', 3000000.00, N'Tiền mặt', 'DV022'),
('TT085', '2025-04-18', 1000000.00, N'Thẻ tín dụng', 'DV106'),
('TT086', '2025-03-27', 2000000.00, N'Chuyển khoản', 'DV042'),
('TT087', '2025-01-15', 3000000.00, N'Tiền mặt', 'DV075'),
('TT088', '2025-05-01', 1000000.00, N'Thẻ tín dụng', 'DV013'),
('TT089', '2025-02-17', 2000000.00, N'Chuyển khoản', 'DV088'),
('TT090', '2025-04-20', 3000000.00, N'Tiền mặt', 'DV030'),
('TT091', '2025-03-10', 1000000.00, N'Thẻ tín dụng', 'DV066'),
('TT092', '2025-01-03', 2000000.00, N'Chuyển khoản', 'DV104'),
('TT093', '2025-05-06', 3000000.00, N'Tiền mặt', 'DV054'),
('TT094', '2025-02-08', 1000000.00, N'Thẻ tín dụng', 'DV086'),
('TT095', '2025-04-13', 2000000.00, N'Chuyển khoản', 'DV019'),
('TT096', '2025-03-23', 3000000.00, N'Tiền mặt', 'DV099'),
('TT097', '2025-01-14', 1000000.00, N'Thẻ tín dụng', 'DV032'),
('TT098', '2025-05-19', 2000000.00, N'Chuyển khoản', 'DV064'),
('TT099', '2025-02-07', 3000000.00, N'Tiền mặt', 'DV103'),
('TT100', '2025-04-20', 1000000.00, N'Thẻ tín dụng', 'DV045');


INSERT INTO HoaDon (MaHoaDon, NgayXuatHD, PhuongThucTT, NgayThanhToan, MaTT) VALUES
('HD001', '2025-03-13', N'Thẻ tín dụng', '2025-03-15', 'TT001'),
('HD002', '2025-01-14', N'Tiền mặt', '2025-01-20', 'TT002'),
('HD003', '2025-04-26', N'Chuyển khoản', '2025-05-01', 'TT003'),
('HD004', '2025-02-23', N'Thẻ tín dụng', '2025-02-28', 'TT004'),
('HD005', '2025-03-29', N'Chuyển khoản', '2025-04-05', 'TT005'),
('HD006', '2025-03-15', N'Tiền mặt', '2025-03-22', 'TT006'),
('HD007', '2025-01-02', N'Thẻ tín dụng', '2025-01-08', 'TT007'),
('HD008', '2025-05-06', N'Chuyển khoản', '2025-05-11', 'TT008'),
('HD009', '2025-02-11', N'Tiền mặt', '2025-02-14', 'TT009'),
('HD010', '2025-04-12', N'Thẻ tín dụng', '2025-04-19', 'TT010'),
('HD011', '2025-02-27', N'Chuyển khoản', '2025-03-03', 'TT011'),
('HD012', '2025-01-20', N'Tiền mặt', '2025-01-25', 'TT012'),
('HD013', '2025-05-03', N'Thẻ tín dụng', '2025-05-07', 'TT013'),
('HD014', '2025-02-03', N'Chuyển khoản', '2025-02-09', 'TT014'),
('HD015', '2025-04-07', N'Tiền mặt', '2025-04-14', 'TT015'),
('HD016', '2025-03-11', N'Thẻ tín dụng', '2025-03-18', 'TT016'),
('HD017', '2025-01-01', N'Chuyển khoản', '2025-01-02', 'TT017'),
('HD018', '2025-05-13', N'Tiền mặt', '2025-05-20', 'TT018'),
('HD019', '2025-02-17', N'Thẻ tín dụng', '2025-02-23', 'TT019'),
('HD020', '2025-04-22', N'Chuyển khoản', '2025-04-28', 'TT020'),
('HD021', '2025-03-01', N'Tiền mặt', '2025-03-07', 'TT021'),
('HD022', '2025-01-05', N'Thẻ tín dụng', '2025-01-11', 'TT022'),
('HD023', '2025-05-10', N'Chuyển khoản', '2025-05-16', 'TT023'),
('HD024', '2025-01-28', N'Tiền mặt', '2025-02-04', 'TT024'),
('HD025', '2025-04-05', N'Thẻ tín dụng', '2025-04-10', 'TT025'),
('HD026', '2025-03-22', N'Chuyển khoản', '2025-03-29', 'TT026'),
('HD027', '2025-01-10', N'Tiền mặt', '2025-01-17', 'TT027'),
('HD028', '2025-04-27', N'Thẻ tín dụng', '2025-05-03', 'TT028'),
('HD029', '2025-02-13', N'Chuyển khoản', '2025-02-19', 'TT029'),
('HD030', '2025-04-17', N'Tiền mặt', '2025-04-24', 'TT030'),
('HD031', '2025-03-06', N'Thẻ tín dụng', '2025-03-12', 'TT031'),
('HD032', '2025-01-01', N'Chuyển khoản', '2025-01-05', 'TT032'),
('HD033', '2025-05-02', N'Tiền mặt', '2025-05-09', 'TT033'),
('HD034', '2025-02-04', N'Thẻ tín dụng', '2025-02-10', 'TT034'),
('HD035', '2025-04-09', N'Chuyển khoản', '2025-04-16', 'TT035'),
('HD036', '2025-03-18', N'Tiền mặt', '2025-03-25', 'TT036'),
('HD037', '2025-01-06', N'Thẻ tín dụng', '2025-01-13', 'TT037'),
('HD038', '2025-05-11', N'Chuyển khoản', '2025-05-18', 'TT038'),
('HD039', '2025-01-31', N'Tiền mặt', '2025-02-06', 'TT039'),
('HD040', '2025-04-15', N'Thẻ tín dụng', '2025-04-22', 'TT040'),
('HD041', '2025-02-23', N'Chuyển khoản', '2025-03-01', 'TT041'),
('HD042', '2025-01-21', N'Tiền mặt', '2025-01-28', 'TT042'),
('HD043', '2025-04-29', N'Thẻ tín dụng', '2025-05-05', 'TT043'),
('HD044', '2025-02-06', N'Chuyển khoản', '2025-02-12', 'TT044'),
('HD045', '2025-04-01', N'Tiền mặt', '2025-04-08', 'TT045'),
('HD046', '2025-03-14', N'Thẻ tín dụng', '2025-03-20', 'TT046'),
('HD047', '2025-01-03', N'Chuyển khoản', '2025-01-09', 'TT047'),
('HD048', '2025-05-07', N'Tiền mặt', '2025-05-14', 'TT048'),
('HD049', '2025-01-26', N'Thẻ tín dụng', '2025-02-01', 'TT049'),
('HD050', '2025-04-19', N'Chuyển khoản', '2025-04-26', 'TT050'),
('HD051', '2025-02-28', N'Tiền mặt', '2025-03-06', 'TT051'),
('HD052', '2025-01-04', N'Thẻ tín dụng', '2025-01-10', 'TT052'),
('HD053', '2025-05-08', N'Chuyển khoản', '2025-05-15', 'TT053'),
('HD054', '2025-01-28', N'Tiền mặt', '2025-02-03', 'TT054'),
('HD055', '2025-04-02', N'Thẻ tín dụng', '2025-04-09', 'TT055'),
('HD056', '2025-03-21', N'Chuyển khoản', '2025-03-28', 'TT056'),
('HD057', '2025-01-10', N'Tiền mặt', '2025-01-16', 'TT057'),
('HD058', '2025-04-26', N'Thẻ tín dụng', '2025-05-02', 'TT058'),
('HD059', '2025-02-12', N'Chuyển khoản', '2025-02-18', 'TT059'),
('HD060', '2025-04-16', N'Tiền mặt', '2025-04-23', 'TT060'),
('HD061', '2025-03-04', N'Thẻ tín dụng', '2025-03-11', 'TT061'),
('HD062', '2025-01-01', N'Chuyển khoản', '2025-01-04', 'TT062'),
('HD063', '2025-05-01', N'Tiền mặt', '2025-05-08', 'TT063'),
('HD064', '2025-02-03', N'Thẻ tín dụng', '2025-02-09', 'TT064'),
('HD065', '2025-04-08', N'Chuyển khoản', '2025-04-15', 'TT065'),
('HD066', '2025-03-17', N'Tiền mặt', '2025-03-24', 'TT066'),
('HD067', '2025-01-06', N'Thẻ tín dụng', '2025-01-12', 'TT067'),
('HD068', '2025-05-10', N'Chuyển khoản', '2025-05-17', 'TT068'),
('HD069', '2025-01-30', N'Tiền mặt', '2025-02-05', 'TT069'),
('HD070', '2025-04-14', N'Thẻ tín dụng', '2025-04-21', 'TT070'),
('HD071', '2025-02-24', N'Chuyển khoản', '2025-03-02', 'TT071'),
('HD072', '2025-01-20', N'Tiền mặt', '2025-01-27', 'TT072'),
('HD073', '2025-04-28', N'Thẻ tín dụng', '2025-05-04', 'TT073'),
('HD074', '2025-02-05', N'Chuyển khoản', '2025-02-11', 'TT074'),
('HD075', '2025-04-01', N'Tiền mặt', '2025-04-07', 'TT075'),
('HD076', '2025-03-12', N'Thẻ tín dụng', '2025-03-19', 'TT076'),
('HD077', '2025-01-01', N'Chuyển khoản', '2025-01-07', 'TT077'),
('HD078', '2025-05-06', N'Tiền mặt', '2025-05-13', 'TT078'),
('HD079', '2025-02-23', N'Thẻ tín dụng', '2025-02-28', 'TT079'),
('HD080', '2025-04-18', N'Chuyển khoản', '2025-04-25', 'TT080'),
('HD081', '2025-02-27', N'Tiền mặt', '2025-03-05', 'TT081'),
('HD082', '2025-01-01', N'Thẻ tín dụng', '2025-01-06', 'TT082'),
('HD083', '2025-05-05', N'Chuyển khoản', '2025-05-12', 'TT083'),
('HD084', '2025-01-27', N'Tiền mặt', '2025-02-02', 'TT084'),
('HD085', '2025-04-11', N'Thẻ tín dụng', '2025-04-18', 'TT085'),
('HD086', '2025-03-20', N'Chuyển khoản', '2025-03-27', 'TT086'),
('HD087', '2025-01-08', N'Tiền mặt', '2025-01-15', 'TT087'),
('HD088', '2025-04-25', N'Thẻ tín dụng', '2025-05-01', 'TT088'),
('HD089', '2025-02-11', N'Chuyển khoản', '2025-02-17', 'TT089'),
('HD090', '2025-04-13', N'Tiền mặt', '2025-04-20', 'TT090'),
('HD091', '2025-03-03', N'Thẻ tín dụng', '2025-03-10', 'TT091'),
('HD092', '2025-01-01', N'Chuyển khoản', '2025-01-03', 'TT092'),
('HD093', '2025-04-29', N'Tiền mặt', '2025-05-06', 'TT093'),
('HD094', '2025-02-02', N'Thẻ tín dụng', '2025-02-08', 'TT094'),
('HD095', '2025-04-06', N'Chuyển khoản', '2025-04-13', 'TT095'),
('HD096', '2025-03-16', N'Tiền mặt', '2025-03-23', 'TT096'),
('HD097', '2025-01-07', N'Thẻ tín dụng', '2025-01-14', 'TT097'),
('HD098', '2025-05-12', N'Chuyển khoản', '2025-05-19', 'TT098'),
('HD099', '2025-02-01', N'Tiền mặt', '2025-02-07', 'TT099'),
('HD100', '2025-04-13', N'Thẻ tín dụng', '2025-04-20', 'TT100');
GO