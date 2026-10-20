/* Old Adept opens existing IPC key files with O_CREAT. Linux protected_regular
 * rejects that operation across users in /tmp even when O_RDWR is permitted.
 * Retry only the known regular IPC files, without creating or following links.
 * This library is preloaded into our temporary hw_server process only.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef ADEPT_IPC_DIRECTORY
#define ADEPT_IPC_DIRECTORY "/tmp"
#endif

static int (*original_open)(const char *, int, ...);
static pthread_once_t resolve_once = PTHREAD_ONCE_INIT;
static atomic_flag reported = ATOMIC_FLAG_INIT;

static void resolve_open(void) {
    original_open = (int (*)(const char *, int, ...))dlsym(RTLD_NEXT, "open");
}

static int known_ipc_path(const char *path) {
    static const char prefix[] = ADEPT_IPC_DIRECTORY "/digilent-adept2-";
    static const char *const names[] = {
        "shm-dvtbl", "shm-dvtopn", "shm-ftdevcmg", "shm-ftdmgr",
        "mtx-otinit", "mtx-dvtbl", "mtx-dvtopn", "mtx-ftdevcmg"
    };
    if (strncmp(path, prefix, sizeof(prefix) - 1) != 0) return 0;
    const char *name = path + sizeof(prefix) - 1;
    for (unsigned i = 0; i < sizeof(names) / sizeof(names[0]); i++)
        if (strcmp(name, names[i]) == 0) return 1;
    return 0;
}

int open(const char *path, int flags, ...) {
    mode_t mode = 0;
    if ((flags & O_CREAT) || (flags & O_TMPFILE) == O_TMPFILE) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
    }
    pthread_once(&resolve_once, resolve_open);
    if (!original_open) { errno = ENOSYS; return -1; }
    int fd = original_open(path, flags, mode);
    if (fd >= 0 || errno != EACCES ||
        (flags & ~(O_CREAT | O_RDWR | O_CLOEXEC | O_LARGEFILE)) ||
        (flags & (O_CREAT | O_ACCMODE)) != (O_CREAT | O_RDWR) ||
        !known_ipc_path(path)) return fd;

    struct stat before, after;
    if (lstat(path, &before) || !S_ISREG(before.st_mode)) {
        errno = EACCES;
        return -1;
    }
    fd = original_open(path, (flags & ~O_CREAT) | O_NOFOLLOW | O_NONBLOCK);
    if (fd < 0) return -1;
    if (fstat(fd, &after) || !S_ISREG(after.st_mode) ||
        before.st_dev != after.st_dev || before.st_ino != after.st_ino ||
        fcntl(fd, F_SETFL, flags & ~O_CREAT) < 0) {
        close(fd);
        errno = EACCES;
        return -1;
    }
    if (!atomic_flag_test_and_set(&reported)) {
        static const char message[] = "DIGILENT_IPC_COMPAT=ACTIVE existing_regular_files_only=1\n";
        ssize_t sent = write(STDERR_FILENO, message, sizeof(message) - 1);
        (void)sent;
    }
    return fd;
}
