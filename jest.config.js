export default {
  testEnvironment: "node",
  transform: {}, // désactive Babel (inutile en Node 20)
  roots: ["<rootDir>/tests/unit"],
  moduleNameMapper: {
    "^(\\.{1,2}/.*)\\.js$": "$1"
  }
};
