document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchFlights();
    
    // Gọi lại khi nhấn tab "Chuyến bay"
    const flightTabButton = document.querySelector("button[onclick*='flights']");
    if (flightTabButton) {
      flightTabButton.addEventListener("click", fetchFlights);
    }

    // Add event listener for enter key on search input
    const searchInput = document.getElementById('searchFlightInput');
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                searchFlight();
            }
        });
    }
  });
  
  async function fetchFlights() {
    try {
        console.log('Đang gửi yêu cầu GET /api/flights');
        const response = await fetch('http://localhost:3000/api/flights', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
  
        if (!response.ok) {
            throw new Error(`Lỗi khi lấy danh sách chuyến bay: ${response.status} ${response.statusText}`);
        }
  
        const flights = await response.json();
        console.log('Dữ liệu chuyến bay nhận được:', flights);
        renderFlightTable(flights);
        return flights;
    } catch (error) {
        console.error('Lỗi:', error);
        alert('Không thể tải danh sách chuyến bay. Vui lòng kiểm tra kết nối.');
        return [];
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
                        <button onclick="showSeatsSection('${f.maChuyenBay}')" class="bg-gray-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-teal-700 hover:shadow-md transition">Quản lý chỗ ngồi</button>
                    </div>
                </td>
            </tr>
        `;
        tbody.insertAdjacentHTML("beforeend", row);
    });
  }
  
  // Add new function to show seats section with flight code
  function showSeatsSection(flightCode) {
      showSection('seats');
      document.getElementById('flightCode').textContent = flightCode;
      fetchSeats();
  }
  
  // Hàm tạo mã chuyến bay ngẫu nhiên
  function generateMaChuyenBay() {
    const randomNum = Math.floor(100 + Math.random() * 900); // Số ngẫu nhiên 3 chữ số
    return `CB${randomNum}`;
  }
  
  // Hàm kiểm tra mã chuyến bay có trùng lặp không
  async function isMaChuyenBayUnique(maChuyenBay) {
    const flights = await fetchFlights();
    return !flights.some(flight => flight.maChuyenBay === maChuyenBay);
  }
  
  // Hàm lưu dữ liệu chuyến bay từ modal
  async function saveFlightData() {
    const maChuyenBay = document.getElementById("flightMaChuyenBay").value.trim();
    const tinhTrangChuyenBay = document.getElementById("flightTinhTrangChuyenBay").value;
    const gioBay = document.getElementById("flightGioBay").value;
    const gioDen = document.getElementById("flightGioDen").value;
    const diaDiemDau = document.getElementById("flightDiaDiemDau").value.trim();
    const diaDiemCuoi = document.getElementById("flightDiaDiemCuoi").value.trim();
  
    // Kiểm tra hợp lệ dữ liệu
    if (!maChuyenBay || !tinhTrangChuyenBay || !gioBay || !gioDen || !diaDiemDau || !diaDiemCuoi) {
        alert("Vui lòng điền đầy đủ các trường bắt buộc!");
        return;
    }
  
    // Kiểm tra định dạng mã chuyến bay (ví dụ: CBxxx)
    if (!/^CB\d{3}$/.test(maChuyenBay)) {
        alert("Mã chuyến bay phải có định dạng CBxxx (xxx là 3 chữ số)!");
        return;
    }
  
    // Kiểm tra mã chuyến bay có trùng lặp
    if (!(await isMaChuyenBayUnique(maChuyenBay))) {
        alert("Mã chuyến bay đã tồn tại!");
        return;
    }
  
    // Kiểm tra giờ đến phải sau giờ bay
    if (new Date(gioDen) <= new Date(gioBay)) {
        alert("Giờ đến phải sau giờ bay!");
        return;
    }
  
    // Kiểm tra địa điểm đầu và cuối không được trùng
    if (diaDiemDau === diaDiemCuoi) {
        alert("Địa điểm đầu và cuối không được trùng nhau!");
        return;
    }
  
    const flightData = {
        maChuyenBay,
        tinhTrangChuyenBay,
        gioBay,
        gioDen,
        diaDiemDau,
        diaDiemCuoi
    };
  
    try {
        console.log('Đang gửi yêu cầu POST /api/flights:', flightData);
        const response = await fetch('http://localhost:3000/api/flights', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(flightData)
        });
  
        const result = await response.json();
        console.log('Kết quả POST /api/flights:', result);
  
        if (!response.ok) {
            throw new Error(result.error || 'Lỗi khi thêm chuyến bay');
        }
  
        alert(result.message || 'Thêm chuyến bay thành công!');
        closeModal();
        fetchFlights();
    } catch (error) {
        console.error('Lỗi:', error);
        alert(`Không thể thêm chuyến bay: ${error.message}`);
    }
  }
  
  // Hàm tạo mã chuyến bay mới
  async function generateNewFlightCode() {
      let newCode;
      let isUnique = false;
      
      while (!isUnique) {
          newCode = generateMaChuyenBay();
          isUnique = await isMaChuyenBayUnique(newCode);
      }
      
      document.getElementById('flightMaChuyenBay').value = newCode;
  }
  
  // Hàm xóa chuyến bay
  async function deleteItem(section, id) {
      if (section === 'flights') {
          if (confirm(`Bạn có chắc chắn muốn xóa chuyến bay với ID: ${id}?`)) {
              try {
                  console.log(`Đang gửi yêu cầu DELETE /api/flights/${id}`);
                  const response = await fetch(`http://localhost:3000/api/flights/${id}`, {
                      method: 'DELETE',
                      headers: {
                          'Content-Type': 'application/json'
                      }
                  });
  
                  const data = await response.json();
                  console.log(`Kết quả DELETE /api/flights/${id}:`, data);
  
                  if (!response.ok) {
                      throw new Error(data.error || `Lỗi khi xóa chuyến bay: ${response.status} ${response.statusText}`);
                  }
  
                  alert(data.message || `Đã xóa chuyến bay với ID: ${id}`);
                  fetchFlights();
              } catch (error) {
                  console.error('Lỗi:', error);
                  alert(`Không thể xóa chuyến bay: ${error.message}`);
              }
          }
      }
  }
  
  // Ghi đè hàm saveData để xử lý lưu chuyến bay
  function saveData() {
      if (currentSection === 'flights') {
          saveFlightData();
      } else {
          alert('Dữ liệu đã được lưu thành công!');
          closeModal();
      }
  }

  function searchFlight() {
    const searchInput = document.getElementById('searchFlightInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('flightTable');
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