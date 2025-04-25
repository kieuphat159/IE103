let currentSection = '';

function showSection(sectionId) {
    document.querySelectorAll('.section').forEach(section => section.classList.add('hidden'));
    document.getElementById(sectionId).classList.remove('hidden');
    currentSection = sectionId;
    populateTable(sectionId);
}

function openModal(modalType) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    const modalContent = document.getElementById('modalContent');
    modal.classList.remove('hidden');

    if (modalType === 'userModal') {
        modalTitle.textContent = 'Thêm khách hàng';
        modalContent.innerHTML = `
            <label class="block mb-2">Tên khách hàng</label>
            <input id="userTen" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Hộ chiếu</label>
            <input id="userPassport" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Email</label>
            <input id="userEmail" type="email" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Ngày sinh</label>
            <input id="userNgaySinh" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Căn cước công dân</label>
            <input id="userSoCCCD" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Số điện thoại</label>
            <input id="phoneNumber" type="text" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'invoiceModal') {
        modalTitle.textContent = 'Thêm hóa đơn';
        modalContent.innerHTML = `
            <label class="block mb-2">Ngày hóa đơn</label>
            <input id="invoiceDate" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Thời gian thanh toán</label>
            <input id="payTime" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Tên khách hàng</label>
            <input id="userTen" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Tổng tiền thanh toán</label>
            <input id="totalPayment" type="text" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'flightModal') {
        modalTitle.textContent = 'Thêm chuyến bay';
        modalContent.innerHTML = `
            <label class="block mb-2">Ngày bay</label>
            <input id="flightDate" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Thời gian khởi hành</label>
            <input id="flyTime" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Thời gian bay</label>
            <input id="totalTime" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Vị trí ngồi</label>
            <input id="totalPayment" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Loại máy bay</label>
            <select id="planType" class="w-full p-2 border rounded mb-4">
                <option value="" disabled selected>Chọn loại máy bay</option>
                <option value="Airbus A320">Airbus A320</option>
                <option value="Boeing 737">Boeing 737</option>
                <option value="Airbus A350">Airbus A350</option>
                <option value="Boeing 787">Boeing 787</option>
            </select>
        `;
    }
}

function closeModal() {
    document.getElementById('modal').classList.add('hidden');
}

function saveData() {
    closeModal();
}

function populateTable(sectionId) {
    console.log('Populating table for section:', sectionId);
    const tableBody = document.getElementById(`${sectionId}Table`);
    console.log('Table body element:', tableBody);
    
    tableBody.innerHTML = '';
    
    if (sectionId === 'users') {
        
        console.log('Sample data:', sampleData);
        
        sampleData.forEach(data => {
            console.log('Creating row for:', data);
            const row = document.createElement('tr');
            row.innerHTML = `
                <td class="p-2">${data.maKH}</td>
                <td class="p-2">${data.tenKH}</td>
                <td class="p-2">${data.email}</td>
                <td class="p-2">${data.sdt}</td>
                <td class="p-2">${data.hoChieu}</td>
            `;
            tableBody.appendChild(row);
        });
        
        // console.log('Table after population:', tableBody.innerHTML);
    } else if (sectionId === 'bookings') {
        
        console.log('Sample data:', sampleData);
        
        sampleData.forEach(data => {
            console.log('Creating row for:', data);
            const row = document.createElement('tr');
            row.innerHTML = `
                <td class="p-2">${data.maDatVe}</td>
                <td class="p-2">${data.ngayDatVe}</td>
                <td class="p-2">${data.ngayBay}</td>
                <td class="p-2">${data.trangThaiThanhToan}</td>
                <td class="p-2">${data.tongSoTien}</td>
            `;
            tableBody.appendChild(row);
        });
        
        // console.log('Table after population:', tableBody.innerHTML);
    }
}

function editUser(ten) {
    // Placeholder for edit functionality
    alert(`Editing user: ${ten}`);
}

function deleteUser(ten) {
    // Placeholder for delete functionality
    alert(`Deleting user: ${ten}`);
}
