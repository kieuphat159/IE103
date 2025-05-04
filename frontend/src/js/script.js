let currentSection = '';

function showSection(sectionId) {
    document.querySelectorAll('.section').forEach(section => section.classList.add('hidden'));
    document.getElementById(sectionId).classList.remove('hidden');
    currentSection = sectionId;
    populateTable(sectionId);
}

function openModal(modalType) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    const modalContent = document.getElementById('modalContent');
    modal.classList.remove('hidden');

    if (modalType === 'userModal') {
        modalTitle.textContent = 'Thêm khách hàng';
        modalContent.innerHTML = `
            <label class="block mb-2">Tên</label>
            <input id="userTen" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Tài khoản</label>
            <input id="userTaiKhoan" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Mật khẩu</label>
            <input id="userMatKhau" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Hộ chiếu</label>
            <input id="userPassport" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Email</label>
            <input id="userEmail" type="email" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">SĐT</label>
            <input id="userSDT" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày sinh</label>
            <input id="userNgaySinh" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Giới tính</label>
            <select id="userGioiTinh" class="w-full p-2 border rounded mb-4">
                <option value="Nam">Nam</option>
                <option value="Nữ">Nữ</option>
            </select>
            <label class="block mb-2">CCCD</label>
            <input id="userCCCD" type="text" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'bookingModal') {
        modalTitle.textContent = 'Thêm thông tin đặt vé';
        modalContent.innerHTML = `
            <label class="block mb-2">Mã đặt vé</label>
            <input id="bookingMaDatVe" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày đặt vé</label>
            <input id="bookingNgayDatVe" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày bay</label>
            <input id="bookingNgayBay" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Trạng thái thanh toán</label>
            <select id="bookingTrangThai" class="w-full p-2 border rounded mb-4">
                <option value="Đã thanh toán">Đã thanh toán</option>
                <option value="Chưa thanh toán">Chưa thanh toán</option>
            </select>
            <label class="block mb-2">Số ghế</label>
            <input id="bookingSoGhe" type="number" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Số tiền</label>
            <input id="bookingSoTien" type="text" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'invoiceModal') {
        modalTitle.textContent = 'Thêm hóa đơn';
        modalContent.innerHTML = `
            <label class="block mb-2">Mã HD</label>
            <input id="invoiceMaHD" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày xuất HD</label>
            <input id="invoiceNgayXuatHD" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Phương thức thanh toán</label>
            <select id="invoicePhuongThucTT" class="w-full p-2 border rounded mb-4">
                <option value="Tiền mặt">Tiền mặt</option>
                <option value="Thẻ tín dụng">Thẻ tín dụng</option>
                <option value="Chuyển khoản">Chuyển khoản</option>
            </select>
            <label class="block mb-2">Ngày thanh toán</label>
            <input id="invoiceNgayThanhToan" type="date" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'flightModal') {
        modalTitle.textContent = 'Thêm chuyến bay';
        modalContent.innerHTML = `
            <label class="block mb-2">Mã chuyến bay</label>
            <input id="flightMaChuyenBay" type="text" class="w-full p-2 border rounded mb-4" placeholder="VD: CB001">
            <label class="block mb-2">Tình trạng chuyến bay</label>
            <select id="flightTinhTrangChuyenBay" class="w-full p-2 border rounded mb-4">
                <option value="Chưa khởi hành">Chưa khởi hành</option>
                <option value="Đang bay">Đang bay</option>
                <option value="Đã hoàn thành">Đã hoàn thành</option>
                <option value="Đã hủy">Đã hủy</option>
            </select>
            <label class="block mb-2">Giờ bay</label>
            <input id="flightGioBay" type="datetime-local" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Giờ đến</label>
            <input id="flightGioDen" type="datetime-local" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Địa điểm đầu</label>
            <input id="flightDiaDiemDau" type="text" class="w-full p-2 border rounded mb-4" placeholder="VD: Hà Nội">
            <label class="block mb-2">Địa điểm cuối</label>
            <input id="flightDiaDiemCuoi" type="text" class="w-full p-2 border rounded mb-4" placeholder="VD: TP.HCM">
        `;
    } else if (modalType === 'seatModal') {
        modalTitle.textContent = 'Thêm vị trí ghế';
        modalContent.innerHTML = `
            <label class="block mb-2">Mã ghế</label>
            <input id="seatMaGhe" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Tài khoản</label>
            <input id="seatTaiKhoan" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Mật khẩu</label>
            <input id="seatMatKhau" type="password" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'reportModal') {
        modalTitle.textContent = 'Thêm báo cáo';
        modalContent.innerHTML = `
            <label class="block mb-2">Mã báo cáo</label>
            <input id="reportMaBaoCao" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày báo cáo</label>
            <input id="reportNgayBaoCao" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Nội dung báo cáo</label>
            <textarea id="reportNoiDung" class="w-full p-2 border rounded mb-4" rows="5"></textarea>
        `;
    }
}

function closeModal() {
    document.getElementById('modal').classList.add('hidden');
}

function saveData() {
    // Implementation for saving data would go here
    alert('Dữ liệu đã được lưu thành công!');
    closeModal();
}

