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
      const response = await fetch('http://localhost:3000/api/customers', {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách khách hàng');
      }

      const customers = await response.json();
      renderCustomerTable(customers);
      return customers; // Trả về danh sách khách hàng để sử dụng trong các hàm khác
  } catch (error) {
      console.error('Lỗi:', error);
      alert('Không thể tải danh sách khách hàng. Vui lòng kiểm tra kết nối.');
      return [];
  }
}

function renderCustomerTable(customers) {
  const tbody = document.getElementById("userTable");
  tbody.innerHTML = "";

  customers.forEach(c => {
    const ngaySinhFormatted = c.ngaySinh ? new Date(c.ngaySinh).toISOString().split('T')[0] : '';

    const row = `
      <tr class="border-t hover:bg-gray-100">
        <td class="p-2">${c.maKH}</td>
        <td class="p-2">${c.ten}</td>
        <td class="p-2">${c.taiKhoan}</td>
        <td class="p-2">${c.email}</td>
        <td class="p-2">${c.sdt}</td>
        <td class="p-2">${ngaySinhFormatted}</td>
        <td class="p-2">${c.gioiTinh}</td>
        <td class="p-2">${c.soCCCD}</td>
        <td class="p-2">
          <button onclick="editItem('users', '${c.maKH}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
          <button onclick="deleteItem('users', '${c.maKH}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}

// Hàm tạo mã khách hàng ngẫu nhiên
function generateMaKH() {
  const randomNum = Math.floor(100000 + Math.random() * 900000); // Số ngẫu nhiên 6 chữ số
  return `KH${randomNum}`;
}

// Hàm kiểm tra mã khách hàng có trùng lặp không
async function isMaKHUnique(maKH) {
  const customers = await fetchCustomers();
  return !customers.some(customer => customer.maKH === maKH);
}

// Hàm lưu dữ liệu khách hàng từ modal
async function saveCustomerData() {
  const ten = document.getElementById("userTen").value.trim();
  const taiKhoan = document.getElementById("userTaiKhoan").value.trim();
  const matKhau = document.getElementById("userMatKhau").value.trim();
  const email = document.getElementById("userEmail").value.trim();
  const sdt = document.getElementById("userSDT").value.trim();
  const ngaySinh = document.getElementById("userNgaySinh").value;
  const gioiTinh = document.getElementById("userGioiTinh").value;
  const soCCCD = document.getElementById("userCCCD").value.trim();
  const passport = document.getElementById("userPassport").value.trim();

  // Kiểm tra hợp lệ dữ liệu
  if (!ten || !taiKhoan || !matKhau || !email || !gioiTinh) {
    alert("Vui lòng điền đầy đủ các trường bắt buộc!");
    return;
  }

  // Kiểm tra định dạng email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    alert("Email không hợp lệ!");
    return;
  }

  // Kiểm tra định dạng số CCCD (ví dụ: 12 chữ số)
  if (soCCCD && !/^\d{12}$/.test(soCCCD)) {
    alert("Số CCCD phải có đúng 12 chữ số!");
    return;
  }

  // Kiểm tra định dạng số điện thoại (ví dụ: 10-11 chữ số)
  if (sdt && !/^\d{10,11}$/.test(sdt)) {
    alert("Số điện thoại phải có 10 hoặc 11 chữ số!");
    return;
  }

  // Kiểm tra giới tính
  if (!["Nam", "Nữ", "Khác"].includes(gioiTinh)) {
    alert("Giới tính không hợp lệ!");
    return;
  }

  // Tạo mã khách hàng ngẫu nhiên và kiểm tra không trùng lặp
  let maKH;
  let attempts = 0;
  const maxAttempts = 10;

  do {
    maKH = generateMaKH();
    attempts++;
    if (attempts > maxAttempts) {
      alert("Không thể tạo mã khách hàng duy nhất. Vui lòng thử lại sau.");
      return;
    }
  } while (!(await isMaKHUnique(maKH)));

  const customerData = {
    maKH,
    ten,
    taiKhoan,
    matKhau,
    email,
    sdt: sdt || null,
    ngaySinh: ngaySinh || null,
    gioiTinh,
    soCCCD: soCCCD || null,
    passport: passport || null
  };

  try {
    const response = await fetch('http://localhost:3000/api/customers', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(customerData)
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || 'Lỗi khi thêm khách hàng');
    }

    alert(result.message || 'Thêm khách hàng thành công!');
    closeModal();
    fetchCustomers(); // Cập nhật lại bảng
  } catch (error) {
    console.error('Lỗi:', error);
    alert(`Không thể thêm khách hàng: ${error.message}`);
  }
}

// Ghi đè hàm saveData trong script.js để xử lý lưu khách hàng
function saveData() {
  if (currentSection === 'users') {
    saveCustomerData();
  } else {
    alert('Dữ liệu đã được lưu thành công!');
    closeModal();
  }
}