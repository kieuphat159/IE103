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
    console.log('Nhận được yêu cầu đăng nhập:', { taiKhoan, matKhau });

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
        console.log('Mật khẩu trong DB:', user.matKhau);

        // Sử dụng bcrypt để so sánh mật khẩu
        const isPasswordValid = await bcrypt.compare(matKhau, user.matKhau);
        console.log('Kết quả so sánh mật khẩu:', isPasswordValid);

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
        res.status(500).json({ error: 'Lỗi server khi đăng nhập' });
    }
});

// API thêm nhân viên
app.post('/api/controllers', async (req, res) => {
    const { maNV, ten, email, sdt, ngaySinh, gioiTinh, soCCCD, taiKhoan, matKhau } = req.body;

    let pool;
    let transaction;

    try {
        // Kiểm tra dữ liệu đầu vào
        if (!maNV || !ten || !email || !sdt || !ngaySinh || !gioiTinh || !soCCCD || !taiKhoan || !matKhau) {
            return res.status(400).json({ error: 'Vui lòng cung cấp đầy đủ thông tin' });
        }

        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        // Mã hóa mật khẩu
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(matKhau, saltRounds);

        // Thêm vào bảng NguoiDung
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

        // Thêm vào bảng NhanVienKiemSoat
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
        if (transaction) {
            await transaction.rollback();
        }
        console.error('Lỗi khi thêm nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi khi thêm nhân viên kiểm soát: ' + err.message });
    }
    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        // Kiểm tra trùng taiKhoan
        const taiKhoanCheck = await transaction.request()
            .input('taiKhoan', sql.VarChar, taiKhoan)
            .query('SELECT TaiKhoan FROM NguoiDung WHERE TaiKhoan = @taiKhoan');
        if (taiKhoanCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Tài khoản đã tồn tại' });
        }

        // Kiểm tra trùng maNV
        const maNVCheck = await transaction.request()
            .input('maNV', sql.VarChar, maNV)
            .query('SELECT MaNV FROM NhanVienKiemSoat WHERE MaNV = @maNV');
        if (maNVCheck.recordset.length > 0) {
            await transaction.rollback();
            return res.status(400).json({ error: 'Mã nhân viên đã tồn tại' });
        }

        // ... (tiếp tục với mã hóa mật khẩu và thêm dữ liệu)
    } catch (err) {
        // ... (xử lý lỗi)
    }
});

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

// API sửa chuyến bay
app.put('/api/flights/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    const { tinhTrangChuyenBay, gioBay, gioDen, diaDiemDau, diaDiemCuoi } = req.body;

    try {
        const pool = await connectToDB();
        await pool.request()
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

        res.json({ message: 'Cập nhật chuyến bay thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi cập nhật chuyến bay: ' + err.message });
    }
});

// API xóa chuyến bay
app.delete('/api/flights/:maChuyenBay', async (req, res) => {
    const { maChuyenBay } = req.params;
    console.log(`Nhận được yêu cầu DELETE /api/flights/${maChuyenBay}`);

    try {
        const pool = await connectToDB();
        
        // Kiểm tra xem chuyến bay có tồn tại không
        const flightCheck = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaChuyenBay FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');

        if (flightCheck.recordset.length === 0) {
            console.log(`Không tìm thấy chuyến bay: ${maChuyenBay}`);
            return res.status(404).json({ error: 'Không tìm thấy chuyến bay' });
        }

        // Xóa thông tin đặt vé liên quan đến chuyến bay
        const bookingResult = await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('SELECT MaDatVe FROM ThongTinDatVe WHERE MaChuyenBay = @maChuyenBay');

        for (const booking of bookingResult.recordset) {
            console.log(`Xóa thanh toán cho MaDatVe: ${booking.MaDatVe}`);
            await fetch(`http://localhost:3000/api/payments/by-booking/${booking.MaDatVe}`, {
                method: 'DELETE'
            });
        }

        await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ThongTinDatVe WHERE MaChuyenBay = @maChuyenBay');

        // Xóa thông tin ghế liên quan
        await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ThongTinGhe WHERE MaChuyenBay = @maChuyenBay');

        // Xóa chuyến bayDeux
        await pool.request()
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query('DELETE FROM ChuyenBay WHERE MaChuyenBay = @maChuyenBay');

        console.log(`Xóa chuyến bay thành công: ${maChuyenBay}`);
        res.json({ message: 'Xóa chuyến bay thành công' });
    } catch (err) {
        console.error('Lỗi khi xóa chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi khi xóa chuyến bay: ' + err.message });
    }
});

