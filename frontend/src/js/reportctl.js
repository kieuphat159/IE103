document.addEventListener("DOMContentLoaded", () => {
    fetchReports('unprocessed');

    // Gọi lại khi nhấn tab "Báo cáo"
    const reportTabButton = document.querySelector("button[onclick*='reports']");
    if (reportTabButton) {
        reportTabButton.addEventListener("click", () => fetchReports('unprocessed'));
    }
});

function generateMaBaoCao() {
    const randomNum = Math.floor(100 + Math.random() * 900); // VD: BC123
    return `BC${randomNum}`;
}
async function isMaBaoCaoUnique(maBaoCao) {
    const response = await fetch('http://localhost:3000/api/reports/full');
    const reports = await response.json();
    return !reports.some(report => report.maBaoCao === maBaoCao);
}
async function generateNewReportCode() {
    let newCode;
    let isUnique = false;

    while (!isUnique) {
        newCode = generateMaBaoCao();
        isUnique = await isMaBaoCaoUnique(newCode);
    }

    document.getElementById('generatedMaBaoCao').value = newCode;
}


async function fetchReports() {
    try {
        const response = await fetch('http://localhost:3000/api/reports/full');
        const reports = await response.json();
        renderReportTable(reports); // Gọi 1 lần duy nhất
    } catch (error) {
        console.error('Lỗi khi fetch báo cáo:', error);
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
                <td class="p-2">${new Date(r.ngayBaoCao).toLocaleString()}</td>
                <td class="p-2">${r.noiDungBaoCao}</td>
                <td class="p-2">${r.trangThai}</td>
            </tr>
        `;
        tbody.insertAdjacentHTML("beforeend", row);
    });
}

async function saveReportData() {
    const maBaoCao = document.getElementById("generatedMaBaoCao").value.trim();
    const maNV = document.getElementById("reportMaNV").value.trim();
    const ngayBaoCao = document.getElementById("reportNgayBaoCao").value;
    const noiDungBaoCao = document.getElementById("reportNoiDung").value.trim();

    if (!maBaoCao || !maNV || !ngayBaoCao || !noiDungBaoCao) {
        alert("Vui lòng điền đầy đủ thông tin báo cáo.");
        return;
    }

    const reportData = {
        maBaoCao,
        maNV,
        ngayBaoCao,
        noiDungBaoCao,
        trangThai: "Chưa xử lý"
    };

    try {
        const response = await fetch('http://localhost:3000/api/reports', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(reportData)
        });

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.error || "Lỗi khi thêm báo cáo.");
        }

        alert("Đã thêm báo cáo thành công!");
        closeModal();           // Đóng modal
        fetchReports();         // Refresh bảng
    } catch (error) {
        console.error("Lỗi khi thêm báo cáo:", error);
        alert("Không thể thêm báo cáo.");
    }
}
function saveData() {
    if (currentSection === 'reports') {
        saveReportData();
    } else {
        alert("Dữ liệu đã được lưu!");
        closeModal();
    }
}
