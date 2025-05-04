document.addEventListener("DOMContentLoaded", () => {
    // Load dữ liệu ngay khi trang được tải
    //fetchReports();
    
    // Gọi lại khi nhấn tab "Báo cáo"
    const reportTabButton = document.querySelector("button[onclick*='reports']");
    if (reportTabButton) {
      reportTabButton.addEventListener("click", fetchReports);
    }
  });
  
  function fetchReports() {
    // Mock API response that matches the BaoCao class in the diagram
    const mockData = [
      {
        maBaoCao: 'BC001',
        ngayBaoCao: '12/04/2025',
        noiDungBaoCao: 'Khách hàng Joe không mang hộ chiếu'
      },
      {
        maBaoCao: 'BC002',
        ngayBaoCao: '14/04/2025',
        noiDungBaoCao: 'Khách hàng John cần thay đổi giờ bay'
      }
    ];
    
    renderReportTable(mockData);
  }
  
  function renderReportTable(reports) {
    const tbody = document.getElementById("reportTable");
    tbody.innerHTML = "";
  
    reports.forEach(r => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${r.maBaoCao}</td>
          <td class="p-2">${r.ngayBaoCao}</td>
          <td class="p-2">${r.noiDungBaoCao}</td>
          <td class="p-2">
            <button onclick="editItem('reports', '${r.maBaoCao}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
            <button onclick="deleteItem('reports', '${r.maBaoCao}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
          </td>
        </tr>
      `;
      tbody.insertAdjacentHTML("beforeend", row);
    });
  }