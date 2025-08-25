import express from "express";
const app = express();
const PORT = Number(process.env.PORT || 3000);
const APP_NAME = process.env.APP_NAME || "TS API";

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: APP_NAME });
});

app.get("/whoami", (_req, res) => {
  res.json({ uid: process.getuid?.(), gid: process.getgid?.() });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`[${APP_NAME}] listening on ${PORT}`);
});
