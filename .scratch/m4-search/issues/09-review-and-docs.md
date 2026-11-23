# 09 — Review, docs and roadmap

Status: done
Blocked by: 01–08

Close M4: quick essential-feed review, check the decision log, update the roadmap and spec. Docs only, unless the review finds a bug (then a separate fix commit first, proposed to the user).

## Files

- Edit: `.scratch/m4-search/spec.md` (`Status: done`, add a `## Review notes` section like M2/M3)
- Edit: `.scratch/roadmap.md`
- Edit: `docs/decision-log.md` (only if a ticket's lines are missing)

## Steps

1. Run `cd Gallery && swift test`, `swift format lint -r Gallery App AppUITests`, and the UI tests command. All green.
2. Check that every ticket 01–08 has `Status: done` and that `docs/decision-log.md` has its `## M4 — Search` lines.
3. Quick review (`/ios-skills:essential-feed review` mode on the M4 diff, `git diff <M4 start>..HEAD`): view model depends only on closures; no `PhotoStream`, endpoint or mapper outside the composition root; no comments; leak checks on every SUT; no Foundation or API error reaching a view. Write the findings as 3–6 bullets in the spec's `## Review notes`, including known edges (for example: the hidden feed can still finish an in-flight load more; a refresh banner from the feed is hidden during search).
4. Roadmap: M4 row → `done (`.scratch/m4-search/`)`, M5 row → `next: write spec`. Replace `## Carried into M4` with `## Carried into M5`, keeping the items that still apply (M3/12 live run, the M7 items, mapper helper, EF-97, synchronized folders, lint command) and adding any new edge from the review.
5. Add to `.scratch/m3-image-pipeline/issues/12-live-key-run.md` under `## Comments`: "When running with a real key, also submit one Query, scroll to its second Page, and cancel back to the feed. Each search Page costs one request."

## Acceptance

- Spec `Status: done` with Review notes; roadmap updated as above; M3/12 comment added.
- `git status` shows only the markdown files above.

## Commit

`docs(scratch): mark M4 done and carry review notes into M5`.
