#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <ini.h>

#define NAME         "Pacman Repository Manager"
#define COPYRIGHT    "Copyright (C) 2014 Renato Silva, David Macek"
#define LICENSE      "Licensed under GNU GPLv2 or later"
#define VERSION      "2014.12.2"

#define HELP         "\n\t" NAME " " VERSION "\n\t" COPYRIGHT "\n\t" LICENSE "\n\nUsage:\n" \
                     "\trepman add NAME URL\n" \
                     "\trepman remove NAME\n" \
                     "\trepman list\n\n" \

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

static void add_repository(const char* name, const char* url, const char* siglevel) {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (0 == strcmp(name, repositories[repo_index].name))
            break;
    repositories[repo_index].name = strdup(name);
    repositories[repo_index].url = strdup(url);
    repositories[repo_index].siglevel = strdup(siglevel);
}

static bool remove_repository(const char* name) {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (0 == strcmp(name, repositories[repo_index].name)) {
            repositories[repo_index].remove = true;
            return true;
        }
    return false;
}

static void list_repositories() {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        printf("%s\n\tServer: %s\n\tSigLevel: %s\n",
            repositories[repo_index].name,
            repositories[repo_index].url,
            repositories[repo_index].siglevel);
}

static int pacman_refresh() {
    return system("pacman --sync --refresh");
}

int main(int argc, char** argv) {
    int pacman_return_code;
    repo_index = 0;
    if (argc < 2) {
        printf(HELP);
        return EXIT_FAILURE;
    }
    fclose(fopen(CONFIG_FILE, "ab+"));
    if (ini_parse(CONFIG_FILE, parse_repositories, NULL) < 0) {
        printf("Could not read %s.\n", CONFIG_FILE);
        return EXIT_FAILURE;
    }

    /* List repositories */
    if (strcmp(argv[1], "list") == 0) {
        if (argc > 2) {
            printf("Extra arguments to list command.\n");
            return EXIT_FAILURE;
        }
        list_repositories();
        return EXIT_SUCCESS;
    }

    /* Modify repositories */
    if (strcmp(argv[1], "add") == 0) {
        if (argc < 4) {
            printf("Please specify the repository name and URL.\n");
            return EXIT_FAILURE;
        }
        add_repository(argv[2], argv[3], "Optional");
    } else if (strcmp(argv[1], "remove") == 0) {
        if (argc < 3) {
            printf("Please specify the repository to remove.\n");
            return EXIT_FAILURE;
        }
        if (!remove_repository(argv[2])) {
            printf("Could not find repository %s.\n", argv[2]);
            return EXIT_FAILURE;
        }
    } else {
        printf("Unknown command %s.\n%s", argv[1], HELP);
        return EXIT_FAILURE;
    }

    /* Save and refresh */
    if (!write_repositories()) {
        printf("Could not write %s.\n", CONFIG_FILE);
        return EXIT_FAILURE;
    }
    pacman_return_code = pacman_refresh();
    if (pacman_return_code == -1)
        return EXIT_FAILURE;
    return pacman_return_code;
}
