// import controllerSession from './controllersession.js';

document.addEventListener("DOMContentLoaded", () => {

    // Load dữ liệu báo cáo
    fetchReports();

    // Gọi lại khi nhấn tab "Thông tin"
    const personalInfoTabButton = document.querySelector("button[onclick*='personal-info']");
    if (personalInfoTabButton) {
        personalInfoTabButton.addEventListener("click", fetchPersonalInfo);
    }

    // Thêm sự kiện cho nút đăng xuất
    const logoutButton = document.querySelector("button[onclick='logout()']");
    if (logoutButton) {
        logoutButton.addEventListener("click", () => {
            const dialog = document.getElementById('confirmDialog');
            if (dialog) dialog.classList.remove('hidden');
        });
    }
});

// Hiển thị section
function showSection(sectionId) {
    document.querySelectorAll('.section').forEach(section => {
        section.classList.add('hidden');
    });
    document.getElementById(sectionId).classList.remove('hidden');
    if (sectionId === 'controllers') {
        fetchControllers(); // Tải danh sách nhân viên kiểm soát
    } else if (sectionId === 'revenue-reports') {
        const revenueSearchInput = document.getElementById('searchRevenueInput');
        if (revenueSearchInput) {
            revenueSearchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    searchRevenue();
                }
            });
        }
        //fetchRevenueReports();
    }
}

