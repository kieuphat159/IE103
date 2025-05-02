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
            <button onclick="editItem('flights', '${f.maChuyenBay}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
            <button onclick="deleteItem('flights', '${f.maChuyenBay}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
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