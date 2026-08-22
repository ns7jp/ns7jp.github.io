const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const checker = path.resolve(__dirname, "check-external-links.js");
const fixtureDir = fs.mkdtempSync(path.join(os.tmpdir(), "portfolio-link-check-"));

function run(extraEnv = {}) {
  return spawnSync(process.execPath, [checker], {
    cwd: fixtureDir,
    encoding: "utf8",
    env: { ...process.env, ...extraEnv },
  });
}

try {
  fs.writeFileSync(
    path.join(fixtureDir, "index.html"),
    '<!doctype html><a href="http://example.com/insecure">external</a>',
    "utf8"
  );
  const insecure = run();
  if (insecure.status === 0 || !insecure.stderr.includes("Insecure external HTTP links")) {
    throw new Error(`HTTP rejection fixture failed:\n${insecure.stdout}\n${insecure.stderr}`);
  }

  fs.writeFileSync(
    path.join(fixtureDir, "index.html"),
    '<!doctype html><a href="http://127.0.0.1:8080/healthz">local</a>',
    "utf8"
  );
  const local = run();
  if (local.status !== 0) {
    throw new Error(`localhost allowlist fixture failed:\n${local.stdout}\n${local.stderr}`);
  }

  const invalidConcurrency = run({ EXTERNAL_LINK_CONCURRENCY: "not-a-number" });
  if (invalidConcurrency.status === 0 ||
      !invalidConcurrency.stderr.includes("EXTERNAL_LINK_CONCURRENCY")) {
    throw new Error(
      `invalid concurrency fixture failed:\n${invalidConcurrency.stdout}\n${invalidConcurrency.stderr}`
    );
  }

  console.log("External link checker guard tests passed.");
} finally {
  fs.rmSync(fixtureDir, { recursive: true, force: true });
}
