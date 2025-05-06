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
        alert('Không thể tải danh sách báo cáo. Vui lòng kiểm tra kết nối.');
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
                        <button onclick="editItem('reports', '${r.maBaoCao}')" class="bg-blue-500 text-white px-2 py-1 rounded mr-1">Sửa</button>
                        <button onclick="markAsProcessed('${r.maBaoCao}')" class="bg-green-500 text-white px-2 py-1 rounded mr-1">Đánh dấu đã xử lý</button>
                        <button onclick="deleteItem('reports', '${r.maBaoCao}')" class="bg-red-500 text-white px-2 py-1 rounded">Xóa</button>
                    </td>
                ` : `
                    <td class="p-2">${r.trangThai}</td>
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
        fetchReports('unprocessed');
    } catch (error) {
        console.error('Lỗi khi cập nhật trạng thái:', error);
        alert(error.message || 'Không thể cập nhật trạng thái báo cáo. Vui lòng thử lại.');
    }
}