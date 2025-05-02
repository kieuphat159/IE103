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
      // Gửi yêu cầu GET tới API
      const response = await fetch('http://localhost:3000/api/seats', {
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
            <button onclick="editItem('seats', '${s.maGhe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
            <button onclick="deleteItem('seats', '${s.maGhe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
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
