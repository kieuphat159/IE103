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
        <td class="p-2">${b.maChuyenBay}</td>
        <td class="p-2">${b.maKH}</td>
        <td class="p-2">
          <div class="flex gap-2 max-w-xs">
            <button onclick="editBookingItem('bookings', '${b.maDatVe}', '${b.ngayDatVe}', '${b.ngayBay}', '${b.trangThaiThanhToan}', ${b.soGhe}, ${b.soTien}, '${b.maChuyenBay}', '${b.maKH}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
            <button onclick="xoaDatVe('${b.maDatVe}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
          </div>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}

async function editBookingItem(section, maDatVe, ngayDatVe, ngayBay, trangThaiThanhToan, soGhe, soTien, maChuyenBay, maKH) {
  if (section === 'bookings') {
    // Tạo modal HTML
    const modalHtml = `
      <div id="editBookingModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
          <h2 class="text-xl font-semibold mb-4">Sửa thông tin đặt vé</h2>
          <form id="editBookingForm">
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Mã đặt vé</label>
              <input type="text" id="editMaDatVe" value="${maDatVe}" class="mt-1 block w-full p-2 border rounded-md" readonly>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Ngày đặt vé</label>
              <input type="date" id="editNgayDatVe" value="${ngayDatVe.split('T')[0]}" class="mt-1 block w-full p-2 border rounded-md" required>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Ngày bay</label>
              <input type="date" id="editNgayBay" value="${ngayBay.split('T')[0]}" class="mt-1 block w-full p-2 border rounded-md" required>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Trạng thái thanh toán</label>
              <select id="editTrangThaiThanhToan" class="mt-1 block w-full p-2 border rounded-md" required>
                <option value="Chưa thanh toán" ${trangThaiThanhToan === 'Chưa thanh toán' ? 'selected' : ''}>Chưa thanh toán</option>
                <option value="Đã thanh toán" ${trangThaiThanhToan === 'Đã thanh toán' ? 'selected' : ''}>Đã thanh toán</option>
              </select>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Số ghế</label>
              <input type="number" id="editSoGhe" value="${soGhe}" class="mt-1 block w-full p-2 border rounded-md" min="1" required>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Số tiền</label>
              <input type="number" id="editSoTien" value="${soTien}" class="mt-1 block w-full p-2 border rounded-md" min="0" step="0.01" required>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Mã chuyến bay</label>
              <input type="text" id="editMaChuyenBay" value="${maChuyenBay}" class="mt-1 block w-full p-2 border rounded-md" required>
            </div>
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700">Mã khách hàng</label>
              <input type="text" id="editMaKH" value="${maKH}" class="mt-1 block w-full p-2 border rounded-md" required>
            </div>
            <div class="flex justify-end gap-2">
              <button type="button" onclick="closeEditBookingModal()" class="bg-gray-500 text-white px-4 py-2 rounded-md hover:bg-gray-600">Hủy</button>
              <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">Lưu</button>
            </div>
          </form>
        </div>
      </div>
    `;

    // Thêm modal vào body
    document.body.insertAdjacentHTML('beforeend', modalHtml);

    // Xử lý submit form
    const editForm = document.getElementById('editBookingForm');
    editForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const updatedBooking = {
        ngayDatVe: document.getElementById('editNgayDatVe').value,
        ngayBay: document.getElementById('editNgayBay').value,
        trangThaiThanhToan: document.getElementById('editTrangThaiThanhToan').value,
        soGhe: parseInt(document.getElementById('editSoGhe').value),
        soTien: parseFloat(document.getElementById('editSoTien').value),
        maChuyenBay: document.getElementById('editMaChuyenBay').value,
        maKH: document.getElementById('editMaKH').value
      };

      console.log('Dữ liệu gửi đi:', updatedBooking); // Log để kiểm tra

      try {
        const response = await fetch(`http://localhost:3000/api/bookings/${maDatVe}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(updatedBooking)
        });

        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || 'Lỗi khi cập nhật thông tin đặt vé');
        }

        alert(data.message || 'Cập nhật thông tin đặt vé thành công');
        closeEditBookingModal();
        fetchBookings();
      } catch (error) {
        console.error('Lỗi:', error);
        alert(`Không thể cập nhật thông tin đặt vé: ${error.message}`);
      }
    });
  }
}

function closeEditBookingModal() {
    const modal = document.getElementById('editBookingModal');
    if (modal) {
        modal.remove();
    }
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