"use strict";
const {chromium}=require("playwright");
const {spawn}=require("node:child_process");
const fs=require("node:fs");
fs.mkdirSync("visual-qa",{recursive:true});
const server=spawn("python3",["-m","http.server","8767","--bind","127.0.0.1"],{stdio:"ignore"});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 await sleep(1100);let browser;let fail=false;const results=[];
 try{
  browser=await chromium.launch({headless:true});
  for(const viewport of [{width:390,height:844},{width:768,height:1024},{width:1366,height:768},{width:1600,height:900}]){
   const page=await browser.newPage({viewport,reducedMotion:"reduce"});
   const errors=[];page.on("pageerror",e=>errors.push(e.message));
   page.on("console",m=>{if(m.type()==="error")errors.push(m.text())});
   page.on("response",response=>{if(response.status()>=400)errors.push(response.status()+" "+response.url())});
   await page.goto("http://127.0.0.1:8767/",{waitUntil:"domcontentloaded"});
   await page.getByRole("heading",{name:/Onde a jornada/}).waitFor();
   const links=await page.locator(".project-card a").count();
   if(links!==3)errors.push("Esperados 3 links de projetos");
   const isOverflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+2);
   if(isOverflow)errors.push("Overflow horizontal da pagina");
   await page.locator("#projects-track").focus();
   await page.keyboard.press("ArrowRight");
   await page.screenshot({path:"visual-qa/"+viewport.width+"x"+viewport.height+".png",fullPage:true,animations:"disabled"});
   results.push({viewport,passed:errors.length===0,errors});
   if(errors.length)fail=true;
   await page.close();
  }
 }finally{fs.writeFileSync("visual-qa/diagnostics.json",JSON.stringify(results,null,2));await browser?.close();server.kill()}
 if(fail)process.exitCode=1;
})().catch(err=>{console.error(err);server.kill();process.exitCode=1});
