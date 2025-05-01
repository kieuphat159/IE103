document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  fetchCustomers();
  
  // Gọi lại khi nhấn tab "Khách hàng"
  const customerTabButton = document.querySelector("button[onclick*='users']");
  if (customerTabButton) {
    customerTabButton.addEventListener("click", fetchCustomers);
  }
});

async function fetchCustomers() {
  try {
      // Gửi yêu cầu GET tới API
      const response = await fetch('http://localhost:3000/api/customers', {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      // Kiểm tra xem yêu cầu có thành công không
      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách khách hàng');
      }

      // Lấy dữ liệu JSON từ response
      const customers = await response.json();

      // Hiển thị dữ liệu lên bảng
      renderCustomerTable(customers);
  } catch (error) {
      console.error('Lỗi:', error);
      alert('Không thể tải danh sách khách hàng. Vui lòng kiểm tra kết nối.');
  }
}

function renderCustomerTable(customers) {
  const tbody = document.getElementById("userTable");
  tbody.innerHTML = "";

  customers.forEach(c => {
    const row = `
      <tr class="border-t hover:bg-gray-100">
        <td class="p-2">${c.maKH}</td>
        <td class="p-2">${c.ten}</td>
        <td class="p-2">${c.taiKhoan}</td>
        <td class="p-2">${c.email}</td>
        <td class="p-2">${c.sdt}</td>
        <td class="p-2">${c.ngaySinh}</td>
        <td class="p-2">${c.gioiTinh}</td>
        <td class="p-2">${c.cccd}</td>
        <td class="p-2">
          <button onclick="editItem('users', '${c.maKH}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
          <button onclick="deleteItem('users', '${c.maKH}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}

// Implement methods from the class diagram
function dangKy(kh) {
  console.log("Đăng ký khách hàng mới:", kh);
  // Implementation for user registration
}

function dangNhap() {
  console.log("Đăng nhập");
  // Implementation for user login
}

function dangXuat() {
  console.log("Đăng xuất");
  // Implementation for user logout
}

function themThongTin() {
  console.log("Thêm thông tin khách hàng");
  // Implementation for adding user information
}

function xoaThongTin() {
  console.log("Xóa thông tin khách hàng");
  // Implementation for deleting user information
}