---
name: playwriter-linkedin-sales-navigator
description: "Operate LinkedIn Sales Navigator through the Playwriter CLI for authenticated browser workflows: first-time setup, personas/products, account searches, lead searches, duplicate-aware lead capture, and structured prospect lists. Use when asked to use Sales Navigator, find LinkedIn leads/accounts, set up Sales Navigator, search by ICP/persona, or extract visible Sales Navigator search results with Playwriter rather than Playwright MCP."
---

# Playwriter + LinkedIn Sales Navigator

Use the **Playwriter CLI** through Bash. Do not use Playwright MCP for this workflow unless the user explicitly overrides.

## Safety and scope

- Operate inside the user's authenticated browser session; if login, CAPTCHA, identity verification, or security approval appears, ask the user to complete it.
- Do not send connection requests, InMails, messages, comments, or save/export large batches unless the user explicitly asks.
- Do not use scraper extensions, hidden/private APIs, mass profile visits, or automation that bypasses LinkedIn UI controls.
- Capture only data visible in Sales Navigator/search results unless the user asks to open profiles manually.
- Keep activity human-scale: focused searches, short batches, manual-quality review.

## Start a Playwriter CLI session

```bash
playwriter session new
```

If unavailable, use:

```bash
npx playwriter@latest session new
```

Use the returned session id for every command:

```bash
playwriter -s <id> -e '/* JS */'
```

Attach to an existing Sales Navigator tab or open one:

```bash
playwriter -s <id> -e '
state.page = context.pages().find((p) => p.url().includes("linkedin.com/sales")) ?? context.pages().find((p) => p.url() === "about:blank") ?? (await context.newPage());
if (!state.page.url().includes("linkedin.com/sales")) await state.page.goto("https://www.linkedin.com/sales/home", { waitUntil: "domcontentloaded" });
await waitForPageLoad({ page: state.page, timeout: 8000 }).catch(() => {});
console.log("URL:", state.page.url());
console.log(await snapshot({ page: state.page, showDiffSinceLastCall: false }));
'
```

Use the observe -> act -> observe loop. After every click/fill/navigation, print `URL:` and a fresh `snapshot()`.

## First-time Sales Navigator setup

1. Open `https://www.linkedin.com/sales/home`.
2. Complete onboarding conservatively:
   - Save only high-confidence accounts/leads matching the user's stated target market.
   - Avoid random suggested saves; they train poor recommendations.
3. In **Settings -> Profile**:
   - Create a product/service if requested. Use the user's website and a concise generic description of what they sell.
   - Create a persona if useful. Prefer broad role/function/geography filters over over-specific titles.
4. Verify setup by returning to Lead or Account Search and checking the persona/product appears in settings.

## Search strategy

Prefer **Account Search first**, then Lead Search inside promising accounts.

Account filters to consider:

- Headquarters geography
- Company headcount / revenue proxy
- Industry
- Company keywords
- Account lists / saved accounts

Lead filters to consider:

- Current company or saved account list
- Geography
- Current job title Boolean patterns
- Function and seniority
- Spotlights such as changed jobs or posted recently

Use multiple focused searches rather than one mega-query. Save the query text used for each captured lead so the user can reproduce it.

## Run a lead keyword search

Use the global Sales Navigator search box for quick keyword sweeps:

```bash
playwriter -s <id> -e '
state.page = state.page && !state.page.isClosed() ? state.page : (context.pages().find((p) => p.url().includes("linkedin.com/sales")) ?? (await context.newPage()));
if (!state.page.url().includes("/sales/search/people")) await state.page.goto("https://www.linkedin.com/sales/search/people", { waitUntil: "domcontentloaded" });
const query = "<company or persona keywords>";
const input = state.page.locator("[id=\"global-typeahead-search-input\"]");
await input.fill(query);
await state.page.keyboard.press("Enter");
await waitForPageLoad({ page: state.page, timeout: 8000 }).catch(() => {});
await state.page.waitForTimeout(1500);
console.log("URL:", state.page.url());
console.log(await snapshot({ locator: state.page.locator("main"), showDiffSinceLastCall: false }));
'
```

For precise title work, use Sales Navigator's **Current job title** filter when practical. The keyword box searches current and past profile text and is noisier.

## Extract visible lead results

After each search, extract only visible results and keep the query with each row:

```bash
playwriter -s <id> -e '
const query = "<query just run>";
const rows = await state.page.evaluate((query) => {
  const out = [];
  const seen = new Set();
  for (const a of Array.from(document.querySelectorAll("a[href*=\"/sales/lead/\"]"))) {
    const li = a.closest("li");
    if (!li) continue;
    const href = a.href;
    if (seen.has(href)) continue;
    seen.add(href);

    const lines = (li.innerText || "").split("\n").map((s) => s.trim()).filter(Boolean);
    let name = (a.textContent || "").trim();
    if (!name || name === "View profile" || name.includes("is reachable") || name.includes("was last active")) {
      name = lines.find((line) => !line.startsWith("Add ") && !line.includes("degree connection") && line !== "View profile") || "";
    }
    if (!name || name === "View profile") continue;

    const companyLink = Array.from(li.querySelectorAll("a[href*=\"/sales/company/\"]")).find((x) => (x.textContent || "").trim());
    const company = companyLink ? (companyLink.textContent || "").trim() : "";
    let marker = lines.findIndex((l) => l.startsWith("·"));
    if (marker < 0) marker = lines.findIndex((l) => l.includes("degree connection"));
    const titleLine = marker >= 0 && lines[marker + 1]
      ? lines[marker + 1]
      : (lines.find((l, i) => i > 1 && !/Message|Save|About:|Experience:/.test(l)) || "");
    const title = company ? titleLine.replace(company, "").replace(/\s{2,}/g, " ").trim() : titleLine.trim();
    const location = marker >= 0 && lines[marker + 2] && !lines[marker + 2].includes("role") ? lines[marker + 2] : "";

    out.push({ company, contactName: name, roleTitle: title, location, linkedInUrl: href, query });
  }
  return out;
}, query);
console.log(JSON.stringify(rows, null, 2));
'
```

If extraction is noisy, inspect a scoped `snapshot({ locator: state.page.locator('main') })` and adjust parsing. Do not scrape hidden pagination APIs.

## Duplicate-aware workflow

Before presenting candidates, compare against any tracker/CRM/export the user provides. If Playwriter cannot read files outside its sandbox, read the tracker with normal file tools, then embed only the needed existing names/companies into the CLI script.

Deduplicate by:

- exact or near-exact contact name
- LinkedIn URL
- company + role when the user wants only one candidate per company
- previous statuses such as contacted, rejected, no need, connection request sent

## Candidate quality scoring

Rank leads by the user's ICP, not by LinkedIn's order. Useful signals:

- role owns the workflow or budget
- title contains the user's target role terms
- company matches target industry/size/geography
- account has visible volume/process signals in public description
- lead is active or recently changed role
- lead is not too junior unless the user wants operators for discovery

When uncertain, mark fit as weaker rather than overclaiming.

## Output format

Return a concise table unless the user requested a file update:

| Company | Contact name | Role/title | LinkedIn URL | Why they fit | Status |
|---|---|---|---|---|---|

Use status values such as:

- `Candidate identified`
- `Candidate identified - not sent`
- `Connection request sent` only if the user confirms/sends it
- `Skipped - duplicate`
- `Skipped - weak fit`

If asked to update a tracker, update only the intended tracker and preserve existing rows/statuses.
