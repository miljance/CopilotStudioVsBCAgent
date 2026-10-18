# Project Billing Agent – notes for Claude Code

- Start with `README.md`: scenario, who decides what, demo data and expected result, APIs, tests, next steps.
- Two AL projects: `App/` (50200..50249) and `Test/` (50250..50299). Open `CopilotStudioVsBCAgent.code-workspace`. The sandbox bc29 also runs Project Inspector (50100..50199), so keep to these ranges.
- Work test-first: add or change a test in `Test/`, see it fail, then change `App/`. Tests run in the company `CopilotStudioVsBCAgent`.
- Never put real customer, company or product names in code, data or instructions. Demo data is fictional (CRONUS US).
- Business Central computes every amount and enforces the rules (flagged lines, no posting); the agent only decides Invoice/Hold and writes the review. Keep it that way for both agents (BC agent and Copilot Studio through the APIs).
- Demo data lives in `tools/build_demo_packages.py`; rebuild `demo/*.rapidstart` from it, never edit the packages by hand. If the data changes, update the expected results in README and in the deck (OneDrive folder DirectionsEMEA2026, `_build/build_csvsbc.py`).
- Every agent run is a real agent task and uses Copilot credits: say how many runs, and ask first.
