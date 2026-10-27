"use strict";
const { chromium } = require("playwright");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
fs.mkdirSync("visual-qa", { recursive: true });
const server = spawn("python3", ["-m", "http.server", "8767", "--bind", "127.0.0.1"], { stdio: "ignore" });
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const sizes = [{ width: 360, height: 740 }, { width: 390, height: 844 }, { width: 768, height: 1024 }, { width: 1366, height: 768 }, { width: 1600, height: 900 }];
const results = [];
(async () => {
  await sleep(900);
  let browser;
  try {
    browser = await chromium.launch({ headless: true });
    for (const viewport of sizes) {
      const page = await browser.newPage({ viewport, reducedMotion: "reduce" });
      const errors = [];
      page.on("pageerror", (error) => errors.push(error.message));
      page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
      page.on("response", (response) => { if (response.status() >= 400) errors.push(response.status() + " " + response.url()); });
      try {
        const response = await page.goto("http://127.0.0.1:8767/", { waitUntil: "domcontentloaded" });
        if (response.status() !== 200) errors.push("Home HTTP " + response.status());
        await page.getByRole("heading", { name: /Onde a jornada/ }).waitFor();
        if (await page.locator(".project-card a").count() !== 3) errors.push("Esperados 3 links de projetos");
        if (await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 2)) errors.push("Overflow horizontal da página");
        const status = page.locator("#carousel-position");
        if (await status.count() !== 1) errors.push("Carrossel sem status acessível");
        const canScroll = await page.locator("#projects-track").evaluate((el) => el.scrollWidth > el.clientWidth + 2);
        const previous = page.getByRole("button", { name: "Cartão anterior" });
        const next = page.getByRole("button", { name: "Próximo cartão" });
        if (canScroll) {
          if (!(await previous.isDisabled())) errors.push("Seta anterior deveria iniciar desativada");
          await next.click();
          await page.waitForFunction(() => document.getElementById("projects-track").scrollLeft > 10);
          if (await previous.isDisabled()) errors.push("Anterior não habilitou após avançar");
          await page.locator("#projects-track").focus();
          await page.keyboard.press("End");
          await page.waitForFunction(() => document.getElementById("next").disabled);
          if (!(await next.isDisabled())) errors.push("Último cartão deveria desabilitar próximo");
          if (!/Projeto 3 de 3/.test(await status.innerText())) errors.push("Anúncio de último cartão incorreto");
          await page.keyboard.press("Home");
          await page.waitForFunction(() => document.getElementById("prev").disabled);
          if (!(await previous.isDisabled())) errors.push("Home não voltou ao primeiro cartão");
        } else {
          if (!(await previous.isDisabled()) || !(await next.isDisabled())) errors.push("Setas deveriam desabilitar se todos os cartões couberem na tela");
        }
        // Once a link is focused, keys are not hijacked by the track.
        await page.locator(".project-card a").first().focus();
        await page.keyboard.press("ArrowRight");
        if (await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 2)) errors.push("Overflow após interação");
        await page.screenshot({ path: `visual-qa/${viewport.width}x${viewport.height}.png`, fullPage: true, animations: "disabled" });
        results.push({ viewport, passed: errors.length === 0, errors, canScroll });
      } catch (error) {
        errors.push(error.stack || String(error));
        results.push({ viewport, passed: false, errors });
      } finally { await page.close(); }
    }
  } finally {
    fs.writeFileSync("visual-qa/diagnostics.json", JSON.stringify(results, null, 2));
    await browser?.close();
    server.kill();
  }
  for (const result of results) console.log(JSON.stringify(result));
  if (results.length !== sizes.length || results.some((x) => !x.passed)) process.exitCode = 1;
})().catch((error) => { console.error(error); server.kill(); process.exitCode = 1; });
