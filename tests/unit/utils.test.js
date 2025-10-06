import { getHostInfo } from "../../src/utils.js";

describe("getHostInfo", () => {
  it("retourne hostname et ip", () => {
    const info = getHostInfo();
    expect(info).toHaveProperty("hostname");
    expect(info).toHaveProperty("ip");
    expect(typeof info.hostname).toBe("string");
    expect(typeof info.ip).toBe("string");
  });
});
