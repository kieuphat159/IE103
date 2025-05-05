const express = require('express');
const sql = require('mssql');
const bcrypt = require('bcrypt');
const cors = require('cors');
const DatabasePassword = 'Thnguyen_123';

const app = express();
app.use(cors());
app.use(express.json());

// Middleware để đảm bảo phản hồi luôn là JSON
app.use((err, req, res, next) => {
    console.error('Lỗi middleware:', err.stack);
    res.status(500).json({ error: 'Đã xảy ra lỗi server' });
});

// Cấu hình kết nối với MS SQL Server
const dbConfig = {
    user: 'sa',
    password: DatabasePassword,
    server: 'localhost',
    database: 'QLdatve',
    options: {
        encrypt: false,
        trustServerCertificate: true
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
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(matKhau, saltRounds);

        const pool = await connectToDB();
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
        const paymentResult = await pool.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('SELECT MaTT FROM ThanhToan WHERE MaDatVe = @maDatVe');

        for (const payment of paymentResult.recordset) {
            await fetch(`http://localhost:3000/api/invoices/by-payment/${payment.MaTT}`, {
                method: 'DELETE'
            });
        }

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
        const bookingResult = await pool.request()
            .input('maKH', sql.VarChar, maKH)
            .query('SELECT MaDatVe FROM ThongTinDatVe WHERE MaKH = @maKH');

        for (const booking of bookingResult.recordset) {
            await fetch(`http://localhost:3000/api/payments/by-booking/${booking.MaDatVe}`, {
                method: 'DELETE'
            });
        }

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
        const findResult = await pool.request()
            .input('maKH', sql.VarChar, maKH)
            .query('SELECT taiKhoan FROM KhachHang WHERE maKH = @maKH');

        if (findResult.recordset.length === 0) {
            res.status(404).json({ error: 'Không tìm thấy khách hàng' });
            return;
        }

        const taiKhoan = findResult.recordset[0].taiKhoan;
        await fetch(`http://localhost:3000/api/bookings/by-customer/${maKH}`, {
            method: 'DELETE'
        });

        await pool.request()
            .input('maKH', sql.VarChar, maKH)
            .query('DELETE FROM KhachHang WHERE maKH = @maKH');

        await pool.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('DELETE FROM NguoiDung WHERE taiKhoan = @taiKhoan');

        res.json({ message: 'Xóa khách hàng thành công' });
    } catch (err) {
        console.error('Lỗi khi xóa khách hàng:', err);
        res.status(500).json({ error: 'Lỗi khi xóa khách hàng' });
    }
});

// API lấy danh sách chuyến bay
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

// API thêm chuyến bay mới
app.post('/api/flights', async (req, res) => {
    console.log('Nhận được yêu cầu POST /api/flights với dữ liệu:', req.body);
    const { maChuyenBay, tinhTrangChuyenBay, gioBay, gioDen, diaDiemDau, diaDiemCuoi } = req.body;

    try {
        const pool = await connectToDB();
        console.log('Kết nối DB thành công, đang thêm chuyến bay...');
        await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .input('tinhTrangChuyenBay', sql.NVarChar, tinhTrangChuyenBay)
            .input('gioBay', sql.DateTime, gioBay)
            .input('gioDen', sql.DateTime, gioDen)
            .input('diaDiemDau', sql.NVarChar, diaDiemDau)
            .input('diaDiemCuoi', sql.NVarChar, diaDiemCuoi)
            .query(`
                INSERT INTO ChuyenBay (MaChuyenBay, TinhTrangChuyenBay, GioBay, GioDen, DiaDiemDau, DiaDiemCuoi)
                VALUES (@maChuyenBay, @tinhTrangChuyenBay, @gioBay, @gioDen, @diaDiemDau, @diaDiemCuoi)
            `);

        console.log('Thêm chuyến bay thành công:', maChuyenBay);
        res.status(201).json({ message: 'Thêm chuyến bay thành công' });
    } catch (err) {
        console.error('Lỗi khi thêm chuyến bay:', err.message);
        res.status(500).json({ error: 'Lỗi khi thêm chuyến bay: ' + err.message });
    }
});

// API lấy danh sách hóa đơn
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

