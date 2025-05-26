***<u>IE103 - Hệ thống quản lý đặt vé online</u>***

## ***<u>Tổng quan</u>***

***<u>Dự án IE103 là một hệ thống quản lý thông tin đặt vé online, hỗ trợ ba vai trò người dùng với các giao diện riêng biệt:</u>***

***<u>Khách hàng: Đăng ký, đăng nhập, đặt vé, xem thông tin cá nhân, xem thông tin chuyến bay và lịch sử đặt vé.</u>***

- ***<u>Nhân viên kiểm soát: Tạo và chỉnh sửa báo cáo gửi lên admin, xem thông tin cá nhân.</u>***
- ***<u>Admin: Quản lý toàn bộ hệ thống, bao gồm quản lý tài khoản, chuyến bay, báo cáo và các thông tin liên quan (xem chi tiết trong mã nguồn dự án).</u>***

***<u>Dự án sử dụng bcrypt để mã hóa mật khẩu, đảm bảo bảo mật thông tin người dùng.</u>***

## ***<u>Công nghệ sử dụng</u>***

- ***<u>Frontend: HTML, CSS, JavaScript</u>***
- ***<u>Backend: Node.js, Express</u>***
- ***<u>Cơ sở dữ liệu: SQL Server</u>***
- ***<u>Bảo mật: bcrypt</u>***
- ***<u>Các thư viện phụ thuộc: cors, các thư viện Node.js khác (xem</u>*** `package.json`***<u>)</u>***

## ***<u>Hướng dẫn cài đặt và chạy dự án</u>***

### ***<u>Yêu cầu</u>***

- ***<u>Node.js (phiên bản mới nhất được khuyến nghị)</u>***
- ***<u>SQL Server</u>***
- ***<u>Trình duyệt web (hỗ trợ Live Server, ví dụ: VS Code với tiện ích Live Server)</u>***
- ***<u>Git (để tải mã nguồn)</u>***

### ***<u>Các bước cài đặt</u>***

1. ***<u>Tải mã nguồn:</u>***

   ```bash
   git clone https://github.com/kieuphat159/IE103.git
   ```

   ***<u>Giải nén nếu tải dưới dạng file ZIP.</u>***

2. ***<u>Cài đặt cơ sở dữ liệu:</u>***

   - ***<u>Mở SQL Server Management Studio.</u>***
   - ***<u>Chạy file SQL trong thư mục</u>*** `database` ***<u>để tạo cơ sở dữ liệu và bảng cần thiết.</u>***

3. ***<u>Cài đặt backend:</u>***

   - ***<u>Mở terminal, di chuyển đến thư mục</u>*** `backend`***<u>:</u>***

     ```bash
     cd backend
     ```

   - ***<u>Cài đặt các thư viện phụ thuộc:</u>***

     ```bash
     npm install
     npm install cors
     ```
   - ***<u>Cấu hình dbconfig trong </u>*** `server.js`***<u>:</u>***

4. ***<u>Khởi động backend:</u>***

   - ***<u>Trong thư mục</u>*** `backend`***<u>, chạy:</u>***

     ```bash
     node server.js
     ```

5. ***<u>Chạy frontend:</u>***

   - ***<u>Mở file</u>*** `login.html` ***<u>trong trình duyệt bằng Live Server (có thể sử dụng VS Code với tiện ích Live Server).</u>***
   - ***<u>Giao diện đăng nhập sẽ hiển thị.</u>***

### ***<u>Thông tin tài khoản</u>***

- ***<u>Admin:</u>***
  - ***<u>Tài khoản:</u>*** `admin`
  - ***<u>Mật khẩu:</u>*** `phatdeptrai123`
- ***<u>Khách hàng:</u>***
  - ***<u>Người dùng có thể tự đăng ký tài khoản thông qua giao diện đăng nhập.</u>***
- ***<u>Nhân viên kiểm soát:</u>***
  - ***<u>Chỉ admin có thể tạo tài khoản cho nhân viên kiểm soát thông qua giao diện quản lý.</u>***

## ***<u>Hướng dẫn sử dụng</u>***

- ***<u>Khách hàng:</u>***
  - ***<u>Đăng ký tài khoản, đăng nhập, đặt vé, xem thông tin chuyến bay và lịch sử đặt vé.</u>***
- ***<u>Nhân viên kiểm soát:</u>***
  - ***<u>Đăng nhập, tạo báo cáo, chỉnh sửa báo cáo và xem thông tin cá nhân.</u>***
- ***<u>Admin:</u>***
  - ***<u>Đăng nhập bằng tài khoản admin, quản lý toàn bộ hệ thống (tài khoản, chuyến bay, báo cáo, v.v.).</u>***

## ***<u>Lưu ý</u>***

- ***<u>Đảm bảo SQL Server đang chạy trước khi khởi động backend.</u>***
- ***<u>Kiểm tra các thư viện phụ thuộc trong</u>*** `package.json` ***<u>để đảm bảo không thiếu gói nào.</u>***
- ***<u>Dự án sử dụng bcrypt để mã hóa mật khẩu, đảm bảo tính bảo mật cho thông tin người dùng.</u>***

## ***<u>Liên hệ</u>***

***<u>Nếu có thắc mắc hoặc vấn đề khi chạy dự án, vui lòng liên hệ qua GitHub Issues hoặc email của tác giả.</u>***
