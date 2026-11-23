# Gallery

## Overview

## Setup

Requirements: Xcode 16 or later, iOS 17 or later.

1. Create an Unsplash app at <https://unsplash.com/oauth/applications> and copy its **Access Key**.
2. Create the local secrets file, which is gitignored:
   ```sh
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
3. Replace `your-unsplash-access-key` in `Config/Secrets.xcconfig` with your key.
4. Open `Gallery.xcodeproj` and run the `GalleryApp` scheme.

Run the logic tests without a simulator:

```sh
cd Gallery && swift test
```

## Architecture

## Technical choices

## Performance

## Testing

## Trade-offs and improvements

## AI usage

## Time log
