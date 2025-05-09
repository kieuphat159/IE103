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

    // Thêm hàm này để đảm bảo saveFlightData được gọi khi nhấn nút lưu
    const saveButton = document.querySelector('button[onclick="saveData()"]');
    if (saveButton) {
        saveButton.addEventListener('click', () => {
            if (currentSection === 'flights') {
                saveFlightData();
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
  
  // Hàm mở modal thêm/sửa chuyến bay
  function openFlightModal(mode, flight = null) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    const modalContent = document.getElementById('modalContent');

    modalTitle.textContent = mode === 'add' ? 'Thêm chuyến bay' : 'Sửa chuyến bay';
    
    modalContent.innerHTML = `
        <form id="flightForm" class="space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700">Mã chuyến bay</label>
                <input type="text" id="flightMaChuyenBay" name="maChuyenBay" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${flight ? flight.maChuyenBay : ''}" ${mode === 'edit' ? 'readonly' : ''}>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Tình trạng chuyến bay</label>
                <select id="flightTinhTrangChuyenBay" name="tinhTrangChuyenBay" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3">
                    <option value="Chưa khởi hành" ${flight && flight.tinhTrangChuyenBay === 'Chưa khởi hành' ? 'selected' : ''}>Chưa khởi hành</option>
                    <option value="Đang bay" ${flight && flight.tinhTrangChuyenBay === 'Đang bay' ? 'selected' : ''}>Đang bay</option>
                    <option value="Đã hoàn thành" ${flight && flight.tinhTrangChuyenBay === 'Đã hoàn thành' ? 'selected' : ''}>Đã hoàn thành</option>
                    <option value="Đã hủy" ${flight && flight.tinhTrangChuyenBay === 'Đã hủy' ? 'selected' : ''}>Đã hủy</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Giờ bay</label>
                <input type="datetime-local" id="flightGioBay" name="gioBay" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${flight ? flight.gioBay : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Giờ đến</label>
                <input type="datetime-local" id="flightGioDen" name="gioDen" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${flight ? flight.gioDen : ''}">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Địa điểm đầu</label>
                <input type="text" id="flightDiaDiemDau" name="diaDiemDau" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${flight ? flight.diaDiemDau : ''}" placeholder="VD: Hà Nội">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Địa điểm cuối</label>
                <input type="text" id="flightDiaDiemCuoi" name="diaDiemCuoi" required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 h-10 px-3"
                    value="${flight ? flight.diaDiemCuoi : ''}" placeholder="VD: TP.HCM">
            </div>
        </form>
    `;

    modal.classList.remove('hidden');
    window.currentMode = mode;
    window.currentFlight = flight;

    if (mode === 'add') {
        generateNewFlightCode();
    }
}
  
  // Hàm tạo mã chuyến bay ngẫu nhiên
  function generateMaChuyenBay() {
    const randomNum = Math.floor(100 + Math.random() * 900);
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
  
    // Kiểm tra mã chuyến bay có trùng lặp (chỉ khi thêm mới)
    if (!window.currentFlight && !(await isMaChuyenBayUnique(maChuyenBay))) {
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
        const method = window.currentFlight ? 'PUT' : 'POST';
        const url = window.currentFlight 
            ? `http://localhost:3000/api/flights/${maChuyenBay}`
            : 'http://localhost:3000/api/flights';

        console.log(`Đang gửi yêu cầu ${method} ${url}:`, flightData);
        const response = await fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(flightData)
        });
  
        const result = await response.json();
        console.log(`Kết quả ${method} ${url}:`, result);
  
        if (!response.ok) {
            throw new Error(result.error || `Lỗi khi ${window.currentFlight ? 'cập nhật' : 'thêm'} chuyến bay`);
        }
  
        alert(result.message || `${window.currentFlight ? 'Cập nhật' : 'Thêm'} chuyến bay thành công!`);
        window.currentFlight = null; // Reset currentFlight sau khi lưu thành công
        closeModal();
        fetchFlights();
    } catch (error) {
        console.error('Lỗi:', error);
        alert(`Không thể ${window.currentFlight ? 'cập nhật' : 'thêm'} chuyến bay: ${error.message}`);
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
  async function editItem(section, id) {
    if (section === 'flights') {
        try {
            console.log(`Đang gửi yêu cầu GET /api/flights/${id}`);
            const response = await fetch(`http://localhost:3000/api/flights/${id}`);
            if (!response.ok) {
                throw new Error(`Lỗi khi lấy thông tin chuyến bay: ${response.status} ${response.statusText}`);
            }
            const flightData = await response.json();
            if (!flightData || (typeof flightData === 'object' && Object.keys(flightData).length === 0)) {
                throw new Error('Không tìm thấy chuyến bay với mã này');
            }
            // Kiểm tra và định dạng lại thời gian nếu cần
            const safeFlightData = {
                ...flightData,
                gioBay: flightData.gioBay ? new Date(flightData.gioBay).toISOString().slice(0, 16) : '',
                gioDen: flightData.gioDen ? new Date(flightData.gioDen).toISOString().slice(0, 16) : ''
            };
            window.currentFlight = safeFlightData;
            openFlightModal('edit', window.currentFlight);
        } catch (error) {
            console.error('Lỗi:', error);
            alert(`Không thể lấy thông tin chuyến bay để sửa: ${error.message}`);
        }
    }
}