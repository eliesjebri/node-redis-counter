import os from "os";

export function getHostInfo() {
  const hostname = os.hostname();
  const ifaces = os.networkInterfaces();

  let ip = "0.0.0.0";
  for (const name of Object.keys(ifaces)) {
    for (const iface of ifaces[name] || []) {
      if (iface.family === "IPv4" && !iface.internal) {
        ip = iface.address;
        break;
      }
    }
    if (ip !== "0.0.0.0") break;
  }

  return { hostname, ip };
}
