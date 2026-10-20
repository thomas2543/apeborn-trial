# APE BORN trial: app access logic

[![Tests](https://github.com/thomas2543/apeborn-trial/actions/workflows/tests.yml/badge.svg)](https://github.com/thomas2543/apeborn-trial/actions/workflows/tests.yml)

Decides what each user sees in the app (which tabs are unlocked, which tab opens first, which upgrade offer to show) based on what they've bought.

- The logic: [`Sources/AppAccess/GetAppState.swift`](Sources/AppAccess/GetAppState.swift)
- The tests: [`Tests/AppAccessTests/GetAppStateTests.swift`](Tests/AppAccessTests/GetAppStateTests.swift)
- My plan and approach: [`Plan.md`](Plan.md)

## Try it

There's a small clickable demo in [`demo/`](demo/). Download the repo and open `demo/index.html` in any browser. Pick a scenario (or change any input) and a phone mock-up shows which tabs that person gets, where they land and what they're offered.

It's a JavaScript copy of the Swift rules so it can run in a browser. I checked it against the Swift on every combination of inputs (37,044 of them) and they give identical results. The Swift is still the actual solution.

## Checking it works

The tests run automatically on GitHub every time code is pushed. The badge at the top of this page shows the latest result, and the **Actions** tab has the full run.

To run them yourself on a Mac with Xcode 16 or later:

```
swift test
```

### What the tests check

All 29 pass.

**Which purchases count**
- ✔ Emails match even with different capitals and spaces
- ✔ A blank email doesn't match purchases with no email
- ✔ Purchases under someone else's email don't count
- ✔ Expired and refunded purchases don't count
- ✔ Purchases from Shopify, App Store, Google Play and web all count

**Path and first tab**
- ✔ The example from the brief gives the exact expected output
- ✔ First tab matches the chosen path
- ✔ Picking "I'm an Elite member" doesn't unlock Elite on its own
- ✔ New user without an Ultra stays on the new path with no message
- ✔ Only new users get the "We found your order." message
- ✔ New user with a paired device but no order isn't moved
- ✔ New user who owns Elite stays on the new path

**Tabs**
- ✔ A paired device unlocks Remote without an order
- ✔ Elite unlocks Elite and the full Train tab
- ✔ Arnold Pro unlocks the full Train tab only
- ✔ Tabs they don't own are locked, not hidden
- ✔ Remote is hidden on the web, even for Ultra owners

**The uncovered case**
- ✔ Ultra path on the web starts on Train
- ✔ New user moved to Ultra path on the web also starts on Train

**Upgrade offer**
- ✔ Ultra owner gets no offer before their first session
- ✔ Ultra owner gets the Elite trial after their first session
- ✔ Ultra owner with Arnold Pro still only gets the Elite trial
- ✔ A paired device counts as owning an Ultra for offers
- ✔ Elite members get no offer
- ✔ Someone who owns nothing is offered Arnold Pro
- ✔ Someone with Arnold Pro is offered the Ultra
- ✔ The Ultra is still offered on the web
- ✔ Expired Elite member is treated as owning nothing

**Other**
- ✔ Value names match the brief exactly

## Main decisions

I went with Swift rather than TypeScript. Partly that's just preference, I enjoy working in Swift more. But it also fits the product, which is mobile-first. Remote only exists on iOS and Android. I kept the code simple on purpose, a loop and some ifs and switches, so you can find each rule from the brief without hunting for it.

I also kept the scope to what the brief asked for: one function, its tests and these notes. There was time to build more, like billing grace periods, tracking past trials or measuring which offers work. But each of those needs a product decision I'd rather make with the team than guess at, so they're listed under "What I'd add next" instead. The clickable demo is a small optional extra so the rules can be tried without running Swift. The Swift is the actual answer.

For emails I strip out every space, not just the ones at the start and end, and ignore capitals. Real email addresses don't have spaces in them, so it's safe and catches a few more typos. A blank email never matches anything, so a purchase with no email on it can't unlock access.

If someone has paired an Ultra, I treat them as an Ultra owner for offers too, not just for unlocking Remote. Otherwise we'd end up trying to sell an Ultra to someone who's already using one.

I only show "We found your order." when there's an actual order. A new user with a paired device but no order stays on the new path, since there's nothing we've "found".

One thing I noticed while writing the offer logic is that Elite never actually gets offered to the "everyone else" group. The order is Arnold Pro, then Ultra, then Elite, but nobody in that group owns an Ultra (they'd be in the Ultra group if they did). So after Arnold Pro it's always the Ultra. I wrote the code to reflect that rather than leave in a branch that can never run.

Swift naming is `arnoldPro` rather than `arnold_pro`, so each value maps back to the exact name in the brief. `null` in the brief is `nil` in Swift, and `me` is always unlocked.

## The uncovered case

If someone is on the Ultra path and opens the app on the web, the rules say their first tab is Remote. But Remote is hidden on the web, so they'd land on a tab that isn't there. The same thing happens to new users who get moved onto the Ultra path.

I keep them on the Ultra path, since that still drives their offer and message, but open the app on Train. I picked Train over Elite because most Ultra owners won't have Elite, and dropping them on a locked preview feels like a worse first impression.

I also noticed that someone who picks "I'm new" but owns Elite doesn't get moved to the Elite path, because the brief only does that for Ultra owners. I left it as written. They still get Elite and the full Train tab, they just start on Train. I'd want to check whether they should get a similar "we found your membership" moment.

## Written answer

When the website order goes through, the backend saves it and sends a silent push to the user's devices. As a fallback, the app also re-checks purchases whenever it comes back to the foreground. Either way, it pulls the latest purchases, runs `getAppState` again and updates the tabs in place, so there's no reinstall or onboarding. Remote goes from locked to unlocked with a small "Your Ultra is on its way" banner. We don't pull them off whatever they're doing in Train.

If the update fails, nothing gets worse. The app keeps showing what it had, so Remote stays locked, and it retries in the background. The locked Remote tab also gets a "Bought an Ultra? Tap to refresh" link, and if that still finds nothing it offers to try a different email or contact support.

## Questions I'd ask on a real project

1. Should someone with a paired Ultra but no order (a gift, or bought under another email) count as an owner? I've said yes.
2. Should an ex-Elite member who now owns an Ultra get the Elite trial again? Expired Elite purchases are in the data, so we could check, but the brief doesn't ask for it, so right now they would.
3. On iOS, should offers sell Elite and Arnold Pro through in-app purchase, or send people to the website?
4. If the app is offline, do we show the last known access or lock things until we can check?

## What I'd add next

I finished with about 30 minutes of the hour left. I could have built these in that time, but none of them were in the brief, and most need a product decision I'd want to make with the team first:

- A "we couldn't find your membership, want to try another email?" prompt for people who pick the Elite path but have no subscription
- Handling App Store and Google Play grace periods, so paying customers don't get locked out while a card retries
- Tracking whether someone has already had an Elite trial
- Working out what a refunded Ultra means for a device that's still paired
- A "control your Ultra from the iOS or Android app" banner for Ultra owners on the web, since they land on Train with no Remote tab
- Tracking how often each upgrade offer is shown and taken, and testing whether Arnold Pro, then Ultra, then Elite is the best order
- Saving the last result on the phone, so the app opens instantly and still works offline, then refreshing it in the background

## Time spent

About 30 minutes.

## AI tools used

I used Claude Code throughout. It wrote the Swift code, the tests and the clickable demo, and I used it to talk through the rules and edge cases. I chose Swift, decided how to handle the cases the brief doesn't cover, and reviewed what it produced against the brief so I understood exactly what was being shipped. That review caught three things in the first version, all now fixed: a missing `me` tab, value names that didn't match the brief, and a blank email matching purchases that had no email.
