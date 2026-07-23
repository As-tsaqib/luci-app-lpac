# luci-app-lpac

`luci-app-lpac` is a clean-room LuCI frontend for the official OpenWrt
[`lpac`](https://github.com/openwrt/packages/tree/master/utils/lpac) package.
It uses `/usr/bin/lpac` and `/etc/config/lpac` as provided by that package and
does not bundle a second lpac build, modem manager, or hardware-specific
wrapper.

## Scope

- Show the installed lpac version, compiled drivers, essential eUICC details,
  and a collapsed advanced section for normalized capability and certification
  metadata.
- Change the persistent default SM-DP+ address with explicit confirmation and
  exact eUICC readback.
- List, enable, disable, rename, and delete profiles. Embedded profile PNG/JPEG
  icons are displayed when valid; otherwise the list uses a CSS-only SIM-card
  fallback without contacting an external icon service.
- Discover pending profile orders through SM-DS and download one directly, or
  use a complete LPA activation code or locally decoded QR image; every path
  pauses for provider-metadata review before installation.
- Display validated PNG/JPEG icons from installed and pre-install metadata.
- Process all valid provider notifications sequentially or explicitly remove
  every local eUICC notification record.
- Configure the official AT, uqmi, and MBIM backends through validated RPC
  methods, with bounded detection of AT, QMI, and MBIM ports.

The Download view accepts a complete LPA string plus optional IMEI and
confirmation-code values. Manual SM-DP+ and matching-ID fields are intentionally
not exposed. Harmless whitespace and Unicode formatting marks copied around the
activation string are removed, while formatting marks inside the activation
data remain invalid. This accommodates copy-and-paste artifacts without silently
changing the credential itself.

QR images are decoded locally in the browser and are never uploaded to the
router. The view presents two explicit actions: a normal PNG, JPEG, or WebP file
picker without a capture hint, and a separate camera action using
`capture="environment"`. The latter is a browser hint rather than a live video
scanner, so a browser may still present its normal chooser. Both paths share the
same 8 MiB file, 40-megapixel image, bounded-canvas, and activation-code checks.

After validation, Retrieve profile preview starts the supervised lpac request
directly. There is no redundant pre-preview confirmation; the later dialog that
shows provider metadata remains the explicit Install or Cancel decision.

Every request uses `lpac profile download -p`. The backend keeps that same
authenticated process paused at lpac's preview prompt and accepts one explicit
Install or Cancel decision before PrepareDownload. The minimum compatible lpac
package makes this prompt unconditional, so a provider that supplies no
metadata still requires the user to choose `Install without metadata` or
cancel.

Activation, matching, and confirmation values are credentials. They are kept
out of LuCI logs, status records, notifications, and confirmation dialogs.
stderr is discarded; bounded NDJSON stdout is parsed only for the preview
protocol and raw records are never returned. The credentials still exist in
browser and RPC memory and become arguments of the privileged lpac process,
where privileged local process inspection can observe them. They also travel
over the transport used for the LuCI session, so operators should use HTTPS or
an otherwise trusted administrative network.

The resulting network operation uses the HTTP backend configured for the
installed lpac package. LuCI does not replace, override, or independently verify
that transport. In particular, lpac v2.3.0 explicitly disables curl peer and
hostname verification in
[driver/http/curl.c](https://github.com/estkme-group/lpac/blob/v2.3.0/driver/http/curl.c#L90-L91).
An active on-path attacker can therefore impersonate the SM-DP+ endpoint; local
QR decoding does not mitigate this later network boundary. This behavior is
inherited rather than introduced by the LuCI page. The merged
[estkme-group/lpac#444](https://github.com/estkme-group/lpac/pull/444) hardens
handling of an untrusted server response but does not enable TLS verification.

Process all invokes the typed single-sequence backend operation in order and
stops at the first failure so partial completion remains explicit. It may remove
each eUICC record after successful delivery. Retrieval failure, unknown provider
outcome, and successful provider delivery followed by local removal failure are
reported separately. Remove all never contacts a provider; its confirmation
states that discarding unprocessed local records can leave provider state out of
sync. The minimum compatible lpac package supports sequence `0` and rejects
non-canonical or overflowing uint32 arguments.

SM-DS discovery uses detailed lpac output carrying each RSP server and EventID.
The EventID and optional discovery IMEI remain only in rpcd memory behind a
random five-minute capability. The browser receives only that opaque token and
the displayable server address. Starting a discovered download consumes the
capability and passes the hidden EventID into the same owner-only preview
supervisor; it is restored only if safe process startup fails before lpac runs.

lpac 2.3.0 may report `v0.0.0-unknown` because its generated version header
collides with an applet header and release tarballs lack Git metadata. This is
a dependency build issue rather than evidence that an eUICC operation failed.
Upstream corrected version handling after 2.3.0 in
[estkme-group/lpac#310](https://github.com/estkme-group/lpac/pull/310).

## Compatibility

This application requires `lpac >= 2.3.0-r4`, the first OpenWrt-format package
release expected to provide every CLI contract used by the LuCI backend. Older
packages must not be used merely because their binary still reports upstream
version 2.3.0. The application itself is architecture-independent.

When driver discovery succeeds, Settings offers the reported AT, uqmi, or MBIM
backends. Native `driver apdu list` enumeration detects stable AT links below
`/dev/serial/by-id`; the backend supplements common OpenWrt `ttyUSB`, `ttyACM`,
and `wwan…at…` paths through strict patterns. QMI and MBIM detection reads only
canonical `/dev` names and the kernel binding of `cdc-wdmN` devices from sysfs;
it neither executes lpac nor opens the modem. Only the detection button matching
the selected APDU backend is enabled, and no button is enabled without a valid
selection.
The application also manages the MBIM slot-mapping bypass. It is disabled by
default and can be enabled on devices that must use the modem's currently
selected slot without normal slot mapping. The uqmi backend accepts only
canonical `/dev/cdc-wdmN` and `/dev/wwanNqmiN` control paths, and the compatible
lpac package must honor the configured device path.

## Architecture

The browser calls a small typed `luci.lpac` rpcd/ucode facade. The facade:

- validates every argument and never accepts a raw command line;
- serializes access to the eUICC with a non-blocking file lock;
- delegates short one-shot operations to bounded rpcd `file.exec` calls with
  fixed argv and a child watchdog below rpcd's own timeout;
- runs SM-DS discovery, provider-notification delivery, and interactive profile
  downloads as supervised `uloop.process()` jobs with owner capabilities;
- validates the official UCI settings before every execution;
- invokes the packaged `/usr/bin/lpac` entrypoint with positional argv;
- parses bounded lpac newline-delimited JSON and returns discovery results,
  notification outcomes, or normalized preview metadata only to the tab holding
  the corresponding owner capability;
- keeps discovered EventIDs behind expiring one-shot capabilities instead of
  returning matching credentials to the browser;
- invokes the native AT device enumerator with fixed argv and allowlists its
  output; QMI/MBIM detection only reads strict device names and sysfs bindings;
- changes the default SM-DP+ address only through a fixed typed RPC and checks
  the result through a fresh normalized `chip info` readback;
- stores the non-secret profile-refresh preference in the app-owned
  `/etc/config/luci_lpac` file through a dedicated typed RPC and fresh UCI
  readback;
- persists only non-secret replay guards and verification flags in a strict
  root-owned `/etc/config/lpac_safety` journal;
- does not return raw APDU, HTTP, activation-code, confirmation-code, EventID,
  or provider-response data.

Each long-running supervisor uses a fixed `/bin/sh` launcher under
`/usr/bin/setsid`, then starts lpac in a separate child process group. The
launcher invokes only its positional `"$@"` arguments, discards stderr, and
connects the required streams to anonymous pipe descriptors. Request values are
never interpolated into shell source. A liveness pipe makes rpcd ownership
explicit: parent death closes the pipe and the guardian terminates the complete
child group. Normal completion also kills any unexpected descendant before the
wrapper publishes its reserved exit status. The child receives only a fixed
system `PATH`. This design does not use `uloop.task()` or `fs.dup2()`.

The output watcher reconstructs fragmented NDJSON, bounds total bytes, line
length, and line count, and recognizes only the metadata, preview, protected
post-gate phases, and terminal result needed to verify the session. Preview
metadata is allowlisted to ICCID, profile/provider name, profile class, and an
optional bounded PNG/JPEG icon; unknown fields are discarded. Malformed,
truncated, oversized, duplicated, or out-of-order protocol data fails closed.
Installed and preview icons accept only bounded Base64 PNG/JPEG data with a
matching file signature, and the browser repeats those checks before
constructing a fixed-type data URL.

OpenWrt configures rpcd command execution with a 30-second timeout. One-shot
children have an earlier 25-second watchdog, SM-DS discovery has a three-minute
limit, and notification processing has a two-minute limit. Profile download
uses a ten-minute operation watchdog and a two-minute preview-decision window.
A decision timeout first sends a rejection; cancellation gets a short grace
period before the process group is killed. After approval, the operation
receives a fresh ten-minute ceiling. The backend waits for both process exit
and real output EOF before publishing a terminal state. A timeout or protocol
failure after an approval attempt is reported as an unknown outcome because it
can race with installation. Both Profiles and Notifications must then refresh
successfully before the operator can acknowledge the incident. The application
does not change the system-wide rpcd timeout.

One-shot eUICC operations are launched through BusyBox `flock`. Supervised jobs
acquire the same lock directly and deliberately pass the descriptor to their
process group. Before either use, the backend creates or repairs the lock as a
regular root-owned mode-0600 file and rejects non-regular, multi-linked, or
non-root-owned paths. The parent rpcd process closes its copy after spawning;
the kernel lock remains held until every inheriting descendant exits or is
terminated. This locking layer does not perform modem, interface, or network
orchestration.

Serialization applies to calls made through this application. Direct CLI calls
or other managers must voluntarily use `/var/run/luci-lpac.lock` to avoid racing
the LuCI backend.

The direct start response returns a random decision token in addition to the job
identifier. Only that initiating tab may retrieve normalized metadata or submit
one decision. Job identifier `0` remains a public current-job query and never
returns the token or preview. The Download view uses it when entering the page
and after an ambiguous start response, allowing safe monitoring without gaining
approval authority. A job found after a lost response is conservatively treated
as uncertain; the form is preserved and retry stays blocked until the operator
checks Profiles and Notifications. A definitively busy request is treated as an
existing external operation and never clears the unsent form.

Job execution state and the small terminal-history rings are kept only in the
rpcd process. Owner tokens, EventIDs, IMEI values, credentials, and raw output
never enter persistent storage. Before an approved download or provider
notification can have an external effect, however, the backend commits a
minimal replay guard to `/etc/config/lpac_safety`. Those guards survive rpcd and
router restarts, fail closed on a malformed schema, and prevent an uncertain
operation from being submitted again automatically.

The application does not reset modems or network interfaces. Some hardware
requires a SIM power cycle or reconnect after enabling or disabling a profile;
that lifecycle remains the responsibility of the modem/network stack.

The profile refresh flag is an ES10c request indicating that terminal refresh
is required; it is not a modem reboot. On a tested Fibocom L850-GL, enabling it
allowed ModemManager to perform a logical SIM reprobe and restore the cellular
connection in about eleven seconds without USB re-enumeration. Other eUICCs
may reject the flag, so the initial default is off. The first writable
Enable/Disable attempt asks whether future dialogs should request refresh by
default. That preference is stored separately in `/etc/config/luci_lpac`; the
dialog checkbox can override it for one operation without changing the saved
default. Missing, malformed, or unverifiable preference state fails off, and a
read-only session is never prompted to store it.

The Profiles view only offers deletion for a profile reported as disabled.
Direct RPC calls bypass that browser state check; the backend relies on the
eUICC to reject deletion of an enabled profile and normalizes the resulting
lpac error.

Settings writes update only the official options managed by this application,
including the MBIM skip-slot-mapping option. Runtime operations validate the
active backend without being blocked by a typo in an inactive backend; Settings
still validates every managed backend before committing. An invalid existing
configuration is displayed as a bounded recovery form with a warning and is
never reset automatically. Additional package- or vendor-specific UCI options
in the named sections are left intact. The profile-refresh default uses its own
typed write and does not cause `/etc/config/lpac` to be committed when no lpac
setting changed.

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

OpenWrt package compilation should use the matching SDK and official package
feeds for each claimed release and target architecture.

Real-device testing is required for every APDU backend that is claimed in a
pull request. Automated download tests must use synthetic values or an
explicitly public, non-secret test profile and must never contact a provider or
consume a private or single-use activation code. Process
supervision tests must cover descendant termination, inherited-lock lifetime,
timeout outcome reporting, fragmented preview pipes, fail-closed cancellation,
current-job recovery, and the absence of raw child output. Frontend tests must
exercise both the ordinary file picker and the separate camera-capture path as
well as the owner-only preview decision. A live provider download requires
explicit owner approval and before/after profile and network-state observations.

Read and write validation was performed on OpenWrt 25.12.5 with a Fibocom
L850-GL. A disposable Speedtest profile was decoded and installed through both
QR controls using an earlier compatible bundle. This validates that combination
only. SM-DS provider discovery/download, QMI/MBIM port detection, standalone
Remove all, and persistent default-SM-DP+ still require separately authorized
live checks after a final CI artifact is reviewed.
