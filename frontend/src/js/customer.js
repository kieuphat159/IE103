document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  fetchCustomers();
  
  // Gọi lại khi nhấn tab "Khách hàng"
  const customerTabButton = document.querySelector("button[onclick*='users']");
  if (customerTabButton) {
    customerTabButton.addEventListener("click", fetchCustomers);
  }
});

function fetchCustomers() {
  // Mock API response that matches the KhachHang class in the diagram
  const mockData = [
    {
      maKH: 'KH001',
      ten: 'Nguyễn Văn A',
      taiKhoan: 'nguyenvana',
      email: 'nguyenvana@example.com',
      sdt: '0123456789',
      ngaySinh: '01/01/1990',
      gioiTinh: 'Nam',
      cccd: '123456789012'
    },
    {
      maKH: 'KH002',
      ten: 'Trần Thị B',
      taiKhoan: 'tranthib',
      email: 'tranthib@example.com',
      sdt: '0987654321',
      ngaySinh: '15/05/1995',
      gioiTinh: 'Nữ',
      cccd: '098765432109'
    }
  ];
  
  renderCustomerTable(mockData);
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