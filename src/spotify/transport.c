#define _GNU_SOURCE
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <json-c/json.h>
#include <openssl/sha.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
typedef struct json_object J;
static char store[4096], home[2048];
static J *get(J *o, const char *k) {
  J *v = NULL;
  if (o)
    json_object_object_get_ex(o, k, &v);
  return v;
}
static const char *str(J *v) { return v ? json_object_get_string(v) : ""; }
static double num(J *v) { return v ? json_object_get_double(v) : 0; }
static int yes(J *v) { return v && json_object_get_boolean(v); }
static void add(J *o, const char *k, J *v) {
  json_object_object_add(o, k, v ? v : json_object_new_null());
}
static void copy(J *o, const char *k, J *v) {
  add(o, k, v ? json_object_get(v) : NULL);
}
static void text(J *o, const char *k, const char *v) {
  add(o, k, json_object_new_string(v));
}
static void integer(J *o, const char *k, long long v) {
  add(o, k, json_object_new_int64(v));
}
static void boolean(J *o, const char *k, int v) {
  add(o, k, json_object_new_boolean(v));
}
static double now(void) {
  struct timespec t;
  clock_gettime(CLOCK_REALTIME, &t);
  return t.tv_sec + t.tv_nsec / 1e9;
}
static void fail(const char *message) {
  J *o = json_object_new_object();
  text(o, "error", message);
  puts(json_object_to_json_string_ext(o, JSON_C_TO_STRING_PLAIN));
  exit(1);
}
static J *readfile(const char *name) {
  char path[8192];
  snprintf(path, sizeof path, "%s/%s", store, name);
  return json_object_from_file(path);
}
static void writefile(const char *name, J *o) {
  char path[8192], temp[8192];
  snprintf(path, sizeof path, "%s/%s", store, name);
  snprintf(temp, sizeof temp, "%s/.event-%d.tmp", store, getpid());
  int fd = open(temp, O_CREAT | O_WRONLY | O_TRUNC | O_CLOEXEC, 0600);
  if (fd < 0)
    return;
  const char *s = json_object_to_json_string_ext(o, JSON_C_TO_STRING_PLAIN);
  size_t len = strlen(s), at = 0;
  while (at < len) {
    ssize_t n = write(fd, s + at, len - at);
    if (n < 1)
      break;
    at += n;
  }
  close(fd);
  if (at == len)
    rename(temp, path);
  else
    unlink(temp);
}
static int lock_event(void) {
  char p[8192];
  snprintf(p, sizeof p, "%s/native-event.lock", store);
  int fd = open(p, O_CREAT | O_RDWR | O_CLOEXEC, 0600);
  if (fd >= 0)
    flock(fd, LOCK_EX);
  return fd;
}
static J *rpc(J *request) {
  int port = 8089;
  char p[4096], line[256];
  snprintf(p, sizeof p, "%s/.config/spotify-player/app.toml", home);
  FILE *f = fopen(p, "r");
  if (f) {
    while (fgets(line, sizeof line, f)) {
      int v;
      if (sscanf(line, "client_port = %d", &v) == 1 && v > 0 && v < 65536)
        port = v;
    }
    fclose(f);
  }
  int fd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
  if (fd < 0)
    fail("Sensei, the player connection could not be opened.");
  struct timeval tv = {2, 0};
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
  struct sockaddr_in a = {.sin_family = AF_INET, .sin_port = htons(port)};
  a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (connect(fd, (void *)&a, sizeof a) < 0)
    fail("Sensei, the local player is unavailable.");
  const char *s =
      json_object_to_json_string_ext(request, JSON_C_TO_STRING_PLAIN);
  if (send(fd, s, strlen(s), 0) < 0)
    fail("Sensei, the local player is unavailable.");
  size_t cap = 65536, len = 0;
  char *buf = malloc(cap);
  if (!buf)
    fail("Out of memory");
  for (;;) {
    char part[65536];
    ssize_t n = recv(fd, part, sizeof part, 0);
    if (n < 0)
      fail("Sensei, Spotify is not responding. Open Account to reconnect.");
    if (!n)
      break;
    if (len + n > 16 * 1024 * 1024)
      fail("Spotify response is too large");
    if (len + n + 1 > cap) {
      cap = (len + n + 1) * 2;
      char *t = realloc(buf, cap);
      if (!t)
        fail("Out of memory");
      buf = t;
    }
    memcpy(buf + len, part, n);
    len += n;
  }
  close(fd);
  buf[len] = 0;
  J *envelope = json_tokener_parse(buf);
  free(buf);
  if (!envelope)
    fail("Spotify returned an invalid response");
  J *err = get(envelope, "Err");
  if (err)
    fail("Sensei, Spotify rejected that control. Check the player in Account.");
  J *bytes = get(envelope, "Ok");
  if (!bytes || !json_object_is_type(bytes, json_type_array))
    fail("Spotify returned an invalid response");
  len = json_object_array_length(bytes);
  buf = malloc(len + 1);
  if (!buf)
    fail("Out of memory");
  for (size_t i = 0; i < len; i++)
    buf[i] = (char)json_object_get_int(json_object_array_get_idx(bytes, i));
  buf[len] = 0;
  J *out = len ? json_tokener_parse(buf) : NULL;
  free(buf);
  json_object_put(envelope);
  return out;
}
static J *playback(void) {
  J *q = json_tokener_parse("{\"Get\":{\"Key\":\"Playback\"}}");
  J *d = rpc(q);
  json_object_put(q);
  return d;
}
static void control(J *c) {
  J *q = json_object_new_object();
  add(q, "Playback", c);
  J *d = rpc(q);
  if (d)
    json_object_put(d);
  json_object_put(q);
}
static J *trackrow(J *item) {
  J *t = get(item, "Track");
  if (t)
    item = t;
  t = get(item, "Episode");
  if (t)
    item = t;
  J *out = json_object_new_object();
  if (!item)
    return out;
  copy(out, "id", get(item, "id"));
  const char *kind = str(get(item, "type"));
  if (!*kind)
    kind = "track";
  text(out, "kind", kind);
  if (strlen(str(get(item, "uri"))))
    copy(out, "uri", get(item, "uri"));
  else {
    char uri[256];
    snprintf(uri, sizeof uri, "spotify:%s:%s", kind, str(get(item, "id")));
    text(out, "uri", uri);
  }
  copy(out, "title", get(item, "name"));
  J *album = get(item, "album");
  copy(out, "album", get(album, "name"));
  copy(out, "albumId", get(album, "id"));
  J *images = get(album, "images");
  if (!images)
    images = get(item, "images");
  J *image = images && json_object_array_length(images)
                 ? json_object_array_get_idx(images, 0)
                 : NULL;
  copy(out, "art", get(image, "url"));
  J *artists = get(item, "artists");
  char names[4096] = "";
  if (artists)
    for (size_t i = 0; i < json_object_array_length(artists); i++) {
      const char *n = str(get(json_object_array_get_idx(artists, i), "name"));
      size_t used = strlen(names);
      snprintf(names + used, sizeof names - used, "%s%s", i ? ", " : "", n);
    }
  text(out, "artist", names);
  J *duration = get(item, "duration_ms");
  if (!duration)
    duration = get(item, "duration");
  integer(out, "duration",
          json_object_is_type(duration, json_type_object)
              ? (long long)(num(get(duration, "secs")) * 1000 +
                            num(get(duration, "nanos")) / 1e6)
              : (long long)num(duration));
  copy(out, "explicit", get(item, "explicit"));
  return out;
}
static J *status(J *d) {
  J *o = json_object_new_object(), *track = trackrow(get(d, "item")),
    *device = get(d, "device");
  int playing = yes(get(d, "is_playing"));
  long long progress = num(get(d, "progress_ms"));
  J *event = readfile("native-event.json");
  double age = now() - num(get(event, "time"));
  J *et = get(event, "track"), *selection = readfile("selected-device.json");
  int loading = yes(get(event, "loading")) && age >= 0 && age < 30;
  int native_playing = yes(get(event, "playing"));
  long long native_progress = num(get(event, "progress")) + (native_playing ? (long long)(age * 1000) : 0);
  int local_selection = !strlen(str(get(selection, "name"))) || !strcmp(str(get(selection, "name")), "Sensei · ZenBook Duo");
  int native_owner = local_selection && native_playing && age >= 0 &&
      native_progress <= num(get(et, "duration")) + 2000 &&
      num(get(event, "player_pid")) > 0 && kill((pid_t)num(get(event, "player_pid")), 0) == 0;

  if ((native_owner || (!strcmp(str(get(device, "name")), "Sensei · ZenBook Duo") && age >= 0 &&
      (age < 8 || !strlen(str(get(track, "id")))))) &&
      strlen(str(get(et, "id")))) {
    if (strcmp(str(get(track, "uri")), str(get(event, "uri"))) ||
        yes(get(event, "seek")))
      progress = num(get(event, "progress")) +
                 (yes(get(event, "playing")) ? (long long)(age * 1000) : 0);
    json_object_put(track);
    track = json_object_get(et);
    playing = yes(get(event, "playing"));
  }
  boolean(o, "ready", d != NULL || native_owner || (local_selection && num(get(event, "player_pid")) > 0 && kill((pid_t)num(get(event, "player_pid")), 0) == 0));
  boolean(o, "playing", playing);
  boolean(o, "loading", loading);
  copy(o, "eventUri", get(event, "uri"));
  add(o, "track", track);
  integer(o, "progress", progress);
  copy(o, "volume", get(device, "volume_percent"));
  copy(o, "reportedDevice", get(device, "name"));
  if (native_owner) {
    text(o, "device", "Sensei · ZenBook Duo");
    copy(o, "deviceId", strlen(str(get(event, "deviceId"))) ? get(event, "deviceId") : get(device, "id"));
  } else {
    copy(o, "device", get(device, "name"));
    copy(o, "deviceId", get(device, "id"));
  }
  copy(o, "selectedDeviceId", get(selection, "id"));
  copy(o, "selectedDevice", get(selection, "name"));
  if (selection) json_object_put(selection);
  copy(o, "shuffle", get(d, "shuffle_state"));
  copy(o, "repeat", get(d, "repeat_state"));
  copy(o, "context", get(d, "context"));
  if (event)
    json_object_put(event);
  return o;
}
static void event(int argc, char **argv) {
  if (argc < 4)
    exit(0);
  const char *kind = argv[2], *uri = argv[3];
  if (strcmp(kind, "Loading") && strcmp(kind, "Changed") && strcmp(kind, "Playing") &&
      strcmp(kind, "Paused"))
    exit(0);
  const char *id = strrchr(uri, ':');
  if (!id)
    exit(0);
  id++;
  if (strlen(id) != 22 ||
      strspn(
          id,
          "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") !=
          22)
    exit(0);
  int lock = lock_event();
  J *old = readfile("native-event.json");
  char name[128];
  snprintf(name, sizeof name, "native-track-%s.json", id);
  J *track = readfile(name);
  if (!track && !strcmp(str(get(old, "uri")), uri))
    track = get(old, "track") ? json_object_get(get(old, "track")) : NULL;
  J *o = json_object_new_object();
  text(o, "uri", uri);
  boolean(o, "loading", !strcmp(kind, "Loading") || !strcmp(kind, "Changed"));
  integer(o, "player_pid", getppid());
  for (int i = 4; i + 1 < argc; ++i)
    if (!strcmp(argv[i], "--device-id")) text(o, "deviceId", argv[i + 1]);
  add(o, "time", json_object_new_double(now()));
  copy(o, "track", track);
  boolean(o, "playing",
          !strcmp(kind, "Changed") ? yes(get(old, "playing"))
                                   : !strcmp(kind, "Playing"));
  integer(o, "progress", argc > 4 ? atoll(argv[4]) : 0);
  writefile("native-event.json", o);
  if (lock >= 0)
    close(lock);
  // A single next-track preload is event-driven, never a background poll.
  if (!strcmp(kind, "Playing") || !strcmp(kind, "Paused")) {
    J *queue = readfile("local-queue.json"), *uris = get(queue, "uris");
    if (uris && json_object_is_type(uris, json_type_array))
      for (size_t i = 0; i + 1 < json_object_array_length(uris); i++) {
        if (!strcmp(str(json_object_array_get_idx(uris, i)), uri)) {
          J *q = json_object_new_object();
          copy(q, "PreloadTrack", json_object_array_get_idx(uris, i + 1));
          control(q);
          break;
        }
      }
    if (queue)
      json_object_put(queue);
  }
  int resolve = !track;
  if (track)
    json_object_put(track);
  if (old)
    json_object_put(old);
  json_object_put(o);
  if (resolve) {
    pid_t pid = fork();
    if (pid == 0) {
      setsid();
      int null = open("/dev/null", O_RDWR);
      for (int i = 0; i < 3; i++)
        dup2(null, i);
      if (null > 2)
        close(null);
      char exe[4096];
      snprintf(exe, sizeof exe, "%s/.local/bin/sensei-spotify-event", home);
      execl("/usr/bin/python3", "python3", exe, "resolve", uri, (char *)NULL);
      _exit(1);
    }
  }
}