// Fetch all controllers
async function fetchControllers() {
    try {
        console.log('Fetching controllers...');
        const response = await fetch('http://localhost:3000/api/control-staff', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('Error response:', errorText);
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Received data:', data);
        displayControllers(data);
    } catch (error) {
        console.error('Error fetching controllers:', error);
        alert('Có lỗi xảy ra khi tải dữ liệu nhân viên kiểm soát: ' + error.message);
    }
}

// Display controllers in the table
function displayControllers(controllers) {
    console.log('Displaying controllers:', controllers);
    const table = document.getElementById('controllerTable');
    if (!table) {
        console.error('Controller table element not found');
        return;
    }
    
    table.innerHTML = '';

    if (!controllers || controllers.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td colspan="8" class="p-2 border text-center">Không có dữ liệu</td>';
        table.appendChild(row);
        return;
    }

    controllers.forEach(controller => {
        console.log('Processing controller:', controller);
        const row = document.createElement('tr');
        row.innerHTML = `
            <td class="p-2 border">${controller.maNV || ''}</td>
            <td class="p-2 border">${controller.ten || ''}</td>
            <td class="p-2 border">${controller.email || ''}</td>
            <td class="p-2 border">${controller.sdt || ''}</td>
            <td class="p-2 border">${controller.ngaySinh ? new Date(controller.ngaySinh).toLocaleDateString() : ''}</td>
            <td class="p-2 border">${controller.gioiTinh || ''}</td>
            <td class="p-2 border">${controller.soCCCD || ''}</td>
            <td class="p-2 border">
                <button onclick="editController('${controller.maNV}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-2">Sửa</button>
                <button onclick="deleteController('${controller.maNV}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
            </td>
        `;
        table.appendChild(row);
    });
}

// Search controllers
function searchController() {
    const searchInput = document.getElementById('searchControllerInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('controllerTable');
    const rows = tableBody.getElementsByTagName('tr');

    for (let i = 0; i < rows.length; i++) {
        const cells = rows[i].getElementsByTagName('td');
        let found = false;
        
        for (let j = 0; j < cells.length - 1; j++) {
            const cellText = cells[j].textContent.toLowerCase();
            if (cellText.includes(searchTerm)) {
                found = true;
                break;
            }
        }
        
        rows[i].style.display = found ? '' : 'none';
    }
}

// Open modal for adding/editing controller
function openControllerModal(mode, controller = null) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    const modalContent = document.getElementById('modalContent');

    modalTitle.textContent = mode === 'add' ? 'Thêm nhân viên kiểm soát' : 'Sửa nhân viên kiểm soát';
    
    modalContent.innerHTML = `
        <form id="controllerForm" class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700">Mã nhân viên</label>
                <input type="text" id="controllerMaNV" name="maNV" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.maNV : ''}" ${mode === 'edit' ? 'readonly' : ''}>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Tài khoản</label>
                <input type="text" id="controllerTaiKhoan" name="taiKhoan" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.taiKhoan : ''}" ${mode === 'edit' ? 'readonly' : ''}>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Họ tên</label>
                <input type="text" id="controllerHoTen" name="hoTen" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.ten : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Email</label>
                <input type="email" id="controllerEmail" name="email" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.email : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Số điện thoại</label>
                <input type="tel" id="controllerSoDienThoai" name="soDienThoai" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.sdt : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Ngày sinh</label>
                <input type="date" id="controllerNgaySinh" name="ngaySinh" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? new Date(controller.ngaySinh).toISOString().split('T')[0] : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Giới tính</label>
                <select id="controllerGioiTinh" name="gioiTinh" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3">
                    <option value="Nam" ${controller && controller.gioiTinh === 'Nam' ? 'selected' : ''}>Nam</option>
                    <option value="Nữ" ${controller && controller.gioiTinh === 'Nữ' ? 'selected' : ''}>Nữ</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Số CCCD</label>
                <input type="text" id="controllerCMND_CCCD" name="CMND_CCCD" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${controller ? controller.soCCCD : ''}">
            </div>
            ${mode === 'add' ? `
            <div>
                <label class="block text-sm font-medium text-gray-700">Mật khẩu</label>
                <input type="password" id="matKhau" name="matKhau" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3">
            </div>
            ` : ''}
        </form>
    `;

    modal.classList.remove('hidden');
    window.currentMode = mode;
    window.currentController = controller;
}

// Save controller data
// controller.js
async function saveController() {
    console.log("");
    const form = document.getElementById('controllerForm');
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());

    // Kiểm tra dữ liệu
    if (!data.maNV || !data.hoTen || !data.email || !data.soDienThoai || !data.ngaySinh || !data.gioiTinh || !data.CMND_CCCD) {
        alert('Vui lòng điền đầy đủ thông tin!');
        return;
    }
    if (window.currentMode === 'add' && !data.matKhau) {
        alert('Vui lòng nhập mật khẩu!');
        return;
    }

    // Định dạng dữ liệu gửi đi
    const payload = {
        maNV: data.maNV,
        taiKhoan: data.taiKhoan, // Send taiKhoan as a separate field
        ten: data.hoTen,
        email: data.email,
        sdt: data.soDienThoai,
        ngaySinh: new Date(data.ngaySinh).toISOString().split('T')[0],
        gioiTinh: data.gioiTinh,
        soCCCD: data.CMND_CCCD,
        matKhau: data.matKhau || undefined
    };

    try {
        const url = window.currentMode === 'add' ? '/api/controllers' : `/api/control-staff/${data.maNV}`;
        const method = window.currentMode === 'add' ? 'POST' : 'PUT';

        const response = await fetch(`http://localhost:3000${url}`, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi khi lưu dữ liệu');
        }

        closeModal();
        fetchControllers();
        alert(window.currentMode === 'add' ? 'Thêm nhân viên kiểm soát thành công' : 'Cập nhật nhân viên kiểm soát thành công');
    } catch (error) {
        console.error('Error saving controller:', error);
        if (error.message.includes('Tài khoản đã tồn tại')) {
            alert('Tài khoản đã tồn tại. Vui lòng chọn tài khoản khác.');
        } else if (error.message.includes('Mã nhân viên đã tồn tại')) {
            alert('Mã nhân viên đã tồn tại. Vui lòng chọn mã nhân viên khác.');
        } else {
            alert('Có lỗi xảy ra khi lưu dữ liệu: ' + error.message);
        }
    }
}

// Edit controller
async function editController(maNV) {
    try {
        const response = await fetch(`http://localhost:3000/api/controllers/${maNV}`);
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi không xác định từ server');
        }
        const controller = await response.json();
        openControllerModal('edit', controller);
    } catch (error) {
        console.error('Error fetching controller details:', error.message);
        alert('Có lỗi xảy ra khi tải thông tin nhân viên kiểm soát: ' + error.message);
    }
}

