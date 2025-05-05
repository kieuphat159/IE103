document.addEventListener("DOMContentLoaded", () => {
    //fetchReports();
    
    // Gọi lại khi nhấn tab "Báo cáo"
    const reportTabButton = document.querySelector("button[onclick*='reports']");
    if (reportTabButton) {
      reportTabButton.addEventListener("click", fetchReports);
    }
  });
  
  async function fetchReports() {
    try {
      // Gửi yêu cầu GET tới API
      const response = await fetch('http://localhost:3000/api/reports', {
          method: 'GET',
          headers: {
              'Content-Type': 'application/json'
          }
      });

      // Kiểm tra xem yêu cầu có thành công không
      if (!response.ok) {
          throw new Error('Lỗi khi lấy danh sách báo cáo');
      }

      // Lấy dữ liệu JSON từ response
      const reports = await response.json();

      // Hiển thị dữ liệu lên bảng
      renderReportTable(reports);
    } catch (error) {
        console.error('Lỗi:', error);
        alert('Không thể tải danh sách báo cáo. Vui lòng kiểm tra kết nối.');
    }
  }
  
  function renderReportTable(reports) {
    const tbody = document.getElementById("reportTable");
    tbody.innerHTML = "";
  
    reports.forEach(r => {
      const row = `
        <tr class="border-t hover:bg-gray-100">
          <td class="p-2">${r.maBaoCao}</td>
          <td class="p-2">${r.maNV}</td>
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