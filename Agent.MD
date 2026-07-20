# luci-app-lpac working contract

## Goal

Finish the native LuCI application so every management operation it exposes is
reliable. Downloads must support pasted activation codes, separate camera and
file QR inputs, SM-DS discovery, provider metadata preview before installation,
and direct review of discovered orders. Profiles must render bounded safe icons,
and pending notifications must be processable with explicit partial/unknown
outcome handling. The result must be suitable for review in `openwrt/luci` pull
request #8836 once its lpac package dependency is available upstream.

## Sources of truth

1. Current lpac CLI behavior and source code.
2. Current OpenWrt LuCI/rpcd conventions and reviewer feedback on PR #8836.
3. Reproducible tests and observations from the target router.
4. `luci-app-lpac-manager` only as a behavioral reference; do not copy its shell
   wrapper or AGPL-derived UI into this Apache-2.0 application.
5. `memory.md` is historical context, not verified truth.

## Required outcomes

- Audit all frontend RPC calls, backend argument construction, ACLs, menu data,
  configuration handling, locking, timeout behavior, and secret handling.
- Accept valid LPA activation strings copied from common apps, including harmless
  surrounding invisible Unicode formatting characters.
- Present separate, explicit QR actions for camera capture and image-file choice.
- Decode QR images locally in the browser; never upload the image to the router.
- Keep activation and confirmation secrets out of logs, status objects, command
  output, notifications, and confirmation dialogs.
- Make Downloads survive normal UI refresh/re-entry where technically possible,
  report terminal state accurately, and prevent concurrent eUICC operations.
- Persist only non-secret verification state across reloads when a download
  outcome is uncertain; never persist activation, matching, or confirmation
  credentials. Require successful checks of both Profiles and Notifications
  before allowing a retry.
- Keep status requests single-flight so polling and lost-response recovery cannot
  apply stale responses out of order.
- Do not attribute a globally discovered running job to a form unless its start
  response returned that job identifier. After a lost response, preserve the
  form and require Profiles/Notifications verification before any retry.
- Bound raw input before normalization and test real supervisor, process-group,
  signal, and inherited-lock behavior in CI without contacting an eSIM provider.
- Preserve the SM-DS EventID needed for a discovered order only in bounded,
  expiring backend memory. Give the browser an opaque entry identifier and the
  validated display server, never the EventID or discovery IMEI.
- Require every download path to enter the same live lpac preview session and
  receive an explicit one-shot decision before PrepareDownload. Missing metadata
  must still stop for confirmation; a lost owner response must never authorize
  installation.
- Accept profile icons only as canonical, bounded PNG/JPEG data with matching
  magic and browser-side dimension checks. Never render SVG, HTML, or an external
  icon URL supplied by a profile.
- Process provider notifications one sequence at a time, including sequence zero.
  Stop a batch on the first failure and distinguish retrieval failure, unknown
  provider outcome, and successful delivery followed by local removal failure.
- Require the bundled lpac transport to verify the provider certificate chain
  and hostname against OpenWrt's CA bundle. Do not offer an insecure fallback.
- Bound provider response allocation with checked arithmetic before JSON or
  base64 processing can amplify memory use on a constrained router.
- Treat the default SM-DP+ address as persistent eUICC state, not a LuCI/UCI
  setting. Expose its nonempty typed update only in Overview, require a second
  old/new confirmation, and claim success only after exact `get_info` readback.
- Inventory lpac applets explicitly. Destructive chip purge and raw notification
  dump/replay are intentionally out of scope for a general LuCI management UI;
  do not expose them merely to claim every diagnostic applet is present.
- Add regression coverage for every bug fixed and run LuCI lint, ucode tests,
  package builds, and proportionate router validation.

## Router safety boundary

Target: `root@192.168.1.1`.

- Read-only inspection is allowed.
- Do not delete, enable, disable, rename, or otherwise mutate existing eSIM
  profiles or notifications.
- Do not reset/restart/reconfigure the modem, ModemManager, netifd, interfaces,
  firewall, routing, DNS, Wi-Fi, Dropbear, or the router.
- Do not install/upgrade/remove packages or write configuration unless the user
  gives fresh, specific approval after reviewing the proposed artifact.
- The previously authorized disposable Speedtest download has already completed
  successfully through both camera and file QR paths. Do not perform another
  download, SM-DS discovery, preview session, provider notification processing,
  notification removal, or other live mutation without fresh specific approval.

## Repository rules

- Preserve unrelated work and do not rewrite history.
- Do not commit, push, modify the GitHub PR, or publish an artifact without the
  user's explicit instruction after the final report.
- Compile OpenWrt packages only in GitHub Actions. Local work is limited to
  syntax, lint, unit/integration tests, and host builds used to validate the lpac
  patch series; never run a local OpenWrt package build.
- Prefer typed rpcd/ucode methods and fixed argv arrays. Never interpolate user
  input into shell source.
- Keep this application hardware-neutral; modem recovery belongs elsewhere.
- Treat provider/network responses as untrusted and expose only allowlisted
  status/error data.

## Verification gate

Work is not ready until the source is clean under `git diff --check`, JSON and JS
syntax checks pass, official LuCI ESLint/POT checks pass, backend/frontend tests
pass on supported ucode variants, package builds succeed, and router observations
match the claimed behavior. Record any untested backend or unresolved risk in the
handoff instead of guessing.
