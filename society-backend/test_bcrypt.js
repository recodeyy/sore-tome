const bcrypt = require("bcryptjs");
const hash = "$2a$10$Wu/OJKVknM61IZOpjgtfTu3pmO3Y5pED/jH4fEC5IH5He/dYFrvMm";

async function test() {
  const passwords = ["123,23", "123123,33", "123123", "password", "taiyo", "123456"];
  for (const pw of passwords) {
    const match = await bcrypt.compare(pw, hash);
    console.log(`Password: "${pw}" => Match: ${match}`);
  }
}
test();
