const express = require('express');
const app = express();
const cors = require('cors');

app.use(cors());

app.get('/api/customers', (req, res) => {
  res.json([
    { id: "KH001", name: "Nguyễn Văn A", email: "a@gmail.com", phone: "0901234567", passport: "B12345678" },
    { id: "KH002", name: "Trần Thị B", email: "b@gmail.com", phone: "0907654321", passport: "C87654321" }
  ]);
});

app.get('/api/bookings', (req, res) => {
  res.json([
    { id: "KH001", name: "Nguyễn Văn A", email: "a@gmail.com", phone: "0901234567", passport: "B12345678" },
    { id: "KH002", name: "Trần Thị B", email: "b@gmail.com", phone: "0907654321", passport: "C87654321" }
  ]);
});

app.listen(3000, () => {
  console.log('API server running at http://localhost:3000');
});
