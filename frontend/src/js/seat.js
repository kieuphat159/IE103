document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchSeats();
    
    // Gọi lại khi nhấn tab "Vị trí ghế"
    const seatTabButton = document.querySelector("button[onclick*='seats']");
    if (seatTabButton) {
      seatTabButton.addEventListener("click", fetchSeats);
    }
  });
  
  async function fetchSeats() {
    try {
      const flightCode = document.getElementById('flightCode').textContent;
      const url = flightCode ? `http://localhost:3000/api/seats?maChuyenBay=${flightCode}` : 'http://localhost:3000/api/seats';
      
      // Gửi yêu cầu GET tới API
      const response = await fetch(url, {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      // Kiểm tra xem yêu cầu có thành công không
      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách ghế');
      }

      // Lấy dữ liệu JSON từ response
      const seats = await response.json();

      // Hiển thị dữ liệu lên bảng
      renderSeatTable(seats);
    } catch (error) {
      console.error('Lỗi:', error);
      alert('Không thể tải danh sách ghế. Vui lòng kiểm tra kết nối.');
    }
  }
  
  function renderSeatTable(seats) {
    const tbody = document.getElementById("seatTable");
    tbody.innerHTML = "";
  
    seats.forEach(s => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${s.soGhe}</td>
          <td class="p-2">${s.giaGhe}</td>
          <td class="p-2">${s.hangGhe}</td>
          <td class="p-2">${s.tinhTrangGhe}</td>
          <td class="p-2">
            <div class="flex gap-2 max-w-xs">
              <button onclick="editSeatItem('seats', '${s.soGhe}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
              <button onclick="deleteSeatItem('seats', '${s.soGhe}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
            </div>
          </td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }
  
  async function deleteSeatItem(section, id) {
    const flightCode = document.getElementById('flightCode').textContent;
      if (section === 'seats') {
          if (confirm(`Bạn có chắc chắn muốn xóa chỗ ngồi với ID: ${id}?`)) {
              try {
                  console.log(`Đang gửi yêu cầu DELETE /api/seats/${id}/${flightCode}`);
                  const response = await fetch(`http://localhost:3000/api/seats/${id}/${flightCode}`, {
                      method: 'DELETE',
                      headers: {
                          'Content-Type': 'application/json'
                      }
                  });
  
                  const data = await response.json();
                  console.log(`Kết quả DELETE /api/seats/${id}:`, data);
  
                  if (!response.ok) {
                      throw new Error(data.error || `Lỗi khi xóa chỗ ngồi: ${response.status} ${response.statusText}`);
                  }
  
                  alert(data.message || `Đã xóa chỗ ngồi với ID: ${id}`);
                  fetchSeats();
              } catch (error) {
                  console.error('Lỗi:', error);
                  alert(`Không thể xóa chô ngồi: ${error.message}`);
              }
          }
      }
  }

  function editSeatItem(section, soGhe, maChuyenBay, giaGhe, hangGhe, tinhTrangGhe) {
    const flightCode = document.getElementById('flightCode').textContent;
    if (section === 'seats') {
        // Tạo modal HTML
        const modalHtml = `
            <div id="editSeatModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
                <div class="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
                    <h2 class="text-xl font-semibold mb-4">Sửa thông tin ghế</h2>
                    <form id="editSeatForm">
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Số ghế</label>
                            <input type="text" id="editSoGhe" value="${soGhe}" class="mt-1 block w-full p-2 border rounded-md" readonly>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Mã chuyến bay</label>
                            <input type="text" id="editMaChuyenBay" value="${flightCode}" class="mt-1 block w-full p-2 border rounded-md" readonly>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Giá ghế</label>
                            <input type="number" id="editGiaGhe" value="${giaGhe}" class="mt-1 block w-full p-2 border rounded-md" required step="0.01">
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Hạng ghế</label>
                            <select id="editHangGhe" class="mt-1 block w-full p-2 border rounded-md" required>
                                <option value="Phổ thông" ${hangGhe === 'Phổ thông' ? 'selected' : ''}>Phổ thông</option>
                                <option value="Thương gia" ${hangGhe === 'Thương gia' ? 'selected' : ''}>Thương gia</option>
                                <option value="Hạng nhất" ${hangGhe === 'Hạng nhất' ? 'selected' : ''}>Hạng nhất</option>
                            </select>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Tình trạng ghế</label>
                            <select id="editTinhTrangGhe" class="mt-1 block w-full p-2 border rounded-md" required>
                                <option value="có sẵn" ${tinhTrangGhe === 'có sẵn' ? 'selected' : ''}>Có sẵn</option>
                                <option value="đã đặt" ${tinhTrangGhe === 'đã đặt' ? 'selected' : ''}>Đã đặt</option>
                            </select>
                        </div>
                        <div class="flex justify-end gap-2">
                            <button type="button" onclick="closeEditModal()" class="bg-gray-500 text-white px-4 py-2 rounded-md hover:bg-gray-600">Hủy</button>
                            <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">Lưu</button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        // Thêm modal vào body
        document.body.insertAdjacentHTML('beforeend', modalHtml);

        // Xử lý submit form
        const editForm = document.getElementById('editSeatForm');
        editForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const updatedSeat = {
                giaGhe: parseFloat(document.getElementById('editGiaGhe').value),
                hangGhe: document.getElementById('editHangGhe').value,
                tinhTrangGhe: document.getElementById('editTinhTrangGhe').value
            };

            try {
                const response = await fetch(`http://localhost:3000/api/seats/${soGhe}/${flightCode}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(updatedSeat)
                });

                const data = await response.json();

                if (!response.ok) {
                    throw new Error(data.error || 'Lỗi khi cập nhật ghế');
                }

                alert(data.message || 'Cập nhật ghế thành công');
                closeEditModal();
                fetchSeats();
            } catch (error) {
                console.error('Lỗi:', error);
                alert(`Không thể cập nhật ghế: ${error.message}`);
            }
        });
    }
}

function closeEditModal() {
    const modal = document.getElementById('editSeatModal');
    if (modal) {
        modal.remove();
    }
}

  function searchSeat() {
    const searchInput = document.getElementById('searchSeatInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('seatTable');
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
