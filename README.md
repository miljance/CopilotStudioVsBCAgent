# Copilot Studio vs. BC Agent: Project Billing Agent

The demo for the Directions EMEA 2026 session **"Copilot Studio or Agent Designer: Let the Demo Decide"** (Nikola Pančić, Miljan Milosavljević; 27 Oct 2026, Room 253). We build the same agent twice:

| Part | Presenter | Tool | How it reaches Business Central | Review by the project manager |
| --- | --- | --- | --- | --- |
| 1 | Miljan | Business Central agent, built with the AL Agent SDK (this repo) | Business Central pages | Task pane on the Billing Run card |
| 2 | Nikola | Copilot Studio agent | Business Central MCP server, using the `billingRuns` and `billingLines` APIs of this app | Teams |

All demo content is fictional (CRONUS US style). **Never add real customer, company or product names.**

**Status (20 Oct 2026):** version 1.0.7.0 (Application 29.0, runtime 18.0) compiles against BC 29 without analyzer warnings and is published to the bc29 sandbox. All 32 tests pass in the company `CopilotStudioVsBCAgent`, and the demo data imports without errors. The agent ran the September demo end to end: 10 of 10 decisions as expected after the two-pass instructions (1.0.2), both draft invoices right.

## The scenario

On the first day of every month, a job queue entry starts the billing run for the past month. The run lists what each project can invoice; the agent decides each line; Business Central creates one draft sales invoice per customer; the project manager reviews and posts.

**Who does what:**

| Business Central (AL code) | The agent | The project manager |
| --- | --- | --- |
| Which billable planning lines belong to the period, and their amounts | Reads the project's **Billing Notes** (the contract) and compares them with each line's description | Reviews the draft invoices |
| Fixed price: is the milestone reached by the end of the period? | Sets **Invoice** or **Hold**, with a one-sentence reason | Decides the flagged lines (over the cap, milestone) |
| Invoice cap (not to exceed), checked again after every decision | Never invoices a flagged line: Business Central refuses it | Chooses Continue (BC agent) or approves in Teams |
| One draft invoice per customer with the standard *Job Create-Invoice* | Sends the Review Summary that Business Central wrote as its review request | Posts the invoices; the agent never posts |

**How the agent knows what to invoice:** through standard Business Central mechanics plus three fields on the project.

- **Time and Material:** usage posted in the project journal with *Line Type = Billable* creates billable planning lines (*System-Created Entry*). Everything up to the end of the period that is still *to transfer to invoice* is proposed.
- **Fixed Price:** a milestone is a planned billable line on a task. On the task, **Milestone Reached** and its date decide whether it belongs to the period. A milestone planned in the period but not reached is proposed as *Milestone Not Reached*, so the agent can report it.
- **Invoice Cap** (Project Card): lines in date order, on top of what is already on invoices. A line that goes over the cap, and every line after it, is *Exceeds Invoice Cap*. Held lines do not count, so the check is repeated after every decision.
- **Billing Notes** (Project Card): what the contract says in plain words ("Warranty work is not billed"). This is where the agent's judgement comes in.

### Demo data (September 2026)

Four RapidStart packages in `demo/`, built by `tools/build_demo_packages.py`:

| Project | Customer | Billing | Expected result for September |
| --- | --- | --- | --- |
| PRJ-1001 POS rollout support | C91010 Fabrikam Retail | Time & material, cap 11,500 | 4 lines invoiced (10,840). Travel (900) and warranty rework (1,120) held per contract. Gift card extension (1,400) over the cap, so the project manager decides |
| PRJ-1002 Store manager training | C91010 Fabrikam Retail | Time & material | 1 line invoiced (1,200), on the same invoice as PRJ-1001 |
| PRJ-2001 Warehouse redesign | C91020 Tailspin Manufacturing | Fixed price 40,000 (30/50/20 %) | Milestone 1 invoiced (12,000). Milestone 2 is due but not reached, so it is held |
| PRJ-3001 Finance health check | C91030 Proseware, Inc. | Time & material | Only October usage, so there is no invoice |

