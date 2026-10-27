const assert=require("node:assert/strict");
const test=require("node:test");
const fs=require("node:fs");
test("nao redistribui pacote premium isolado",()=>{
 assert.equal(fs.existsSync("sprites/Sprout Lands - Sprites - premium pack.zip"),false);
 assert.equal(fs.existsSync("sprites/read_me.txt"),true);
});
test("paginas estaticas nao dependem de backend",()=>{
 const html=fs.readFileSync("index.html","utf8");
 assert.match(html,/lang="pt-BR"/);
 assert.match(html,/id="projects-track"/);
 assert.match(html,/aria-label="Controles dos cartões/);
 assert.doesNotMatch(html,/(src|href)="\/(src|static|movie)\//);
 for(const f of ["styles.css","app.js","favicon.svg","docs/DESIGN_SYSTEM.md"])assert.ok(fs.existsSync(f));
});
