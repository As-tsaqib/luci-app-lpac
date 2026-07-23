#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only

set -eu

if [ "$#" -ne 2 ]; then
	printf 'usage: %s PATCHED_LPAC_SOURCE PACKAGE_MAKEFILE\n' "$0" >&2
	exit 2
fi

python3 - "$1" "$2" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1])
makefile = pathlib.Path(sys.argv[2]).read_text()

discovery = (source / "src/applet/profile/discovery.c").read_text()
es9p = (source / "euicc/es9p.c").read_text()
events = (source / "euicc/es11_event.c").read_text()
driver_cmake = (source / "driver/CMakeLists.txt").read_text()
download = (source / "src/applet/profile/download.c").read_text()

assert 'option(LPAC_WITH_APDU_UQMI "Build OpenWrt uqmi APDU backend" ON)' in driver_cmake
assert re.search(
    r"if\(LPAC_WITH_APDU_UQMI\)\s+"
    r'set\(CMAKE_C_FLAGS "\$\{CMAKE_C_FLAGS\} -DLPAC_WITH_APDU_UQMI"\)\s+'
    r"target_sources\(euicc-drivers PRIVATE "
    r"\$\{CMAKE_CURRENT_SOURCE_DIR\}/apdu/uqmi\.c\)\s+endif\(\)",
    driver_cmake,
)

assert discovery.count("getopt(argc, argv, opt_string)") == 1
assert 'static const char *opt_string = "s:i:jh?";' in discovery
assert 'cJSON_AddStringToObject(jevent, "eventId"' in discovery
assert 'cJSON_AddStringToObject(jevent, "rspServerAddress"' in discovery
assert "cJSON_CreateString(smdp_list[i])" in discovery

for field in ("reasonCode", "subjectCode", "subjectIdentifier", "message"):
    assert re.search(
        rf"snprintf\(ctx->http.status\.{field}, "
        rf"sizeof\(ctx->http.status\.{field}\), \"%s\"",
        es9p,
    )
assert not re.search(
    r"strncpy\(ctx->http.status\.(?:reasonCode|subjectCode|subjectIdentifier|message),"
    r"\s*cJSON_GetObjectItem",
    es9p,
)

for applet in ("dump.c", "process.c", "remove.c"):
    text = (source / "src/applet/notification" / applet).read_text()
    assert "notification_parse_sequence_number" in text
    assert "strtoul" not in text

metadata = download.index('jprint_progress_obj("es8p_meatadata_parse", jmetadata)')
preview = download.index("if (interactive_preview)", metadata)
prepare = download.index('jprint_progress("es10b_prepare_download", smdp)', preview)
assert metadata < preview < prepare
assert len(re.findall(r"if \(interactive_preview\)", download)) == 1
assert 'jprint_progress("preview", "y/n")' in download

assert "length <= maximum_length" in events
assert "copy[length] = '\\0'" in events
assert "ES11_EVENT_ENTRIES_MAX" in events

assert "PKG_VERSION:=2.3.0" in makefile
assert "PKG_RELEASE:=4" in makefile
assert "+ca-bundle" not in makefile
PY
