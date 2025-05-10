// controller.js
import controllerSession from './controllersession.js';

document.addEventListener("DOMContentLoaded", () => {
    // Kiểm tra đăng nhập và vai trò controller
    if (!controllerSession.isLoggedInAsController()) {
        alert('Bạn cần đăng nhập với vai trò nhân viên kiểm soát để truy cập trang này.');
        window.location.href = 'login.html';
        return;
    }

    // Cập nhật thông tin người dùng trên giao diện
    controllerSession.updateUserInterface();

    // Load dữ liệu ngay khi trang được tải
    fetchControllers();
    
    // Gọi lại khi nhấn tab "Nhân viên kiểm soát"
    const controllerTabButton = document.querySelector("button[onclick*='controllers']");
    if (controllerTabButton) {
        controllerTabButton.addEventListener("click", fetchControllers);
    }

    // Add event listener for enter key on search input
    const searchInput = document.getElementById('searchControllerInput');
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                searchController();
            }
        });
    }

    // Thêm sự kiện cho nút đăng xuất
    const logoutButton = document.getElementById('logoutButton');
    if (logoutButton) {
        logoutButton.addEventListener('click', () => {
            const dialog = document.getElementById('confirmDialog');
            if (dialog) dialog.classList.remove('hidden');
        });
    }
});

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
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
            </div>
            ` : ''}
        </form>
    `;

    modal.classList.remove('hidden');
    window.currentMode = mode;
    window.currentController = controller;
}

// Save controller data
async function saveController() {
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

    // Định dạng ngày sinh
    data.ngaySinh = new Date(data.ngaySinh).toISOString().split('T')[0];

    try {
        const url = window.currentMode === 'add' ? '/api/controllers' : `/api/controllers/${data.maNV}`;
        const method = window.currentMode === 'add' ? 'POST' : 'PUT';

        const response = await fetch(`http://localhost:3000${url}`, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                maNV: data.maNV,
                ten: data.hoTen,
                email: data.email,
                sdt: data.soDienThoai,
                ngaySinh: data.ngaySinh,
                gioiTinh: data.gioiTinh,
                soCCCD: data.CMND_CCCD,
                matKhau: data.matKhau || undefined // Chỉ gửi matKhau khi thêm mới
            })
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
        alert('Có lỗi xảy ra khi lưu dữ liệu: ' + error.message);
    }
}

// Edit controller
async function editController(maNV) {
    try {
        const response = await fetch(`/api/controllers/${maNV}`);
        const controller = await response.json();
        openControllerModal('edit', controller);
    } catch (error) {
        console.error('Error fetching controller details:', error);
        alert('Có lỗi xảy ra khi tải thông tin nhân viên kiểm soát');
    }
}

// Delete controller
async function deleteController(maNV) {
    if (!confirm('Bạn có chắc chắn muốn xóa nhân viên kiểm soát này?')) {
        return;
    }

    try {
        const response = await fetch(`/api/controllers/${maNV}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error('Lỗi khi xóa nhân viên kiểm soát');
        }

        fetchControllers();
        alert('Xóa nhân viên kiểm soát thành công');
    } catch (error) {
        console.error('Error deleting controller:', error);
        alert('Có lỗi xảy ra khi xóa nhân viên kiểm soát');
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