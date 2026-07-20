# luci-app-lpac

`luci-app-lpac` is a clean-room LuCI frontend for the official OpenWrt
[`lpac`](https://github.com/openwrt/packages/tree/master/utils/lpac) package.
It uses `/usr/bin/lpac` and `/etc/config/lpac` as provided by that package and
does not bundle a second lpac build, modem manager, or hardware-specific
wrapper.

## Scope

- Show the installed lpac version, compiled drivers, and eUICC information.
- Change the persistent default SM-DP+ address from Overview with an explicit
  confirmation and immediate eUICC readback.
- List, enable, disable, rename, and delete profiles.
- Discover pending orders through SM-DS and open the matching EventID/server
  pair without exposing that matching credential to the browser.
- Download a profile with a complete LPA activation code, a locally decoded QR
  image, manual parameters, or a discovery result, with a mandatory live
  metadata preview before installation.
- Display bounded PNG/JPEG profile icons with a neutral malformed-image fallback.
- List, process to the provider, and explicitly remove pending eUICC
  notifications, including sequence zero.
- Configure the official AT, uqmi, MBIM, and PC/SC backends through validated
  RPC methods.

The Download view accepts a complete LPA string and the upstream SM-DP+,
matching-ID, IMEI, and confirmation-code parameters. It also invokes detailed
`lpac profile discovery -j`; the backend retains each secret EventID and the
original IMEI for five minutes and gives the browser only a random opaque entry
identifier plus its validated display server. Harmless whitespace and Unicode formatting marks
copied around the activation string are removed, while formatting marks inside
the activation data remain invalid. This accommodates copy-and-paste artifacts
without silently changing the credential itself.

Overview displays the default SM-DP+ address read from the eUICC. With write
permission, its Change action accepts only a nonempty host or bracketed IPv6
address with an optional valid port. It shows the old and new values before
calling the typed update RPC and then calls `get_info` again. The UI reports
success only when that readback exactly matches the requested address; a
mismatch or failed readback remains a warning. This is persistent eUICC state,
not UCI configuration, and it determines the server used by a manual download
when its SM-DP+ field is empty. The form intentionally does not expose clearing
the default.

QR images are decoded locally in the browser and are never uploaded to the
router. The view presents two explicit actions: a normal PNG, JPEG, or WebP file
picker without a capture hint, and a separate camera action using
`capture="environment"`. The latter is a browser hint rather than a live video
scanner, so a browser may still present its normal chooser. Both paths share the
same 8 MiB file, 40-megapixel image, bounded-canvas, and activation-code checks.

Activation, matching, EventID, and confirmation values are credentials. They are kept
out of LuCI logs, status records, notifications, and confirmation dialogs, and
raw lpac output and stderr are never returned. User-entered values still exist in browser and RPC
memory and become arguments of the privileged lpac process, where privileged
local process inspection can observe them. They also travel over the transport
used for the LuCI session, so operators should use HTTPS or an otherwise trusted
administrative network.

The network operations use the HTTP backend configured for the installed lpac
package. LuCI does not replace that transport. The required bundled
`lpac 2.3.0.444-r1` package explicitly enables libcurl peer and hostname
verification, depends on OpenWrt's CA bundle, and backports the untrusted server
response hardening from [estkme-group/lpac#444](https://github.com/estkme-group/lpac/pull/444).
A wrong clock, missing trust anchor, invalid chain, or hostname mismatch fails
closed; the UI does not offer an insecure override. Provider response bodies
are capped at 16 MiB with checked allocation arithmetic to protect constrained
router memory before JSON and base64 decoding.

Process sends one pending notification to its provider and optionally removes
the eUICC record only after successful delivery. Process all takes a browser
snapshot and invokes those single operations in sequence, stopping on the first
failure so partial completion is explicit. The backend distinguishes retrieval
failure, unknown provider outcome, and successful provider delivery followed by
local removal failure. The separate Remove action never contacts the provider.
Sequence `0` is supported through the strict uint32 parser backported from and
hardened beyond [estkme-group/lpac#429](https://github.com/estkme-group/lpac/pull/429).

lpac 2.3.0 may report `v0.0.0-unknown` because its generated version header
collides with an applet header and release tarballs lack Git metadata. This is
a dependency build issue rather than evidence that an eUICC operation failed.
Upstream corrected version handling after 2.3.0 in
[estkme-group/lpac#310](https://github.com/estkme-group/lpac/pull/310).

## Compatibility

This release branch requires the bundled `lpac >= 2.3.0.444-r1`. OpenWrt
25.12 requires a compatible backport or custom package, while the stock 24.10
lpac is too old. The application itself is architecture-independent.

When driver discovery succeeds, Settings offers the reported AT, uqmi, MBIM,
or PC/SC backends. Safe AT and MBIM device paths below `/dev` are accepted.
The release branch also manages the upstream MBIM slot-mapping bypass. It is
enabled by default for compatibility and can be disabled for multi-slot
devices that require normal slot selection.
The active uqmi backend remains restricted to `/dev/cdc-wdmN`; the bundled
package fixes client setup so the configured control-device path is honored.

## Architecture

The browser calls a small typed `luci.lpac` rpcd/ucode facade. The facade:

- validates every argument and never accepts a raw command line;
- serializes access to the eUICC with a non-blocking file lock;
- delegates one-shot operations to rpcd `file.exec` using argv arrays;
- runs the longer profile preview/download as a supervised `uloop.process()`
  group with anonymous decision/output pipes;
- exposes a numeric job identifier plus a one-shot decision token only in the
  owning start response;
- validates the official UCI settings before every execution;
- invokes the packaged `/usr/bin/lpac` entrypoint with positional argv;
- parses bounded lpac newline-delimited JSON and returns only normalized
  discovery, preview, profile, and notification fields;
- changes the default SM-DP+ address only through fixed `chip defaultsmdp`
  arguments and verifies it with a fresh normalized `chip info` readback;
- does not return raw APDU, HTTP, activation-code, or confirmation-code data.

The download supervisor uses `/usr/bin/setsid` to place a fixed `/bin/sh`
launcher, the packaged wrapper, lpac, and any helper descendants in one process
group. The launcher program is constant, invokes only its positional `"$@"`
arguments, and never interpolates request values into shell source. stderr is
discarded. stdout is drained through a bounded fragmented-NDJSON parser solely
to detect phases and normalize preview metadata. An anonymous stdin pipe carries
exactly one `y` or `n` decision; inherited unused ends are closed so rpcd death
becomes EOF and cannot approve installation. The child receives only a fixed
system `PATH`.

OpenWrt configures rpcd command execution with a 30-second timeout. The
one-shot RPC methods retain that limit. Profile download instead has its own
operation watchdog and a shorter decision deadline while lpac waits at preview.
On expiry the backend first rejects a pending preview where possible and sends `SIGKILL` to the
entire supervised process group, not merely the OpenWrt shell wrapper, then
waits for the process callback before publishing terminal state. A timeout or
signal after approval is reported as an unknown outcome because it can race
with the final eUICC installation step. Failure or cancellation before approval
cannot install and is reported separately. The application does not change the
system-wide rpcd timeout.

If rpcd itself exits while lpac is waiting for preview, closing the parent-only
pipe writer produces EOF and the patched lpac cancels before PrepareDownload.
The uloop watchdog disappears with rpcd, so a provider cancellation request
that then hangs can keep the inherited operation lock until that process exits
or an administrator intervenes. Subsequent LuCI calls remain busy rather than
racing it; no shell-side sleeper is used because it could retain pipe/lock
descriptors or become orphaned.

One-shot eUICC operations are launched through BusyBox `flock`. Downloads
acquire the same lock directly and deliberately pass the descriptor to the
supervised process group. Before either use, the backend creates or repairs the
lock as a regular root-owned mode-0600 file and rejects non-regular,
multi-linked, or non-root-owned paths. The parent rpcd process closes its copy
after spawning; the kernel lock remains held until every inheriting download
descendant exits or the process group is terminated. If group signalling fails,
the remaining descendant retains the lock and later calls stay busy rather than
racing the eUICC. This locking layer does not perform modem, interface, or
network orchestration.

Serialization applies to calls made through this application. Direct CLI calls
or other managers must voluntarily use `/var/run/luci-lpac.lock` to avoid racing
the LuCI backend.

The status RPC accepts job identifier `0` as a request for the currently running
download. It returns only sanitized phase data unless the caller supplies the
decision token from the owning start response. Only that exact token can reveal
the normalized preview or submit a decision; it is never returned by current-job
discovery or stored in browser site storage. A job found after a lost response
is therefore monitored but conservatively treated as uncertain and can only
cancel at the preview deadline, never be authorized by the rediscovering tab.
As soon as a start response becomes ambiguous, the browser stores a versioned
verification marker in origin-local site storage. The marker contains only its
phase and a fresh generation tag; separate observation flags record whether
Profiles and Notifications were loaded successfully for that generation. A
stale tab therefore cannot clear a newer ambiguity marker. This state never
contains activation data, confirmation data, a profile identifier, or a job
identifier. The submitted form is preserved on the current page, while the retry
block remains across reloads and tabs until the uncertain operation is known to
have stopped and the operator has successfully opened both views. Corrupt or
unavailable site storage fails closed.
A job that was explicitly rejected as busy is identified as an existing operation
and never clears the unsent form.

Job state and the small terminal-history ring are kept only in the rpcd process;
they do not survive an rpcd restart, and a job that completed while no page
retained its identifier cannot be rediscovered as the current job. The shared
kernel lock still prevents a new LuCI operation from racing any surviving
download process.

For one-shot calls, an rpcd timeout can still leave a descendant holding the
inherited BusyBox lock until it exits. Subsequent calls remain busy in that case,
which is safer than assuming cancellation and starting a concurrent eUICC
operation.

The application does not reset modems or network interfaces. Some hardware
requires a SIM power cycle or reconnect after enabling or disabling a profile;
that lifecycle remains the responsibility of the modem/network stack.

The profile refresh flag is an ES10c request indicating that terminal refresh
is required; it is not a modem reboot. On a tested Fibocom L850-GL, enabling it
allowed ModemManager to perform a logical SIM reprobe and restore the cellular
connection in about eleven seconds without USB re-enumeration. Other eUICCs
may reject the flag, so the choice remains explicit rather than universal.

The Profiles view only offers deletion for a profile reported as disabled.
Direct RPC calls bypass that browser state check; the backend relies on the
eUICC to reject deletion of an enabled profile and normalizes the resulting
lpac error.

Settings writes update only the official options managed by this application,
including the merged upstream MBIM skip-slot-mapping option on this release
branch.
Additional package- or vendor-specific UCI options in the named sections are
left intact.

## Testing

The package targets the LuCI `master` branch. Before submission, run:

```sh
npx eslint applications/luci-app-lpac
applications/luci-app-lpac/tests/run-tests.sh
node applications/luci-app-lpac/tests/frontend.js
git diff --check
./build/i18n-scan.pl applications/luci-app-lpac \
  > applications/luci-app-lpac/po/templates/lpac.pot
```

OpenWrt package compilation for this repository is performed only by the
GitHub Actions SDK and bundled-package workflows.

Real-device testing is required for every APDU backend that is claimed in a
pull request. Automated download tests must use synthetic values or an
explicitly public, non-secret test profile and must never contact a provider or
consume a private or single-use activation code. Process
supervision tests must cover descendant termination, inherited-lock lifetime,
timeout outcome reporting, current-job recovery, and the absence of raw child
output. Frontend tests must exercise both the ordinary file picker and the
separate camera-capture path. A live provider download requires explicit owner
approval and before/after profile and network-state observations.

Read and write validation was performed on OpenWrt 25.12.5 with a Fibocom
L850-GL. A disposable Speedtest profile was decoded and installed successfully
through both the separate camera and existing-file QR controls using the prior
download supervisor. This validates that combination only and does not claim
support for every modem, eUICC, backend, or firmware. The new SM-DS,
interactive-preview, TLS-verification, and provider-notification paths still
require separately authorized live checks after their final CI artifact is
reviewed.
