document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  fetchBookings();
  
  // Gọi lại khi nhấn tab "Thông tin đặt vé"
  const bookingTabButton = document.querySelector("button[onclick*='bookings']");
  if (bookingTabButton) {
    bookingTabButton.addEventListener("click", fetchBookings);
  }
});

async function fetchBookings() {
  try {
    // Gửi yêu cầu GET tới API
    const response = await fetch('http://localhost:3000/api/bookings', {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
        }
    });

    // Kiểm tra xem yêu cầu có thành công không
    if (!response.ok) {
        throw new Error('Lỗi khi lấy danh sách thông tin đặt vé');
    }

    // Lấy dữ liệu JSON từ response
    const bookings = await response.json();

    // Hiển thị dữ liệu lên bảng
    renderBookingTable(bookings);
  } catch (error) {
    console.error('Lỗi:', error);
    alert('Không thể tải danh sách thông tin đặt vé. Vui lòng kiểm tra kết nối.');
  }
}

function renderBookingTable(bookings) {
  const tbody = document.getElementById("bookingTable");
  tbody.innerHTML = "";

  bookings.forEach(b => {
    const row = `
      <tr class="border-t hover:bg-gray-100">
        <td class="p-2">${b.maDatVe}</td>
        <td class="p-2">${b.ngayDatVe}</td>
        <td class="p-2">${b.ngayBay}</td>
        <td class="p-2">${b.trangThaiThanhToan}</td>
        <td class="p-2">${b.soGhe}</td>
        <td class="p-2">${b.soTien}</td>
        <td class="p-2">
          <button onclick="editItem('bookings', '${b.maDatVe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
          <button onclick="deleteItem('bookings', '${b.maDatVe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}

// Implement methods from the class diagram
function themChongTinDatVe() {
  console.log("Thêm thông tin đặt vé");
  // Implementation for adding booking information
}

function capNhatThongTin() {
  console.log("Cập nhật thông tin đặt vé");
  // Implementation for updating booking information
}

function xoaDatVe() {
  console.log("Xóa thông tin đặt vé");
  // Implementation for deleting booking information
}