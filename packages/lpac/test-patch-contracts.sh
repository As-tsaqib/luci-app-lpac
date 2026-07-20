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
download = (source / "src/applet/profile/download.c").read_text()
curl = (source / "driver/http/curl.c").read_text()
es9p = (source / "euicc/es9p.c").read_text()
events = (source / "euicc/es11_event.c").read_text()
driver_cmake = (source / "driver/CMakeLists.txt").read_text()

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

metadata = download.index(
    "if (euicc_ctx.http._internal.prepare_download_param->b64_profileMetadata)"
)
preview = download.index("if (interactive_preview)", metadata)
prepare = download.index('jprint_progress("es10b_prepare_download", smdp)', preview)
assert metadata < preview < prepare
assert re.search(
    r'jprint_progress_obj\("es8p_meatadata_parse", jmetadata\);\s*}\s*'
    r'if \(interactive_preview\)',
    download,
)
assert 'jprint_progress("preview", "y/n")' in download
assert "answer != 'y' && answer != 'Y'" in download

assert "CURLOPT_SSL_VERIFYPEER, 1L" in curl
assert "CURLOPT_SSL_VERIFYHOST, 2L" in curl
assert "CURLOPT_SSL_VERIFYPEER, 0L" not in curl
assert "CURLOPT_SSL_VERIFYHOST, 0L" not in curl
assert "+ca-bundle" in makefile
assert "HTTP_RESPONSE_MAX_SIZE ((size_t)16U * 1024U * 1024U)" in curl
assert "nmemb > HTTP_RESPONSE_MAX_SIZE / size" in curl
assert "realsize > HTTP_RESPONSE_MAX_SIZE - mem->size" in curl
assert "expanded = realloc(mem->data, mem->size + realsize + 1U)" in curl
assert "mem->data = realloc" not in curl
assert 'fprintf(stderr, "provider response exceeds memory limit' in curl

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

assert "length <= maximum_length" in events
assert "copy[length] = '\\0'" in events
assert "ES11_EVENT_ENTRIES_MAX" in events
assert "PKG_VERSION:=$(LPAC_UPSTREAM_VERSION).444" in makefile
assert "PKG_RELEASE:=1" in makefile
PY
