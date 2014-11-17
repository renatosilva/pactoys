/*
 * Pacman Repository Manager 2014.11.16
 * Copyright (C) 2014 Renato Silva, David Macek
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
    bool remove;
} simple_repository;

simple_repository repositories[MAX_REPOSITORIES];
int repo_index;

static bool write_repositories() {
    FILE* ini = fopen(CONFIG_FILE, "w");
    if (ini == NULL)
        return false;
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (!repositories[repo_index].remove) {
            fprintf(ini, "[%s]\n", repositories[repo_index].name);
            fprintf(ini, "Server = %s\n", repositories[repo_index].url);
            fprintf(ini, "SigLevel = %s\n", repositories[repo_index].siglevel);
            fprintf(ini, "\n");
        }
    fclose(ini);
    return true;
}

static void remove_repository(const char* name) {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (0 == strcmp(name, repositories[repo_index].name)) {
            repositories[repo_index].remove = true;
            return;
        }
}

static void add_repository(const char* name, const char* url, const char* siglevel) {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        ;
    repositories[repo_index].name = strdup(name);
    repositories[repo_index].url = strdup(url);
    repositories[repo_index].siglevel = strdup(siglevel);
    repo_index++;
}

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
    if (!write_repositories()) {
        printf("Could not write %s.\n", CONFIG_FILE);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
