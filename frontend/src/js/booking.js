document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchBookings();
    
    // Gọi lại khi nhấn tab "Khách hàng"
    const bookingTabButton = document.querySelector("button[onclick*='bookings']");
    if (bookingTabButton) {
      bookingTabButton.addEventListener("click", fetchBookings);
    }
  });
  
  function fetchBookings() {
    // Mock API response
    const mockData = [
      {
        id: 'DV001',
        bookingDate: '10/04/2025',
        flightDate: '12/04/2025',
        payStatus: 'Đã thanh toán',
        totalPrice: '1.250.000đ'
      }
    ];
    
    renderBookingTable(mockData);
  }
  
  function renderBookingTable(bookings) {
    const tbody = document.getElementById("bookingTable");
    tbody.innerHTML = "";
  
    bookings.forEach(c => {
      const row = `
        <tr class="border-t">
          <td class="p-2">${c.id}</td>
          <td class="p-2">${c.bookingDate}</td>
          <td class="p-2">${c.flightDate}</td>
          <td class="p-2">${c.payStatus}</td>
          <td class="p-2">${c.totalPrice}</td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }