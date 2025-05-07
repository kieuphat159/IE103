document.addEventListener('DOMContentLoaded', function() {
    const menuItems = document.querySelectorAll('.menu-item');
    const mainContent = document.querySelector('.main-content');
    const mainContentTitle = document.querySelector('.main-content-title');

    // Thêm modal xác nhận đăng xuất vào body
    const logoutModal = document.createElement('div');
    logoutModal.id = 'logoutModal';
    logoutModal.className = 'modal';
    logoutModal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>Xác nhận đăng xuất</h3>
                <span class="close" onclick="closeLogoutModal()">&times;</span>
            </div>
            <div class="modal-body">
                <p>Bạn có chắc chắn muốn đăng xuất?</p>
            </div>
            <div class="modal-footer">
                <button onclick="closeLogoutModal()" class="cancel-btn">Hủy</button>
                <button onclick="confirmLogout()" class="confirm-btn">Đăng xuất</button>
            </div>
        </div>
    `;
    document.body.appendChild(logoutModal);

    // Thêm CSS cho modal
    const style = document.createElement('style');
    style.textContent = `
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .modal-content {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            width: 400px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .modal-header h3 {
            margin: 0;
            color: #333;
            font-size: 1.5em;
        }
        .close {
            font-size: 24px;
            font-weight: bold;
            color: #666;
            cursor: pointer;
        }
        .close:hover {
            color: #333;
        }
        .modal-body {
            margin-bottom: 20px;
        }
        .modal-body p {
            margin: 0;
            color: #666;
            font-size: 1.1em;
        }
        .modal-footer {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }
        .modal-footer button {
            padding: 8px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 1em;
            transition: background-color 0.3s;
        }
        .cancel-btn {
            background-color: #e0e0e0;
            color: #333;
        }
        .cancel-btn:hover {
            background-color: #d0d0d0;
        }
        .confirm-btn {
            background-color: #dc3545;
            color: white;
        }
        .confirm-btn:hover {
            background-color: #c82333;
        }
    `;
    document.head.appendChild(style);

    // Hàm hiển thị modal đăng xuất
    window.showLogoutModal = function() {
        document.getElementById('logoutModal').style.display = 'flex';
    }

    // Hàm đóng modal đăng xuất
    window.closeLogoutModal = function() {
        document.getElementById('logoutModal').style.display = 'none';
    }

    // Hàm xác nhận đăng xuất
    window.confirmLogout = function() {
        localStorage.removeItem('currentUser');
        window.location.href = '../public/login.html';
    }

    // hàm lấy khách hàng
    async function fetchCustomerByTaiKhoan(taiKhoan) {
        try {
            const response = await fetch(`http://localhost:3000/api/customers/by-username/${taiKhoan}`);
            if (!response.ok) throw new Error("Không tìm thấy khách hàng");
            return await response.json();
        } catch (err) {
            console.error(err);
            return null;
        }
    }
    // Dữ liệu chuyến bay mẫu
    const flightData = [
    ];

    // Dữ liệu vé đã đặt mẫu
    const bookedTicketsData = [
    ];

    // Hàm để lọc dữ liệu chuyến bay
    function filterFlights(searchTerm) {
        const lowerSearchTerm = searchTerm.toLowerCase();
        return flightData.filter(flight =>
            flight.MaCB.toLowerCase().includes(lowerSearchTerm) ||
            flight.ThoiGianBay.toLowerCase().includes(lowerSearchTerm) ||
            flight.DiemDi.toLowerCase().includes(lowerSearchTerm) ||
            flight.DiemDen.toLowerCase().includes(lowerSearchTerm) ||
            flight.TrangThai.toLowerCase().includes(lowerSearchTerm)
        );
    }

    // Hàm xử lý sự kiện tìm kiếm chuyến bay
    function handleSearchInput() {
        const searchTerm = searchInput.value;
        const filteredData = filterFlights(searchTerm);
        displayTable(filteredData, ['Mã chuyến bay ', 'Thời gian bay', 'Điểm khởi hành', 'Điểm đến', 'Trạng thái', 'Số chỗ còn trống'], 'Danh Sách Các chuyến bay', true);
    }

    // Hàm để hiển thị bảng dữ liệu
    function displayTable(dataArray, columns, titleText, showSearch = false) {
        mainContent.innerHTML = '';

        const headerDiv = document.createElement('div');
        headerDiv.classList.add('main-content-header');
        const infoText = document.createElement('p');
        infoText.textContent = titleText;
        headerDiv.appendChild(infoText);
        mainContent.appendChild(headerDiv);

        if (showSearch) {
            const searchContainer = document.createElement('div');
            searchContainer.classList.add('search-container');
            const searchInputLabel = document.createElement('label');
            searchInputLabel.textContent = 'Tìm kiếm chuyến bay: ';
            searchInput = document.createElement('input');
            searchInput.type = 'text';
            searchInput.placeholder = 'Nhập mã CB, điểm đi, đến...';
            searchInput.addEventListener('input', handleSearchInput);
            searchContainer.appendChild(searchInputLabel);
            searchContainer.appendChild(searchInput);
            mainContent.appendChild(searchContainer);
        }

        const table = document.createElement('table');
        const thead = document.createElement('thead');
        const tbody = document.createElement('tbody');

        const headerRow = document.createElement('tr');
        columns.forEach(column => {
            const th = document.createElement('th');
            th.textContent = column;
            headerRow.appendChild(th);
        });
        thead.appendChild(headerRow);
        table.appendChild(thead);
        table.appendChild(tbody);

        mainContent.appendChild(table);

        if (!dataArray || dataArray.length === 0) {
            const noDataMessage = document.createElement('p');
            noDataMessage.textContent = 'Không có dữ liệu.';
            mainContent.appendChild(noDataMessage);
        } else {
            dataArray.forEach(item => {
                const row = document.createElement('tr');
                columns.forEach(column => {
                    const td = document.createElement('td');
                    td.textContent = item[column];
                    row.appendChild(td);
                });
                tbody.appendChild(row);
            });
        }
    }

    // Hàm để hiển thị dữ liệu dạng bảng đứng
    function displayVerticalTable(data) {
        mainContent.innerHTML = '';

        const headerDiv = document.createElement('div');
        headerDiv.classList.add('main-content-header');
        const infoText = document.createElement('p');
        infoText.textContent = 'Thông tin khách hàng';
        headerDiv.appendChild(infoText);
        mainContent.appendChild(headerDiv);

        const table = document.createElement('table');
        table.classList.add('vertical-table');

        const headers = ['Mã KH', 'Tên', 'Email', 'Số Điện Thoại', 'Địa Chỉ', 'Passport'];

        if (!data || Object.keys(data).length === 0) {
            const noDataMessage = document.createElement('p');
            noDataMessage.textContent = 'Không có dữ liệu khách hàng.';
            mainContent.appendChild(noDataMessage);

            headers.forEach(header => {
                const row = document.createElement('tr');
                const th = document.createElement('th');
                th.textContent = header;
                const td = document.createElement('td');
                row.appendChild(th);
                row.appendChild(td);
                table.appendChild(row);
            });
        } else {
            headers.forEach(header => {
                const row = document.createElement('tr');
                const th = document.createElement('th');
                th.textContent = header;
                const td = document.createElement('td');
                td.textContent = data[header] || '';
                row.appendChild(th);
                row.appendChild(td);
                table.appendChild(row);
            });
        }
        mainContent.appendChild(table);
    }

    // Hàm xử lý đăng xuất
    function handleLogout() {
        showLogoutModal();
    }

    // Hàm để hiển thị nội dung tương ứng
    function showContent(contentId) {
        switch (contentId) {
            case 'logout':
                handleLogout();
                break;
            case 'booked-tickets':
                fetch('http://localhost:3000/api/flights')
                .then(res => res.json())
                .then(data => {
                    flightData.length = 0; // Clear cũ
                    data.forEach(f => {
                        flightData.push({
                            'Mã chuyến bay ': f.maChuyenBay,
                            'Thời gian bay': new Date(f.gioBay).toLocaleString() + ' - ' + new Date(f.gioDen).toLocaleString(),
                            'Điểm khởi hành': f.diaDiemDau,
                            'Điểm đến': f.diaDiemCuoi,
                            'Trạng thái': f.tinhTrangChuyenBay,
                            'Số chỗ còn trống': 'N/A' // Nếu chưa xử lý số ghế trống
                        });
                    });
        
                    displayTable(flightData, ['Mã chuyến bay ', 'Thời gian bay', 'Điểm khởi hành', 'Điểm đến', 'Trạng thái', 'Số chỗ còn trống'], 'Danh Sách Các chuyến bay', true);
                })
                .catch(err => {
                    console.error('Lỗi gọi API /flights:', err);
                    mainContent.innerHTML = '<p style="color:red">Không thể tải danh sách chuyến bay</p>';
                });
                break;
                case 'flight-list':
                    mainContentTitle.textContent = 'Vé đã đặt';
                    const currentUsername = localStorage.getItem('currentUser') || "user1";
                    fetch(`http://localhost:3000/api/bookings?username=${currentUsername}`)
                        .then(res => res.json())
                        .then(data => {
                            console.log("Dữ liệu từ API /bookings:", data);
                            bookedTicketsData.length = 0;
                
                            data.forEach(v => {
                                bookedTicketsData.push({
                                    'Mã khách hàng': v.maKH ?? 'Không có',
                                    'Mã vé': v.maDatVe ?? 'Không rõ',
                                    'Mã chuyến bay': v.maChuyenBay ?? 'Không có',
                                    'Ngày mua': v.ngayDatVe ? new Date(v.ngayDatVe).toLocaleDateString() : 'Không rõ',
                                    'Số ghế': v.soGhe ?? '?',
                                    'Hạng ghế': 'N/A',
                                    'Tình trạng vé': v.trangThaiThanhToan ?? 'Không rõ'
                                });
                            });
                
                            displayTable(
                                bookedTicketsData,
                                ['Mã khách hàng', 'Mã vé', 'Mã chuyến bay', 'Ngày mua', 'Số ghế', 'Hạng ghế', 'Tình trạng vé'],
                                'Danh sách vé đã đặt'
                            );
                        })
                        .catch(err => {
                            console.error('Lỗi API /bookings:', err);
                            mainContent.innerHTML = '<p style="color:red">Không thể tải danh sách vé đã đặt</p>';
                        });
                    break;
                
                
                    case 'customer-info':
                        mainContentTitle.textContent = 'Thông tin khách hàng';
                        fetchCustomerByTaiKhoan("user1")  // ← dùng tài khoản đang đăng nhập thật
                            .then(data => {
                                displayVerticalTable({
                                    'Mã KH': data?.MaKH || '',
                                    'Tên': data?.Ten || '',
                                    'Email': data?.Email || '',
                                    'Số Điện Thoại': data?.Sdt || '',
                                    'Địa Chỉ': '',  // chưa có cột này, có thể thêm nếu muốn
                                    'Passport': data?.Passport || ''
                                });
                            });
                        break;
            default:
                mainContentTitle.textContent = 'Chào mừng';
                mainContent.innerHTML = '<div class="main-content-header"><p>Chào mừng!</p></div>';
                break;
        }
    }

    // Gắn sự kiện click cho mỗi mục menu
    menuItems.forEach(item => {
        item.addEventListener('click', function() {
            const contentId = this.getAttribute('data-content');
            showContent(contentId);
        });
    });

    // Hiển thị trang chào mừng khi tải trang
    showContent('');
});