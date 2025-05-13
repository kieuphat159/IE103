import controllerSession from './controllerSession.js';

document.addEventListener("DOMContentLoaded", () => {
    // Kiểm tra đăng nhập và vai trò controller
    if (!controllerSession.isLoggedInAsController()) {
        alert('Bạn cần đăng nhập với vai trò nhân viên kiểm soát để truy cập trang này.');
        window.location.href = 'login.html';
        return;
    }

    // Cập nhật thông tin người dùng trên giao diện
    controllerSession.updateUserInterface();

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
    if (sectionId === 'reports') {
        fetchReports();
    } else if (sectionId === 'personal-info') {
        fetchPersonalInfo();
    }
}

// Lấy thông tin cá nhân
async function fetchPersonalInfo() {
    try {
        const user = controllerSession.getUser();
        if (!user || !user.taiKhoan) {
            alert('Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.');
            window.location.href = 'login.html';
            return;
        }

        const response = await fetch(`http://localhost:3000/api/control-staff?taiKhoan=${user.taiKhoan}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        if (data.length === 0) {
            throw new Error('Không tìm thấy thông tin nhân viên kiểm soát');
        }

        displayPersonalInfo(data[0]);
    } catch (error) {
        console.error('Error fetching personal info:', error);
        alert('Có lỗi xảy ra khi tải thông tin cá nhân: ' + error.message);
        displayPersonalInfo({});
    }
}

// Hiển thị thông tin cá nhân trong bảng đứng
function displayPersonalInfo(controller) {
    const tableBody = document.getElementById('personalInfoTable');
    tableBody.innerHTML = '';

    const fields = [
        { label: 'Mã NV', key: 'maNV' },
        { label: 'Họ tên', key: 'ten' },
        { label: 'Email', key: 'email' },
        { label: 'Số điện thoại', key: 'sdt' },
        { label: 'Ngày sinh', key: 'ngaySinh', format: (value) => value ? new Date(value).toLocaleDateString() : '' },
        { label: 'Giới tính', key: 'gioiTinh' },
        { label: 'Số CCCD', key: 'soCCCD' }
    ];

    if (!controller || Object.keys(controller).length === 0) {
        fields.forEach(field => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <th class="p-2 border font-bold">${field.label}</th>
                <td class="p-2 border"></td>
            `;
            tableBody.appendChild(row);
        });
        return;
    }

    fields.forEach(field => {
        const value = field.format ? field.format(controller[field.key]) : controller[field.key] || '';
        const row = document.createElement('tr');
        row.innerHTML = `
            <th class="p-2 border font-bold">${field.label}</th>
            <td class="p-2 border">${value}</td>
        `;
        tableBody.appendChild(row);
    });
}

