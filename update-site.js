// Апдейтер сайту: підняти версію → закомітити → запушити.
// GitHub Pages підхопить сам за ~1 хвилину.
const fs = require("fs");
const { execSync } = require("child_process");

process.chdir(__dirname);
const run = cmd => execSync(cmd, { stdio: "inherit" });

const vj = JSON.parse(fs.readFileSync("version.json", "utf8"));
vj.v++;
vj.date = new Date().toISOString().slice(0, 10);
fs.writeFileSync("version.json", JSON.stringify(vj) + "\n");

let html = fs.readFileSync("index.html", "utf8");
html = html.replace(/const GAME_V = \d+;/, `const GAME_V = ${vj.v};`);
fs.writeFileSync("index.html", html);

console.log(`\n  Публікую версію ${vj.v}...\n`);
run("git add -A");
run(`git commit -m "Оновлення гри — v${vj.v}"`);
run("git push");
console.log(`\n  ✅ Готово! Сайт оновиться за ~1 хвилину:`);
console.log(`  https://camio1447-netizen.github.io/billiard/\n`);
console.log(`  Відкриті вкладки гравців самі покажуть "Вийшла нова версія".\n`);
