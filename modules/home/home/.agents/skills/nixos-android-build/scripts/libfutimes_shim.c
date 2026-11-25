#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <unistd.h>

/* Some sandboxes block futimens/futimes on a raw fd (EPERM) but allow
 * path-based utimensat.  Translate the fd form into a /proc/self/fd/N path. */
static int fd_utimens(int fd, const struct timespec ts[2]) {
    char path[64];
    snprintf(path, sizeof(path), "/proc/self/fd/%d", fd);
    return syscall(SYS_utimensat, AT_FDCWD, path, ts, 0);
}

int futimens(int fd, const struct timespec times[2]) {
    return fd_utimens(fd, times);
}

int futimes(int fd, const struct timeval times[2]) {
    if (!times) {
        struct timespec ts[2] = {{0, UTIME_NOW}, {0, UTIME_NOW}};
        return fd_utimens(fd, ts);
    }
    struct timespec ts[2];
    ts[0].tv_sec = times[0].tv_sec; ts[0].tv_nsec = times[0].tv_usec * 1000;
    ts[1].tv_sec = times[1].tv_sec; ts[1].tv_nsec = times[1].tv_usec * 1000;
    return fd_utimens(fd, ts);
}

int futimesat(int dirfd, const char *pathname, const struct timeval times[2]) {
    if (pathname) {
        struct timespec ts[2];
        if (!times) {
            ts[0].tv_sec = 0; ts[0].tv_nsec = UTIME_NOW;
            ts[1].tv_sec = 0; ts[1].tv_nsec = UTIME_NOW;
        } else {
            ts[0].tv_sec = times[0].tv_sec; ts[0].tv_nsec = times[0].tv_usec * 1000;
            ts[1].tv_sec = times[1].tv_sec; ts[1].tv_nsec = times[1].tv_usec * 1000;
        }
        return syscall(SYS_utimensat, dirfd, pathname, ts, 0);
    }
    return futimes(dirfd, times);
}
