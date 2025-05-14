document.addEventListener("DOMContentLoaded", () => {
    fetchReports('unprocessed');
    
    // Gọi lại khi nhấn tab "Báo cáo"
    const reportTabButton = document.querySelector("button[onclick*='reports']");
    if (reportTabButton) {
      reportTabButton.addEventListener("click", () => fetchReports('unprocessed'));
    }
});

function showReportTab(tab) {
    const unprocessedTab = document.getElementById('unprocessedReports');
    const processedTab = document.getElementById('processedReports');
    const unprocessedButton = document.querySelector("button[onclick=\"showReportTab('unprocessed')\"]");
    const processedButton = document.querySelector("button[onclick=\"showReportTab('processed')\"]");

    if (tab === 'unprocessed') {
        unprocessedTab.classList.remove('hidden');
        processedTab.classList.add('hidden');
        unprocessedButton.classList.add('bg-gray-700');
        processedButton.classList.remove('bg-gray-700');
        fetchReports('unprocessed');
    } else {
        unprocessedTab.classList.add('hidden');
        processedTab.classList.remove('hidden');
        unprocessedButton.classList.remove('bg-gray-700');
        processedButton.classList.add('bg-gray-700');
        fetchReports('processed');
    }
}

async function fetchReports(status) {
    try {
        const trangThai = status === 'unprocessed' ? 'Chưa xử lý' : 'Đã xử lý';
        const response = await fetch(`http://localhost:3000/api/reports?trangThai=${encodeURIComponent(trangThai)}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Lỗi khi lấy danh sách báo cáo');
        }

        const reports = await response.json();
        renderReportTable(reports, status);
    } catch (error) {
        console.error('Lỗi:', error);
        // alert('Không thể tải danh sách báo cáo. Vui lòng kiểm tra kết nối.');
    }
}

function renderReportTable(reports, status) {
    const tbody = document.getElementById(`${status}ReportTable`);
    tbody.innerHTML = "";

    reports.forEach(r => {
        const row = `
            <tr class="border-t hover:bg-gray-100">
                <td class="p-2">${r.maBaoCao}</td>
                <td class="p-2">${r.maNV}</td>
                <td class="p-2">${r.ngayBaoCao}</td>
                <td class="p-2">${r.noiDungBaoCao}</td>
                ${status === 'unprocessed' ? `
                    <td class="p-2">
                        <div class="flex gap-2 max-w-xs">
                            <button onclick="markAsProcessed('${r.maBaoCao}')" class="bg-green-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-teal-700 hover:shadow-md transition">Đánh dấu đã xử lý</button>
                            <button onclick="deleteItem('reports', '${r.maBaoCao}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
                        </div>
                    </td>
                ` : `
                    <td class="p-2">
                        <div class="flex gap-2 max-w-xs">
                           <button onclick="markAsUnprocessed('${r.maBaoCao}')" class="bg-green-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-teal-700 hover:shadow-md transition">Đánh dấu chưa xử lý</button>
                            <button onclick="deleteItem('reports', '${r.maBaoCao}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
                        </div>
                    </td>
                `}
            </tr>
        `;
        tbody.insertAdjacentHTML("beforeend", row);
    });
}

async function markAsProcessed(maBaoCao) {
    try {
        console.log('Đang cập nhật trạng thái báo cáo:', maBaoCao);
        const response = await fetch(`http://localhost:3000/api/reports/${maBaoCao}/status`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify({ trangThai: 'Đã xử lý' })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi khi cập nhật trạng thái báo cáo');
        }

        const data = await response.json();
        console.log('Cập nhật trạng thái thành công:', data);
        alert('Đã đánh dấu báo cáo là đã xử lý');
        fetchReports('processed');
        fetchReports('unprocessed');
    } catch (error) {
        console.error('Lỗi khi cập nhật trạng thái:', error);
        alert(error.message || 'Không thể cập nhật trạng thái báo cáo. Vui lòng thử lại.');
    }
}

async function markAsUnprocessed(maBaoCao) {
    try {
        console.log('Đang cập nhật trạng thái báo cáo:', maBaoCao);
        const response = await fetch(`http://localhost:3000/api/reports/${maBaoCao}/status1`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify({ trangThai: 'Chưa xử lý' })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Lỗi khi cập nhật trạng thái báo cáo');
        }

        const data = await response.json();
        console.log('Cập nhật trạng thái thành công:', data);
        alert('Đã đánh dấu báo cáo là chưa xử lý');
        fetchReports('processed');
        fetchReports('unprocessed');
    } catch (error) {
        console.error('Lỗi khi cập nhật trạng thái:', error);
        alert(error.message || 'Không thể cập nhật trạng thái báo cáo. Vui lòng thử lại.');
    }
}

function searchReport() {
    const searchInput = document.getElementById('searchReportInput');
    const searchTerm = searchInput.value.toLowerCase();
    
    // Search in both processed and unprocessed tables
    const unprocessedTableBody = document.getElementById('unprocessedReportTable');
    const processedTableBody = document.getElementById('processedReportTable');
    
    if (unprocessedTableBody) {
        const unprocessedRows = unprocessedTableBody.getElementsByTagName('tr');
        searchInTable(unprocessedRows, searchTerm);
    }
    
    if (processedTableBody) {
        const processedRows = processedTableBody.getElementsByTagName('tr');
        searchInTable(processedRows, searchTerm);
    }
}

function searchInTable(rows, searchTerm) {
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