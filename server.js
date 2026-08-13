// Малесенький статичний сервер для гри (без залежностей)
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const PORT = process.env.PORT || 3199;
const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

const SNAP_DIR = process.env.SNAP_DIR || ROOT;
// Тестовий ендпоінт знімків вмикається тільки локально: SNAP_ENABLE=1 node server.js
const SNAP_ON = process.env.SNAP_ENABLE === "1";

http.createServer((req, res) => {
  let p = decodeURIComponent((req.url || "/").split("?")[0]);
  if (req.method === "POST" && p === "/snap" && SNAP_ON) {
    let body = "";
    req.on("data", c => { body += c; if (body.length > 8e6) req.destroy(); });
    req.on("end", () => {
      const m = body.match(/^data:image\/(png|jpeg);base64,(.+)$/s);
      if (!m) { res.writeHead(400); res.end(); return; }
      const name = ((req.url.split("?name=")[1] || "snap")).replace(/[^a-zA-Z0-9_-]/g, "") || "snap";
      const file = path.join(SNAP_DIR, name + (m[1] === "jpeg" ? ".jpg" : ".png"));
      fs.writeFile(file, Buffer.from(m[2], "base64"), err => {
        res.writeHead(err ? 500 : 200); res.end(err ? "err" : "ok " + file);
      });
    });
    return;
  }
  if (p === "/") p = "/index.html";
  const file = path.normalize(path.join(ROOT, p));
  if (!file.startsWith(ROOT)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end("404"); return; }
    res.writeHead(200, { "Content-Type": MIME[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  });
}).listen(PORT, () => console.log(`Більярд: http://localhost:${PORT}`));
