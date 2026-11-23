# 06 — Search fixtures for `-useStubs`

Status: ready-for-agent
Blocked by: 02

`StubHTTPClient` answers `/search/photos` from bundled fixtures, so search works offline under `-useStubs` and the XCUITests (ticket 08) never touch the network. "cats" has two Pages (30 + 10 Photos, `total_pages: 2`); every other Query, and any missing page, answers zero results. No unit test: the app target has no unit test target (same as M2/07); ticket 08 covers this end to end.

## Files

- New: `App/Stubs/Fixtures/search-cats-page-1.json`, `App/Stubs/Fixtures/search-cats-page-2.json` (generated, see below)
- Edit: `App/Stubs/StubHTTPClient.swift`
- Edit: `docs/decision-log.md`

## Fixtures

The search response is `{"total": Int, "total_pages": Int, "results": [<the same photo object as the Editorial fixtures>]}` (`SearchPhotosMapper` decodes `total_pages` and `results`; `total` is ignored but kept for realism). Generate both files from the Editorial template so the photo shape stays identical. Run from the repo root (a one-off, not committed):

```sh
python3 - <<'EOF'
import json, pathlib
d = pathlib.Path("App/Stubs/Fixtures")
template = json.loads((d / "editorial-page-1.json").read_text())[0]
def photo(n):
    p = json.loads(json.dumps(template))
    fid = f"fixture-{100 + n}"
    p["id"] = fid
    p["description"] = f"Cat fixture description {n}"
    p["alt_description"] = f"Cat fixture photo {n}"
    p["urls"] = {k: v.replace("fixture-01", fid) for k, v in p["urls"].items()}
    return p
for page, numbers in {1: range(1, 31), 2: range(31, 41)}.items():
    body = {"total": 40, "total_pages": 2, "results": [photo(n) for n in numbers]}
    (d / f"search-cats-page-{page}.json").write_text(json.dumps(body, indent=2) + "\n")
EOF
```

Ids `fixture-101`…`fixture-140` keep `StubImageHTTPClient` working (it maps `fixture-NN` to one of the four bundled JPEGs) and never collide with the Editorial ids.

## Shape

```swift
func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)   // unchanged guard, returns (fixture(for: url), response)

private func fixture(for url: URL) -> Data {
    let page = queryValue(named: "page", in: url) ?? "1"
    guard url.path().hasSuffix("search/photos") else {
        return bundledJSON(named: "editorial-page-\(page)") ?? Data("[]".utf8)
    }
    let query = (queryValue(named: "query", in: url) ?? "").lowercased()
    return bundledJSON(named: "search-\(query)-page-\(page)") ?? Self.noSearchResults
}

private func queryValue(named name: String, in url: URL) -> String?
private func bundledJSON(named name: String) -> Data?
private static let noSearchResults = Data(#"{"total":0,"total_pages":0,"results":[]}"#.utf8)
```

`queryValue` replaces today's `page(of:)`; `bundledJSON` replaces `fixture(forPage:)`.

## Acceptance

- `xcodebuild build …` succeeds; both JSON files are valid (`python3 -m json.tool App/Stubs/Fixtures/search-cats-page-1.json > /dev/null`).
- Existing XCUITests still pass (Editorial routing unchanged): `xcodebuild test … -only-testing:GalleryAppUITests`.
- Search routing is proven by ticket 08's tests (`test_submittingAQuery_showsItsSearchResults`, `test_searchingWithNoResults_showsTheQueryInTheEmptyState`).

## Decision log

- `-useStubs` also answers search: `search-<query>-page-N.json` for "cats" (two Pages, `total_pages: 2`), zero results for any other Query, so the XCUITests stay offline.

## Commit

`feat(app): stub search responses with bundled fixtures`.
