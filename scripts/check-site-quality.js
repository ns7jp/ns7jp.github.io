const fs = require("fs");
const path = require("path");

const root = process.cwd();
const htmlFiles = fs.readdirSync(root).filter((file) => file.endsWith(".html"));
const failures = [];
const sitemap = fs.readFileSync(path.join(root, "sitemap.xml"), "utf8");

function countMatches(text, pattern) {
  return Array.from(text.matchAll(pattern)).length;
}

function getAttribute(tag, name) {
  const match = tag.match(new RegExp(`\\b${name}=["']([^"']*)["']`, "i"));
  return match ? match[1] : null;
}

function hasAttribute(tag, name, valuePattern) {
  const value = getAttribute(tag, name);
  return value !== null && (!valuePattern || valuePattern.test(value));
}

function stripIgnoredBlocks(html) {
  return html
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<style\b[\s\S]*?<\/style>/gi, "");
}

for (const file of htmlFiles) {
  const raw = fs.readFileSync(path.join(root, file), "utf8");
  const html = stripIgnoredBlocks(raw);
  const isNoindex = /<meta\b[^>]*name=["']robots["'][^>]*content=["'][^"']*noindex/i.test(html);
  const expectedUrl = file === "index.html"
    ? "https://ns7jp.github.io/"
    : `https://ns7jp.github.io/${file}`;

  const mainCount = countMatches(html, /<main\b/gi);
  if (mainCount !== 1) failures.push(`${file}: expected exactly one <main>, found ${mainCount}`);
  if (mainCount === 1) {
    const mainTag = html.match(/<main\b[^>]*>/i)?.[0] || "";
    if (!hasAttribute(mainTag, "tabindex", /^-1$/)) {
      failures.push(`${file}: <main> requires tabindex="-1" for skip-link focus`);
    }
  }

  const h1Count = countMatches(html, /<h1\b/gi);
  if (h1Count !== 1) failures.push(`${file}: expected exactly one <h1>, found ${h1Count}`);

  if (mainCount === 1 && h1Count === 1) {
    const mainOpen = html.search(/<main\b/i);
    const mainClose = html.search(/<\/main>/i);
    const h1 = html.search(/<h1\b/i);
    if (h1 < mainOpen || h1 > mainClose) {
      failures.push(`${file}: <h1> must be inside the <main> landmark`);
    }
  }

  const ids = Array.from(html.matchAll(/\bid=["']([^"']+)["']/gi), (match) => match[1]);
  const duplicates = [...new Set(ids.filter((id, index) => ids.indexOf(id) !== index))];
  if (duplicates.length) failures.push(`${file}: duplicate ids: ${duplicates.join(", ")}`);

  for (const match of html.matchAll(/href=["']#([^"']+)["']/gi)) {
    if (!ids.includes(match[1])) failures.push(`${file}: same-page anchor #${match[1]} is missing`);
  }

  const anchorTags = Array.from(html.matchAll(/<a\b[^>]*>/gi), (match) => match[0]);
  const skipLink = anchorTags.find((tag) => hasAttribute(tag, "class", /(?:^|\s)skip-link(?:\s|$)/i));
  if (!skipLink) {
    failures.push(`${file}: page requires a skip link`);
  } else {
    const skipHref = getAttribute(skipLink, "href");
    if (!skipHref || !skipHref.startsWith("#")) {
      failures.push(`${file}: skip link requires a same-page target`);
    } else if (!ids.includes(skipHref.slice(1))) {
      failures.push(`${file}: skip link target ${skipHref} is missing`);
    }
  }

  for (const tag of anchorTags.filter((anchor) => hasAttribute(anchor, "aria-current", /^page$/i))) {
    const href = getAttribute(tag, "href") || "";
    const currentPath = href.split(/[?#]/)[0].replace(/^\//, "");
    const expectedPath = file === "index.html" && currentPath === "" ? "index.html" : currentPath;
    if (expectedPath !== file) {
      failures.push(`${file}: aria-current="page" points to ${href || "an empty href"}`);
    }
  }

  for (const match of html.matchAll(/<img\b[^>]*>/gi)) {
    const tag = match[0];
    if (!hasAttribute(tag, "alt")) failures.push(`${file}: image is missing alt text: ${tag.slice(0, 100)}`);
    if (!hasAttribute(tag, "width") || !hasAttribute(tag, "height")) {
      failures.push(`${file}: image is missing explicit width/height: ${tag.slice(0, 100)}`);
    }
  }

  for (const match of html.matchAll(/<a\b[^>]*target=["']_blank["'][^>]*>/gi)) {
    const tag = match[0];
    if (!hasAttribute(tag, "rel", /(?:^|\s)noopener(?:\s|$)/i) ||
        !hasAttribute(tag, "rel", /(?:^|\s)noreferrer(?:\s|$)/i)) {
      failures.push(`${file}: target=_blank link requires rel="noopener noreferrer"`);
    }
  }

  for (const match of raw.matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)) {
    try {
      JSON.parse(match[1]);
    } catch (error) {
      failures.push(`${file}: invalid JSON-LD (${error.message})`);
    }
  }

  if (isNoindex) {
    if (sitemap.includes(expectedUrl)) failures.push(`${file}: noindex page must not be in sitemap.xml`);
    continue;
  }

  const requiredPatterns = [
    ["meta description", /<meta\b[^>]*name=["']description["'][^>]*content=["'][^"']+["']/i],
    ["canonical", new RegExp(`<link\\b[^>]*rel=["']canonical["'][^>]*href=["']${expectedUrl.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}["']`, "i")],
    ["og:title", /<meta\b[^>]*property=["']og:title["'][^>]*content=["'][^"']+["']/i],
    ["og:description", /<meta\b[^>]*property=["']og:description["'][^>]*content=["'][^"']+["']/i],
    ["og:image", /<meta\b[^>]*property=["']og:image["'][^>]*content=["'][^"']+["']/i],
    ["twitter:card", /<meta\b[^>]*name=["']twitter:card["'][^>]*content=["'][^"']+["']/i],
    ["twitter:image", /<meta\b[^>]*name=["']twitter:image["'][^>]*content=["'][^"']+["']/i],
  ];

  for (const [label, pattern] of requiredPatterns) {
    if (!pattern.test(html)) failures.push(`${file}: missing or incorrect ${label}`);
  }

  if (!sitemap.includes(`<loc>${expectedUrl}</loc>`)) {
    failures.push(`${file}: indexable page is missing from sitemap.xml`);
  }
}

if (failures.length) {
  console.error("Site quality check failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Checked ${htmlFiles.length} HTML files. Accessibility and SEO guardrails look good.`);
