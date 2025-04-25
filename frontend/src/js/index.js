document.addEventListener('DOMContentLoaded', function() {
    const menuItems = document.querySelectorAll('.menu-item');
    const mainContent = document.querySelector('.main-content');
    const mainContentTitle = document.querySelector('.main-content-title');

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
        displayTable(filteredData, ['MaCB', 'ThoiGianBay', 'DiemDi', 'DiemDen', 'TrangThai', 'SoChoConTrong'], 'Danh Sách Các chuyến bay', true);
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

    // Hàm để hiển thị nội dung tương ứng
    function showContent(contentId) {
        switch (contentId) {
            case 'booked-tickets':
                mainContentTitle.textContent = 'Danh sách chuyến bay';
                displayTable(flightData, ['MaCB', 'ThoiGianBay', 'DiemDi', 'DiemDen', 'TrangThai', 'SoChoConTrong'], 'Danh Sách Các chuyến bay', true);
                break;
            case 'flight-list':
                mainContentTitle.textContent = 'Vé đã đặt';
                displayTable(bookedTicketsData, ['MaKH', 'MaVe', 'MaCB', 'NgayMua', 'SoGhe', 'HangGhe', 'TinhTrangVe'], 'Danh sách vé đã đặt');
                break;
            case 'customer-info':
                mainContentTitle.textContent = 'Thông tin khách hàng';
                displayVerticalTable({});
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
