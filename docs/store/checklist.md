# Store submission checklist

## Accounts and identity (owner)
- [ ] Google Play developer account and the publisher name for the listing
- [ ] A contact e-mail for the privacy policy and the listing
- [ ] Upload key and Play App Signing set up (the bundle must be signed with the release key)

## Build
- [ ] `flutter build appbundle --release --split-per-abi` is not used for Play: upload one `.aab` (`flutter build appbundle --release`)
- [ ] Size check: the engine files make the download large (see `docs/perf/nnue-size.md` when it exists)
- [ ] Version name and code from `pubspec.yaml`

## Listing
- [ ] Title, short and full description in en, ru, tk (`listing_*.md`; Turkmen needs a native read)
- [ ] Privacy policy published at a public URL (`privacy-policy.md`)
- [ ] App icon 512×512 and feature graphic 1024×500
- [ ] Phone screenshots (at least 4): Play home, a game, Review, Learn map, a lesson, Puzzles

## Forms
- **Data safety:** no data collected, none shared; no data is sent off the device (the release build has no internet permission).
- **Content rating:** no violence, gambling, user-generated content or communication between users; suitable for everyone.
- **Ads:** none. **Target audience:** all ages (not designed for children only).
- **App access:** everything is available without sign-in.

## If crash reporting is added later
- [ ] Add the internet permission, update the privacy policy and the data-safety answers first.