Draft invoices: **Fabrikam Retail 12,040** (5 lines, 2 projects) and **Tailspin Manufacturing 12,000**. If the project manager invoices the gift card line, the Fabrikam invoice becomes 13,440. Milestones are entered as resource `R-MILESTONE` in unit `PERCENT` (1 % = 400 USD), so the price comes from the resource card like every other line.

## Set up

1. In `App` and `Test`, copy `.vscode/launch.example.json` to `.vscode/launch.json` and set your tenant. `launch.json` is not in the repo.
2. Publish **App**, then **Test** (the test app needs *Library Assert*).
3. **Copilot & agent capabilities**: enable *Project Billing Agent*.
4. Role Center: choose the Project Billing Agent avatar with **+**, set it up and activate it. Every company gets its own agent (and its own monthly job); set it up in each company that should bill. Saving the setup schedules the monthly job queue entry (also available as **Schedule Monthly Billing** on the Billing Runs page). The agent gets its profile and permissions (D365 READ + PBA Agent Edit) from the app.
5. Assign the permission set **PBA Project Billing** to the project managers and to the Copilot Studio connection user.
6. Demo data: `./tools/Import-DemoData.ps1 -Tenant <tenant id>` (Azure CLI signed in). Then open **Project Journals**, batch **BILLING**, and post the usage lines.
7. **Billing Runs** → **Run Billing Now** → September 2026. The action always starts a run for the Project Billing Agent; the Copilot Studio agent starts its own runs only through the `billingRuns` API (BC MCP server), never from Business Central.

### Running the demo again

- The packages can be applied again at any time. Master data and projects go back to the package values.
- **PBA-4-USAGE only once per company:** once its lines are posted, applying it again brings the same lines back, and posting them again doubles the usage. Use `-SkipUsage` after the first time.
- A line on a draft invoice is no longer *to invoice*. To bill September again, delete the draft invoices and the billing run (card or `DELETE billingRuns(id)`).
- Posted invoices cannot be undone: post only in the final recording.

## APIs (for the Copilot Studio agent)

`/api/contoso/projectBilling/v1.0/companies({id})/...`

| Entity | Operations | Notes |
| --- | --- | --- |
| `billingRuns` | GET, POST `{ "periodEnd": "2026-09-30" }`, DELETE, bound action `Microsoft.NAV.createDraftInvoices` | POST creates the run of that month with `handledBy` = Copilot Studio Agent (no BC agent task) and proposes the lines. `reviewSummary` (three sentences) and `invoiceSummary` (numbers, projects) describe the draft invoices; `cardUrl` opens the Billing Run card |
| `billingLines` | GET, PATCH `decision`, `decisionNote` | Also as `billingRuns({id})/billingLines`. Setting `Invoice` on a line whose `check` is not OK is refused, as it is for the BC agent. Shows `decidedByPerson` and `decidedBy` |
| `billingLineDecisions` | GET, PATCH `decision`, `decisionNote`, `decidedBy` | **A person's decision**, for example the project manager's answer on the Teams approval card: may invoice a flagged line and marks it *Decided By Person*. **Not for agents:** keep it out of every MCP server configuration; only the step that handles the person's response calls it. Refused in a BC agent session |

## Tests

32 tests, without an agent and without Copilot credits: `PBA Test Library` replaces the agent task dispatcher with `PBA Mock Task Dispatcher`, and `PBA Session Context` tells the code whether the session is an agent's. The tests use the company's own CRONUS setup and roll back.

| Codeunit | Covers |
| --- | --- |
| 50250 PBA Billing Proposal Tests | time & material usage up to the period end, planned and budget lines ignored, projects without billing method, milestones (reached, due, future, reached after the period), invoice cap and its recalculation after a hold, billing notes and discount |
| 50251 PBA Billing Run Tests | a run becomes one agent task, no task when there is nothing to invoice, no run without an active agent, Copilot Studio runs, run numbers, the period of the monthly job |
| 50252 PBA Billing Decision Tests | the agent and the agent API cannot invoice a flagged line, a person can (in the client and through billingLineDecisions), the person API is refused for agents and for invoiced lines, Decided By names the person, decisions are fixed once invoiced |
| 50253 PBA Draft Invoice Tests | one invoice per customer across projects, held lines stay in the project, undecided lines block the invoices, a second round adds to the customer's invoice, the short review summary |
| 50254 PBA Agent Per Company Tests | one agent per company: an agent of another company does not block a new one |

