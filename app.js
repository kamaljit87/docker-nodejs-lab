// app.js
const express = require("express");
const app = express();

app.get("/", (_req, res) => {
  res.json({ message: "Hello from Node in Docker! 🚀" });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server listening on port ${port}`));