// Delete controller
async function deleteController(maNV) {
    if (!confirm('Bạn có chắc chắn muốn xóa nhân viên kiểm soát này?')) {
        return;
    }

    try {
        const response = await fetch(`http://localhost:3000/api/controllers/${maNV}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi không xác định từ server');
        }

        fetchControllers();
        alert('Xóa nhân viên kiểm soát thành công');
    } catch (error) {
        console.error('Error deleting controller:', error.message);
        alert('Có lỗi xảy ra khi xóa nhân viên kiểm soát: ' + error.message);
    }
}
// Đăng xuất
function logout() {
    const dialog = document.getElementById('confirmDialog');
    if (dialog) dialog.classList.remove('hidden');
}

function closeConfirmDialog() {
    const dialog = document.getElementById('confirmDialog');
    if (dialog) dialog.classList.add('hidden');
}

function confirmLogout() {
    controllerSession.logout();
}
async function fetchRevenueReports() {
    try {
        // Fetch monthly revenue data
        const monthlyResponse = await fetch('http://localhost:3000/api/revenue-reports-monthly');
        if (!monthlyResponse.ok) {
            throw new Error('Không thể lấy dữ liệu báo cáo doanh thu theo tháng');
        }
        const monthlyData = await monthlyResponse.json();

        // Fetch total revenue data
        const totalResponse = await fetch('http://localhost:3000/api/revenue-reports-total');
        if (!totalResponse.ok) {
            throw new Error('Không thể lấy dữ liệu báo cáo tổng doanh thu');
        }
        const totalData = await totalResponse.json();

        renderRevenueChart(monthlyData);
        displayTotalRevenue(totalData);
    } catch (error) {
        console.error('Lỗi khi lấy báo cáo doanh thu:', error);
        alert('Không thể tải báo cáo doanh thu: ' + error.message);
    }
}

// Function to render the bar chart using Chart.js
function renderRevenueChart(reports) {
    const canvas = document.getElementById('revenueChart');
    if (!canvas) {
        console.error('Canvas element not found for revenue chart');
        return;
    }

    const ctx = canvas.getContext('2d');
    if (!ctx) {
        console.error('Canvas context not available');
        return;
    }

    // Destroy existing chart instance if it exists
    const existingChart = Chart.getChart(canvas);
    if (existingChart) {
        existingChart.destroy();
    }

    // Prepare data for the chart
    const labels = reports.map(report => `${report.Thang}/${report.Nam}`);
    const revenueData = reports.map(report => report.TongDoanhThu);
    const transactionData = reports.map(report => report.SoGiaoDich);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Doanh Thu (VND)',
                    data: revenueData,
                    backgroundColor: 'rgba(54, 162, 235, 0.6)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                },
                {
                    label: 'Số Giao Dịch',
                    data: transactionData,
                    backgroundColor: 'rgba(255, 99, 132, 0.6)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }
            ]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Giá trị'
                    }
                },
                x: {
                    title: {
                        display: true,
                        text: 'Tháng/Năm'
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'top'
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            let label = context.dataset.label || '';
                            if (label) {
                                label += ': ';
                            }
                            if (context.dataset.label === 'Doanh Thu (VND)') {
                                label += new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(context.parsed.y);
                            } else {
                                label += context.parsed.y;
                            }
                            return label;
                        }
                    }
                }
            }
        }
    });
}

// Function to display total revenue in the footer
function displayTotalRevenue(totalData) {
    const totalRevenueElement = document.getElementById('totalRevenue');
    if (!totalRevenueElement) {
        console.error('Total revenue element not found');
        return;
    }
    totalRevenueElement.innerHTML = `
        Tổng Doanh Thu: ${totalData[0].TongDoanhThu.toLocaleString('vi-VN', { style: 'currency', currency: 'VND' })}
        | Tổng Số Giao Dịch: ${totalData[0].TongSoGiaoDich}
    `;
}

// Function to search revenue reports by month/year
function searchRevenue() {
    const searchInput = document.getElementById('searchRevenueInput');
    const searchTerm = searchInput.value.toLowerCase();
    fetchRevenueReports().then(() => {
        const canvas = document.getElementById('revenueChart');
        if (!canvas) return;

        const chart = Chart.getChart(canvas);
        if (!chart) return;

        const filteredLabels = chart.data.labels.filter(label => label.toLowerCase().includes(searchTerm));
        const filteredIndices = chart.data.labels
            .map((label, index) => label.toLowerCase().includes(searchTerm) ? index : -1)
            .filter(index => index !== -1);

        const filteredDatasets = chart.data.datasets.map(dataset => ({
            ...dataset,
            data: filteredIndices.map(index => dataset.data[index])
        }));

        chart.data.labels = filteredLabels;
        chart.data.datasets = filteredDatasets;
        chart.update();
    });
}

// Hook into showSection to fetch data when the revenue-reports section is shown
document.addEventListener('showSectionEvent', (e) => {
    if (e.detail.sectionId === 'revenue-reports') {
        fetchRevenueReports();
    }
});

// Modify showSection to dispatch custom event
const originalShowSection = showSection;
showSection = function(sectionId) {
    originalShowSection(sectionId);
    const event = new CustomEvent('showSectionEvent', { detail: { sectionId } });
    document.dispatchEvent(event);
};