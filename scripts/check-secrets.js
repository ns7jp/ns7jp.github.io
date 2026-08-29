const { execFileSync } = require("node:child_process");
const fs = require("node:fs");

const files = execFileSync("git", ["ls-files", "-z"], { encoding: "utf8" })
  .split("\0")
  .filter(Boolean);
const findings = [];
const rules = [
  ["private key", /-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----/],
  ["AWS access key", /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
  ["GitHub token", /\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,255}\b/],
  ["Slack token", /\bxox(?:a|b|p|r|s)-[A-Za-z0-9-]{10,}\b/],
];

for (const file of files) {
  const buffer = fs.readFileSync(file);
  if (buffer.includes(0)) continue;
  const lines = buffer.toString("utf8").split(/\r?\n/);
  lines.forEach((line, index) => {
    for (const [label, pattern] of rules) {
      if (pattern.test(line)) findings.push(`${file}:${index + 1}: possible ${label}`);
    }
  });
}

if (findings.length) {
  console.error("Credential guard failed:");
  findings.forEach((finding) => console.error(`- ${finding}`));
  process.exit(1);
}

console.log(`Checked ${files.length} tracked files for high-confidence credential patterns.`);
