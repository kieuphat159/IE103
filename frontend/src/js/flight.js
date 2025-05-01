document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchFlights();
    
    // Gọi lại khi nhấn tab "Chuyến bay"
    const flightTabButton = document.querySelector("button[onclick*='flights']");
    if (flightTabButton) {
      flightTabButton.addEventListener("click", fetchFlights);
    }
  });
  
  function fetchFlights() {
    // Mock API response that matches the ChuyenBay class in the diagram
    const mockData = [
      {
        maChuyenBay: 'CB001',
        thoiGianChuyenBay: '2 giờ 30 phút',
        soGhe: 150,
        giaBay: '1,500,000 VND',
        diemDi: 'Hà Nội',
        diemDen: 'Hồ Chí Minh',
        thoiGian: '08:00 15/04/2025'
      },
      {
        maChuyenBay: 'CB002',
        thoiGianChuyenBay: '1 giờ 45 phút',
        soGhe: 120,
        giaBay: '1,200,000 VND',
        diemDi: 'Hồ Chí Minh',
        diemDen: 'Đà Nẵng',
        thoiGian: '10:30 16/04/2025'
      }
    ];
    
    renderFlightTable(mockData);
  }
  
  function renderFlightTable(flights) {
    const tbody = document.getElementById("flightTable");
    tbody.innerHTML = "";
  
    flights.forEach(f => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${f.maChuyenBay}</td>
          <td class="p-2">${f.thoiGianChuyenBay}</td>
          <td class="p-2">${f.soGhe}</td>
          <td class="p-2">${f.giaBay}</td>
          <td class="p-2">${f.diemDi}</td>
          <td class="p-2">${f.diemDen}</td>
          <td class="p-2">${f.thoiGian}</td>
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