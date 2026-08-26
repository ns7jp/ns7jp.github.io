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

  const htmlTag = html.match(/<html\b[^>]*>/i)?.[0] || "";
  if (!hasAttribute(htmlTag, "lang", /^ja(?:-|$)/i)) {
    failures.push(`${file}: <html> requires a Japanese lang attribute`);
  }
  if (!/<meta\b[^>]*charset=["']?utf-8["']?/i.test(html)) {
    failures.push(`${file}: UTF-8 charset declaration is required`);
  }
  if (!/<meta\b[^>]*name=["']viewport["'][^>]*content=["'][^"']*width=device-width/i.test(html)) {
    failures.push(`${file}: responsive viewport meta tag is required`);
  }
  if (!/<title>[^<]+<\/title>/i.test(html)) {
    failures.push(`${file}: a non-empty <title> is required`);
  }

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

  const buttonTags = Array.from(html.matchAll(/<button\b[^>]*>/gi), (match) => match[0]);
  for (const tag of buttonTags) {
    if (!hasAttribute(tag, "type", /^(?:button|submit|reset)$/i)) {
      failures.push(`${file}: every <button> requires an explicit valid type`);
    }
  }

  if (ids.includes("site-nav")) {
    const menuButtons = buttonTags.filter((tag) =>
      hasAttribute(tag, "class", /(?:^|\s)res-menu(?:\s|$)/i)
    );
    if (menuButtons.length !== 1) {
      failures.push(`${file}: site navigation requires exactly one .res-menu button`);
    } else {
      const menuButton = menuButtons[0];
      if (!hasAttribute(menuButton, "aria-controls", /^site-nav$/)) {
        failures.push(`${file}: .res-menu must control #site-nav`);
      }
      if (!hasAttribute(menuButton, "aria-expanded", /^false$/i)) {
        failures.push(`${file}: .res-menu must start with aria-expanded="false"`);
      }
      if (!hasAttribute(menuButton, "aria-label", /^メニューを開く$/)) {
        failures.push(`${file}: .res-menu requires the initial label メニューを開く`);
      }
    }
  }

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

  for (const match of html.matchAll(/<i\b[^>]*class=["'][^"']*\bfa-(?:solid|regular|brands)\b[^"']*["'][^>]*>/gi)) {
    const tag = match[0];
    if (!hasAttribute(tag, "aria-hidden", /^true$/i)) {
      failures.push(`${file}: decorative Font Awesome icon requires aria-hidden="true": ${tag.slice(0, 100)}`);
    }
  }

  for (const match of html.matchAll(/<table\b[^>]*>[\s\S]*?<\/table>/gi)) {
    const tableBlock = match[0];
    if (!/<thead\b/i.test(tableBlock)) continue;
    const tableTag = tableBlock.match(/<table\b[^>]*>/i)?.[0] || "";
    const hasAccessibleName = /<caption\b[^>]*>[\s\S]*?\S[\s\S]*?<\/caption>/i.test(tableBlock) ||
      hasAttribute(tableTag, "aria-label") || hasAttribute(tableTag, "aria-labelledby");
    if (!hasAccessibleName) failures.push(`${file}: data table requires a caption or accessible name`);

    const theadBlock = tableBlock.match(/<thead\b[\s\S]*?<\/thead>/i)?.[0] || "";
    for (const headerMatch of theadBlock.matchAll(/<th\b[^>]*>/gi)) {
      const headerTag = headerMatch[0];
      if (!hasAttribute(headerTag, "scope", /^col$/i)) {
        failures.push(`${file}: column header requires scope="col"`);
      }
    }
  }

  for (const match of html.matchAll(/<video\b[^>]*>[\s\S]*?<\/video>/gi)) {
    const block = match[0];
    const openTag = block.match(/<video\b[^>]*>/i)?.[0] || "";
    if (!/\bcontrols(?:\s|>|=)/i.test(openTag)) failures.push(`${file}: video requires controls`);
    if (!hasAttribute(openTag, "poster")) failures.push(`${file}: video requires a poster image`);
    if (!hasAttribute(openTag, "width") || !hasAttribute(openTag, "height")) {
      failures.push(`${file}: video requires explicit width/height`);
    }
    if (!/<track\b[^>]*kind=["']captions["'][^>]*srclang=["'][^"']+["']/i.test(block)) {
      failures.push(`${file}: video requires a captions track with srclang`);
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
    ["og:url", new RegExp(`<meta\\b[^>]*property=["']og:url["'][^>]*content=["']${expectedUrl.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}["']`, "i")],
    ["og:image", /<meta\b[^>]*property=["']og:image["'][^>]*content=["'][^"']+["']/i],
    ["og:image:width", /<meta\b[^>]*property=["']og:image:width["'][^>]*content=["']\d+["']/i],
    ["og:image:height", /<meta\b[^>]*property=["']og:image:height["'][^>]*content=["']\d+["']/i],
    ["og:image:alt", /<meta\b[^>]*property=["']og:image:alt["'][^>]*content=["'][^"']+["']/i],
    ["og:site_name", /<meta\b[^>]*property=["']og:site_name["'][^>]*content=["'][^"']+["']/i],
    ["twitter:card", /<meta\b[^>]*name=["']twitter:card["'][^>]*content=["'][^"']+["']/i],
    ["twitter:image", /<meta\b[^>]*name=["']twitter:image["'][^>]*content=["'][^"']+["']/i],
    ["twitter:image:alt", /<meta\b[^>]*name=["']twitter:image:alt["'][^>]*content=["'][^"']+["']/i],
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
