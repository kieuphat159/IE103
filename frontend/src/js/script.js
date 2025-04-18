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
        modalTitle.textContent = 'Add User';
        modalContent.innerHTML = `
            <label class="block mb-2">Username</label>
            <input id="userTen" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Full Name</label>
            <input id="userTaiKhoan" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Email</label>
            <input id="userEmail" type="email" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Birthday</label>
            <input id="userNgaySinh" type="date" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">ID Number</label>
            <input id="userSoCCCD" type="text" class="w-full p-2 border rounded mb-4">
        `;
    } else if (modalType === 'customerModal') {
        modalTitle.textContent = 'Add Customer';
        modalContent.innerHTML = `
            <label class="block mb-2">Customer ID</label>
            <input id="customerMaKH" type="text" class="w-full p-2 border rounded mb-4">
            <label class="block mb-2">Password</label>
            <input id="customerPass" type="password" class="w-full p-2 border rounded mb-4">
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
    const tableBody = document.getElementById(`${sectionId}Table`);
    tableBody.innerHTML = '';
    if (sectionId === 'users') {
        const sampleData = [
            { ten: 'John Doe', taiKhoan: 'johndoe', email: 'john@example.com' }
        ];
        sampleData.forEach(data => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td class="p-2">${data.ten}</td>
                <td class="p-2">${data.taiKhoan}</td>
                <td class="p-2">${data.email}</td>
                <td class="p-2">
                    <button onclick="editUser('${data.ten}')" class="bg-yellow-500 text-white px-2 py-1 rounded hover:bg-yellow-600">Edit</button>
                    <button onclick="deleteUser('${data.ten}')" class="bg-red-500 text-white px-2 py-1 rounded hover:bg-red-600">Delete</button>
                </td>
            `;
            tableBody.appendChild(row);
        });
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

// Initialize
showSection('users');