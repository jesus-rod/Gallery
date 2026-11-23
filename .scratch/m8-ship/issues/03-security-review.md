# security-review

Status: done

/security-review of the project; fix confirmed findings; record the result (even if clean) in Comments.

## Comments

Checked on 2026-11-23 (manual: `/security-review` only covers pending branch changes). No findings to fix.
- Access key: `Config/Secrets.xcconfig` is gitignored, not in the index, and in no commit on any branch (`git log --all`). It reaches the app via `Info.plist` → `UNSPLASH_ACCESS_KEY`; `AuthorizingHTTPClient` hides it from reflection (`customMirror`), and there is no logging anywhere (`print`, `NSLog`, `Logger`). Known limit, for the README: a client-side key ships inside the app bundle; Unsplash's model expects a server proxy for production.
- Transport: HTTPS only, no ATS exceptions.
- Debug paths: `-useStubs`, `-stubOffline`, `-resetOfflineFeed` and both stub clients are inside `#if DEBUG`, so a release build can't be switched to fixtures.
- Input: the Query goes through `URLQueryItem` (percent-encoded); renditions keep existing query items via `URLComponents`.
- Storage: disk-cached renditions are named by SHA-256 of the URL (no path injection); the Offline feed is public photo metadata in Application Support, written atomically. No file protection needed for public data.
