const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware untuk membaca JSON
app.use(express.json());

// Endpoint Method GET (Cek status)
app.get('/', (req, res) => {
    res.json({
        status: "success",
        message: "Welcome to EC2 Web Server API!",
        timestamp: new Date()
    });
});

// Endpoint Method GET (Contoh data)
app.get('/api/users', (req, res) => {
    res.json([
        { id: 1, name: "Alice" },
        { id: 2, name: "Bob" }
    ]);
});

app.listen(PORT, () => {
    console.log(`Application is running on port ${PORT}`);
});