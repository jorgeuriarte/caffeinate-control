/*
 * CaffeinateControl pmset Helper
 *
 * A minimal SUID binary to manage pmset disablesleep setting.
 * This allows CaffeinateControl to enable/disable lid sleep prevention
 * without requiring password prompts each time.
 *
 * Security considerations:
 * - Only accepts "0" or "1" as arguments (strict validation)
 * - Only executes /usr/bin/pmset with fixed arguments
 * - Logs all actions to system log
 * - No user input beyond the single argument
 *
 * Installation:
 * - Compiled as universal binary (arm64 + x86_64)
 * - Installed to /usr/local/bin/caffeinatecontrol-pmset
 * - Owned by root:wheel with mode 4755 (SUID)
 *
 * Usage:
 *   caffeinatecontrol-pmset 1   # Enable disablesleep (prevent lid sleep)
 *   caffeinatecontrol-pmset 0   # Disable disablesleep (allow lid sleep)
 *
 * Copyright (c) 2024 Jorge Uriarte
 * Licensed under MIT License
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>

#define PMSET_PATH "/usr/bin/pmset"
#define HELPER_NAME "caffeinatecontrol-pmset"

int main(int argc, char *argv[]) {
    // Open syslog for logging
    openlog(HELPER_NAME, LOG_PID | LOG_CONS, LOG_USER);

    // Validate argument count
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <0|1>\n", argv[0]);
        fprintf(stderr, "  0 = Allow sleep when lid closes (disablesleep off)\n");
        fprintf(stderr, "  1 = Prevent sleep when lid closes (disablesleep on)\n");
        syslog(LOG_WARNING, "Invalid invocation: wrong argument count (%d)", argc);
        closelog();
        return 1;
    }

    // Strict argument validation - only "0" or "1" allowed
    if (strcmp(argv[1], "0") != 0 && strcmp(argv[1], "1") != 0) {
        fprintf(stderr, "Error: Invalid argument '%s'. Only '0' or '1' allowed.\n", argv[1]);
        syslog(LOG_WARNING, "Invalid argument: '%s'", argv[1]);
        closelog();
        return 1;
    }

    // Verify pmset exists
    if (access(PMSET_PATH, X_OK) != 0) {
        fprintf(stderr, "Error: pmset not found or not executable at %s\n", PMSET_PATH);
        syslog(LOG_ERR, "pmset not found at %s", PMSET_PATH);
        closelog();
        return 1;
    }

    // Set real UID to effective UID (root if SUID bit is set)
    // This is necessary because pmset checks real UID
    if (setuid(geteuid()) != 0) {
        perror("setuid failed");
        syslog(LOG_ERR, "setuid failed");
        closelog();
        return 1;
    }

    // Log the action
    syslog(LOG_INFO, "Setting disablesleep to %s (invoked by uid %d)",
           argv[1], getuid());

    // Execute pmset with the validated argument
    char *pmset_args[] = {
        PMSET_PATH,
        "-a",
        "disablesleep",
        argv[1],
        NULL
    };

    // Replace current process with pmset
    execv(PMSET_PATH, pmset_args);

    // If execv returns, it failed
    perror("execv failed");
    syslog(LOG_ERR, "execv failed for pmset");
    closelog();
    return 1;
}
