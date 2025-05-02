    const express = require('express');
    const sql = require('mssql');
    const bcrypt = require('bcrypt');
    const cors = require('cors');

    const app = express();
    app.use(cors());
    app.use(express.json());

    // Cấu hình kết nối với MS SQL Server
    const dbConfig = {
        user: 'sa', // Thay bằng username SQL Server của bạn
        password: 'Thnguyen_123', // Thay bằng password SQL Server của bạn
        server: 'LAPTOPCUAPHAT\\SQLEXPRESS', // Sửa tên server
        database: 'QLdatve',
        options: {
            encrypt: true, // Bật nếu sử dụng Azure hoặc cần mã hóa
            trustServerCertificate: true // Bật nếu sử dụng chứng chỉ tự ký
        }
    };

    // Kết nối với cơ sở dữ liệu
    const connectToDB = async () => {
        try {
            console.log('Đang kết nối đến cơ sở dữ liệu...');
            const pool = await sql.connect(dbConfig);
            console.log('Đã kết nối với cơ sở dữ liệu MS SQL Server');
            return pool;
        } catch (err) {
            console.error('Lỗi kết nối cơ sở dữ liệu:', err);
            throw err;
        }
    };

    // API lấy danh sách khách hàng
    app.get('/api/customers', async (req, res) => {
        try {
            console.log('Nhận được yêu cầu GET /api/customers');
            const pool = await connectToDB();
            const result = await pool.request().query(`
                SELECT k.maKH, nd.ten, nd.taiKhoan, nd.email, nd.sdt, nd.ngaySinh, nd.gioiTinh, nd.soCCCD
                FROM KhachHang k
                JOIN NguoiDung nd ON k.taiKhoan = nd.taiKhoan
            `);
            console.log('Dữ liệu trả về:', result.recordset);
            res.json(result.recordset);
        } catch (err) {
            console.error('Lỗi khi lấy danh sách khách hàng:', err);
            res.status(500).json({ error: 'Lỗi server' });
        }
    });

    // API thêm khách hàng mới
    app.post('/api/customers', async (req, res) => {
        const { maKH, ten, taiKhoan, matKhau, email, sdt, ngaySinh, gioiTinh, soCCCD, passport } = req.body;

        try {
            // Mã hóa mật khẩu bằng bcrypt
            const saltRounds = 10;
            const hashedPassword = await bcrypt.hash(matKhau, saltRounds);

            const pool = await connectToDB();

            // Thêm vào bảng NguoiDung
            await pool.request()
                .input('taiKhoan', sql.VarChar, taiKhoan)
                .input('ten', sql.NVarChar, ten)
                .input('matKhau', sql.VarChar, hashedPassword)
                .input('email', sql.VarChar, email)
                .input('sdt', sql.VarChar, sdt)
                .input('ngaySinh', sql.Date, ngaySinh)
                .input('gioiTinh', sql.NVarChar, gioiTinh)
                .input('soCCCD', sql.VarChar, soCCCD)
                .query(`
                    INSERT INTO NguoiDung (taiKhoan, ten, matKhau, email, sdt, ngaySinh, gioiTinh, soCCCD)
                    VALUES (@taiKhoan, @ten, @matKhau, @email, @sdt, @ngaySinh, @gioiTinh, @soCCCD)
                `);

            // Thêm vào bảng KhachHang
            await pool.request()
                .input('maKH', sql.VarChar, maKH)
                .input('passport', sql.VarChar, passport)
                .input('taiKhoan', sql.VarChar, taiKhoan)
                .query(`
                    INSERT INTO KhachHang (maKH, passport, taiKhoan)
                    VALUES (@maKH, @passport, @taiKhoan)
                `);

            res.status(201).json({ message: 'Thêm khách hàng thành công' });
        } catch (err) {
            console.error('Lỗi khi thêm khách hàng:', err);
            res.status(500).json({ error: 'Lỗi khi thêm khách hàng' });
        }
    });


    // API xóa hóa đơn liên quan đến MaTT
    app.delete('/api/invoices/by-payment/:maTT', async (req, res) => {
        const { maTT } = req.params;

        try {
            const pool = await connectToDB();
            await pool.request()
                .input('maTT', sql.VarChar, maTT)
                .query('DELETE FROM HoaDon WHERE MaTT = @maTT');
            res.json({ message: 'Xóa hóa đơn thành công' });
        } catch (err) {
            console.error('Lỗi khi xóa hóa đơn:', err);
            res.status(500).json({ error: 'Lỗi khi xóa hóa đơn' });
        }
    });

    // API xóa thanh toán liên quan đến MaDatVe
    app.delete('/api/payments/by-booking/:maDatVe', async (req, res) => {
        const { maDatVe } = req.params;

        try {
            const pool = await connectToDB();

            // Tìm tất cả MaTT liên quan đến MaDatVe
            const paymentResult = await pool.request()
                .input('maDatVe', sql.VarChar, maDatVe)
                .query('SELECT MaTT FROM ThanhToan WHERE MaDatVe = @maDatVe');

            // Xóa các hóa đơn liên quan đến từng MaTT
            for (const payment of paymentResult.recordset) {
                await fetch(`http://localhost:3000/api/invoices/by-payment/${payment.MaTT}`, {
                    method: 'DELETE'
                });
            }

            // Xóa bản ghi trong ThanhToan
            await pool.request()
                .input('maDatVe', sql.VarChar, maDatVe)
                .query('DELETE FROM ThanhToan WHERE MaDatVe = @maDatVe');

            res.json({ message: 'Xóa thanh toán thành công' });
        } catch (err) {
            console.error('Lỗi khi xóa thanh toán:', err);
            res.status(500).json({ error: 'Lỗi khi xóa thanh toán' });
        }
    });

    // API xóa thông tin đặt vé liên quan đến MaKH
    app.delete('/api/bookings/by-customer/:maKH', async (req, res) => {
        const { maKH } = req.params;

        try {
            const pool = await connectToDB();

            // Tìm tất cả MaDatVe liên quan đến MaKH
            const bookingResult = await pool.request()
                .input('maKH', sql.VarChar, maKH)
                .query('SELECT MaDatVe FROM ThongTinDatVe WHERE MaKH = @maKH');

            // Xóa các thanh toán liên quan đến từng MaDatVe
            for (const booking of bookingResult.recordset) {
                await fetch(`http://localhost:3000/api/payments/by-booking/${booking.MaDatVe}`, {
                    method: 'DELETE'
                });
            }

            // Xóa bản ghi trong ThongTinDatVe
            await pool.request()
                .input('maKH', sql.VarChar, maKH)
                .query('DELETE FROM ThongTinDatVe WHERE MaKH = @maKH');

            res.json({ message: 'Xóa thông tin đặt vé thành công' });
        } catch (err) {
            console.error('Lỗi khi xóa thông tin đặt vé:', err);
            res.status(500).json({ error: 'Lỗi khi xóa thông tin đặt vé' });
        }
    });

    // API xóa khách hàng
    app.delete('/api/customers/:maKH', async (req, res) => {
        const { maKH } = req.params;

        try {
            const pool = await connectToDB();

            // Tìm taiKhoan từ maKH để xóa khỏi NguoiDung
            const findResult = await pool.request()
                .input('maKH', sql.VarChar, maKH)
                .query('SELECT taiKhoan FROM KhachHang WHERE maKH = @maKH');

            if (findResult.recordset.length === 0) {
                res.status(404).json({ error: 'Không tìm thấy khách hàng' });
                return;
            }

            const taiKhoan = findResult.recordset[0].taiKhoan;

            // Xóa thông tin đặt vé liên quan đến MaKH
            await fetch(`http://localhost:3000/api/bookings/by-customer/${maKH}`, {
                method: 'DELETE'
            });

            // Xóa khỏi bảng KhachHang
            await pool.request()
                .input('maKH', sql.VarChar, maKH)
                .query('DELETE FROM KhachHang WHERE maKH = @maKH');

            // Xóa khỏi bảng NguoiDung
            await pool.request()
                .input('taiKhoan', sql.VarChar, taiKhoan)
                .query('DELETE FROM NguoiDung WHERE taiKhoan = @taiKhoan');

            res.json({ message: 'Xóa khách hàng thành công' });
        } catch (err) {
            console.error('Lỗi khi xóa khách hàng:', err);
            res.status(500).json({ error: 'Lỗi khi xóa khách hàng' });
        }
    });

    app.get('/api/flights', async (req, res) => {
        try {
            console.log('Nhận được yêu cầu GET /api/flights');
            const pool = await connectToDB();
            const result = await pool.request().query(`
                SELECT 
                    MaChuyenBay AS maChuyenBay,
                    TinhTrangChuyenBay AS tinhTrangChuyenBay,
                    GioBay AS gioBay,
                    GioDen AS gioDen,
                    DiaDiemDau AS diaDiemDau,
                    DiaDiemCuoi AS diaDiemCuoi
                FROM ChuyenBay
            `);
            console.log('Dữ liệu trả về:', result.recordset);
            res.json(result.recordset);
        } catch (err) {
            console.error('Lỗi khi lấy danh sách chuyến bay:', err);
            res.status(500).json({ error: 'Lỗi server' });
        }
    });

    app.get('/api/invoices', async (req, res) => {
        try {
            console.log('Nhận được yêu cầu GET /api/invoices');
            const pool = await connectToDB();
            const result = await pool.request().query(`
                SELECT 
                    MaHoaDon AS maHD,
                    NgayXuatHD AS ngayXuatHD,
                    PhuongThucTT as phuongThucTT,
                    NgayThanhToan AS ngayThanhToan
                FROM HoaDon
            `);
            console.log('Dữ liệu trả về:', result.recordset);
            res.json(result.recordset);
        } catch (err) {
            console.error('Lỗi khi lấy danh sách hóa đơn:', err);
            res.status(500).json({ error: 'Lỗi server' });
        }
    });

    app.get('/api/seats', async (req, res) => {
        try {
            console.log('Nhận được yêu cầu GET /api/seats');
            const pool = await connectToDB();
            const result = await pool.request().query(`
                SELECT 
                    SoGhe AS soGhe,
                    GiaGhe AS giaGhe,
                    HangGhe as hangGhe,
                    TinhTrangGhe AS tinhTrangGhe
                FROM ThongTinGhe
            `);
            console.log('Dữ liệu trả về:', result.recordset);
            res.json(result.recordset);
        } catch (err) {
            console.error('Lỗi khi lấy danh sách ghế:', err);
            res.status(500).json({ error: 'Lỗi server' });
        }
    });

    app.get('/api/bookings', async (req, res) => {
        try {
            console.log('Nhận được yêu cầu GET /api/bookings');
            const pool = await connectToDB();
            const result = await pool.request().query(`
                SELECT 
                    MaDatVe AS maDatVe,
                    NgayDatVe AS ngayDatVe,
                    NgayBay AS ngayBay,
                    SoGhe AS soGhe,
                    SoTien AS soTien 
                FROM ThongTinDatVe
            `);
            console.log('Dữ liệu trả về:', result.recordset);
            res.json(result.recordset);
        } catch (err) {
            console.error('Lỗi khi lấy danh sách thông tin đặt vé:', err);
            res.status(500).json({ error: 'Lỗi server' });
        }
    });

    const PORT = 3000;
    app.listen(PORT, () => {
        console.log(`Server đang chạy trên cổng ${PORT}`);
    });