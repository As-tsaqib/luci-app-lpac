# Bundled lpac package

This directory is a downstream OpenWrt package definition used only by the
bundled GitHub releases of `luci-app-lpac`. It downloads the authoritative
lpac `v2.3.0` source archive instead of vendoring a modified source tree.

The package uses the official OpenWrt version format `2.3.0-r4`. The runtime
`lpac version` output remains the upstream project version `2.3.0`.

Patch provenance:

1. OpenWrt's uqmi backend patch from `openwrt/packages`, made conditional so
   disabling `LPAC_WITH_UQMI` also removes the driver and its runtime dependency.
2. A small downstream correction that makes the uqmi backend use the
   configured `LPAC_QMI_DEV` when allocating its client ID instead of
   constructing a duplicated command fixed to `/dev/cdc-wdm0`.
3. The version handling fix merged upstream as lpac pull request 310.
4. The environment helper fix merged upstream as lpac pull request 308. This
   is required because v2.3.0 otherwise interprets numeric UCI boolean values
   such as `1` as false.
5. The MBIM compatibility work merged as lpac pull request 438 / commit
   `79fcec9d89a247f1a1995f7b4560ea819bfe654f`.
6. Notification sequence-number zero handling from lpac pull request 429.
7. A downstream decimal-only `uint32_t` parser which rejects signs, suffixes,
   whitespace, and overflow instead of truncating notification sequences.
8. A discovery CLI parser fix so SM-DS and IMEI options are both retained.
9. Detailed SM-DS discovery output which preserves each bounded EventID with
   its RSP server while leaving legacy output unchanged.
10. A fail-closed interactive preview gate. `lpac profile download -p` always
   asks for a decision before PrepareDownload, even if no metadata was supplied.
11. The provider-status string hardening merged as lpac pull request 444 /
   commit `3ff35594ec15062a3ed10c3da1c26eb0a13390b8`.

The patch directory intentionally contains exactly these eleven patches.
TLS verification and provider-response memory bounds are deferred to later
work.

The compatibility bundle selects the uqmi APDU backend and keeps the MBIM
slot-mapping bypass disabled by default, matching the official OpenWrt package.
PC/SC compilation is disabled by default and is not managed by the LuCI
application on this branch.
LuCI exposes the bypass at
`Network → eSIM Manager → Settings → MBIM backend`.
Set `lpac.mbim.skip_slot_mapping=1` only on devices that must use the modem's
currently selected slot without querying or changing MBIM Device Slot Mapping.
While the bypass is enabled,
`LPAC_APDU_MBIM_UIM_SLOT` is ignored and a multi-slot modem may expose a
different eUICC than expected. The package does not include modem reset
scripts, ModemManager integration, or the legacy shell management interface.

The staged package retains lpac v2.3.0's curl behavior, which disables peer and
hostname verification. Network-facing operations should therefore be used
only with a trusted provider source and network until the deferred transport
work is ready.