// API xóa ghế
app.delete('/api/seats/:soGhe/:maChuyenBay', async (req, res) => {
    const { soGhe, maChuyenBay } = req.params;
    console.log(`Nhận được yêu cầu DELETE /api/seats/${soGhe}/${maChuyenBay}`);

    let pool;
    let transaction;

    try {
        pool = await connectToDB();
        transaction = new sql.Transaction(pool);
        await transaction.begin();

        // Kiểm tra xem ghế có tồn tại không
        const seatCheck = await transaction.request()
            .input('soGhe', sql.VarChar, soGhe)
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                SELECT SoGhe, TinhTrangGhe 
                FROM ThongTinGhe 
                WHERE SoGhe = @soGhe AND MaChuyenBay = @maChuyenBay
            `);

        if (seatCheck.recordset.length === 0) {
            console.log(`Không tìm thấy ghế ${soGhe} cho chuyến bay ${maChuyenBay}`);
            await transaction.rollback();
            return res.status(404).json({ error: 'Không tìm thấy ghế' });
        }

        // Kiểm tra trạng thái ghế
        if (seatCheck.recordset[0].TinhTrangGhe === 'đã đặt') {
            console.log(`Ghế ${soGhe} đã được đặt, không thể xóa`);
            await transaction.rollback();
            return res.status(400).json({ error: 'Không thể xóa ghế đã được đặt' });
        }

        // Xóa ghế và kiểm tra số hàng bị ảnh hưởng
        const deleteResult = await transaction.request()
            .input('soGhe', sql.VarChar, soGhe)
            .input('maChuyenBay', sql.VarChar, maChuyenBay)
            .query(`
                DELETE FROM ThongTinGhe 
                WHERE SoGhe = @soGhe AND MaChuyenBay = @maChuyenBay
            `);

        if (deleteResult.rowsAffected[0] === 0) {
            console.log(`Không có ghế nào bị xóa cho SoGhe: ${soGhe}, MaChuyenBay: ${maChuyenBay}`);
            await transaction.rollback();
            return res.status(500).json({ error: 'Không thể xóa ghế: Không có hàng nào bị ảnh hưởng' });
        }

        await transaction.commit();
        console.log(`Xóa ghế ${soGhe} thành công cho chuyến bay ${maChuyenBay}`);
        res.json({ message: 'Xóa ghế thành công' });
    } catch (err) {
        console.error('Lỗi khi xóa ghế:', err);
        if (transaction) {
            await transaction.rollback();
        }
        res.status(500).json({ error: 'Lỗi khi xóa ghế: ' + err.message });
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

// API tạo thông tin đặt vé
app.post('/api/bookings', async (req, res) => {
    const { MaDatVe, NgayDatVe, NgayBay, TrangThaiThanhToan, SoGhe, SoTien, MaChuyenBay, MaKH } = req.body;

    try {
        const pool = await connectToDB();
        await pool.request()
            .input('MaDatVe', sql.VarChar, MaDatVe)
            .input('NgayDatVe', sql.Date, NgayDatVe)
            .input('NgayBay', sql.Date, NgayBay)
            .input('TrangThaiThanhToan', sql.NVarChar, TrangThaiThanhToan)
            .input('SoGhe', sql.VarChar, SoGhe)
            .input('SoTien', sql.Decimal(18, 2), SoTien)
            .input('MaChuyenBay', sql.VarChar, MaChuyenBay)
            .input('MaKH', sql.VarChar, MaKH)
            .execute('sp_ThemDatVe');

        res.status(201).json({ message: 'Đặt vé thành công' });
    } catch (err) {
        console.error('Lỗi khi đặt vé:', err);
        res.status(500).json({ error: 'Lỗi khi đặt vé: ' + err.message });
    }
});

// API tạo mã chuyến bay mới
app.get('/api/flights/generate-code', async (req, res) => {
    try {
        console.log('Đang tạo mã chuyến bay mới...');
        const pool = await connectToDB();
        console.log('Đã kết nối database');
        
        const result = await pool.request().query('SELECT MaChuyenBay FROM ChuyenBay');
        console.log('Đã lấy danh sách mã chuyến bay hiện có');
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
        res.status(500).json({ error: 'Lỗi server' });
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
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách báo cáo đầy đủ:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API tạo mã báo cáo
app.get('/api/reports/generate-code', async (req, res) => {
    try {
        console.log('Đang tạo mã báo cáo mới...');
        const pool = await connectToDB();
        console.log('Đã kết nối database');
        
        const result = await pool.request().query('SELECT MaBaoCao FROM BaoCao');
        console.log('Đã lấy danh sách mã báo cáo hiện có');
        const existingCodes = result.recordset.map(row => row.MaBaoCao);
        
        let newCode;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 100;
        
        while (!isUnique && attempts < maxAttempts) {
            const randomNum = Math.floor(100 + Math.random() * 900);
            newCode = `BC${randomNum}`; // Sửa thành BCxxx cho báo cáo
            
            if (!existingCodes.includes(newCode)) {
                isUnique = true;
                console.log('Đã tìm thấy mã báo cáo mới:', newCode);
            }
            attempts++;
        }
        
        if (!isUnique) {
            console.error('Không thể tạo mã báo cáo mới sau', maxAttempts, 'lần thử');
            throw new Error('Không thể tạo mã báo cáo mới');
        }
        
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

        res.status(201).json({ message: 'Thêm báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi thêm báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API cập nhật trạng thái báo cáo
app.put('/api/reports/:maBaoCao/status', async (req, res) => {
    const { maBaoCao } = req.params;
    const { trangThai } = req.body;
    
    try {
        console.log('=== Bắt đầu xử lý cập nhật trạng thái báo cáo ===');
        console.log('Mã báo cáo:', maBaoCao);
        console.log('Trạng thái mới:', trangThai);
        
        const pool = await connectToDB();
        console.log('Đã kết nối database');
        
        const checkResult = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaBaoCao = @maBaoCao');
            
        console.log('Kết quả kiểm tra báo cáo:', checkResult.recordset);
            
        if (checkResult.recordset.length === 0) {
            console.log('Không tìm thấy báo cáo');
            return res.status(404).json({ error: 'Không tìm thấy báo cáo' });
        }
        
        const updateResult = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .input('trangThai', sql.NVarChar, trangThai)
            .query(`
                UPDATE BaoCao
                SET TrangThai = @trangThai
                WHERE MaBaoCao = @maBaoCao
            `);
            
        console.log('Kết quả cập nhật:', updateResult);
        console.log('=== Kết thúc xử lý cập nhật trạng thái báo cáo ===');
        
        res.json({ message: 'Cập nhật trạng thái báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật trạng thái báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});

// API xóa báo cáo
app.delete('/api/reports/:maBaoCao', async (req, res) => {
    const { maBaoCao } = req.params;
    console.log(`Nhận được yêu cầu DELETE /api/reports/${maBaoCao}`);

    try {
        const pool = await connectToDB();
        
        // Kiểm tra xem báo cáo có tồn tại không
        const reportCheck = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaBaoCao = @maBaoCao');

        if (reportCheck.recordset.length === 0) {
            console.log(`Không tìm thấy báo cáo: ${maBaoCao}`);
            return res.status(404).json({ error: 'Không tìm thấy báo cáo' });
        }

        // Xóa báo cáo
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

app.put('/api/reports/:maBaoCao/status1', async (req, res) => {
    const { maBaoCao } = req.params;
    const { trangThai } = req.body;
    
    try {
        console.log('=== Bắt đầu xử lý cập nhật trạng thái báo cáo ===');
        console.log('Mã báo cáo:', maBaoCao);
        console.log('Trạng thái mới:', trangThai);
        
        const pool = await connectToDB();
        console.log('Đã kết nối database');
        
        const checkResult = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .query('SELECT MaBaoCao FROM BaoCao WHERE MaBaoCao = @maBaoCao');
            
        console.log('Kết quả kiểm tra báo cáo:', checkResult.recordset);
            
        if (checkResult.recordset.length === 0) {
            console.log('Không tìm thấy báo cáo');
            return res.status(404).json({ error: 'Không tìm thấy báo cáo' });
        }
        
        const updateResult = await pool.request()
            .input('maBaoCao', sql.VarChar, maBaoCao)
            .input('trangThai', sql.NVarChar, trangThai)
            .query(`
                UPDATE BaoCao
                SET TrangThai = @trangThai
                WHERE MaBaoCao = @maBaoCao
            `);
            
        console.log('Kết quả cập nhật:', updateResult);
        console.log('=== Kết thúc xử lý cập nhật trạng thái báo cáo ===');
        
        res.json({ message: 'Cập nhật trạng thái báo cáo thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật trạng thái báo cáo:', err);
        res.status(500).json({ error: 'Lỗi server: ' + err.message });
    }
});


// API lấy danh sách nhân viên kiểm soát
app.get('/api/control-staff', async (req, res) => {
    try {
        console.log('Nhận được yêu cầu GET /api/control-staff với taiKhoan:', req.query.taiKhoan);
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
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API cập nhật nhân viên kiểm soát
app.put('/api/control-staff/:maNV', async (req, res) => {
    const { maNV } = req.params;
    const { ten, email, sdt, ngaySinh, gioiTinh, soCCCD } = req.body;

    try {
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
            console.log(`Không tìm thấy nhân viên kiểm soát với mã: ${maNV}`);
            return res.status(404).json({ error: 'Không tìm thấy nhân viên kiểm soát' });
        }

        console.log(`Cập nhật nhân viên kiểm soát thành công: ${maNV}`);
        res.json({ message: 'Cập nhật nhân viên kiểm soát thành công' });
    } catch (err) {
        console.error('Lỗi khi cập nhật nhân viên kiểm soát:', err);
        res.status(500).json({ error: 'Lỗi khi cập nhật nhân viên kiểm soát: ' + err.message });
    }
});

// Xử lý các route không tồn tại
app.use((req, res) => {
    console.log(`Route không tồn tại: ${req.method} ${req.url}`);
    res.status(404).json({ error: 'Endpoint không tồn tại' });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên cổng ${PORT}`);
});