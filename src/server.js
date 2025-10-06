import express from "express";
import { ensureRedis, redis } from "./redis.js";
import { getHostInfo } from "./utils.js";

const app = express();

const PORT = parseInt(process.env.PORT || "3000", 10);
const COUNTER_KEY = process.env.COUNTER_KEY || "global:hits";
const SERVICE_NAME = process.env.SERVICE_NAME || "node-redis-counter";

app.get("/healthz", async (_req, res) => {
  try {
    await ensureRedis();
    await redis.ping();
    res.status(200).json({ status: "ok" });
  } catch (e) {
    res.status(500).json({ status: "down", error: String(e) });
  }
});

app.get("/readyz", async (_req, res) => {
  try {
    await ensureRedis();
    await redis.ping();
    res.status(200).json({ ready: true });
  } catch {
    res.status(503).json({ ready: false });
  }
});

app.get("/", async (req, res) => {
  try {
    await ensureRedis();
    const count = await redis.incr(COUNTER_KEY);
    const { hostname, ip } = getHostInfo();

    res.json({
      service: SERVICE_NAME,
      container_ip: ip,
      container_hostname: hostname,
      request_ip: req.headers["x-forwarded-for"] || req.socket.remoteAddress,
      count
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

const server = app.listen(PORT, async () => {
  const { hostname, ip } = getHostInfo();
  console.log(`[startup] ${SERVICE_NAME} listening on ${PORT} (host=${hostname} ip=${ip})`);
});

process.on("SIGTERM", async () => {
  console.log("[shutdown] SIGTERM received");
  try { if (redis?.isOpen) await redis.quit(); } catch {}
  server.close(() => process.exit(0));
});
