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

Download status contains only an opaque job identifier and sanitized state.
The current-job query carries no request nonce, so a job found after a lost RPC
response is treated as uncertain: the browser preserves the form and requires
the operator to verify Profiles and Notifications before retrying.

The download supervisor discards lpac stdout and stderr and runs a constant
positional shell launcher in a dedicated process group. Request values remain
separate argv entries and are never interpolated into shell source. The shared
lock descriptor is inherited by the group, and the ten-minute watchdog targets
the whole process group before reporting a sanitized terminal state.

QR image selection and decoding happen locally in the browser; the image is
not uploaded to the router. File choice and camera capture are separate actions,
and only the camera action carries a capture hint. Declared file type (when
available), byte size, pixel count, decoded format, and activation-code fields
are bounded before the RPC call.

The download uses the HTTP backend configured for the installed lpac package.
LuCI does not replace, override, or independently verify its TLS behavior. The
bundled lpac v2.3.0 build disables curl peer and hostname verification. Network
notification processing and SM-DS discovery remain unavailable. Local
notification removal does not notify the provider and must not be confused
with notification processing.

The application does not manage modem, SIM-power, or network-interface
lifecycle. Profile changes can interrupt mobile connectivity.
