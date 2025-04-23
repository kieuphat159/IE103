document.addEventListener("DOMContentLoaded", () => {
  // Load dữ liệu ngay khi trang được tải
  fetchCustomers();
  
  // Gọi lại khi nhấn tab "Khách hàng"
  const customerTabButton = document.querySelector("button[onclick*='users']");
  if (customerTabButton) {
    customerTabButton.addEventListener("click", fetchCustomers);
  }
});

function fetchCustomers() {
  // Mock API response
  const mockData = [
    {
      id: 'KH001',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '0123456789',
      passport: 'A1234567'
    },
    {
      id: 'KH002',
      name: 'Jane Smith',
      email: 'jane@example.com',
      phone: '0987654321',
      passport: 'B7654321'
    }
  ];
  
  renderCustomerTable(mockData);
}

function renderCustomerTable(customers) {
  const tbody = document.getElementById("userTable");
  tbody.innerHTML = "";

  customers.forEach(c => {
    const row = `
      <tr class="border-t">
        <td class="p-2">${c.id}</td>
        <td class="p-2">${c.name}</td>
        <td class="p-2">${c.email}</td>
        <td class="p-2">${c.phone}</td>
        <td class="p-2">${c.passport}</td>
      </tr>
    `;
    tbody.insertAdjacentHTML("beforeend", row);
  });
}