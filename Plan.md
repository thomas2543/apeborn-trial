# Plan and approach

How I broke the problem down and what I decided before and during the build.

## The rules in my own words

Someone opens the app, picks a path and gives their email. We look at what they've actually paid for, and that decides what they can use. The path they picked only decides where they land and how we talk to them. It never unlocks anything on its own.

## Approach

One function, five steps, in the order a person would reason about it:

1. **What do they own?** Only active purchases under their email count, from any store. Clean the email first (no spaces, lowercase).
2. **Which path?** Whatever they picked, unless they picked "new" and have an Ultra order. Then move them to Ultra and say "We found your order."
3. **Which tabs?** Start everything at its lowest level, then unlock based on what they own. Remote is hidden on the web no matter what.
4. **Which tab first?** Comes from the path, with one exception: Remote can't be first on the web, because it's hidden there (see gaps below).
5. **Which offer?** At most one. Elite members get nothing, Ultra owners get the Elite trial once they've done a session, everyone else gets the first thing they don't own. Working through this, I noticed Elite can never be reached in that last group: nobody in it owns an Ultra, so after Arnold Pro the offer is always the Ultra.

I wrote it in Swift and kept it deliberately simple, so anyone reading it can match each block to a rule in the brief.

## Cases I wanted to be careful with

- Emails with different capitals or spaces, and blank emails
- Purchases from other people's emails mixed in
- Expired and refunded purchases
- Someone picking "I'm an Elite member" without a subscription
- A paired device with no order behind it
- The Elite trial before and after the first session
- Every step of the offer order

## Gaps in the rules

- **Ultra path on the web.** First tab would be Remote, but Remote is hidden there. Decision: open on Train.
- **"New" user who owns Elite.** The brief only moves Ultra owners. Decision: leave them on the new path, as written.
- **Paired device but no order.** Decision: treat them as an Ultra owner for Remote and offers, but don't show "We found your order."

## Scope

Stick to what the brief asks for: the function, its tests and the notes. Things like billing grace periods, trial history and measuring which offers work need product decisions, so they go under "What I'd add next" rather than being guessed at. The one extra is a small clickable demo, so the rules can be tried without running Swift.

## Testing

One test per rule and per tricky case, each with a plain-English name so the results read like a checklist. The tests also run automatically on GitHub on every push.
