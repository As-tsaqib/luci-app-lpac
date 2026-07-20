# Security policy

Please use GitHub private vulnerability reporting for security issues. Do not
include live eSIM activation codes, confirmation codes, EIDs, ICCIDs, raw APDU
traces, HTTP debug payloads, or provider credentials in a public report.

## Security boundaries

The browser can invoke only typed `luci.lpac` methods. The backend validates
arguments and UCI data, executes fixed binaries with argv arrays, normalizes
lpac output, and serializes LuCI eUICC operations with
`/var/run/luci-lpac.lock`. The backend requires that lock to be a regular
root-owned mode-0600 file and refuses unsafe lock-path objects.

Direct CLI tools and other managers do not automatically participate in this
lock. They must use the same lock voluntarily if run concurrently.

The Download view accepts credentials through typed RPC and invokes the
installed `lpac profile download` implementation. The LuCI facade does not put
activation or confirmation codes in its logs, status record, or RPC result.
The values nevertheless exist in browser and RPC memory and necessarily become
arguments of the privileged lpac process, where privileged local process
inspection can observe them while the operation runs.

Download status contains only an opaque job identifier, sanitized phase, and,
for the owning request, allowlisted preview metadata. The start response returns
a one-shot decision token which is kept only in page memory. A current-job query
or another tab never receives that token and therefore cannot authorize
installation. A preview with no owner decision expires and is rejected before
PrepareDownload.

A job found after a lost RPC response is treated as uncertain: the browser
preserves the form and requires the operator to verify Profiles and
Notifications before retrying. A versioned browser-local marker persists that
requirement across reloads and tabs. The marker contains only the
pending/verification phase and generation-tagged view checks; activation,
matching, confirmation, profile, notification, decision-token, and job data are
never stored in it. Corrupt or unavailable site storage fails closed.

The download supervisor reads lpac stdout only through a bounded, incremental
NDJSON parser so it can detect the preview gate and normalize metadata. Raw
output and stderr are never returned or logged. Anonymous inherited pipes carry
the one-shot `y`/`n` decision; the child closes the inherited write end so an
rpcd exit produces EOF and fails closed. A constant positional shell launcher
runs in a dedicated process group. Request values remain separate argv entries
and are never interpolated into shell source. The shared lock descriptor is
inherited by the group, and watchdogs target the whole group before publishing
a sanitized terminal state.

If rpcd exits, the parent-only decision writer closes and lpac receives EOF at
the patched preview gate, so it cannot interpret daemon loss as approval. rpcd's
uloop timers also disappear, however. If the provider's subsequent cancellation
cleanup itself hangs, the surviving process can retain the operation lock until
it exits or an administrator intervenes. Later LuCI operations remain `busy`
instead of racing that unknown process. A shell-side watchdog was rejected
because a portable implementation could retain the high-numbered pipe and lock
descriptors or orphan its sleeper, weakening these guarantees.

SM-DS detailed discovery returns an EventID required as the matching credential
for its RSP server. The backend replaces each EventID with a random opaque entry
identifier and keeps the EventID and discovery IMEI only in bounded memory for
five minutes. Starting the matching preview consumes it; neither value is sent
to browser storage, status, or logs.

QR image selection and decoding happen locally in the browser; the image is
not uploaded to the router. File choice and camera capture are separate actions,
and only the camera action carries a capture hint. Declared file type (when
available), byte size, pixel count, decoded format, and activation-code fields
are bounded before the RPC call.

The bundled `lpac 2.3.0.444-r1` package requires OpenWrt's CA bundle and enables
libcurl certificate-chain and hostname verification. Download, SM-DS discovery,
and provider-notification processing fail closed when TLS cannot be verified;
there is no insecure UI fallback. Its response accumulator checks arithmetic,
retains the prior allocation on failure, and rejects bodies above 16 MiB before
JSON/base64 processing can amplify memory use. LuCI still relies on the
installed lpac HTTP backend and does not implement a second transport.

Notifications are processed one sequence at a time. A batch stops at the first
failure. Retrieval failure, unknown provider-delivery outcome, and successful
provider delivery followed by local removal failure are distinct sanitized
states so the UI does not blindly resend. Local Remove never contacts the
provider. Profile icons are accepted only as bounded canonical PNG/JPEG data;
SVG, external URLs, type/magic mismatches, and browser-decoded dimensions above
64 by 64 are rejected or rendered as a neutral fallback.

The application does not manage modem, SIM-power, or network-interface
lifecycle. Profile changes can interrupt mobile connectivity.
