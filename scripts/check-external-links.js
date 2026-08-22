const fs = require("fs");
const path = require("path");

const root = process.cwd();
const htmlFiles = fs.readdirSync(root).filter((file) => file.endsWith(".html"));
const timeoutMs = Number(process.env.EXTERNAL_LINK_TIMEOUT_MS || 15000);
const concurrency = Number(process.env.EXTERNAL_LINK_CONCURRENCY || 4);
const references = new Map();
const insecureReferences = new Map();

if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1) {
  throw new Error("EXTERNAL_LINK_TIMEOUT_MS must be a positive integer");
}
if (!Number.isSafeInteger(concurrency) || concurrency < 1 || concurrency > 16) {
  throw new Error("EXTERNAL_LINK_CONCURRENCY must be an integer from 1 to 16");
}

function isAllowedLocalHttp(url) {
  try {
    return ["127.0.0.1", "localhost", "[::1]"].includes(new URL(url).hostname);
  } catch (_error) {
    return false;
  }
}

function record(url, file) {
  if (/^http:\/\//i.test(url) && !isAllowedLocalHttp(url)) {
    if (!insecureReferences.has(url)) insecureReferences.set(url, new Set());
    insecureReferences.get(url).add(file);
    return;
  }
  if (!/^https:\/\//i.test(url)) return;
  const normalized = url.replace(/&amp;/g, "&").split("#")[0];
  if (!references.has(normalized)) references.set(normalized, new Set());
  references.get(normalized).add(file);
}

function getAttribute(tag, name) {
  const match = tag.match(new RegExp(`\\b${name}=["']([^"']*)["']`, "i"));
  return match ? match[1] : "";
}

for (const file of htmlFiles) {
  const html = fs.readFileSync(path.join(root, file), "utf8").replace(/<!--[\s\S]*?-->/g, "");
  for (const match of html.matchAll(/<a\b[^>]*>/gi)) {
    record(getAttribute(match[0], "href").trim(), file);
  }
  for (const match of html.matchAll(/<link\b[^>]*>/gi)) {
    const tag = match[0];
    if (/(?:^|\s)(?:stylesheet|canonical)(?:\s|$)/i.test(getAttribute(tag, "rel"))) {
      record(getAttribute(tag, "href").trim(), file);
    }
  }
  for (const match of html.matchAll(/<script\b[^>]*>/gi)) {
    record(getAttribute(match[0], "src").trim(), file);
  }
  for (const match of html.matchAll(/<meta\b[^>]*>/gi)) {
    const tag = match[0];
    const key = getAttribute(tag, "property") || getAttribute(tag, "name");
    if (["og:url", "og:image", "twitter:image"].includes(key.toLowerCase())) {
      record(getAttribute(tag, "content").trim(), file);
    }
  }
}

if (insecureReferences.size) {
  console.error("Insecure external HTTP links are not allowed:");
  for (const [url, files] of [...insecureReferences.entries()].sort()) {
    console.error(`- ${url} (${[...files].join(", ")})`);
  }
  process.exit(1);
}

async function request(url, method) {
  return fetch(url, {
    method,
    redirect: "follow",
    headers: {
      "User-Agent": "ns7jp-portfolio-link-check/1.0",
      ...(method === "GET" ? { Range: "bytes=0-0" } : {}),
    },
    signal: AbortSignal.timeout(timeoutMs),
  });
}

async function check(url) {
  let response = await request(url, "HEAD");
  if ([403, 405].includes(response.status)) response = await request(url, "GET");
  return {
    ok: response.status >= 200 && response.status < 400,
    status: response.status,
    finalUrl: response.url,
  };
}

const queue = [...references.keys()].sort();
const results = [];
let cursor = 0;

async function worker() {
  while (cursor < queue.length) {
    const url = queue[cursor++];
    try {
      results.push({ url, ...(await check(url)) });
    } catch (error) {
      results.push({ url, ok: false, status: "ERROR", error: error.message });
    }
  }
}

Promise.all(Array.from({ length: Math.min(concurrency, queue.length) }, worker)).then(() => {
  const failures = results.filter((result) => !result.ok).sort((a, b) => a.url.localeCompare(b.url));
  for (const result of results.filter((item) => item.ok).sort((a, b) => a.url.localeCompare(b.url))) {
    console.log(`PASS ${result.status} ${result.url}`);
  }

  if (failures.length) {
    console.error("External link check failed:");
    for (const failure of failures) {
      const files = [...references.get(failure.url)].join(", ");
      console.error(`- ${failure.status} ${failure.url} (${files})${failure.error ? `: ${failure.error}` : ""}`);
    }
    process.exit(1);
  }

  console.log(`Checked ${queue.length} unique external links from ${htmlFiles.length} HTML files.`);
});
