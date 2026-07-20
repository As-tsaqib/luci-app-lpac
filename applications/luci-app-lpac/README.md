# luci-app-lpac

`luci-app-lpac` is a clean-room LuCI frontend for the official OpenWrt
[`lpac`](https://github.com/openwrt/packages/tree/master/utils/lpac) package.
It uses `/usr/bin/lpac` and `/etc/config/lpac` as provided by that package and
does not bundle a second lpac build, modem manager, or hardware-specific
wrapper.

## Initial scope

- Show the installed lpac version, compiled drivers, and eUICC information.
- List, enable, disable, rename, and delete profiles.
- Download a profile with a complete LPA activation code, a locally decoded QR
  image, or the non-interactive manual parameters supported by upstream lpac.
- List and remove pending eUICC notifications.
- Configure the official AT, uqmi, MBIM, and PC/SC backends through validated
  RPC methods.

The Download view mirrors `lpac profile download`: it accepts a complete LPA
string and the non-interactive upstream SM-DP+, matching-ID, IMEI, and
confirmation-code parameters. Harmless whitespace and Unicode formatting marks
copied around the activation string are removed, while formatting marks inside
the activation data remain invalid. This accommodates copy-and-paste artifacts
without silently changing the credential itself.

QR images are decoded locally in the browser and are never uploaded to the
router. The view presents two explicit actions: a normal PNG, JPEG, or WebP file
picker without a capture hint, and a separate camera action using
`capture="environment"`. The latter is a browser hint rather than a live video
scanner, so a browser may still present its normal chooser. Both paths share the
same 8 MiB file, 40-megapixel image, bounded-canvas, and activation-code checks.

Activation, matching, and confirmation values are credentials. They are kept
out of LuCI logs, status records, notifications, and confirmation dialogs, and
lpac stdout and stderr are discarded. They still exist in browser and RPC
memory and become arguments of the privileged lpac process, where privileged
local process inspection can observe them. They also travel over the transport
used for the LuCI session, so operators should use HTTPS or an otherwise trusted
administrative network.

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

Removing a pending notification only deletes its record from the eUICC. It
does not contact the provider or undo the profile operation, and discarding an
unprocessed record can leave the provider state out of sync. Network
notification processing and its bulk Process action remain outside the current
application scope. The packaged bulk implementation can complete only part of
a batch before an error and does not guarantee the grouping and ordering
required by SGP.22.

Notification sequence `0` is valid and is displayed, but its explicit Remove
action is disabled. The packaged lpac 2.3.0 reports false success without
removing that sequence. Upstream fixed this after 2.3.0 in
[estkme-group/lpac#429](https://github.com/estkme-group/lpac/pull/429), but the
fix is not yet present in the OpenWrt package; see also
[estkme-group/lpac#430](https://github.com/estkme-group/lpac/issues/430).

lpac 2.3.0 may report `v0.0.0-unknown` because its generated version header
collides with an applet header and release tarballs lack Git metadata. This is
a dependency build issue rather than evidence that an eUICC operation failed.
Upstream corrected version handling after 2.3.0 in
[estkme-group/lpac#310](https://github.com/estkme-group/lpac/pull/310).

## Compatibility

This release branch requires the bundled `lpac >= 2.3.0.438-r2`. OpenWrt
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
- runs the longer profile download as a supervised `uloop.process()` process
  group and exposes only a short-lived numeric status identifier;
- validates the official UCI settings before every execution;
- invokes the packaged `/usr/bin/lpac` entrypoint with positional argv;
- parses lpac newline-delimited JSON and returns a normalized response;
- does not return raw APDU, HTTP, activation-code, or confirmation-code data.

The download supervisor uses `/usr/bin/setsid` to place a fixed `/bin/sh`
launcher, the packaged wrapper, lpac, and any helper descendants in one process
group. The launcher program is constant, invokes only its positional `"$@"`
arguments, and redirects stdout and stderr to `/dev/null`; request values are
never interpolated into shell source. The child receives only a fixed system
`PATH`. This design does not use `uloop.task()`, `fs.dup2()`, or a
version-dependent redirection fallback.

OpenWrt configures rpcd command execution with a 30-second timeout. The
one-shot RPC methods retain that limit. Profile download instead has its own
ten-minute `uloop.timer()` ceiling. On expiry the backend sends `SIGKILL` to the
entire supervised process group, not merely the OpenWrt shell wrapper, then
waits for the process callback before publishing terminal state. A timeout or
signal-style supervisor failure is reported as an unknown outcome because it
can race with the final eUICC installation step; the Profiles view remains the
authoritative place to verify whether a profile was installed. The application
does not change the system-wide rpcd timeout.

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
download. The Download view uses it when entering or refreshing the page and
after an ambiguous start response, allowing it to monitor the active process
without retaining the activation credential in backend status. The status does
not contain a request nonce, so a job found after a lost response is
conservatively treated as uncertain rather than assumed to belong to that form.
The form is preserved and retry stays blocked until the operator checks Profiles
and Notifications and returns to the page. A job that was explicitly rejected
as busy is identified as an existing operation and never clears the unsent form.

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
make package/luci-app-lpac/clean package/luci-app-lpac/compile V=s
```

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
L850-GL and a modem-specific lpac 2.3.0-r2 package. This validates that
combination only and does not claim support for every modem, eUICC, backend, or
firmware. It does not by itself validate the newer download supervisor or the
mobile file-versus-camera interaction; those require the controlled tests
described above.
