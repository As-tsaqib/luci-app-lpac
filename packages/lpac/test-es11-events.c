// SPDX-License-Identifier: AGPL-3.0-only

#include "euicc/es11_event.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static cJSON *make_entry(const char *event_id, const char *server_address) {
  cJSON *entry = cJSON_CreateObject();

  if (entry == NULL ||
      (event_id != NULL &&
       cJSON_AddStringToObject(entry, "eventId", event_id) == NULL) ||
      (server_address != NULL &&
       cJSON_AddStringToObject(entry, "rspServerAddress", server_address) ==
           NULL)) {
    cJSON_Delete(entry);
    return NULL;
  }
  return entry;
}

static int expect_rejected(cJSON *entries, const char *description) {
  struct es11_event_entry *parsed = NULL;
  int result = es11_event_entries_parse(&parsed, entries);

  cJSON_Delete(entries);
  if (result == 0 || parsed != NULL) {
    fprintf(stderr, "invalid SM-DS entries accepted: %s\n", description);
    es11_event_list_free_all(parsed);
    return 1;
  }
  return 0;
}

static cJSON *single_entry(const char *event_id, const char *server_address) {
  cJSON *entries = cJSON_CreateArray();
  cJSON *entry = make_entry(event_id, server_address);

  if (entries == NULL || entry == NULL) {
    cJSON_Delete(entries);
    cJSON_Delete(entry);
    return NULL;
  }
  cJSON_AddItemToArray(entries, entry);
  return entries;
}

int main(void) {
  struct es11_event_entry *parsed = NULL;
  cJSON *entries = single_entry("event-0", "rsp.example.test");

  if (entries == NULL || es11_event_entries_parse(&parsed, entries) != 0 ||
      parsed == NULL || strcmp(parsed[0].event_id, "event-0") != 0 ||
      strcmp(parsed[0].rsp_server_address, "rsp.example.test") != 0 ||
      parsed[1].event_id != NULL || parsed[1].rsp_server_address != NULL) {
    fputs("valid detailed SM-DS entry was not copied correctly\n", stderr);
    cJSON_Delete(entries);
    es11_event_list_free_all(parsed);
    return 1;
  }
  if (parsed[0].event_id ==
          cJSON_GetObjectItem(cJSON_GetArrayItem(entries, 0), "eventId")
              ->valuestring ||
      parsed[0].rsp_server_address ==
          cJSON_GetObjectItem(cJSON_GetArrayItem(entries, 0),
                              "rspServerAddress")
              ->valuestring) {
    fputs("SM-DS provider strings were returned without copying\n", stderr);
    cJSON_Delete(entries);
    es11_event_list_free_all(parsed);
    return 1;
  }
  cJSON_Delete(entries);
  es11_event_list_free_all(parsed);

  entries = cJSON_CreateArray();
  parsed = NULL;
  if (entries == NULL || es11_event_entries_parse(&parsed, entries) != 0 ||
      parsed == NULL || parsed[0].event_id != NULL ||
      parsed[0].rsp_server_address != NULL) {
    fputs("empty SM-DS result did not produce a safe sentinel\n", stderr);
    cJSON_Delete(entries);
    es11_event_list_free_all(parsed);
    return 1;
  }
  cJSON_Delete(entries);
  es11_event_list_free_all(parsed);

  if (expect_rejected(single_entry("", "rsp.example.test"), "empty EventID") ||
      expect_rejected(single_entry("event", ""), "empty server address") ||
      expect_rejected(single_entry(NULL, "rsp.example.test"),
                      "missing EventID") ||
      expect_rejected(single_entry("event", NULL), "missing server address")) {
    return 1;
  }

  char *maximum_id = malloc(ES11_EVENT_ID_MAX_LENGTH + 2U);
  char *maximum_server = malloc(ES11_RSP_SERVER_ADDRESS_MAX_LENGTH + 2U);
  if (maximum_id == NULL || maximum_server == NULL) {
    free(maximum_id);
    free(maximum_server);
    return 1;
  }
  memset(maximum_id, 'i', ES11_EVENT_ID_MAX_LENGTH + 1U);
  maximum_id[ES11_EVENT_ID_MAX_LENGTH + 1U] = '\0';
  memset(maximum_server, 's', ES11_RSP_SERVER_ADDRESS_MAX_LENGTH + 1U);
  maximum_server[ES11_RSP_SERVER_ADDRESS_MAX_LENGTH + 1U] = '\0';

  maximum_id[ES11_EVENT_ID_MAX_LENGTH] = '\0';
  maximum_server[ES11_RSP_SERVER_ADDRESS_MAX_LENGTH] = '\0';
  entries = single_entry(maximum_id, maximum_server);
  parsed = NULL;
  if (entries == NULL || es11_event_entries_parse(&parsed, entries) != 0 ||
      parsed == NULL || parsed[0].event_id == NULL ||
      parsed[0].rsp_server_address == NULL ||
      strlen(parsed[0].event_id) != ES11_EVENT_ID_MAX_LENGTH ||
      strlen(parsed[0].rsp_server_address) !=
          ES11_RSP_SERVER_ADDRESS_MAX_LENGTH) {
    fputs("maximum-size SM-DS fields were not accepted and terminated\n",
          stderr);
    cJSON_Delete(entries);
    es11_event_list_free_all(parsed);
    free(maximum_id);
    free(maximum_server);
    return 1;
  }
  cJSON_Delete(entries);
  es11_event_list_free_all(parsed);

  maximum_id[ES11_EVENT_ID_MAX_LENGTH] = 'i';
  maximum_server[ES11_RSP_SERVER_ADDRESS_MAX_LENGTH] = 's';
  if (expect_rejected(single_entry(maximum_id, "rsp.example.test"),
                      "oversized EventID") ||
      expect_rejected(single_entry("event", maximum_server),
                      "oversized server address")) {
    free(maximum_id);
    free(maximum_server);
    return 1;
  }
  free(maximum_id);
  free(maximum_server);

  entries = cJSON_CreateArray();
  if (entries == NULL) {
    return 1;
  }
  for (size_t i = 0; i <= ES11_EVENT_ENTRIES_MAX; i++) {
    cJSON *entry = make_entry("event", "rsp.example.test");
    if (entry == NULL) {
      cJSON_Delete(entries);
      return 1;
    }
    cJSON_AddItemToArray(entries, entry);
  }
  return expect_rejected(entries, "too many event entries");
}
