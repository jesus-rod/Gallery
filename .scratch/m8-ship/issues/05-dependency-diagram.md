# dependency-diagram

Status: done

Draw the module and type dependency diagram (essential-feed diagram mode) for the README; flag coupling problems found.

## Comments

`depgraph.py` run on `Gallery/Sources` and `App`. Its EF-01 flags on `URLSessionHTTPClient` and `CodableFeedStore` are infrastructure in their own GalleryCore folders (Foundation only, ADR 0002), and the EF-03 global lookups are in the composition root or a store, so neither was a real problem. Real finding the script could not see: GalleryUI declared an unused package dependency on GalleryImageLoading, now removed (`cb5bc47`). Type diagrams are hand-corrected for closure-injected seams and live in the README.
