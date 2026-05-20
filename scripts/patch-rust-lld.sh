#!/usr/bin/env bash
# Patches rust-lld in the active Rust toolchain to inject --allow-shlib-undefined
# when linking for the x86_64-unknown-linux-gnu host target.
#
# WHY: glibc 2.34 merged libpthread into libc. rust-lld's --no-allow-shlib-undefined
# default causes it to reject libgcc_s.so.1 which references pthread symbols that
# resolve at runtime but aren't in the static link graph. This breaks build script
# compilation when building flutter_vodozemac / native_imaging for Android.
#
# Run this script after `rustup update` if builds start failing again.

set -e

TOOLCHAIN_BIN=$(rustup run stable rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin

if [ ! -f "$TOOLCHAIN_BIN/rust-lld.real" ]; then
    cp "$TOOLCHAIN_BIN/rust-lld" "$TOOLCHAIN_BIN/rust-lld.real"
    echo "Backed up rust-lld to rust-lld.real"
else
    echo "rust-lld.real already exists, skipping backup"
fi

WRAPPER_SRC=$(mktemp /tmp/rust_lld_wrapper_XXXXXX.c)
cat > "$WRAPPER_SRC" << 'C_EOF'
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <libgen.h>
#include <stdio.h>

/* Injects --allow-shlib-undefined after the -flavor <type> args that the
   lld-wrapper (gcc-ld/ld.lld) prepends. This suppresses lld's strict check
   on libgcc_s.so.1's transitive pthread references (glibc 2.34+ issue). */
int main(int argc, char *argv[]) {
    char self_path[4096];
    ssize_t len = readlink("/proc/self/exe", self_path, sizeof(self_path) - 1);
    if (len < 0) { perror("readlink"); return 1; }
    self_path[len] = '\0';

    char *dir = dirname(self_path);
    char real[4096];
    snprintf(real, sizeof(real), "%s/rust-lld.real", dir);

    int insert_at = 1;
    for (int i = 1; i < argc - 1; i++) {
        if (strcmp(argv[i], "-flavor") == 0) {
            insert_at = i + 2;
            break;
        }
    }

    char **new_argv = malloc((argc + 2) * sizeof(char *));
    if (!new_argv) return 1;

    int j = 0;
    for (int i = 0; i < insert_at && i < argc; i++) new_argv[j++] = argv[i];
    new_argv[j++] = "--allow-shlib-undefined";
    for (int i = insert_at; i < argc; i++) new_argv[j++] = argv[i];
    new_argv[j] = NULL;

    execv(real, new_argv);
    perror("execv");
    return 1;
}
C_EOF

gcc -O2 -o "$TOOLCHAIN_BIN/rust-lld" "$WRAPPER_SRC"
rm "$WRAPPER_SRC"
echo "rust-lld wrapper installed at $TOOLCHAIN_BIN/rust-lld"
echo "Original binary preserved as $TOOLCHAIN_BIN/rust-lld.real"
