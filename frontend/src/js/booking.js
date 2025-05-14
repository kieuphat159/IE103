document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  // fetchBookings();
  
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
          <div class="flex gap-2 max-w-xs">
            <button onclick="editItem('bookings', '${b.maDatVe}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
            <button onclick="xoaDatVe('${b.maDatVe}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
          </div>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}


function capNhatThongTin() {
  console.log("Cập nhật thông tin đặt vé");
  // Implementation for updating booking information
}

async function xoaDatVe(maDatVe) {
  if (confirm(`Bạn có chắc chắn muốn xóa đặt vé với mã ${maDatVe}?`)) {
    try {
      const response = await fetch(`http://localhost:3000/api/bookings/${maDatVe}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || 'Lỗi khi xóa đặt vé');
      }

      alert(data.message || `Đã xóa đặt vé với mã ${maDatVe}`);
      fetchBookings(); // Refresh the booking table
    } catch (error) {
      console.error('Lỗi:', error);
      alert(`Không thể xóa đặt vé: ${error.message}`);
    }
  }
}


function searchBooking() {
    const searchInput = document.getElementById('searchBookingInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('bookingTable');
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