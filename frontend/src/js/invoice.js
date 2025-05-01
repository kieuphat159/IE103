document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    fetchInvoices();
    
    // Gọi lại khi nhấn tab "Hóa đơn"
    const invoiceTabButton = document.querySelector("button[onclick*='invoices']");
    if (invoiceTabButton) {
      invoiceTabButton.addEventListener("click", fetchInvoices);
    }
  });
  
  function fetchInvoices() {
    // Mock API response that matches the HoaDon class in the diagram
    const mockData = [
      {
        maHD: 'HD001',
        ngayXuatHD: '10/04/2025',
        phuongThucTT: 'Thẻ tín dụng',
        ngayThanhToan: '10/04/2025'
      },
      {
        maHD: 'HD002',
        ngayXuatHD: '11/04/2025',
        phuongThucTT: 'Chuyển khoản',
        ngayThanhToan: '12/04/2025'
      }
    ];
    
    renderInvoiceTable(mockData);
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
            <button onclick="editItem('invoices', '${i.maHD}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
            <button onclick="deleteItem('invoices', '${i.maHD}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
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