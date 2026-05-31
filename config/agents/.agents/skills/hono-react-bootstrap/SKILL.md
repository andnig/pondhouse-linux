---
name: hono-react-bootstrap
description: Manual-only skill for bootstrapping a generic empty TypeScript monorepo with Hono API, Vite React web app, TanStack Router, TanStack Query, Tailwind/shadcn-style UI, Drizzle/Postgres, pg-boss, Mastra, better-auth placeholders, Vitest, Docker, and production compose. Use only when the user explicitly invokes this skill by name or asks to load the Hono React bootstrap skill; do not auto-trigger from ordinary app-building requests.
disable-model-invocation: true
---

# Hono React bootstrap

Bootstrap an empty app into a runnable, testable pnpm monorepo. Keep it generic. Do not add product features unless the user asks.

## Non-negotiables

- Query npm immediately and pin the latest available versions. Do not reuse stale versions from memory.
- Stay maximally type-safe: strict TypeScript, no `any`, no type suppression comments, no loose request parsing.
- Make the scaffold testable from the first commit: Vitest in each workspace, smoke tests for API, web router, and DB schema.
- Verify by actually running install, typecheck, tests, builds, Docker builds, DB migration, API smoke calls, and browser smoke checks.
- Keep the monorepo small: `apps/web`, `apps/api`, `packages/db`. Do not add workers or shared packages until needed.
- If package latest versions conflict, prefer latest direct dependencies and document peer warnings precisely.

## Target shape

```text
apps/
  api/      Hono on Node, Zod env parsing, pg-boss in-process, Mastra runtime boundary
  web/      Vite React, TanStack Router, TanStack Query, Tailwind, shadcn-style aliases
packages/
  db/       Drizzle schema, postgres client, migrations, schema tests
```

Root files to include:

- `package.json` with pnpm workspace scripts: `dev`, `build`, `typecheck`, `test`, `format`, `format:check`, `db:generate`, `db:migrate`
- `pnpm-workspace.yaml` with shared catalog versions
- `.npmrc` with pnpm settings needed by Drizzle and `pnpm deploy`
- `.gitignore`, `.dockerignore`, `.prettierignore`, `.nvmrc`, `tsconfig.base.json`, `vitest.config.ts`
- `.env.example`
- `docker-compose.yml` for Postgres only
- `start-database.sh`
- root `Dockerfile` with `api-runner` and `web-runner` targets
- `docker-compose.prod.yml` with app services only, no Postgres
- `README.md` with concrete commands and no marketing fluff

## Version workflow

Before writing package manifests, run `npm view <package> version` for every package you plan to install. At minimum verify:

```text
@hono/node-server @mastra/core @radix-ui/react-slot @tanstack/react-query
@tanstack/react-query-devtools @tanstack/react-router @tanstack/react-router-devtools
@tanstack/router-plugin @tailwindcss/vite @vitejs/plugin-react @types/node
@types/react @types/react-dom better-auth class-variance-authority clsx drizzle-kit
drizzle-orm hono jsdom lucide-react pg pg-boss postgres prettier react react-dom
tailwind-merge tailwindcss tsx typescript vite vitest zod
```

Pin exact versions in `package.json` or the pnpm catalog. Avoid `^` ranges when the user asks for latest.

## Implementation notes

- Use Node 22+ and ESM.
- Use `.js` extensions in NodeNext TypeScript imports for API and DB packages.
- Keep Hono endpoints minimal: `/health`, `/ready`, and one empty bootstrap API route such as `/api/queue/today`.
- Wire pg-boss behind `DATABASE_URL`; do not require a database for API unit tests.
- Create a Mastra runtime boundary but do not implement workflows.
- Include better-auth as an installed dependency and env placeholders, but do not add auth flows unless asked.
- Use Drizzle with the `postgres` driver for app DB access. pg-boss manages its own `pg` connection.
- Add an initial Drizzle schema that matches the generic app domain only if the user provided one. Otherwise create a tiny neutral smoke-test schema.
- For Tailwind v4, use `@tailwindcss/vite` and `@import "tailwindcss"`.
- If using TanStack Router file generation, make the route files complete. Otherwise use code-based routes and omit the generator plugin.
- Add shadcn-compatible `components.json`, `@/` aliases, `cn()`, and one starter UI component.
- Include a favicon or browser smoke tests may report a 404 console error.

## Verification checklist

Run all applicable checks and fix every failure:

```bash
pnpm install
pnpm format:check
pnpm typecheck
pnpm test
pnpm build
pnpm db:generate
./start-database.sh
pnpm db:migrate
docker build --target api-runner -t app-api-bootstrap .
docker build --target web-runner -t app-web-bootstrap .
```

Then use the app like a user:

- Start the API against local Postgres and fetch `/health`, `/ready`, and the starter API route.
- Start the web app preview and load it in a real browser with Playwright.
- Check browser console errors and network calls.
- Run LSP diagnostics on changed TypeScript files or package directories.

Report exact commands that passed. If a peer warning remains because a package has not caught up to another latest package, state it plainly.
