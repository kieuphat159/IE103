document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchSeats();
    
    // Gọi lại khi nhấn tab "Vị trí ghế"
    const seatTabButton = document.querySelector("button[onclick*='seats']");
    if (seatTabButton) {
      seatTabButton.addEventListener("click", fetchSeats);
    }
  });
  
  function fetchSeats() {
    // Mock API response that matches the NhanVienKiemSoat class in the diagram
    const mockData = [
      {
        maGhe: 'G001',
        taiKhoan: 'seat001',
        matKhau: '********'
      },
      {
        maGhe: 'G002',
        taiKhoan: 'seat002',
        matKhau: '********'
      }
    ];
    
    renderSeatTable(mockData);
  }
  
  function renderSeatTable(seats) {
    const tbody = document.getElementById("seatTable");
    tbody.innerHTML = "";
  
    seats.forEach(s => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${s.maGhe}</td>
          <td class="p-2">${s.taiKhoan}</td>
          <td class="p-2">${s.matKhau}</td>
          <td class="p-2">
            <button onclick="editItem('seats', '${s.maGhe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
            <button onclick="deleteItem('seats', '${s.maGhe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
          </td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }
  
  // Implement methods from the class diagram
  function dangNhap() {
    console.log("Đăng nhập kiểm soát ghế");
    // Implementation for seat controller login
  }
  
  function dangXuat() {
    console.log("Đăng xuất kiểm soát ghế");
    // Implementation for seat controller logout
  }
  
  function themGhe() {
    console.log("Thêm ghế mới");
    // Implementation for adding a new seat
  }
  
  function themBaoCao() {
    console.log("Thêm báo cáo ghế");
    // Implementation for adding seat report
  }
  
  function xoaBaoCao() {
    console.log("Xóa báo cáo ghế");
    // Implementation for deleting seat report
  }
  
  function suaBaoCao() {
    console.log("Sửa báo cáo ghế");
    // Implementation for updating seat report
  }