# Bundled lpac package

This directory is a downstream OpenWrt package definition used only by the
bundled GitHub releases of `luci-app-lpac`. It downloads the authoritative
lpac `v2.3.0` source archive instead of vendoring a modified source tree.

The package version is `2.3.0.444-r1` so it cannot be confused with the
official OpenWrt `2.3.0-rN` package. The runtime `lpac version` output remains
the upstream project version `2.3.0`.

Patch provenance:

1. OpenWrt's uqmi backend patch from `openwrt/packages`, made conditional so
   disabling `LPAC_WITH_UQMI` also removes the driver and its runtime dependency.
2. A small downstream correction that makes the uqmi backend use the
   configured `LPAC_QMI_DEV` when allocating its client ID instead of
   constructing a duplicated command fixed to `/dev/cdc-wdm0`.
3. The environment helper fix merged upstream as lpac pull request 308. This
   is required because v2.3.0 otherwise interprets numeric UCI boolean values
   such as `1` as false.
4. The version handling fix merged upstream as lpac pull request 310.
5. The MBIM compatibility work merged as lpac pull request 438 / commit
   `79fcec9d89a247f1a1995f7b4560ea819bfe654f`.
6. Notification sequence-number zero handling from lpac pull request 429,
   followed by a downstream decimal-only `uint32_t` parser which rejects
   signs, suffixes, whitespace, and overflow instead of truncating them.
7. A discovery option parser correction and a backward-compatible detailed
   discovery mode. `lpac profile discovery -j` returns objects containing
   both `eventId` and `rspServerAddress`; the default output remains an array
   of address strings.
8. A fail-closed interactive preview gate. `lpac profile download -p` always
   waits for explicit `y`/`Y` approval before `prepareDownload`, including
   when a provider supplies no profile metadata.
9. The provider-status string hardening merged as lpac pull request 444 /
   commit `3ff35594ec15062a3ed10c3da1c26eb0a13390b8`.
10. TLS peer and hostname verification for the curl backend. The package
    explicitly depends on OpenWrt's `ca-bundle`; libcurl uses its configured
    `/etc/ssl/certs/ca-certificates.crt` system trust store.
11. Checked curl response accumulation with a 16 MiB body limit. This prevents
    integer overflow, lost realloc pointers, and unbounded memory consumption
    by a TLS-valid but faulty or hostile provider.

The compatibility bundle enables the MBIM slot-mapping bypass by default.
It also selects the MBIM APDU backend by default for new installations.
LuCI exposes the bypass at
`Modem → eSIM Manager → Settings → MBIM backend`.
Set `lpac.mbim.skip_slot_mapping=0` on devices that require lpac to query and
change the MBIM Device Slot Mapping. While the bypass is enabled,
`LPAC_APDU_MBIM_UIM_SLOT` is ignored and a multi-slot modem may expose a
different eUICC than expected. The package does not include modem reset
scripts, ModemManager integration, or the legacy shell management interface.

Provider connections now fail closed when the certificate chain or requested
hostname cannot be verified. Devices with an incorrect clock or a missing CA
store must fix that system condition; disabling TLS verification is not a
supported fallback. Provider bodies above 16 MiB are also rejected as a
resource-safety boundary; this still permits roughly 12 MiB of base64-decoded
profile-package data.
