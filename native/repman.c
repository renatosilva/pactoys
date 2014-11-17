/*
 * Pacman Repository Manager 2014.11.16
 * Copyright (C) 2014 Renato Silva
 * Licensed under GNU GPLv2 or later
 *
 * This is a prototype for a native C implementation. Currently it just lists
 * repositories from an existing /etc/pacman.d/repman.conf. It needs to add and
 * remove entries, as well as parse the command line options.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <ini.h>

#define CONFIG_FILE "/etc/pacman.d/repman.conf"
#define MAX_REPOSITORIES 1024

typedef struct {
    const char* name;
    const char* url;
    const char* siglevel;
} simple_repository;

simple_repository repositories[MAX_REPOSITORIES];
int repo_index;

static int parse_repositories(void* data, const char* section, const char* name, const char* value) {
    if (strcmp(name, "Server") == 0) {
        repositories[repo_index].url = strdup(value);
    } else if (strcmp(name, "SigLevel") == 0) {
        repositories[repo_index].siglevel = strdup(value);
    } else
        return false;
    if (repositories[repo_index].url != NULL && repositories[repo_index].siglevel != NULL) {
        repositories[repo_index].name = strdup(section);
        repo_index++;
    }
    return true;
}

int main(int argc, char** argv) {
    repo_index = 0;
    if (ini_parse(CONFIG_FILE, parse_repositories, NULL) < 0) {
        printf("Could not read %s.\n", CONFIG_FILE);
        return EXIT_FAILURE;
    }
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        printf("%s:\n\tServer: %s\n\tSigLevel: %s\n",
            repositories[repo_index].name,
            repositories[repo_index].url,
            repositories[repo_index].siglevel);
    return EXIT_SUCCESS;
}
