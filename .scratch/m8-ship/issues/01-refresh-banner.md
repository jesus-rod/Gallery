# 01 — Refresh error banner visible under the search field

Status: done

The refresh error banner is an overlay at the top of the grid's `ZStack`, so it sits behind the large navigation title and the search field. Move it so it shows below the search field (e.g. `.safeAreaInset(edge: .top)` on the content, or an overlay on the scroll content's top inset), for the feed and Search results, keeping the 3 s auto-dismiss and the `refresh-error` identifier. With the Offline banner shown, the refresh error stacks above it.

## Commit

`fix(ui): show the refresh error below the search field`