// Fetch reports
async function fetchReports() {
    try {
        console.log('Fetching reports...');
        const user = controllerSession.getUser();
        if (!user || !user.taiKhoan) {
            throw new Error('Không tìm thấy thông tin người dùng');
        }

        // Lấy maNV từ thông tin nhân viên kiểm soát
        const response = await fetch(`http://localhost:3000/api/control-staff?taiKhoan=${user.taiKhoan}`);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const staffData = await response.json();
        if (staffData.length === 0) {
            throw new Error('Không tìm thấy thông tin nhân viên kiểm soát');
        }
        const maNV = staffData[0].maNV;

        // Gửi yêu cầu lấy báo cáo với maNV
        const reportsResponse = await fetch(`http://localhost:3000/api/reports?maNV=${maNV}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        });

        if (!reportsResponse.ok) {
            throw new Error(`HTTP error! status: ${reportsResponse.status}`);
        }

        const reports = await reportsResponse.json();
        console.log('Received reports:', reports);
        displayReports(reports);
    } catch (error) {
        console.error('Error fetching reports:', error);
        alert('Có lỗi xảy ra khi tải dữ liệu báo cáo: ' + error.message);
        displayReports([]);
    }
}

// Display reports in the table
function displayReports(reports) {
    const tableBody = document.getElementById('reportTable');
    tableBody.innerHTML = '';

    if (!reports || reports.length === 0) {
        const row = document.createElement('tr');
        row.innerHTML = '<td colspan="5" class="p-2 border text-center">Không có báo cáo nào</td>';
        tableBody.appendChild(row);
        return;
    }

    reports.forEach(report => {
        const row = document.createElement('tr');
        row.classList.add('hover:bg-gray-100');
        row.innerHTML = `
            <td class="p-2 border">${report.maBaoCao}</td>
            <td class="p-2 border">${report.ngayBaoCao ? new Date(report.ngayBaoCao).toLocaleDateString() : ''}</td>
            <td class="p-2 border">${report.noiDungBaoCao}</td>
            <td class="p-2 border">${report.maNV}</td>
            <td class="p-2 border">${report.trangThai}</td>
        `;
        tableBody.appendChild(row);
    });
}

// Search reports
function searchReport() {
    const searchInput = document.getElementById('searchReportInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('reportTable');
    const rows = tableBody.getElementsByTagName('tr');

    for (let i = 0; i < rows.length; i++) {
        const cells = rows[i].getElementsByTagName('td');
        let found = false;

        for (let j = 0; j < cells.length; j++) {
            const cellText = cells[j].textContent.toLowerCase();
            if (cellText.includes(searchTerm)) {
                found = true;
                break;
            }
        }

        rows[i].style.display = found ? '' : 'none';
    }
}

// Open modal for adding report
function openReportModal() {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    const modalContent = document.getElementById('modalContent');

    modalTitle.textContent = 'Thêm báo cáo';
    modalContent.innerHTML = `
        <input id="generatedMaBaoCao" type="hidden">
        <div>
            <label class="block text-sm font-medium text-gray-700">Mã nhân viên</label>
            <input type="text" id="reportMaNV" name="maNV" required
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700">Ngày báo cáo</label>
            <input type="date" id="reportNgayBaoCao" name="ngayBaoCao" required
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700">Nội dung báo cáo</label>
            <textarea id="reportNoiDung" name="noiDungBaoCao" required
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-20 px-3 py-2"></textarea>
        </div>
    `;

    modal.classList.remove('hidden');
    generateNewReportCode();
}

// Generate new report code
async function generateNewReportCode() {
    try {
        const response = await fetch('http://localhost:3000/api/reports/generate-code');
        if (!response.ok) {
            throw new Error('Không thể tạo mã báo cáo');
        }
        const data = await response.json();
        document.getElementById('generatedMaBaoCao').value = data.maBaoCao;
    } catch (error) {
        console.error('Error generating report code:', error);
        alert('Có lỗi xảy ra khi tạo mã báo cáo');
    }
}

// Save report data
async function saveReport() {
    const maBaoCao = document.getElementById('generatedMaBaoCao').value;
    const maNV = document.getElementById('reportMaNV').value;
    const ngayBaoCao = document.getElementById('reportNgayBaoCao').value;
    const noiDungBaoCao = document.getElementById('reportNoiDung').value;

    if (!maBaoCao || !maNV || !ngayBaoCao || !noiDungBaoCao) {
        alert('Vui lòng điền đầy đủ thông tin!');
        return;
    }

    try {
        const response = await fetch('http://localhost:3000/api/reports', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                maBaoCao,
                maNV,
                ngayBaoCao,
                noiDungBaoCao,
                trangThai: 'Chưa xử lý'
            })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi khi lưu báo cáo');
        }

        closeModal();
        fetchReports();
        alert('Thêm báo cáo thành công');
    } catch (error) {
        console.error('Error saving report:', error);
        alert('Có lỗi xảy ra khi lưu báo cáo: ' + error.message);
    }
}

// Close modal
function closeModal() {
    const modal = document.getElementById('modal');
    modal.classList.add('hidden');
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