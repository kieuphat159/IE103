const express = require('express');
const sql = require('mssql');
const bcrypt = require('bcrypt');
const cors = require('cors');

const app = express();

// Configure CORS
app.use(cors({
    origin: ['http://localhost:5500', 'http://127.0.0.1:5500', 'http://localhost:3000', 'http://127.0.0.1:3000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Accept']
}));

app.use(express.json());

// Cấu hình kết nối với MS SQL Server
const dbConfig = {
    user: "sa",
    password: "Thnguyen_123",
    server: "localhost",
    port: 1433,
    database: "QLdatve",
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

// API đăng nhập
app.post('/api/login', async (req, res) => {
    const { taiKhoan, matKhau } = req.body;
    console.log('Nhận được yêu cầu đăng nhập:', { taiKhoan });

    try {
        const pool = await connectToDB();
        const result = await pool.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query(`
                SELECT taiKhoan, matKhau, ten
                FROM NguoiDung
                WHERE taiKhoan = @taiKhoan
            `);

        if (result.recordset.length === 0) {
            console.log('Tài khoản không tồn tại:', taiKhoan);
            return res.status(401).json({ error: 'Tài khoản không tồn tại' });
        }

        const user = result.recordset[0];
        const isPasswordValid = await bcrypt.compare(matKhau, user.matKhau);
        if (!isPasswordValid) {
            console.log('Mật khẩu không đúng cho tài khoản:', taiKhoan);
            return res.status(401).json({ error: 'Mật khẩu không đúng' });
        }

        const isAdmin = taiKhoan === 'admin';
        const controllerResult = await pool.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query(`
                SELECT TaiKhoan
                FROM NhanVienKiemSoat
                WHERE TaiKhoan = @taiKhoan
            `);
        const isController = controllerResult.recordset.length > 0;

        console.log('Đăng nhập thành công:', { taiKhoan, isAdmin, isController });
        res.json({
            message: 'Đăng nhập thành công',
            user: {
                taiKhoan: user.taiKhoan,
                ten: user.ten,
                isAdmin: isAdmin,
                isController: isController
            }
        });
    } catch (err) {
        console.error('Lỗi khi đăng nhập:', err);
        res.status(500).json({ error: 'Lỗi server khi đăng nhập: ' + err.message });
    }
});

// API thêm nhân viên
app.post('/api/controllers', async (req, res) => {
    const { maNV, ten, email, sdt, ngaySinh, gioiTinh, soCCCD, taiKhoan, matKhau } = req.body;

    let pool;
    let transaction;

    try {
        if (!maNV || !ten || !email || !sdt || !ngaySinh || !gioiTinh || !soCCCD || !taiKhoan || !matKhau) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const taiKhoanCheck = await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('SELECT TaiKhoan FROM NguoiDung WHERE TaiKhoan = @taiKhoan');
        if (taiKhoanCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Tài khoản đã tồn tại' });
        }

        const maNVCheck = await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .query('SELECT MaNV FROM NhanVienKiemSoat WHERE MaNV = @maNV');
        if (maNVCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Mã nhân viên đã tồn tại' });
        }

        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(matKhau, saltRounds);

        await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .input('ten', sql.NVarChar, ten)
            .input('matKhau', sql.VarChar, hashedPassword)
            .input('email', sql.VarChar, email)
            .input('sdt', sql.VarChar, sdt)
            .input('ngaySinh', sql.Date, ngaySinh)
            .input('gioiTinh', sql.NVarChar, gioiTinh)
            .input('soCCCD', sql.VarChar, soCCCD)
            .query(`
                INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD)
                VALUES (@taiKhoan, @ten, @matKhau, @email, @sdt, @ngaySinh, @gioiTinh, @soCCCD)
            `);

        await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query(`
                INSERT INTO NhanVienKiemSoat (MaNV, TaiKhoan)
                VALUES (@maNV, @taiKhoan)
            `);

        await transaction.commit();
        console.log(`Thêm nhân viên kiểm soát thành công: ${maNV}`);
        res.status(201).json({ message: 'Thêm nhân viên kiểm soát thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi thêm nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi khi thêm nhân viên kiểm soát: ' + err.message });
    }
});

// API lấy danh sách khách hàng
app.get('/api/customers', async (req, res) => {
    try {
        console.log('Nhận được yêu cầu GET /api/customers');
        const pool = await connectToDB();
        const result = await pool.request().query(`
            SELECT k.maKH, nd.ten, nd.taiKhoan, nd.email, nd.sdt, nd.ngaySinh, nd.gioiTinh, nd.soCCCD, k.passport
            FROM KhachHang k
            JOIN NguoiDung nd ON k.taiKhoan = nd.taiKhoan
        `);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách khách hàng:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API thêm khách hàng mới
app.post('/api/customers', async (req, res) => {
    const { maKH, ten, taiKhoan, matKhau, email, sdt, ngaySinh, gioiTinh, soCCCD, passport } = req.body;

    let pool;
    let transaction;

    try {
        if (!maKH || !ten || !taiKhoan || !matKhau || !email || !sdt || !ngaySinh || !gioiTinh || !soCCCD) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const taiKhoanCheck = await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('SELECT TaiKhoan FROM NguoiDung WHERE TaiKhoan = @taiKhoan');
        if (taiKhoanCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Tài khoản đã tồn tại' });
        }

        const maKHCheck = await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('SELECT MaKH FROM KhachHang WHERE MaKH = @maKH');
        if (maKHCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Mã khách hàng đã tồn tại' });
        }

        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(matKhau, saltRounds);

        await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .input('ten', sql.NVarChar, ten)
            .input('matKhau', sql.VarChar, hashedPassword)
            .input('email', sql.VarChar, email)
            .input('sdt', sql.VarChar, sdt)
            .input('ngaySinh', sql.Date, ngaySinh)
            .input('gioiTinh', sql.NVarChar, gioiTinh)
            .input('soCCCD', sql.VarChar, soCCCD)
            .query(`
                INSERT INTO NguoiDung (TaiKhoan, Ten, MatKhau, Email, Sdt, NgaySinh, GioiTinh, SoCCCD)
                VALUES (@taiKhoan, @ten, @matKhau, @email, @sdt, @ngaySinh, @gioiTinh, @soCCCD)
            `);

        await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .input('passport', sql.VarChar, passport)
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query(`
                INSERT INTO KhachHang (maKH, passport, taiKhoan)
                VALUES (@maKH, @passport, @taiKhoan)
            `);

        await transaction.commit();
        console.log(`Thêm khách hàng thành công: ${maKH}`);
        res.status(201).json({ message: 'Thêm khách hàng thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi thêm khách hàng:', err);
        res.status(500).json({ error: 'Lỗi khi thêm khách hàng: ' + err.message });
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
        console.log(`Xóa hóa đơn liên quan đến MaTT ${maTT} thành công`);
        res.json({ message: 'Xóa hóa đơn thành công' });
    } catch (err) {
        console.error('Lỗi khi xóa hóa đơn:', err);
        res.status(500).json({ error: 'Lỗi khi xóa hóa đơn: ' + err.message });
    }
});

// API xóa thanh toán liên quan đến MaDatVe
app.delete('/api/payments/by-booking/:maDatVe', async (req, res) => {
    const { maDatVe } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const paymentResult = await transaction.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('SELECT MaTT FROM ThanhToan WHERE MaDatVe = @maDatVe');

        for (const payment of paymentResult.recordset) {
            await transaction.request()
                .input('maTT', sql.VarChar, payment.MaTT)
                .query('DELETE FROM HoaDon WHERE MaTT = @maTT');
        }

        await transaction.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('DELETE FROM ThanhToan WHERE MaDatVe = @maDatVe');

        await transaction.commit();
        console.log(`Xóa thanh toán liên quan đến MaDatVe ${maDatVe} thành công`);
        res.json({ message: 'Xóa thanh toán thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa thanh toán:', err);
        res.status(500).json({ error: 'Lỗi khi xóa thanh toán: ' + err.message });
    }
});

// API xóa thông tin đặt vé liên quan đến MaKH
app.delete('/api/bookings/by-customer/:maKH', async (req, res) => {
    const { maKH } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const bookingResult = await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('SELECT MaDatVe FROM ThongTinDatVe WHERE MaKH = @maKH');

        for (const booking of bookingResult.recordset) {
            await transaction.request()
                .input('maDatVe', sql.VarChar, booking.MaDatVe)
                .query('DELETE FROM ThanhToan WHERE MaDatVe = @maDatVe');
        }

        await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('DELETE FROM ThongTinDatVe WHERE MaKH = @maKH');

        await transaction.commit();
        console.log(`Xóa thông tin đặt vé liên quan đến MaKH ${maKH} thành công`);
        res.json({ message: 'Xóa thông tin đặt vé thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa thông tin đặt vé:', err);
        res.status(500).json({ error: 'Lỗi khi xóa thông tin đặt vé: ' + err.message });
    }
});

// API xóa khách hàng
app.delete('/api/customers/:maKH', async (req, res) => {
    const { maKH } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const findResult = await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('SELECT taiKhoan FROM KhachHang WHERE maKH = @maKH');

        if (findResult.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy khách hàng' });
        }

        const taiKhoan = findResult.recordset[0].taiKhoan;

        await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('DELETE FROM ThongTinDatVe WHERE MaKH = @maKH');

        await transaction.request()
            .input('maKH', sql.VarChar, maKH)
            .query('DELETE FROM KhachHang WHERE maKH = @maKH');

        await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('DELETE FROM NguoiDung WHERE taiKhoan = @taiKhoan');

        await transaction.commit();
        console.log(`Xóa khách hàng ${maKH} thành công`);
        res.json({ message: 'Xóa khách hàng thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa khách hàng:', err);
        res.status(500).json({ error: 'Lỗi khi xóa khách hàng: ' + err.message });
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
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy thông tin chuyến bay theo maChuyenBay
app.get('/api/flights/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    try {
        const pool = await connectToDB();
        const result = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                SELECT 
                    MaChuyenBay AS maChuyenBay,
                    TinhTrangChuyenBay AS tinhTrangChuyenBay,
                    FORMAT(GioBay, 'yyyy-MM-ddTHH:mm:ssZ') AS gioBay,
                    FORMAT(GioDen, 'yyyy-MM-ddTHH:mm:ssZ') AS gioDen,
                    DiaDiemDau AS diaDiemDau,
                    DiaDiemCuoi AS diaDiemCuoi
                FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay
            `);
        if (result.recordset.length === 0) {
            console.log(`Không tìm thấy chuyến bay với mã: ${maChuyenBay}`);
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }
        console.log('Dữ liệu trả về:', result.recordset[0]);
        res.json(result.recordset[0]);
    } catch (err) {
        console.error('Lỗi khi lấy thông tin chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API thêm chuyến bay mới
app.post('/api/flights', async (req, res) => {
    const { maChuyenBay, tinhTrangChuyenBay, gioBay, gioDen, diaDiemDau, diaDiemCuoi } = req.body;

    try {
        if (!maChuyenBay || !tinhTrangChuyenBay || !gioBay || !gioDen || !diaDiemDau || !diaDiemCuoi) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        const pool = await connectToDB();
        await pool.request()
            .input('MaChuyenBay', sql.VarChar, maChuyenBay)
            .input('TinhTrangChuyenBay', sql.NVarChar, tinhTrangChuyenBay)
            .input('GioBay', sql.DateTime, gioBay)
            .input('GioDen', sql.DateTime, gioDen)
            .input('DiaDiemDau', sql.NVarChar, diaDiemDau)
            .input('DiaDiemCuoi', sql.NVarChar, diaDiemCuoi)
            .execute('sp_ThemChuyenBay');

        console.log(`Thêm chuyến bay thành công: ${maChuyenBay}`);
        res.status(201).json({ message: 'Thêm chuyến bay thành công' });
    } catch (err) {
        console.error('Lỗi khi thêm chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi thêm chuyến bay: ' + err.message });
    }
});

// API sửa chuyến bay
app.put('/api/flights/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    const { tinhTrangChuyenBay, gioBay, gioDen, diaDiemDau, diaDiemCuoi } = req.body;

    try {
        if (!tinhTrangChuyenBay || !gioBay || !gioDen || !diaDiemDau || !diaDiemCuoi) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        const pool = await connectToDB();
        const result = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .input('tinhTrangChuyenBay', sql.NVarChar, tinhTrangChuyenBay)
            .input('gioBay', sql.DateTime, gioBay)
            .input('gioDen', sql.DateTime, gioDen)
            .input('diaDiemDau', sql.NVarChar, diaDiemDau)
            .input('diaDiemCuoi', sql.NVarChar, diaDiemCuoi)
            .query(`
                UPDATE ChuyenBay
                SET TinhTrangChuyenBay = @tinhTrangChuyenBay,
                    GioBay = @gioBay,
                    GioDen = @gioDen,
                    DiaDiemDau = @diaDiemDau,
                    DiaDiemCuoi = @diaDiemCuoi
                WHERE MaChuyenBay = @maChuyenBay
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }

        console.log(`Cập nhật chuyến bay thành công: ${maChuyenBay}`);
        res.json({ message: 'Cập nhật chuyến bay thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi cập nhật chuyến bay: ' + err.message });
    }
});

// API xóa chuyến bay
app.delete('/api/flights/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const flightCheck = await transaction.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaChuyenBay FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');

        if (flightCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }

        const bookingResult = await transaction.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaDatVe FROM ThongTinDatVe WHERE MaChuyenBay = @maChuyenBay');

        for (const booking of bookingResult.recordset) {
            await transaction.request()
                .input('maDatVe', sql.VarChar, booking.MaDatVe)
                .query('DELETE FROM ThanhToan WHERE MaDatVe = @maDatVe');
        }

        await transaction.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ThongTinDatVe WHERE MaChuyenBay = @maChuyenBay');

        await transaction.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ThongTinGhe WHERE MaChuyenBay = @maChuyenBay');

        await transaction.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');

        await transaction.commit();
        console.log(`Xóa chuyến bay thành công: ${maChuyenBay}`);
        res.json({ message: 'Xóa chuyến bay thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi xóa chuyến bay: ' + err.message });
    }
});

// API xóa ghế
app.delete('/api/seats/:soGhe/:maChuyenBay', async (req, res) => {
    const { soGhe, maChuyenBay } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const seatCheck = await transaction.request()
            .input('soGhe', sql.VarChar, soGhe)
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                SELECT SoGhe, TinhTrangGhe 
                FROM ThongTinGhe 
                WHERE SoGhe = @soGhe AND MaChuyenBay = @maChuyenBay
            `);

        if (seatCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy ghế' });
        }

        if (seatCheck.recordset[0].TinhTrangGhe === 'đã đặt') {
            await transaction.rollback();
            return res.status(400).json({ error: 'Không thể xóa ghế đã được đặt' });
        }

        await transaction.request()
            .input('soGhe', sql.VarChar, soGhe)
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                DELETE FROM ThongTinGhe 
                WHERE SoGhe = @soGhe AND MaChuyenBay = @maChuyenBay
            `);

        await transaction.commit();
        console.log(`Xóa ghế ${soGhe} thành công cho chuyến bay ${maChuyenBay}`);
        res.json({ message: 'Xóa ghế thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa ghế:', err);
        res.status(500).json({ error: 'Lỗi khi xóa ghế: ' + err.message });
    }
});

// API sửa thông tin ghế
app.put('/api/seats/:soGhe/:maChuyenBay', async (req, res) => {
    const { soGhe, maChuyenBay } = req.params;
    const { giaGhe, hangGhe, tinhTrangGhe } = req.body;
    const validHangGhe = ['Phổ thông', 'Thương gia', 'Hạng nhất'];

    try {
        if (!validHangGhe.includes(hangGhe)) {
            return res.status(400).json({ error: `Hạng ghế không hợp lệ. Chỉ chấp nhận: ${validHangGhe.join(', ')}` });
        }

        const pool = await connectToDB();
        const result = await pool.request()
            .input('SoGhe', sql.VarChar, soGhe)
            .input('MaChuyenBay', sql.VarChar, maChuyenBay)
            .input('GiaGhe', sql.Decimal(18, 2), giaGhe)
            .input('HangGhe', sql.NVarChar, hangGhe)
            .input('TinhTrangGhe', sql.NVarChar, tinhTrangGhe)
            .query(`
                UPDATE ThongTinGhe
                SET GiaGhe = @GiaGhe,
                    HangGhe = @HangGhe,
                    TinhTrangGhe = @TinhTrangGhe
                WHERE SoGhe = @SoGhe AND MaChuyenBay = @MaChuyenBay
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ error: 'Không tìm thấy ghế để cập nhật' });
        }

        console.log(`Cập nhật ghế ${soGhe} thành công cho chuyến bay ${maChuyenBay}`);
        res.json({ message: 'Cập nhật ghế thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật ghế:', err);
        res.status(500).json({ error: 'Lỗi server khi cập nhật ghế: ' + err.message });
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
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API xóa hóa đơn theo mã hóa đơn
app.delete('/api/invoices/:maHoaDon', async (req, res) => {
    const { maHoaDon } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const invoiceResult = await transaction.request()
            .input('maHoaDon', sql.VarChar, maHoaDon)
            .query('SELECT MaTT FROM HoaDon WHERE MaHoaDon = @maHoaDon');

        if (invoiceResult.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy hóa đơn' });
        }

        const maTT = invoiceResult.recordset[0].MaTT;

        await transaction.request()
            .input('maHoaDon', sql.VarChar, maHoaDon)
            .query('DELETE FROM HoaDon WHERE MaHoaDon = @maHoaDon');

        if (maTT) {
            await transaction.request()
                .input('maTT', sql.VarChar, maTT)
                .query(`
                    UPDATE ThongTinDatVe
                    SET TrangThaiThanhToan = N'Chưa thanh toán'
                    FROM ThongTinDatVe ttdv
                    JOIN ThanhToan tt ON ttdv.MaDatVe = tt.MaDatVe
                    WHERE tt.MaTT = @maTT
                `);
        }

        await transaction.commit();
        console.log(`Xóa hóa đơn thành công: ${maHoaDon}`);
        res.json({ message: 'Xóa hóa đơn thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa hóa đơn:', err);
        res.status(500).json({ error: 'Lỗi khi xóa hóa đơn: ' + err.message });
    }
});

// API chỉnh sửa hóa đơn
app.put('/api/invoices/:maHoaDon', async (req, res) => {
    const { maHoaDon } = req.params;
    const { ngayXuatHD, phuongThucTT, ngayThanhToan } = req.body;
    const validPhuongThucTT = ['Tiền mặt', 'Thẻ tín dụng', 'Chuyển khoản'];

    try {
        if (!validPhuongThucTT.includes(phuongThucTT)) {
            return res.status(400).json({ error: `Phương thức thanh toán không hợp lệ. Chỉ chấp nhận: ${validPhuongThucTT.join(', ')}` });
        }

        const pool = await connectToDB();
        const result = await pool.request()
            .input('MaHoaDon', sql.VarChar, maHoaDon)
            .input('NgayXuatHD', sql.Date, ngayXuatHD)
            .input('PhuongThucTT', sql.NVarChar, phuongThucTT)
            .input('NgayThanhToan', sql.Date, ngayThanhToan)
            .query(`
                UPDATE HoaDon
                SET NgayXuatHD = @NgayXuatHD,
                    PhuongThucTT = @PhuongThucTT,
                    NgayThanhToan = @NgayThanhToan
                WHERE MaHoaDon = @MaHoaDon
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ error: 'Không tìm thấy hóa đơn để cập nhật' });
        }

        console.log(`Cập nhật hóa đơn thành công: ${maHoaDon}`);
        res.json({ message: 'Cập nhật hóa đơn thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật hóa đơn:', err);
        res.status(500).json({ error: 'Lỗi server khi cập nhật hóa đơn: ' + err.message });
    }
});

