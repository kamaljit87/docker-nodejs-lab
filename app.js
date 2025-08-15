// app.js (ESM)
import express from "express";
import { readFileSync, existsSync } from "fs";

const app = express();

function getMessage() {
  const secretPath = "/run/secrets/app_message";
  if (existsSync(secretPath)) {
    try {
      return readFileSync(secretPath, "utf8").trim();
    } catch (_) {
      // fallthrough to default
    }
  }
  return "Hello from Node in Docker! 🚀";
}

app.get("/", (_req, res) => {
  res.json({ message: getMessage() });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server listening on port ${port}`));
