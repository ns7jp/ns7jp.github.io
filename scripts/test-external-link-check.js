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

const assert = require("node:assert/strict");
const { retryTransientResponse } = require("./external-link-retry");

async function testTransientResponses() {
  const ok = { ok: true, status: 200, finalUrl: "https://example.com/final" };
  const unavailable = { ok: false, status: 503, finalUrl: "https://example.com/" };

  let calls = 0;
  const waits = [];
  const retries = [];
  const recovered = await retryTransientResponse(async () => ++calls === 1 ? unavailable : ok, {
    wait: async (ms) => waits.push(ms),
    onRetry: (event) => retries.push(event),
  });
  assert.equal(recovered, ok);
  assert.equal(calls, 2);
  assert.deepEqual(waits, [1000]);
  assert.deepEqual(retries, [{ status: 503, attempt: 1, maxAttempts: 3, delayMs: 1000 }]);

  calls = 0;
  waits.length = 0;
  const persistent = await retryTransientResponse(async () => { calls += 1; return unavailable; }, {
    wait: async (ms) => waits.push(ms),
  });
  assert.equal(persistent, unavailable);
  assert.equal(persistent.ok, false);
  assert.equal(calls, 3);
  assert.deepEqual(waits, [1000, 2000]);

  for (const status of [401, 403, 404, 405, 429]) {
    calls = 0;
    const permanent = { ok: false, status, finalUrl: "https://example.com/" };
    const result = await retryTransientResponse(async () => { calls += 1; return permanent; }, {
      wait: async () => { throw new Error("Non-transient HTTP response must not wait"); },
    });
    assert.equal(result, permanent);
    assert.equal(calls, 1);
  }

  for (const status of [500, 502, 504]) {
    calls = 0;
    const result = await retryTransientResponse(async () => ++calls === 1 ? { ok: false, status } : ok, {
      wait: async () => {},
    });
    assert.equal(result, ok);
    assert.equal(calls, 2);
  }

  calls = 0;
  assert.equal(await retryTransientResponse(async () => { calls += 1; return ok; }, {
    wait: async () => { throw new Error("Successful response must not wait"); },
  }), ok);
  assert.equal(calls, 1);

  calls = 0;
  const networkError = new Error("fetch failed");
  await assert.rejects(retryTransientResponse(async () => { calls += 1; throw networkError; }, {
    wait: async () => { throw new Error("Network errors must remain visible"); },
  }), (error) => error === networkError);
  assert.equal(calls, 1);
  console.log("Transient HTTP retry tests passed.");
}

testTransientResponses().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
