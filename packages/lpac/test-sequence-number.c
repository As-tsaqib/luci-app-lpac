// SPDX-License-Identifier: AGPL-3.0-only

#include "src/applet/notification/notification_sequence.h"

#include <stdint.h>
#include <stdio.h>

struct valid_case {
  const char *text;
  uint32_t expected;
};

int main(void) {
  static const struct valid_case valid[] = {
      {"0", 0U},
      {"00", 0U},
      {"1", 1U},
      {"00042", 42U},
      {"4294967295", UINT32_MAX},
  };
  static const char *const invalid[] = {
      "",    " ",  " 0",  "0 ",         "+0",          "-0",
      "0x0", "1x", "1\n", "4294967296", "99999999999", "18446744073709551615",
  };

  for (size_t i = 0; i < sizeof(valid) / sizeof(valid[0]); i++) {
    uint32_t parsed = UINT32_MAX;
    if (!notification_parse_sequence_number(valid[i].text, &parsed) ||
        parsed != valid[i].expected) {
      fprintf(stderr, "valid notification sequence rejected: %s\n",
              valid[i].text);
      return 1;
    }
  }

  for (size_t i = 0; i < sizeof(invalid) / sizeof(invalid[0]); i++) {
    uint32_t parsed = 123U;
    if (notification_parse_sequence_number(invalid[i], &parsed)) {
      fprintf(stderr, "invalid notification sequence accepted: %s\n",
              invalid[i]);
      return 1;
    }
  }

  if (notification_parse_sequence_number(NULL, NULL) ||
      notification_parse_sequence_number("0", NULL)) {
    fputs("notification sequence parser accepted a NULL argument\n", stderr);
    return 1;
  }

  return 0;
}
