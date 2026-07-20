# luci-app-lpac working contract

## Goal

Finish the native LuCI application so every exposed lpac operation is reliable,
with particular emphasis on profile download from a pasted activation code or a
QR image. The result must be suitable for review in `openwrt/luci` pull request
#8836.

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
- Do not attribute a globally discovered running job to a form unless its start
  response returned that job identifier. After a lost response, preserve the
  form and require Profiles/Notifications verification before any retry.
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
- One controlled download of the supplied disposable Speedtest profile is
  allowed, but only after static tests pass and baseline network/profile state is
  recorded. Stop and report before any broader mutation.

## Repository rules

- Preserve unrelated work and do not rewrite history.
- Do not commit, push, modify the GitHub PR, or publish an artifact without the
  user's explicit instruction after the final report.
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
