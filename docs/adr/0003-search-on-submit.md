# Search runs on submit, not as you type

Unsplash demo apps get 50 API requests per hour, and search-as-you-type spends several requests per Query even with debouncing. Search therefore runs only when the Query is submitted. Search results replace the Editorial feed in the same grid, while the Editorial feed keeps its loaded Pages and scroll position in memory, so cancelling a search returns to it instantly and without a request.

## Consequences

- If the app later gets a production key with a higher Request budget, a debounced search-as-you-type is a contained change in the gallery view model.
- Running out of the Request budget is surfaced to the user as its own state, distinct from a generic network error.
