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
            FROM CHUYENBAY
        `);
        console.log('Dữ liệu trả về:', result.recordset);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi khi lấy danh sách chuyến bay:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
});

// API thêm khách hàng mới
/*app.post('/api/customers', async (req, res) => {
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

*/
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên cổng ${PORT}`);
});