static void artwork(int argc, char **argv) {
  if (argc < 3)
    fail("Missing artwork");
  char *url = strdup(argv[2]);
  char *low = strstr(url, "ab67616d00004851");
  if (low && !strncmp(url, "https://i.scdn.co/image/", 24))
    memcpy(low, "ab67616d0000b273", 16);
  unsigned char digest[SHA256_DIGEST_LENGTH];
  SHA256((unsigned char *)url, strlen(url), digest);
  char hash[65];
  for (int i = 0; i < 32; i++)
    sprintf(hash + 2 * i, "%02x", digest[i]);
  char path[8192];
  snprintf(path, sizeof path, "%s/%s.jpg", store, hash);
  free(url);
  if (access(path, R_OK) == 0) {
    J *o = json_object_new_object();
    char uri[8200];
    snprintf(uri, sizeof uri, "file://%s", path);
    text(o, "path", uri);
    puts(json_object_to_json_string_ext(o, JSON_C_TO_STRING_PLAIN));
    json_object_put(o);
    return;
  }
  char exe[4096];
  snprintf(exe, sizeof exe, "%s/.local/bin/sensei-spotify", home);
  argv[0] = exe;
  execv(exe, argv);
  fail("Unable to load artwork");
}
static int valid_uri(const char *uri) {
  const char *id = strrchr(uri, ':');
  return id &&
         (!strncmp(uri, "spotify:track:", 14) ||
          !strncmp(uri, "spotify:episode:", 16)) &&
         strlen(id + 1) == 22 &&
         strspn(id + 1, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01"
                        "23456789") == 22;
}
static void cache_rows(J *rows) {
  if (!rows || !json_object_is_type(rows, json_type_array))
    return;
  for (size_t i = 0; i < json_object_array_length(rows); i++) {
    J *r = json_object_array_get_idx(rows, i);
    const char *id = str(get(r, "id"));
    if (strlen(id) != 22 ||
        strspn(
            id,
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") !=
            22)
      continue;
    char path[128];
    snprintf(path, sizeof path, "native-track-%s.json", id);
    writefile(path, r);
  }
}
static void music_start(int argc, char **argv) {
  const char *name = argv[1];
  // The local player accepts these commands directly. A Web API playback
  // snapshot can sit behind Spotify's rate limit for seconds even while the
  // local socket is ready, so only consult it when a remote device was chosen.
  J *selection = readfile("selected-device.json");
  int selected_local = !selection || !strlen(str(get(selection, "name"))) ||
      !strcmp(str(get(selection, "name")), "Sensei · ZenBook Duo");
  if (selection) json_object_put(selection);
  J *d = selected_local ? NULL : playback();
  const char *device = str(get(get(d, "device"), "name"));
  if (*device && strcmp(device, "Sensei · ZenBook Duo")) {
    char exe[4096];
    snprintf(exe, sizeof exe, "%s/.local/bin/sensei-spotify", home);
    argv[0] = exe;
    setenv("SENSEI_SPOTIFY_REMOTE", "1", 1);
    execv(exe, argv);
    fail("Unable to start remote playback");
  }
  if (d)
    json_object_put(d);
  J *request = json_object_new_object(), *options = json_object_new_object();
  boolean(options, "start_playing", 1);
  if (!strcmp(name, "play-list") || !strcmp(name, "play-track")) {
    J *list = NULL, *uris = NULL;
    long long offset = 0, position = 0;
    if (!strcmp(name, "play-list")) {
      if (argc < 3)
        fail("Missing playlist");
      list = json_tokener_parse(argv[2]);
      uris = get(list, "uris");
      offset = num(get(list, "offset"));
      position = num(get(list, "position_ms"));
      cache_rows(get(list, "tracks"));
      if (get(list, "start_playing"))
        boolean(options, "start_playing", yes(get(list, "start_playing")));
    } else {
      if (argc < 3 || strlen(argv[2]) != 22 ||
          strspn(argv[2], "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                          "0123456789") != 22)
        fail("Invalid track");
      uris = json_object_new_array();
      char uri[80];
      snprintf(uri, sizeof uri, "spotify:track:%s", argv[2]);
      json_object_array_add(uris, json_object_new_string(uri));
      list = json_object_new_object();
      add(list, "uris", uris);
    }
    if (!uris || !json_object_is_type(uris, json_type_array) ||
        !json_object_array_length(uris) ||
        json_object_array_length(uris) > 1000)
      fail("Invalid queue size");
    for (size_t i = 0; i < json_object_array_length(uris); i++)
      if (!valid_uri(str(json_object_array_get_idx(uris, i))))
        fail("Invalid track URI");
    if (offset < 0 || offset >= (long long)json_object_array_length(uris))
      offset = 0;
    copy(options, "uris", uris);
    integer(options, "offset", offset);
    integer(options, "position_ms", position < 0 ? 0 : position);
    add(request, "StartUris", options);
    control(request);
    add(list, "time", json_object_new_double(now()));
    writefile("local-queue.json", list);
    // Start fetching the next song as soon as the queue is accepted. Waiting
    // for the Playing event loses several seconds of useful preload time and
    // makes an early Next leave a second of digital silence.
    if (offset + 1 < (long long)json_object_array_length(uris)) {
      J *q = json_object_new_object();
      copy(q, "PreloadTrack", json_object_array_get_idx(uris, offset + 1));
      control(q);
    }
    json_object_put(list);
  } else {
    if (argc < 4 || (!strcmp(argv[2], "playlist") && !strlen(argv[3])) ||
        (strcmp(argv[2], "playlist") && strcmp(argv[2], "album") &&
         strcmp(argv[2], "artist")) ||
        strlen(argv[3]) != 22 ||
        strspn(
            argv[3],
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") !=
            22)
      fail("Invalid music context");
    char uri[100];
    snprintf(uri, sizeof uri, "spotify:%s:%s", argv[2], argv[3]);
    text(options, "uri", uri);
    if (!strcmp(name, "play-context-track")) {
      if (argc < 5 || !valid_uri(argv[4]))
        fail("Invalid context track");
      text(options, "offset_uri", argv[4]);
      if (argc > 5) {
        J *rows = json_tokener_parse(argv[5]);
        cache_rows(rows);
        if (rows)
          json_object_put(rows);
      }
    } else
      add(options, "offset_uri", NULL);
    add(request, "StartLocalContext", options);
    control(request);
    J *empty = json_object_new_object();
    writefile("local-queue.json", empty);
    json_object_put(empty);
  }
  puts("{\"ok\":true}");
}

int main(int argc, char **argv) {
  umask(0077);
  const char *base = getenv("SENSEI_SPOTIFY_HOME");
  if (!base)
    base = getenv("HOME");
  snprintf(home, sizeof home, "%s", base ? base : "@HOME@");
  snprintf(store, sizeof store, "%s/.cache/sensei-spotify", home);
  if (argc < 2)
    fail("Missing action");
  const char *name = argv[1];
  if (!strcmp(name, "art")) {
    artwork(argc, argv);
    return 0;
  }
  if (!strcmp(name, "event")) {
    event(argc, argv);
    return 0;
  }
  if (!strcmp(name, "status")) {
    J *d = playback(), *o = status(d);
    puts(json_object_to_json_string_ext(o, JSON_C_TO_STRING_PLAIN));
    json_object_put(o);
    if (d)
      json_object_put(d);
    return 0;
  }
  if (!strcmp(name, "play-list") || !strcmp(name, "play-track") ||
      !strcmp(name, "play-context") || !strcmp(name, "play-context-track")) {
    music_start(argc, argv);
    return 0;
  }
  const char *simple = NULL;
  if (!strcmp(name, "play"))
    simple = "Play";
  else if (!strcmp(name, "pause"))
    simple = "Pause";
  else if (!strcmp(name, "toggle"))
    simple = "PlayPause";
  else if (!strcmp(name, "next"))
    simple = "Next";
  else if (!strcmp(name, "previous"))
    simple = "Previous";
  else if (!strcmp(name, "shuffle"))
    simple = "Shuffle";
  else if (!strcmp(name, "repeat"))
    simple = "Repeat";
  J *d = NULL;
  if (simple) {
    if (!strcmp(name, "next") || !strcmp(name, "previous")) {
      int playing;
      if (argc > 2 &&
          (!strcmp(argv[2], "playing") || !strcmp(argv[2], "paused")))
        playing = !strcmp(argv[2], "playing");
      else {
        d = playback();
        playing = yes(get(d, "is_playing"));
      }
      control(json_object_new_string(simple));
      control(json_object_new_string(playing ? "Play" : "Pause"));
    } else
      control(json_object_new_string(simple));
  } else if (!strcmp(name, "volume")) {
    if (argc < 3)
      fail("Missing volume");
    int volume = atoi(argv[2]);
    if (volume < 0)
      volume = 0;
    if (volume > 100)
      volume = 100;
    J *v = json_object_new_object(), *q = json_object_new_object();
    integer(v, "percent", volume);
    boolean(v, "is_offset", 0);
    add(q, "Volume", v);
    control(q);
  } else if (!strcmp(name, "seek") || !strcmp(name, "seek-to")) {
    if (argc < 3)
      fail("Missing position");
    d = playback();
    long long current = num(get(d, "progress_ms")),
              target = atoll(argv[2]) + (!strcmp(name, "seek") ? current : 0);
    if (target < 0)
      target = 0;
    J *q = json_object_new_object();
    integer(q, "SeekAbsolute", target);
    control(q);
    J *o = status(d), *e = json_object_new_object();
    copy(e, "track", get(o, "track"));
    copy(e, "uri", get(get(o, "track"), "uri"));
    add(e, "time", json_object_new_double(now()));
    copy(e, "playing", get(o, "playing"));
    integer(e, "progress", target);
    boolean(e, "seek", 1);
    int lock = lock_event();
    writefile("native-event.json", e);
    if (lock >= 0)
      close(lock);
    json_object_put(o);
    json_object_put(e);
  } else
    fail("Unsupported local transport action");
  if (d)
    json_object_put(d);
  puts("{\"ok\":true}");
  return 0;
}
