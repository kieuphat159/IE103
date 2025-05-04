document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchFlights();
    
    // Gọi lại khi nhấn tab "Chuyến bay"
    const flightTabButton = document.querySelector("button[onclick*='flights']");
    if (flightTabButton) {
      flightTabButton.addEventListener("click", fetchFlights);
    }
  });
  
  async function fetchFlights() {
    try {
      // Gửi yêu cầu GET tới API
      const response = await fetch('http://localhost:3000/api/flights', {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      // Kiểm tra xem yêu cầu có thành công không
      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách chuyến bay');
      }

      // Lấy dữ liệu JSON từ response
      const flights = await response.json();

      // Hiển thị dữ liệu lên bảng
      renderFlightTable(flights);
    } catch (error) {
      console.error('Lỗi:', error);
      alert('Không thể tải danh sách chuyến bay. Vui lòng kiểm tra kết nối.');
    }
}
  
function renderFlightTable(flights) {
  const tbody = document.getElementById("flightTable");
  tbody.innerHTML = "";

  flights.forEach(f => {
    const row = `
      <tr class="border-t hover:bg-gray-100">
        <td class="p-2">${f.maChuyenBay}</td>
        <td class="p-2">${f.tinhTrangChuyenBay}</td>
        <td class="p-2">${f.gioBay}</td>
        <td class="p-2">${f.gioDen}</td>
        <td class="p-2">${f.diaDiemDau}</td>
        <td class="p-2">${f.diaDiemCuoi}</td>
        <td class="p-2">
          <div class="flex gap-2 max-w-xs">
            <button onclick="editItem('flights', '${f.maChuyenBay}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
            <button onclick="deleteItem('flights', '${f.maChuyenBay}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
            <button onclick="showSection('seats');fetchSeats();" class="bg-gray-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-teal-700 hover:shadow-md transition">Quản lý chỗ ngồi</button>
          </div>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}
  
  // Implement methods from the class diagram
  function capNhatSoGhe() {
    console.log("Cập nhật số ghế");
    // Implementation for updating seat count
  }
  
  function capNhatTinhTrang() {
    console.log("Cập nhật tình trạng chuyến bay");
    // Implementation for updating flight status
  }
  
  function capNhatGioBay() {
    console.log("Cập nhật giờ bay");
    // Implementation for updating flight time
  }