function populateTable(sectionId) {
    console.log('Populating table for section:', sectionId);
    const tableBody = document.getElementById(`${sectionId}Table`);
    
    if (!tableBody) {
        console.error(`Table body not found for section: ${sectionId}`);
        return;
    }
    
    tableBody.innerHTML = '';
    
    // Add sample data to each table accordingly
    switch(sectionId) {
        case 'users':
            populateUserTable(tableBody);
            break;
        case 'bookings':
            populateBookingTable(tableBody);
            break;
        case 'invoices':
            populateInvoiceTable(tableBody);
            break;
        case 'flights':
            populateFlightTable(tableBody);
            break;
        case 'seats':
            populateSeatTable(tableBody);
            break;
        //case 'reports':
            //populateReportTable(tableBody);
        //    break;
    }
}

function populateUserTable(tableBody) {
    userData.forEach(user => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2">${user.maKH}</td>
            <td class="p-2">${user.ten}</td>
            <td class="p-2">${user.taiKhoan}</td>
            <td class="p-2">${user.matKhau}</td>
            <td class="p-2">${user.email}</td>
            <td class="p-2">${user.sdt}</td>
            <td class="p-2">${user.ngaySinh}</td>
            <td class="p-2">${user.gioiTinh}</td>
            <td class="p-2">${user.cccd}</td>
            <td class="p-2">
                <button onclick="editItem('users', '${user.maKH}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                <button onclick="deleteItem('users', '${user.maKH}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function populateBookingTable(tableBody) {
    bookingData.forEach(booking => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2">${booking.maDatVe}</td>
            <td class="p-2">${booking.ngayDatVe}</td>
            <td class="p-2">${booking.ngayBay}</td>
            <td class="p-2">${booking.trangThaiThanhToan}</td>
            <td class="p-2">${booking.soGhe}</td>
            <td class="p-2">${booking.soTien}</td>
            <td class="p-2">
                <button onclick="editItem('bookings', '${booking.maDatVe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                <button onclick="deleteItem('bookings', '${booking.maDatVe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function populateInvoiceTable(tableBody) {
    invoiceData.forEach(invoice => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2">${invoice.maHD}</td>
            <td class="p-2">${invoice.ngayXuatHD}</td>
            <td class="p-2">${invoice.phuongThucTT}</td>
            <td class="p-2">${invoice.ngayThanhToan}</td>
            <td class="p-2">
                <button onclick="editItem('invoices', '${invoice.maHD}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                <button onclick="deleteItem('invoices', '${invoice.maHD}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function populateSeatTable(tableBody) {
    seatData.forEach(seat => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2">${seat.maGhe}</td>
            <td class="p-2">${seat.taiKhoan}</td>
            <td class="p-2">${seat.matKhau}</td>
            <td class="p-2">
                <button onclick="editItem('seats', '${seat.maGhe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                <button onclick="deleteItem('seats', '${seat.maGhe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function populateReportTable(tableBody) {
    const reportData = [
        {
            maBaoCao: 'BC001',
            ngayBaoCao: '12/04/2025',
            noiDungBaoCao: 'Khách hàng Joe không mang hộ chiếu'
        },
        {
            maBaoCao: 'BC002',
            ngayBaoCao: '14/04/2025',
            noiDungBaoCao: 'Khách hàng John cần thay đổi giờ bay'
        }
    ];

    reportData.forEach(report => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2">${report.maBaoCao}</td>
            <td class="p-2">${report.ngayBaoCao}</td>
            <td class="p-2">${report.noiDungBaoCao}</td>
            <td class="p-2">
                <button onclick="editItem('reports', '${report.maBaoCao}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                <button onclick="deleteItem('reports', '${report.maBaoCao}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function editItem(section, id) {
    alert(`Đang chỉnh sửa ${section} với ID: ${id}`);
    // Implementation for editing items would go here
    // This would typically involve opening the modal and populating it with data
}

async function deleteItem(section, id) {
    if (section === 'users') {
        if (confirm(`Bạn có chắc chắn muốn xóa khách hàng với ID: ${id}?`)) {
            try {
                // Gửi yêu cầu DELETE tới API
                const response = await fetch(`http://localhost:3000/api/customers/${id}`, {
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                // Lấy dữ liệu JSON từ response
                const data = await response.json();

                // Kiểm tra xem yêu cầu có thành công không
                if (!response.ok) {
                    throw new Error(data.error || 'Lỗi khi xóa khách hàng');
                }

                // Hiển thị thông báo thành công
                alert(data.message || `Đã xóa khách hàng với ID: ${id}`);

                // Cập nhật lại bảng khách hàng
                if (currentSection === 'users') {
                    fetchCustomers(); // Gọi hàm từ customer.js để tải lại danh sách
                }
            } catch (error) {
                console.error('Lỗi:', error);
                alert(`Không thể xóa khách hàng: ${error.message}`);
            }
        }
    } else {
        if (confirm(`Bạn có chắc chắn muốn xóa ${section} với ID: ${id}?`)) {
            alert(`Đã xóa ${section} với ID: ${id}`);
            // Thêm logic xóa cho các section khác nếu cần
        }
    }
}