// API lấy danh sách ghế
app.get('/api/seats', async (req, res) => {
    try {
        console.log('Nhận được yêu cầu GET /api/seats');
        const { maChuyenBay } = req.query;
        const pool = await connectToDB();
        
        let query = `
            SELECT 
                SoGhe AS soGhe,
                GiaGhe AS giaGhe,
                HangGhe as hangGhe,
                TinhTrangGhe AS tinhTrangGhe
            FROM ThongTinGhe
        `;
        
        if (maChuyenBay) {
            query += ' WHERE MaChuyenBay = @maChuyenBay';
        }
        
        const request = pool.request();
        if (maChuyenBay) {
            request.input('maChuyenBay', sql.VarChar, maChuyenBay);
        }
        
        const result = await request.query(query);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách ghế:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API lấy danh sách thông tin đặt vé
app.get('/api/bookings', async (req, res) => {
    try {
        console.log('Nhận được yêu cầu GET /api/bookings với username:', req.query.username);
        const { username } = req.query;
        const pool = await connectToDB();

        let query = `
            SELECT 
                tdv.MaDatVe AS maDatVe,
                tdv.NgayDatVe AS ngayDatVe,
                tdv.NgayBay AS ngayBay,
                tdv.SoGhe AS soGhe,
                tdv.SoTien AS soTien,
                kh.MaKH AS maKH,
                cb.MaChuyenBay AS maChuyenBay,
                tdv.TrangThaiThanhToan AS trangThaiThanhToan
            FROM ThongTinDatVe tdv
            LEFT JOIN KhachHang kh ON tdv.MaKH = kh.MaKH
            LEFT JOIN ChuyenBay cb ON tdv.MaChuyenBay = cb.MaChuyenBay
        `.trim();

        if (username) {
            query += ` WHERE kh.TaiKhoan = @username`;
        }

        const request = pool.request();
        if (username) {
            request.input('username', sql.VarChar, username);
        }

        const result = await request.query(query);
        console.log('Dữ liệu thô từ database:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách thông tin đặt vé:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API tạo mã chuyến bay mới
app.get('/api/flights/generate-code', async (req, res) => {
    try {
        console.log('Đang tạo mã chuyến bay mới...');
        const pool = await connectToDB();
        console.log('Đã kết nối database');
        
        // Lấy danh sách mã chuyến bay hiện có
        const result = await pool.request().query('SELECT MaChuyenBay FROM ChuyenBay');
        console.log('Đã lấy danh sách mã chuyến bay hiện có');
        const existingCodes = result.recordset.map(row => row.MaChuyenBay);
        
        // Tạo mã mới cho đến khi tìm được mã không trùng
        let newCode;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 100; // Giới hạn số lần thử để tránh vòng lặp vô hạn
        
        while (!isUnique && attempts < maxAttempts) {
            // Tạo mã ngẫu nhiên dạng CBxxx (xxx là số từ 100-999)
            const randomNum = Math.floor(100 + Math.random() * 900);
            newCode = `CB${randomNum}`;
            
            // Kiểm tra xem mã đã tồn tại chưa
            if (!existingCodes.includes(newCode)) {
                isUnique = true;
                console.log('Đã tìm thấy mã chuyến bay mới:', newCode);
            }
            attempts++;
        }
        
        if (!isUnique) {
            console.error('Không thể tạo mã chuyến bay mới sau', maxAttempts, 'lần thử');
            throw new Error('Không thể tạo mã chuyến bay mới');
        }
        
        res.json({ maChuyenBay: newCode });
    } catch (err) {
        console.error('Lỗi khi tạo mã chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi tạo mã chuyến bay: ' + err.message });
    }
});

app.get('/api/customers/by-username/:taiKhoan', async (req, res) => {
    const { taiKhoan } = req.params;

    try {
        const pool = await connectToDB();
        const result = await pool.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query(`
                SELECT kh.MaKH, nd.Ten, nd.Email, nd.Sdt, nd.SoCCCD, kh.Passport
                FROM KhachHang kh
                JOIN NguoiDung nd ON kh.TaiKhoan = nd.TaiKhoan
                WHERE kh.TaiKhoan = @taiKhoan
            `);

        if (result.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy khách hàng' });
        }

        res.json(result.recordset[0]);
    } catch (err) {
        console.error('Lỗi khi lấy thông tin khách hàng:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API lấy danh sách ghế theo mã chuyến bay
app.get('/api/seats/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    try {
        console.log('Nhận được yêu cầu GET /api/seats/' + maChuyenBay);
        const pool = await connectToDB();
        console.log('Đã kết nối database, đang thực hiện truy vấn...');
        
        // First check if the flight exists
        const flightCheck = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaChuyenBay FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');
            
        if (flightCheck.recordset.length === 0) {
            console.log('Không tìm thấy chuyến bay:', maChuyenBay);
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }
        
        const result = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                SELECT 
                    SoGhe AS soGhe,
                    GiaGhe AS giaGhe,
                    HangGhe as hangGhe,
                    TinhTrangGhe AS tinhTrangGhe
                FROM ThongTinGhe
                WHERE MaChuyenBay = @maChuyenBay
            `);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách ghế:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy danh sách báo cáo
app.get('/api/reports', async (req, res) => {
    try {
        console.log('Nhận được yêu cầu GET /api/reports');
        const pool = await connectToDB();
        const result = await pool.request().query(`
            SELECT 
                MaBaoCao as maBaoCao,
                NgayBaoCao as ngayBaoCao,
                NoiDungBaoCao as noiDungBaoCao,
                MaNV as maNV
            FROM BaoCao
        `);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// Xử lý các route không tồn tại
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint không tồn tại' });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên cổng ${PORT}`);
});

