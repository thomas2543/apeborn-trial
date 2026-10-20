# CLAUDE.md

Swift package for the APE BORN app access logic (which tabs, first tab and upgrade offer a user gets).

- Logic: `Sources/AppAccess/GetAppState.swift`
- Types (match the brief's names via raw values): `Sources/AppAccess/Models.swift`
- Tests: `Tests/AppAccessTests/GetAppStateTests.swift` (Swift Testing)
- Run tests: `swift test`
- Demo page: `demo/index.html`, using `demo/getAppState.js`, a JavaScript copy of the Swift logic

## Conventions

- Keep the logic plain: loops, `if` and `switch`. No clever one-liners. Every rule from the brief should be easy to find.
- Every rule or decision gets a test with a plain-English label, e.g. `@Test("Expired and refunded purchases don't count")`.
- If a rule isn't covered by the brief, make a call, comment it in the code and record it in the README.
- Value names must match the brief exactly (`arnold_pro`, `elite_trial`, etc.).
- If the rules in `GetAppState.swift` change, make the same change in `demo/getAppState.js`.
