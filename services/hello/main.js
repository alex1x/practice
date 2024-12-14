const express = require('express');
const app = express();
const port = 8400;

app.get('/', (req, res) => {
  res.json({ message: 'hello world' });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
