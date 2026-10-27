# Filing the 3.2(f) appeal — checklist

## Deadline
- File within 30 calendar days of the Pending Termination Notice. Do not wait for a perfect draft.

## How to file
1. Go to App Store Connect → Contact the App Review Team (or the link in the notice).
2. From the drop-down, select **"I would like to appeal an app rejection or app removal"**.
3. Paste `appeal-3-2f.txt` as the written statement.
4. Send from the account holder's email registered to the OMNIAI LTD membership.

## Attach as supporting evidence
- The two prior rejection notices (2.3.6 age rating, 2.3.2 metadata) plus your Resolution Center replies — they show the cure history.
- Before/after of the App Store description showing the subscription disclosure added (the "fixed" description is in `appstore-listing/description.txt`).
- One labelled screenshot showing the "Requires subscription" tag (`screenshots/final-labelled/`).
- A screenshot of the in-app paywall showing prices, auto-renewal wording, and the Terms/Privacy links.
- The Biblica copyright notice as it appears in your in-app Terms of Use.

## What NOT to do
- No legal threats, no mention of counsel, no demands — Apple has broad discretion under the agreement; the appeal's leverage is the clean cure record and the technical facts.
- Do not create new apps or a new developer account while the flag is in place (the notice says new accounts may be terminated too).
- Do not resubmit the app or push new builds while the appeal is pending.
- Do not let the second TestFlight app expire/distribute broadly during the appeal; keep it internal-tester only.

## Expectations (honest framing)
- Apple has wide contractual discretion; a first appeal is frequently answered by a request for more specifics — that is why section 1 asks Apple to name the conduct. Answer follow-ups fast and factually.
- If the first appeal is declined, a second, shorter appeal addressing whatever specifics Apple provides is still possible; a legal professional becomes worth consulting only after that.
- Response times on termination appeals are commonly weeks, not days.

## If reinstated
- Rebuild goodwill: submit the next binary (build 8) with the concession edits from section 4 of the appeal (removed "Apple has to approve" strings, renamed demo tiles) already applied.
- Keep the metadata exactly as cured in `appstore-listing/` unless it genuinely changes.
