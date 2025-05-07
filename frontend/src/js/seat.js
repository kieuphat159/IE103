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
              <button onclick="editItem('seats', '${s.soGhe}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
              <button onclick="deleteItem('seats', '${s.soGhe}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
            </div>
          </td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }
  
  function themGhe() {
    console.log("Thêm ghế mới");
    // Implementation for adding a new seat
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