// API lấy danh sách ghế
app.get('/api/seats', async (req, res) => {
    try {
        const { maChuyenBay } = req.query;
        const pool = await connectToDB();

        let query = `
            SELECT 
                SoGhe AS soGhe,
                GiaGhe AS giaGhe,
                HangGhe as hangGhe,
                TinhTrangGhe AS tinhTrangGhe,
                MaChuyenBay
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
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy danh sách ghế theo mã chuyến bay
app.get('/api/seats/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    try {
        const pool = await connectToDB();
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
                    HangGhe AS hangGhe,
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

// API kiểm tra ghế trống theo hạng ghế và chuyến bay
app.get('/api/seats/available/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    const { hangGhe } = req.query;

    try {
        const pool = await connectToDB();

        const flightCheck = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaChuyenBay FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');
        if (flightCheck.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }

        const validHangGhe = ['Phổ thông', 'Thương gia', 'Hạng nhất'];
        if (hangGhe && !validHangGhe.includes(hangGhe)) {
            return res.status(400).json({ error: `Hạng ghế không hợp lệ. Chỉ chấp nhận: ${validHangGhe.join(', ')}` });
        }

        let query = `
            SELECT 
                HangGhe AS hangGhe,
                COUNT(*) AS soGheTrong,
                MIN(GiaGhe) AS giaGheMin
            FROM ThongTinGhe
            WHERE MaChuyenBay = @maChuyenBay AND TinhTrangGhe = N'trống'
        `;
        if (hangGhe) {
            query += ' AND HangGhe = @hangGhe';
        }
        query += ' GROUP BY HangGhe';

        const request = pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay);
        if (hangGhe) {
            request.input('hangGhe', sql.NVarChar, hangGhe);
        }

        const result = await request.query(query);
        console.log('Số ghế trống:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi kiểm tra ghế trống:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API tạo mã đặt vé
app.get('/api/bookings/generate-code', async (req, res) => {
    try {
        const pool = await connectToDB();
        const result = await pool.request().query('SELECT MaDatVe FROM ThongTinDatVe');
        const existingCodes = result.recordset.map(row => row.MaDatVe);

        let newCode;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 100;

        while (!isUnique && attempts < maxAttempts) {
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            newCode = `DV${randomNum}`;
            if (!existingCodes.includes(newCode)) {
                isUnique = true;
            }
            attempts++;
        }

        if (!isUnique) {
            throw new Error('Không thể tạo mã đặt vé mới');
        }

        console.log(`Tạo mã đặt vé thành công: ${newCode}`);
        res.json({ maDatVe: newCode });
    } catch (err) {
        console.error('Lỗi khi tạo mã đặt vé:', err);
        res.status(500).json({ error: 'Lỗi khi tạo mã đặt vé: ' + err.message });
    }
});


// API đặt vé
app.post('/api/bookings', async (req, res) => {
    const { MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, HangGhe, SoTien, MaChuyenBay, MaKH } = req.body;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        // Kiểm tra trạng thái chuyến bay
        const flightCheck = await transaction.request()
            .input('maChuyenBay', sql.VarChar, MaChuyenBay)
            .query(`
                SELECT TinhTrangChuyenBay, GioBay
                FROM ChuyenBay
                WHERE MaChuyenBay = @maChuyenBay
            `);

        if (flightCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }

        const { TinhTrangChuyenBay, GioBay } = flightCheck.recordset[0];
        if (TinhTrangChuyenBay !== 'Chưa khởi hành' || new Date(GioBay) < new Date()) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Chỉ có thể đặt vé cho các chuyến bay chưa khởi hành và chưa đến giờ bay' });
        }

        // Kiểm tra ghế trống
        const seatResult = await transaction.request()
            .input('maChuyenBay', sql.VarChar, MaChuyenBay)
            .input('hangGhe', sql.NVarChar, HangGhe)
            .query(`
                SELECT TOP 1 SoGhe
                FROM ThongTinGhe
                WHERE MaChuyenBay = @maChuyenBay 
                AND HangGhe = @hangGhe 
                AND TinhTrangGhe = N'có sẵn'
            `);

        if (seatResult.recordset.length === 0) {
            await transaction.rollback();
            return res.status(400).json({ error: `Hết ghế ở hạng ${HangGhe} cho chuyến bay này.` });
        }

        const soGhe = seatResult.recordset[0].SoGhe;

        await transaction.request()
            .input('maDatVe', sql.VarChar, MaDatVe)
            .input('ngayDatVe', sql.Date, NgayDatVe)
            .input('ngayBay', sql.Date, NgayBay)
            .input('trangThaiThanhToan', sql.NVarChar, TrangThaiThanhToan)
            .input('soGhe', sql.Int, soGhe)
            .input('soTien', sql.Decimal(18, 2), SoTien)
            .input('maChuyenBay', sql.VarChar, MaChuyenBay)
            .input('maKH', sql.VarChar, MaKH)
            .execute('sp_ThemDatVe');

        await transaction.commit();
        console.log(`Đặt vé thành công: ${MaDatVe}, Ghế: ${soGhe}`);
        res.status(201).json({ message: 'Đặt vé thành công', bookedSeat: soGhe });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi đặt vé:', err);
        res.status(500).json({ error: 'Lỗi server khi đặt vé: ' + err.message });
    } finally {
        if (pool) {
            try {
                await pool.close();
            } catch (err) {
                console.error('Lỗi khi đóng kết nối pool:', err);
            }
        }
    }
});

// API xóa thông tin đặt vé theo mã đặt vé
app.delete('/api/bookings/:maDatVe', async (req, res) => {
    const { maDatVe } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const bookingCheck = await transaction.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('SELECT MaDatVe, MaChuyenBay FROM ThongTinDatVe WHERE MaDatVe = @maDatVe');

        if (bookingCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy thông tin đặt vé' });
        }

        const { MaChuyenBay } = bookingCheck.recordset[0];

        await transaction.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('DELETE FROM ThanhToan WHERE MaDatVe = @maDatVe');

        await transaction.request()
            .input('maDatVe', sql.VarChar, maDatVe)
            .query('DELETE FROM ThongTinDatVe WHERE MaDatVe = @maDatVe');

        await transaction.commit();
        console.log(`Xóa thông tin đặt vé thành công: ${maDatVe}`);
        res.json({ message: 'Xóa thông tin đặt vé thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa thông tin đặt vé:', err);
        res.status(500).json({ error: 'Lỗi khi xóa thông tin đặt vé: ' + err.message });
    }
});

// API lấy danh sách thông tin đặt vé
app.get('/api/bookings', async (req, res) => {
    try {
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
        `;

        if (username) {
            query += ` WHERE kh.TaiKhoan = @username`;
        }

        const request = pool.request();
        if (username) {
            request.input('username', sql.VarChar, username);
        }

        const result = await request.query(query);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách thông tin đặt vé:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API cập nhật thông tin đặt vé
app.put('/api/bookings/:maDatVe', async (req, res) => {
    const validTrangThaiThanhToan = ['Chưa thanh toán', 'Đã thanh toán'];
    const { maDatVe } = req.params;
    const { ngayDatVe, ngayBay, trangThaiThanhToan, soGhe, soTien, maChuyenBay, maKH } = req.body;

    // Kiểm tra giá trị trangThaiThanhToan nếu được cung cấp
    if (trangThaiThanhToan && !validTrangThaiThanhToan.includes(trangThaiThanhToan)) {
        return res.status(400).json({ error: `Trạng thái thanh toán không hợp lệ. Chỉ chấp nhận: ${validTrangThaiThanhToan.join(', ')}` });
    }

    let pool;
    let transaction;
    try {
        pool = await sql.connect(dbConfig);
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        // Lấy bản ghi hiện tại để sử dụng các giá trị mặc định
        const bookingCheck = await transaction.request()
            .input('MaDatVe', sql.VarChar, maDatVe)
            .query('SELECT * FROM ThongTinDatVe WHERE MaDatVe = @MaDatVe');

        if (bookingCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy thông tin đặt vé để cập nhật' });
        }

        const existing = bookingCheck.recordset[0];

        // Sử dụng giá trị từ request nếu có, nếu không thì giữ giá trị hiện tại
        const updatedNgayDatVe = ngayDatVe !== undefined ? ngayDatVe : existing.NgayDatVe;
        const updatedNgayBay = ngayBay !== undefined ? ngayBay : existing.NgayBay;
        const updatedTrangThaiThanhToan = trangThaiThanhToan !== undefined ? trangThaiThanhToan : existing.TrangThaiThanhToan;
        const updatedSoGhe = soGhe !== undefined ? soGhe : existing.SoGhe;
        const updatedSoTien = soTien !== undefined ? soTien : existing.SoTien;
        const updatedMaChuyenBay = maChuyenBay !== undefined ? maChuyenBay : existing.MaChuyenBay;
        const updatedMaKH = maKH !== undefined ? maKH : existing.MaKH;

        // Kiểm tra các trường bắt buộc không được NULL
        if (!updatedNgayDatVe || !updatedNgayBay || !updatedSoTien) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Các trường NgayDatVe, NgayBay, SoTien không được để trống' });
        }

        // Nếu chuyển từ 'Chưa thanh toán' sang 'Đã thanh toán', tạo bản ghi ThanhToan và HoaDon
        if (existing.TrangThaiThanhToan === 'Chưa thanh toán' && updatedTrangThaiThanhToan === 'Đã thanh toán') {
            // Kiểm tra xem đã có bản ghi ThanhToan chưa
            const paymentResult = await transaction.request()
                .input('MaDatVe', sql.VarChar, maDatVe)
                .query('SELECT MaTT FROM ThanhToan WHERE MaDatVe = @MaDatVe');

            let maTT;
            if (paymentResult.recordset.length > 0) {
                maTT = paymentResult.recordset[0].MaTT;
            } else {
                // Tạo mã MaTT mới
                const maxTTResult = await transaction.request().query('SELECT MAX(MaTT) as maxMaTT FROM ThanhToan');
                const maxMaTT = maxTTResult.recordset[0].maxMaTT || 'TT000';
                const newMaTTNum = parseInt(maxMaTT.replace('TT', '')) + 1;
                maTT = `TT${newMaTTNum.toString().padStart(3, '0')}`;

                // Thêm vào ThanhToan
                const currentDate = new Date().toISOString().split('T')[0];
                await transaction.request()
                    .input('MaTT', sql.VarChar, maTT)
                    .input('NgayTT', sql.Date, currentDate)
                    .input('SoTien', sql.Decimal(18, 2), updatedSoTien)
                    .input('PTTT', sql.NVarChar, 'Chuyển khoản')
                    .input('MaDatVe', sql.VarChar, maDatVe)
                    .query('INSERT INTO ThanhToan (MaTT, NgayTT, SoTien, PTTT, MaDatVe) VALUES (@MaTT, @NgayTT, @SoTien, @PTTT, @MaDatVe)');
            }

            // Tạo hóa đơn
            const currentDate = new Date().toISOString().split('T')[0];
            const maHoaDon = `HD${Date.now()}`;
            await transaction.request()
                .input('MaHoaDon', sql.VarChar, maHoaDon)
                .input('MaTT', sql.VarChar, maTT)
                .input('NgayXuatHD', sql.Date, currentDate)
                .input('PhuongThucTT', sql.NVarChar, 'Chuyển khoản')
                .input('NgayThanhToan', sql.Date, currentDate)
                .query(`
                    INSERT INTO HoaDon (MaHoaDon, MaTT, NgayXuatHD, PhuongThucTT, NgayThanhToan)
                    VALUES (@MaHoaDon, @MaTT, @NgayXuatHD, @PhuongThucTT, @NgayThanhToan)
                `);
        }

        // Nếu chuyển từ 'Đã thanh toán' sang 'Chưa thanh toán', xóa hóa đơn và thanh toán
        if (existing.TrangThaiThanhToan === 'Đã thanh toán' && updatedTrangThaiThanhToan === 'Chưa thanh toán') {
            await transaction.request()
                .input('MaDatVe', sql.VarChar, maDatVe)
                .query(`
                    DELETE FROM HoaDon
                    WHERE MaTT IN (SELECT MaTT FROM ThanhToan WHERE MaDatVe = @MaDatVe)
                `);

            await transaction.request()
                .input('MaDatVe', sql.VarChar, maDatVe)
                .query('DELETE FROM ThanhToan WHERE MaDatVe = @MaDatVe');
        }

        // Cập nhật thông tin đặt vé
        const updateResult = await transaction.request()
            .input('MaDatVe', sql.VarChar, maDatVe)
            .input('NgayDatVe', sql.Date, updatedNgayDatVe)
            .input('NgayBay', sql.Date, updatedNgayBay)
            .input('TrangThaiThanhToan', sql.NVarChar, updatedTrangThaiThanhToan)
            .input('SoGhe', sql.Int, updatedSoGhe)
            .input('SoTien', sql.Decimal(18, 2), updatedSoTien)
            .input('MaChuyenBay', sql.VarChar, updatedMaChuyenBay)
            .input('MaKH', sql.VarChar, updatedMaKH)
            .query(`
                UPDATE ThongTinDatVe
                SET NgayDatVe = @NgayDatVe,
                    NgayBay = @NgayBay,
                    TrangThaiThanhToan = @TrangThaiThanhToan,
                    SoGhe = @SoGhe,
                    SoTien = @SoTien,
                    MaChuyenBay = @MaChuyenBay,
                    MaKH = @MaKH
                WHERE MaDatVe = @MaDatVe
            `);

        if (updateResult.rowsAffected[0] === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không thể cập nhật thông tin đặt vé' });
        }

        await transaction.commit();
        res.json({ message: 'Cập nhật thông tin đặt vé thành công' });
    } catch (err) {
        if (transaction) {
            await transaction.rollback();
        }
        console.error('Lỗi khi cập nhật thông tin đặt vé:', err);
        res.status(500).json({ error: 'Lỗi server khi cập nhật thông tin đặt vé: ' + err.message });
    } finally {
        if (pool) {
            pool.close();
        }
    }
});

// API tạo mã chuyến bay mới
app.get('/api/flights/generate-code', async (req, res) => {
    try {
        const pool = await connectToDB();
        const result = await pool.request().query('SELECT MaChuyenBay FROM ChuyenBay');
        const existingCodes = result.recordset.map(row => row.MaChuyenBay);

        let newCode;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 100;

        while (!isUnique && attempts < maxAttempts) {
            const randomNum = Math.floor(100 + Math.random() * 900);
            newCode = `CB${randomNum}`;
            if (!existingCodes.includes(newCode)) {
                isUnique = true;
            }
            attempts++;
        }

        if (!isUnique) {
            throw new Error('Không thể tạo mã chuyến bay mới');
        }

        console.log(`Tạo mã chuyến bay thành công: ${newCode}`);
        res.json({ maChuyenBay: newCode });
    } catch (err) {
        console.error('Lỗi khi tạo mã chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi tạo mã chuyến bay: ' + err.message });
    }
});

// API lấy thông tin khách hàng theo tài khoản
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

        console.log(`Lấy thông tin khách hàng thành công: ${taiKhoan}`);
        res.json(result.recordset[0]);
    } catch (err) {
        console.error('Lỗi khi lấy thông tin khách hàng:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy danh sách báo cáo
app.get('/api/reports', async (req, res) => {
    try {
        const { trangThai } = req.query;
        const pool = await connectToDB();

        let query = `
            SELECT 
                MaBaoCao as maBaoCao,
                NgayBaoCao as ngayBaoCao,
                NoiDungBaoCao as noiDungBaoCao,
                MaNV as maNV
            FROM BaoCao
        `;

        if (trangThai) {
            query += ' WHERE TrangThai = @trangThai';
        }

        const request = pool.request();
        if (trangThai) {
            request.input('trangThai', sql.NVarChar, trangThai);
        }

        const result = await request.query(query);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy báo cáo đầy đủ
app.get('/api/reports/full', async (req, res) => {
    try {
        const pool = await connectToDB();
        const result = await pool.request().query(`
            SELECT 
                MaBaoCao AS maBaoCao,
                NgayBaoCao AS ngayBaoCao,
                NoiDungBaoCao AS noiDungBaoCao,
                MaNV AS maNV,
                TrangThai AS trangThai
            FROM BaoCao
        `);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách báo cáo đầy đủ:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API tạo mã báo cáo
app.get('/api/reports/generate-code', async (req, res) => {
    try {
        const pool = await connectToDB();
        const result = await pool.request().query('SELECT MaBaoCao FROM BaoCao');
        const existingCodes = result.recordset.map(row => row.MaBaoCao);

        let newCode;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 100;

        while (!isUnique && attempts < maxAttempts) {
            const randomNum = Math.floor(100 + Math.random() * 900);
            newCode = `BC${randomNum}`;
            if (!existingCodes.includes(newCode)) {
                isUnique = true;
            }
            attempts++;
        }

        if (!isUnique) {
            throw new Error('Không thể tạo mã báo cáo mới');
        }

        console.log(`Tạo mã báo cáo thành công: ${newCode}`);
        res.json({ maBaoCao: newCode });
    } catch (err) {
        console.error('Lỗi khi tạo mã báo cáo:', err);
        res.status(500).json({ error: 'Lỗi khi tạo mã báo cáo: ' + err.message });
    }
});

// API thêm báo cáo
app.post('/api/reports', async (req, res) => {
    const { maBaoCao, maNV, ngayBaoCao, noiDungBaoCao, trangThai } = req.body;

    try {
        if (!maBaoCao || !maNV || !ngayBaoCao || !noiDungBaoCao) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        const pool = await connectToDB();
        await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .input('maNV', sql.VarChar, maNV)
            .input('ngayBaoCao', sql.DateTime, ngayBaoCao)
            .input('noiDungBaoCao', sql.NVarChar, noiDungBaoCao)
            .input('trangThai', sql.NVarChar, trangThai || 'Chưa xử lý')
            .query(`
                INSERT INTO BaoCao (MaBaoCao, MaNV, NgayBaoCao, NoiDungBaoCao, TrangThai)
                VALUES (@maBaoCao, @maNV, @ngayBaoCao, @noiDungBaoCao, @trangThai)
            `);

        console.log(`Thêm báo cáo thành công: ${maBaoCao}`);
        res.status(201).json({ message: 'Thêm báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi thêm báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API cập nhật trạng thái báo cáo
app.put('/api/reports/:maBaoCao/status', async (req, res) => {
    const { maBaoCao } = req.params;
    const { trangThai } = req.body;

    try {
        const pool = await connectToDB();
        const checkResult = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaBaoCao = @maBaoCao');

        if (checkResult.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy báo cáo' });
        }

        await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .input('trangThai', sql.NVarChar, trangThai)
            .query(`
                UPDATE BaoCao
                SET TrangThai = @trangThai
                WHERE MaBaoCao = @maBaoCao
            `);

        console.log(`Cập nhật trạng thái báo cáo thành công: ${maBaoCao}`);
        res.json({ message: 'Cập nhật trạng thái báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật trạng thái báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API xóa báo cáo
app.delete('/api/reports/:maBaoCao', async (req, res) => {
    const { maBaoCao } = req.params;

    try {
        const pool = await connectToDB();
        const reportCheck = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaBaoCao = @maBaoCao');

        if (reportCheck.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy báo cáo' });
        }

        await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('DELETE FROM BaoCao WHERE MaBaoCao = @maBaoCao');

        console.log(`Xóa báo cáo thành công: ${maBaoCao}`);
        res.json({ message: 'Xóa báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi xóa báo cáo:', err);
        res.status(500).json({ error: 'Lỗi khi xóa báo cáo: ' + err.message });
    }
});

// API lấy danh sách nhân viên kiểm soát
app.get('/api/control-staff', async (req, res) => {
    try {
        const { taiKhoan } = req.query;
        const pool = await connectToDB();

        let query = `
            SELECT 
                nv.MaNV as maNV,
                nd.Ten as ten,
                nd.TaiKhoan as taiKhoan,
                nd.Email as email,
                nd.Sdt as sdt,
                nd.NgaySinh as ngaySinh,
                nd.GioiTinh as gioiTinh,
                nd.SoCCCD as soCCCD
            FROM NhanVienKiemSoat nv
            JOIN NguoiDung nd ON nv.TaiKhoan = nd.TaiKhoan
        `;

        if (taiKhoan) {
            query += ' WHERE nd.TaiKhoan = @taiKhoan';
        }

        const request = pool.request();
        if (taiKhoan) {
            request.input('taiKhoan', sql.VarChar, taiKhoan);
        }

        const result = await request.query(query);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API lấy thông tin nhân viên kiểm soát theo mã
app.get('/api/controllers/:maNV', async (req, res) => {
    const { maNV } = req.params;

    try {
        const pool = await connectToDB();
        const result = await pool.request()
            .input('maNV', sql.VarChar, maNV)
            .query(`
                SELECT 
                    nv.MaNV as maNV,
                    nd.Ten as ten,
                    nd.TaiKhoan as taiKhoan,
                    nd.Email as email,
                    nd.Sdt as sdt,
                    nd.NgaySinh as ngaySinh,
                    nd.GioiTinh as gioiTinh,
                    nd.SoCCCD as soCCCD
                FROM NhanVienKiemSoat nv
                JOIN NguoiDung nd ON nv.TaiKhoan = nd.TaiKhoan
                WHERE nv.MaNV = @maNV
            `);

        if (result.recordset.length === 0) {
            return res.status(404).json({ error: 'Không tìm thấy nhân viên kiểm soát' });
        }

        console.log(`Lấy thông tin nhân viên kiểm soát thành công: ${maNV}`);
        res.json(result.recordset[0]);
    } catch (err) {
        console.error('Lỗi khi lấy thông tin nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API cập nhật nhân viên kiểm soát
app.put('/api/control-staff/:maNV', async (req, res) => {
    const { maNV } = req.params;
    const { ten, email, sdt, ngaySinh, gioiTinh, soCCCD } = req.body;

    try {
        if (!ten || !email || !sdt || !ngaySinh || !gioiTinh || !soCCCD) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        const pool = await connectToDB();
        const result = await pool.request()
            .input('maNV', sql.VarChar, maNV)
            .input('ten', sql.NVarChar, ten)
            .input('email', sql.VarChar, email)
            .input('sdt', sql.VarChar, sdt)
            .input('ngaySinh', sql.Date, ngaySinh)
            .input('gioiTinh', sql.NVarChar, gioiTinh)
            .input('soCCCD', sql.VarChar, soCCCD)
            .query(`
                UPDATE NguoiDung
                SET ten = @ten,
                    email = @email,
                    sdt = @sdt,
                    ngaySinh = @ngaySinh,
                    gioiTinh = @gioiTinh,
                    soCCCD = @soCCCD
                FROM NguoiDung nd
                JOIN NhanVienKiemSoat nv ON nd.taiKhoan = nv.TaiKhoan
                WHERE nv.MaNV = @maNV
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ error: 'Không tìm thấy nhân viên kiểm soát' });
        }

        console.log(`Cập nhật nhân viên kiểm soát thành công: ${maNV}`);
        res.json({ message: 'Cập nhật nhân viên kiểm soát thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi khi cập nhật nhân viên kiểm soát: ' + err.message });
    }
});

// API xóa nhân viên kiểm soát
app.delete('/api/controllers/:maNV', async (req, res) => {
    const { maNV } = req.params;

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        const controllerCheck = await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .query('SELECT MaNV, TaiKhoan FROM NhanVienKiemSoat WHERE MaNV = @maNV');

        if (controllerCheck.recordset.length === 0) {
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy nhân viên kiểm soát' });
        }

        const taiKhoan = controllerCheck.recordset[0].TaiKhoan;

        const reportCheck = await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaNV = @maNV');

        if (reportCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Không thể xóa nhân viên kiểm soát vì có báo cáo liên quan' });
        }

        await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .query('DELETE FROM NhanVienKiemSoat WHERE MaNV = @maNV');

        await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('DELETE FROM NguoiDung WHERE TaiKhoan = @taiKhoan');

        await transaction.commit();
        console.log(`Xóa nhân viên kiểm soát thành công: ${maNV}`);
        res.json({ message: 'Xóa nhân viên kiểm soát thành công' });
    } catch (err) {
        if (transaction) await transaction.rollback();
        console.error('Lỗi khi xóa nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi khi xóa nhân viên kiểm soát: ' + err.message });
    }
});

// Endpoint to fetch monthly revenue reports
app.get('/api/revenue-reports-monthly', async (req, res) => {
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request().query('SELECT Nam, Thang, TongDoanhThu, SoGiaoDich FROM vw_BaoCaoDoanhThuTheoThang ORDER BY Nam, Thang');
        res.json(result.recordset);
    } catch (err) {
        console.error('Error fetching monthly revenue reports:', err);
        res.status(500).json({ error: 'Không thể lấy dữ liệu báo cáo doanh thu theo tháng' });
    }
});

// Endpoint to fetch total revenue summary
app.get('/api/revenue-reports-total', async (req, res) => {
    try {
        let pool = await sql.connect(dbConfig);
        let result = await pool.request().query('SELECT TongDoanhThu, TongSoGiaoDich FROM vw_BaoCaoTongDoanhThu');
        res.json(result.recordset);
    } catch (err) {
        console.error('Error fetching total revenue:', err);
        res.status(500).json({ error: 'Không thể lấy dữ liệu báo cáo tổng doanh thu' });
    }
});

// Khởi động server
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên port ${PORT}`);
});