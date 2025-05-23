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
    try {
        const response = await fetch('http://localhost:3000/api/invoices', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Lỗi khi lấy danh sách hóa đơn');
        }

        const invoices = await response.json();
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
                        <button onclick="editInvoiceItem('invoices', '${i.maHD}', '${i.ngayXuatHD}', '${i.phuongThucTT}', '${i.ngayThanhToan}')" class="bg-indigo-600 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-indigo-700 hover:shadow-md transition">Sửa</button>
                        <button onclick="deleteItem('invoices', '${i.maHD}')" class="bg-red-500 text-white px-3 py-1 rounded-md text-sm shadow-sm hover:bg-rose-700 hover:shadow-md transition">Xóa</button>
                    </div>
                </td>
            </tr>
        `;
        tbody.insertAdjacentHTML("beforeend", row);
    });
}

function editInvoiceItem(section, maHD, ngayXuatHD, phuongThucTT, ngayThanhToan) {
    if (section === 'invoices') {
        // Tạo modal HTML
        const modalHtml = `
            <div id="editInvoiceModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
                <div class="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
                    <h2 class="text-xl font-semibold mb-4">Sửa thông tin hóa đơn</h2>
                    <form id="editInvoiceForm">
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Mã hóa đơn</label>
                            <input type="text" id="editMaHD" value="${maHD}" class="mt-1 block w-full p-2 border rounded-md" readonly>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Ngày xuất hóa đơn</label>
                            <input type="date" id="editNgayXuatHD" value="${ngayXuatHD.split('T')[0]}" class="mt-1 block w-full p-2 border rounded-md" required>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Phương thức thanh toán</label>
                            <select id="editPhuongThucTT" class="mt-1 block w-full p-2 border rounded-md" required>
                                <option value="Tiền mặt" ${phuongThucTT === 'Tiền mặt' ? 'selected' : ''}>Tiền mặt</option>
                                <option value="Thẻ tín dụng" ${phuongThucTT === 'Thẻ tín dụng' ? 'selected' : ''}>Thẻ tín dụng</option>
                                <option value="Chuyển khoản" ${phuongThucTT === 'Chuyển khoản' ? 'selected' : ''}>Chuyển khoản</option>
                            </select>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700">Ngày thanh toán</label>
                            <input type="date" id="editNgayThanhToan" value="${ngayThanhToan.split('T')[0]}" class="mt-1 block w-full p-2 border rounded-md" required>
                        </div>
                        <div class="flex justify-end gap-2">
                            <button type="button" onclick="closeEditModal()" class="bg-gray-500 text-white px-4 py-2 rounded-md hover:bg-gray-600">Hủy</button>
                            <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">Lưu</button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        // Thêm modal vào body
        document.body.insertAdjacentHTML('beforeend', modalHtml);

        // Xử lý submit form
        const editForm = document.getElementById('editInvoiceForm');
        editForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const updatedInvoice = {
                ngayXuatHD: document.getElementById('editNgayXuatHD').value,
                phuongThucTT: document.getElementById('editPhuongThucTT').value,
                ngayThanhToan: document.getElementById('editNgayThanhToan').value
            };

            console.log('Dữ liệu gửi đi:', updatedInvoice); // Log để kiểm tra

            try {
                const response = await fetch(`http://localhost:3000/api/invoices/${maHD}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(updatedInvoice)
                });

                const data = await response.json();

                if (!response.ok) {
                    throw new Error(data.error || 'Lỗi khi cập nhật hóa đơn');
                }

                alert(data.message || 'Cập nhật hóa đơn thành công');
                closeEditModal();
                fetchInvoices();
            } catch (error) {
                console.error('Lỗi:', error);
                alert(`Không thể cập nhật hóa đơn: ${error.message}`);
            }
        });
    }
}

function closeEditModal() {
    const modal = document.getElementById('editInvoiceModal');
    if (modal) {
        modal.remove();
    }
    const modal2 = document.getElementById('editSeatModal');
    if (modal2) {
        modal2.remove();
    }
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