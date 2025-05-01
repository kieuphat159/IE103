document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  fetchBookings();
  
  // Gọi lại khi nhấn tab "Thông tin đặt vé"
  const bookingTabButton = document.querySelector("button[onclick*='bookings']");
  if (bookingTabButton) {
    bookingTabButton.addEventListener("click", fetchBookings);
  }
});

function fetchBookings() {
  // Mock API response that matches the ThongTinDatVe class in the diagram
  const mockData = [
    {
      maDatVe: 'DV001',
      ngayDatVe: '10/04/2025',
      ngayBay: '15/04/2025',
      trangThaiThanhToan: 'Đã thanh toán',
      soGhe: 3,
      soTien: '3,500,000 VND'
    },
    {
      maDatVe: 'DV002',
      ngayDatVe: '11/04/2025',
      ngayBay: '20/04/2025',
      trangThaiThanhToan: 'Chưa thanh toán',
      soGhe: 2,
      soTien: '2,800,000 VND'
    }
  ];
  
  renderBookingTable(mockData);
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
        <td class="p-2">
          <button onclick="editItem('bookings', '${b.maDatVe}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
          <button onclick="deleteItem('bookings', '${b.maDatVe}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
        </td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}

// Implement methods from the class diagram
function themChongTinDatVe() {
  console.log("Thêm thông tin đặt vé");
  // Implementation for adding booking information
}

function capNhatThongTin() {
  console.log("Cập nhật thông tin đặt vé");
  // Implementation for updating booking information
}

function xoaDatVe() {
  console.log("Xóa thông tin đặt vé");
  // Implementation for deleting booking information
}