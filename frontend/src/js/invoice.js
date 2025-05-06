document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchInvoices();
    
    // Gọi lại khi nhấn tab "Hóa đơn"
    const invoiceTabButton = document.querySelector("button[onclick*='invoices']");
    if (invoiceTabButton) {
      invoiceTabButton.addEventListener("click", fetchInvoices);
    }
  });
  
  async function fetchInvoices() {
    // Mock API response that matches the HoaDon class in the diagram
    try {
      // Gửi yêu cầu GET tới API
      const response = await fetch('http://localhost:3000/api/invoices', {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      // Kiểm tra xem yêu cầu có thành công không
      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách hóa đơn');
      }

      // Lấy dữ liệu JSON từ response
      const invoices = await response.json();

      // Hiển thị dữ liệu lên bảng
      renderInvoiceTable(invoices);
    } catch (error) {
        console.error('Lỗi:', error);
        alert('Không thể tải danh sách hóa đơn. Vui lòng kiểm tra kết nối.');
    }
  }
  
  function renderInvoiceTable(invoices) {
    const tbody = document.getElementById("invoiceTable");
    tbody.innerHTML = "";
  
    invoices.forEach(i => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${i.maHD}</td>
          <td class="p-2">${i.ngayXuatHD}</td>
          <td class="p-2">${i.phuongThucTT}</td>
          <td class="p-2">${i.ngayThanhToan}</td>
          <td class="p-2">
            <div class="flex gap-2 max-w-xs">
              <button onclick="editItem('invoices', '${i.maHD}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
              <button onclick="deleteItem('invoices', '${i.maHD}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
            </div>
          </td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }
  
  // Implement methods from the class diagram
  function capNhatHD() {
    console.log("Cập nhật hóa đơn");
    // Implementation for updating invoice
  }
  
  function xuatHD() {
    console.log("Xuất hóa đơn");
    // Implementation for exporting invoice
  }

  function searchInvoice() {
    const searchInput = document.getElementById('searchInvoiceInput');
    const searchTerm = searchInput.value.toLowerCase();
    const tableBody = document.getElementById('invoiceTable');
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