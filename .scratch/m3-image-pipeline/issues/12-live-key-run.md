# 12 — Live run with a real key

Status: ready-for-human

Carried from M1/M2. Add a key to `Config/Secrets.xcconfig`, run the app, confirm the Editorial feed and images load, and that paging works. Note anything odd here.

## Comments

- 2026-11-23: first live run showed the generic error. Cause: the key in `Config/Secrets.xcconfig` was wrapped in quotes, which xcconfig keeps, so Unsplash answered 401. Quotes removed; a direct request returned 200. The README now warns about quotes.
- A 401 currently surfaces as the generic error. Consider a distinct "invalid key" state in M7.
- Still to confirm by the user: the Editorial feed, paging and images with the real key.
- When running with a real key, also submit one Query, scroll to its second Page, and cancel back to the feed. Each search Page costs one request.
- During the same run, open one Photo full screen and close it. It costs no API request: the full-screen Rendition is an image URL, not an API call.
