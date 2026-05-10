const fs = require("fs");
const path = require("path");

const root = process.cwd();
const htmlFiles = fs.readdirSync(root).filter((file) => file.endsWith(".html"));
const structuralTags = new Set([
  "html",
  "head",
  "body",
  "header",
  "nav",
  "main",
  "article",
  "section",
  "footer",
  "div",
  "ul",
  "ol",
  "li",
  "dl",
  "dt",
  "dd",
  "table",
  "thead",
  "tbody",
  "tr",
  "td",
  "th",
  "form",
]);

const failures = [];

function withoutIgnoredBlocks(html) {
  return html
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<script\b[\s\S]*?<\/script>/gi, "")
    .replace(/<style\b[\s\S]*?<\/style>/gi, "");
}

for (const file of htmlFiles) {
  const html = withoutIgnoredBlocks(fs.readFileSync(path.join(root, file), "utf8"));
  const stack = [];
  const tags = html.matchAll(/<\/?([a-zA-Z][\w:-]*)(?:\s[^<>]*)?>/g);

  for (const match of tags) {
    const fullTag = match[0];
    const tag = match[1].toLowerCase();
    if (!structuralTags.has(tag)) continue;

    if (fullTag.startsWith("</")) {
      const expected = stack.pop();
      if (expected !== tag) {
        failures.push(
          `${file}: expected </${expected || "none"}> but found </${tag}> near index ${match.index}`,
        );
        break;
      }
    } else if (!fullTag.endsWith("/>")) {
      stack.push(tag);
    }
  }

  if (stack.length > 0) {
    failures.push(`${file}: unclosed tags: ${stack.map((tag) => `<${tag}>`).join(", ")}`);
  }
}

if (failures.length > 0) {
  console.error("HTML structure check failed:");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log(`Checked ${htmlFiles.length} HTML files. Structural tags look balanced.`);
