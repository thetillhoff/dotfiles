// Emit one TSV row per class/method/function/interface/type:
// path, line, kind, vis, name, signature, doc.
//
// Uses the `typescript` the repo already has in node_modules (resolved from cwd),
// so it adds no dependency. Signature and JSDoc are mechanical; the audit's agents
// supply purpose + verdict.
"use strict";

const path = require("path");

function loadTs() {
  for (const from of [process.cwd(), __dirname]) {
    try {
      return require(require.resolve("typescript", { paths: [from] }));
    } catch (_) {}
  }
  console.error(
    "typescript not resolvable from cwd or the skill dir. Run from the repo root " +
      "(where node_modules/typescript lives), or `npx -y typescript` is available " +
      "but downloads a package - ask first."
  );
  process.exit(2);
}
const ts = loadTs();

const cell = (s) => String(s == null ? "" : s).split(/\s+/).join(" ").slice(0, 200);

function docOf(node) {
  const jsdoc = node.jsDoc && node.jsDoc[0];
  if (!jsdoc || !jsdoc.comment) return "-";
  const raw =
    typeof jsdoc.comment === "string"
      ? jsdoc.comment
      : jsdoc.comment.map((c) => c.text || "").join(" ");
  return cell(raw.split("\n\n")[0]) || "-";
}

// `member` = declared inside a class/interface, where the TS default is public.
// At module level the default is the opposite: unexported, hence "local".
function visOf(node, member) {
  const mods = ts.canHaveModifiers(node) ? ts.getModifiers(node) || [] : [];
  const has = (k) => mods.some((m) => m.kind === k);
  const named = node.name ? node.name.getText() : "";
  if (has(ts.SyntaxKind.PrivateKeyword) || has(ts.SyntaxKind.ProtectedKeyword)) return "priv";
  if (named.startsWith("_") || named.startsWith("#")) return "priv";
  if (has(ts.SyntaxKind.ExportKeyword) || has(ts.SyntaxKind.DefaultKeyword)) return "pub";
  return member ? "pub" : "local";
}

function sigOf(node, sf) {
  if (!node.parameters) return node.type ? cell(node.type.getText(sf)) : "";
  const params = node.parameters.map((p) => cell(p.getText(sf))).join(", ");
  const ret = node.type ? "->" + cell(node.type.getText(sf)) : "";
  return `(${params})${ret}`;
}

const fnInit = (d) =>
  d.initializer &&
  (ts.isArrowFunction(d.initializer) || ts.isFunctionExpression(d.initializer));

function rows(file, sf, out) {
  const push = (node, kind, vis, name, sig, doc) =>
    out.push([
      file,
      sf.getLineAndCharacterOfPosition(node.getStart(sf)).line + 1,
      kind,
      vis,
      name,
      sig,
      doc,
    ]);
  const emit = (node, kind, name, sig, member) =>
    push(node, kind, visOf(node, member), name, sig, docOf(node));

  // owner: {name, iface} of the enclosing class/interface, or null at module level.
  const visit = (node, owner) => {
    const qual = (n) => (owner ? owner.name + "." + n : n);
    if (ts.isClassDeclaration(node) && node.name) {
      const heritage = (node.heritageClauses || []).map((h) => cell(h.getText(sf))).join(" ");
      emit(node, "class", node.name.text, heritage);
      node.members.forEach((m) => visit(m, { name: node.name.text, iface: false }));
    } else if (ts.isInterfaceDeclaration(node)) {
      emit(node, "interface", node.name.text, "");
      node.members.forEach((m) => visit(m, { name: node.name.text, iface: true }));
    } else if (
      ts.isMethodDeclaration(node) ||
      ts.isMethodSignature(node) ||
      ts.isConstructorDeclaration(node)
    ) {
      const own = ts.isConstructorDeclaration(node) ? "constructor" : node.name.getText(sf);
      // An interface method is a contract someone implements, not a call site -
      // same distinction the Go extractor draws, so findings compare across languages.
      const kind = !owner ? "func" : owner.iface ? "iface-method" : "method";
      emit(node, kind, qual(own), sigOf(node, sf), Boolean(owner));
    } else if (ts.isFunctionDeclaration(node) && node.name) {
      emit(node, "func", node.name.text, sigOf(node, sf));
    } else if (ts.isTypeAliasDeclaration(node)) {
      emit(node, "type", node.name.text, cell(node.type.getText(sf)));
    } else if (ts.isVariableStatement(node)) {
      // `export const foo = () => {}` is a function in every way that matters, and
      // both its export modifier and its JSDoc sit on the statement, not the declaration.
      const vis = visOf(node);
      const doc = docOf(node);
      node.declarationList.declarations
        .filter(fnInit)
        .forEach((d) =>
          push(d, "func", vis, qual(d.name.getText(sf)), sigOf(d.initializer, sf), doc)
        );
    } else {
      ts.forEachChild(node, (c) => visit(c, owner));
    }
  };

  ts.forEachChild(sf, (n) => visit(n, null));
}

const fs = require("fs");
console.log(["path", "line", "kind", "vis", "name", "signature", "doc"].join("\t"));
for (const file of process.argv.slice(2)) {
  let out = [];
  try {
    const text = fs.readFileSync(file, "utf8");
    const kind = /\.tsx?$/.test(file) ? undefined : ts.ScriptKind.JS;
    const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, kind);
    rows(path.relative(process.cwd(), file) || file, sf, out);
  } catch (err) {
    out = [[file, 0, "ERROR", "-", "-", "-", cell(err.message)]];
  }
  out.forEach((r) => console.log(r.join("\t")));
}