The test app also contains two read-only developer APIs: `PBA Config Errors API` (RapidStart apply errors, used by `Import-DemoData.ps1`) and `PBA Agent Diagnostics API` (`agentDiagnostics`: the agent's company, its users and its permissions per company).

## Agent instructions

The instructions are in `App/.resources/Instructions/InstructionsV1.txt`. To change them, edit the file, raise the version in `App/app.json` and publish: `PBA Agent Upgrade` sets the new instructions, profile and permissions on the agent. **Instructions version** in the agent setup dialog shows which version the agent has. A task keeps the instructions it was created with.

## Design decisions

- **Business Central does the arithmetic and the mechanical checks; the agent does the judgement.** We learned this in Project Inspector: when the agent added numbers up itself, it was off by 100 USD in some runs.
- **The hard rules are code, not instructions.** A flagged line cannot be invoiced by an agent session or through the API. The agent cannot post.
- **Invoices are created by our action with the standard *Job Create-Invoice*,** not by the agent filling in sales lines.
- **One task per billing run** (External ID = run No.), created by code. With nothing to invoice there is no task and no credits.
- **Business Central writes the review request.** After Create Draft Invoices it fills *Review Summary* in three sentences (draft invoices per customer, what is on hold, what the project manager must decide); the agent sends it unchanged. The first version let the agent compose the message from the lines: correct, but far too long.
- **The same backend for both agents,** so the comparison is about the agent tools, not about different logic.
- **One agent per company.** The setup record names the company; the monthly job and the run of a company go to that company's agent. Its permissions and the users who may use it are limited to that company, so it does not show up in the others. Permissions are never set in `OnUpgradePerDatabase`: `CompanyName()` is blank there, and blank means every company. `Agent.GetAccessControl` fails on BC 29, so the app reads *Access Control* directly.
- **The agent gets every permission it needs from the app** (D365 READ + PBA Agent Edit), as in Project Inspector. Creating a sales invoice also writes the API buffers *Sales Invoice Entity Aggregate* and *Sales Invoice Line Aggregate*, which users get from D365 BASIC; PBA Agent Edit grants them. When BC offers an unrelated permission set in a permission request (it offered EXPENSE AGENT for 5475), fix PBA Agent Edit instead.

## Next steps

1. Run the full round once more (review, gift card to Invoice, Continue, second invoice round), record it and measure its Copilot credits, twice.
2. Nikola: Copilot Studio agent with the MCP configuration for `billingRuns` and `billingLines`, the monthly flow and the Teams approval.
3. Fill in the comparison slides together after both runs.
4. Before the session, upload the app as a per-tenant extension, so that a sandbox update does not remove the dev publish.

## Repository layout

```
CopilotStudioVsBCAgent/
├── CopilotStudioVsBCAgent.code-workspace
├── App/                              Project Billing Agent (50200..50249)
│   ├── .resources/Instructions/InstructionsV1.txt
│   └── src/
│       ├── Agent/                    agent registration (SDK), setup, profile + home page, KPI, install/upgrade
│       ├── Project/                  Billing Method, Invoice Cap, Billing Notes, Milestone Reached
│       ├── Billing/                  billing run and lines, proposal, draft invoices, monthly job, dispatcher
│       ├── Api/                      billingRuns, billingLines
│       └── Permissions/
├── Test/                             tests (50250..50299)
├── demo/                             RapidStart packages PBA-1..4
└── tools/
    ├── build_demo_packages.py        builds demo/*.rapidstart
    └── Import-DemoData.ps1           imports and applies them through the API
```

Conventions: object prefix `PBA`, namespace `Contoso.ProjectBilling` (tests: `Contoso.ProjectBilling.Test`), publisher *Contoso Demo*. Code, captions and instructions are in English (agents support English only).

## License

[MIT](LICENSE)
