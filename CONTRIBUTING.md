# Contributing

Contributions and review reports are welcome. Keep changes focused on the
native LuCI application under `applications/luci-app-lpac`.

## Before submitting a change

Run:

```sh
applications/luci-app-lpac/tests/run-tests.sh
node applications/luci-app-lpac/tests/frontend.js
node --check applications/luci-app-lpac/htdocs/luci-static/resources/lpac.js
git diff --check
```

The CI validation job additionally runs the official LuCI ESLint configuration,
parses menu and ACL JSON, compiles the ucode backend, and verifies that the POT
template is reproducible. The SDK workflow must build only `luci-app-lpac`.

## Design rules

- Never accept a raw command, executable path, shell fragment, or environment
  variable from the browser.
- Keep all process arguments as separate argv elements.
- Keep the asynchronous download launcher constant and pass request values only
  through positional argv. Never interpolate them into the shell program text
  or add a general-purpose command interface.
- Keep long downloads under `uloop.process()` supervision in a dedicated
  `setsid` process group. Use bounded inherited pipes for the preview protocol;
  close unused child ends so parent death produces EOF. Do not introduce a
  timeout that kills only the wrapper PID.
- Preserve the inheritable shared-lock descriptor for every download descendant.
  Timeout handling must signal the entire process group and wait for its process
  callback before reporting terminal state.
- Do not expose raw lpac stdout, stderr, APDU data, activation codes, EventIDs,
  or HTTP payloads through RPC. The stdout parser may return only explicitly
  allowlisted preview fields and inert bounded icon data.
- Never write live activation codes, confirmation codes, matching IDs, or
  secret-bearing lpac download argv to application logs or test fixtures.
- Keep download status recoverable without storing credentials. The current-job
  query may return only an opaque identifier and sanitized state. Preview
  metadata and decisions require the one-shot token returned only by the owning
  start response; document and test that state does not survive an rpcd restart.
- Keep SM-DS EventIDs and the matching IMEI only in bounded expiring backend
  memory. Return random opaque entry identifiers, consume an entry only after a
  preview process starts, and restore it if process startup fails.
- Persist only an allowlisted, non-secret verification marker after an ambiguous
  start or outcome. Reloads and tabs must not bypass it, corrupt storage must
  fail closed, and only successful visits to both Profiles and Notifications may
  clear it. Never put form values or eUICC/provider data in browser storage.
- Serialize frontend status checks through one in-flight promise. Lost-response
  recovery and periodic polling must not issue concurrent requests whose stale
  results can overwrite newer job state.
- Keep QR file choice and camera capture as separate controls. The normal file
  picker must not carry a capture hint; the camera control may use
  `capture="environment"`, with both paths decoding locally through the same
  bounded image pipeline.
- Normalize only harmless whitespace and Unicode formatting marks surrounding
  an activation code. Continue rejecting such marks inside its fields so that
  normalization cannot silently alter a credential. Bound the raw input before
  scanning its edges so repeated marks cannot create disproportionate rpcd work.
- Do not add modem resets, network restarts, or hardware-specific patches to
  this application.
- Network methods must mirror documented lpac arguments and require the bundled
  transport's peer and hostname verification against OpenWrt's CA bundle. Do not
  add an insecure fallback or claim LuCI independently implements TLS.
- Preserve the license and source provenance of third-party frontend assets.
- Preserve granular read/write rpcd ACLs.
- Add tests for every backend validation or normalization change.
- Test process startup failure, process-group timeout, descendant cleanup,
  inherited-lock release, unknown-outcome mapping, page re-entry, an ambiguous
  start response, external-job monitoring, and transient status failures. A
  job discovered after a lost response must not be attributed to that form
  without a backend nonce; preserve the form and require outcome verification.
  Tests must also prove that no raw child output or request credential reaches
  RPC results, no preparation/install phase precedes approval, and a tab without
  the decision token cannot authorize a discovered job.
- Exercise the actual QR decoder with bounded image fixtures and test both file
  and camera inputs; a decoder stub alone is not regression coverage for the
  image pipeline.
- Use synthetic download parameters or an explicitly public, non-secret test
  profile in automated tests. Never consume a private or single-use activation
  code, and never contact an SM-DP+ service from CI.

## Translations

Only update `po/templates/lpac.pot` in this review repository. An eventual LuCI
contribution must use OpenWrt Weblate for translated `.po` files.

## Commits and DCO

Use a component-prefixed lowercase subject, a meaningful body, and
`git commit -s`. LuCI prefers a first-and-last name and its pull request
template permits a nickname. In either case, use an identity you can certify
and a reachable non-noreply email linked to the GitHub account opening the pull
request.
