document.addEventListener('DOMContentLoaded', function() {
    const menuItems = document.querySelectorAll('.menu-item');
    const mainContent = document.querySelector('.main-content');
    const mainContentTitle = document.querySelector('.main-content-title');

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
    const flightData = [];

    // Dữ liệu vé đã đặt mẫu
    const bookedTicketsData = [];

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
        const tabContent = document.getElementById(titleText.toLowerCase().replace(/\s+/g, '-'));
        if (!tabContent) return;
        
        tabContent.innerHTML = '';

        const headerDiv = document.createElement('div');
        headerDiv.classList.add('main-content-header');
        const infoText = document.createElement('p');
        infoText.textContent = titleText;
        headerDiv.appendChild(infoText);
        tabContent.appendChild(headerDiv);

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
            tabContent.appendChild(searchContainer);
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

        tabContent.appendChild(table);

        if (!dataArray || dataArray.length === 0) {
            const noDataMessage = document.createElement('p');
            noDataMessage.textContent = 'Không có dữ liệu.';
            tabContent.appendChild(noDataMessage);
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
        const tabContent = document.getElementById('customer-info');
        if (!tabContent) return;
        
        tabContent.innerHTML = '';

        const headerDiv = document.createElement('div');
        headerDiv.classList.add('main-content-header');
        const infoText = document.createElement('p');
        infoText.textContent = 'Thông tin khách hàng';
        headerDiv.appendChild(infoText);
        tabContent.appendChild(headerDiv);

        const table = document.createElement('table');
        table.classList.add('vertical-table');

        const headers = ['Mã KH', 'Tên', 'Email', 'Số Điện Thoại', 'Địa Chỉ', 'Passport'];

        if (!data || Object.keys(data).length === 0) {
            const noDataMessage = document.createElement('p');
            noDataMessage.textContent = 'Không có dữ liệu khách hàng.';
            tabContent.appendChild(noDataMessage);

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
        tabContent.appendChild(table);
    }

    // Hàm để hiển thị nội dung tương ứng
    function showContent(contentId) {
        // Ẩn tất cả các tab content
        document.querySelectorAll('.tab-content').forEach(tab => {
            tab.style.display = 'none';
        });

        switch (contentId) {
            case 'booked-tickets':
                mainContentTitle.textContent = 'Danh Sách Các chuyến bay';
                fetch('http://localhost:3000/api/flights')
                .then(res => res.json())
                .then(data => {
                    flightData.length = 0;
                    data.forEach(f => {
                        flightData.push({
                            'Mã chuyến bay ': f.maChuyenBay,
                            'Thời gian bay': new Date(f.gioBay).toLocaleString() + ' - ' + new Date(f.gioDen).toLocaleString(),
                            'Điểm khởi hành': f.diaDiemDau,
                            'Điểm đến': f.diaDiemCuoi,
                            'Trạng thái': f.tinhTrangChuyenBay,
                            'Số chỗ còn trống': 'N/A'
                        });
                    });
                    displayTable(flightData, ['Mã chuyến bay ', 'Thời gian bay', 'Điểm khởi hành', 'Điểm đến', 'Trạng thái', 'Số chỗ còn trống'], 'Danh Sách Các chuyến bay', true);
                })
                .catch(err => {
                    console.error('Lỗi gọi API /flights:', err);
                    const tabContent = document.getElementById('booked-tickets');
                    if (tabContent) {
                        tabContent.innerHTML = '<p style="color:red">Không thể tải danh sách chuyến bay</p>';
                    }
                });
                break;

            case 'flight-list':
                mainContentTitle.textContent = 'Vé đã đặt';
                fetch(`http://localhost:3000/api/bookings?username=user1`)
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
                        displayTable(bookedTicketsData, ['Mã khách hàng', 'Mã vé', 'Mã chuyến bay', 'Ngày mua', 'Số ghế', 'Hạng ghế', 'Tình trạng vé'], 'Danh sách vé đã đặt');
                    })
                    .catch(err => {
                        console.error('Lỗi API /bookings:', err);
                        const tabContent = document.getElementById('flight-list');
                        if (tabContent) {
                            tabContent.innerHTML = '<p style="color:red">Không thể tải danh sách vé đã đặt</p>';
                        }
                    });
                break;

            case 'customer-info':
                mainContentTitle.textContent = 'Thông tin khách hàng';
                fetchCustomerByTaiKhoan("user1")
                    .then(data => {
                        if (!data) {
                            const tabContent = document.getElementById('customer-info');
                            if (tabContent) {
                                tabContent.innerHTML = '<p style="color:red">Không thể tải thông tin khách hàng</p>';
                            }
                            return;
                        }
                        displayVerticalTable({
                            'Mã KH': data.MaKH || '',
                            'Tên': data.Ten || '',
                            'Email': data.Email || '',
                            'Số Điện Thoại': data.Sdt || '',
                            'Địa Chỉ': data.DiaChi || '',
                            'Passport': data.Passport || ''
                        });
                    })
                    .catch(err => {
                        console.error('Lỗi khi lấy thông tin khách hàng:', err);
                        const tabContent = document.getElementById('customer-info');
                        if (tabContent) {
                            tabContent.innerHTML = '<p style="color:red">Không thể tải thông tin khách hàng</p>';
                        }
                    });
                break;

            default:
                mainContentTitle.textContent = 'Chào mừng';
                const welcomeContent = document.createElement('div');
                welcomeContent.classList.add('main-content-header');
                //welcomeContent.innerHTML = '<p>Chào mừng!</p>';
                mainContent.appendChild(welcomeContent);
                break;
        }

        // Hiển thị tab content được chọn
        const selectedTab = document.getElementById(contentId);
        if (selectedTab) {
            selectedTab.style.display = 'block';
        }
    }

    // Gắn sự kiện click cho mỗi mục menu
    menuItems.forEach(item => {
        item.addEventListener('click', function() {
            const contentId = this.getAttribute('data-content');
            
            // Xử lý đăng xuất
            if (contentId === 'logout') {
                showConfirmDialog();
                return;
            }

            showContent(contentId);
        });
    });

    // Hiển thị trang chào mừng khi tải trang
    showContent('');
});

// Xử lý đăng xuất
function showConfirmDialog() {
    const dialog = document.getElementById('confirmDialog');
    dialog.style.display = 'flex';
}

function closeConfirmDialog() {
    const dialog = document.getElementById('confirmDialog');
    dialog.style.display = 'none';
}

function confirmLogout() {
    // Xóa thông tin người dùng
    localStorage.removeItem('user');
    
    // Chuyển về trang đăng nhập
    window.location.href = 'login.html';
}

// Đóng dialog khi click bên ngoài
window.onclick = function(event) {
    const dialog = document.getElementById('confirmDialog');
    if (event.target === dialog) {
        dialog.style.display = 'none';
    }
}
