/*
 * Copyright (c) 2014, 2016 Renato Silva <br.renatosilva@gmail.com>
 * Copyright (c) 2014 David Macek <david.macek.0@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <ini.h>

#define NAME         "Pacman Repository Manager"
#define COPYRIGHT    "Copyright (C) 2014, 2016 Renato Silva and others"
#define LICENSE      "Licensed under BSD"
#define VERSION      "16.1"

#define HELP         "\n\t" NAME " " VERSION "\n\t" COPYRIGHT "\n\t" LICENSE "\n\nUsage:\n" \
                     "\trepman add NAME URL\n" \
                     "\trepman remove NAME\n" \
                     "\trepman list\n\n" \

#define PACMAN_CONF "/etc/pacman.conf"
#define CONFIG_FILE "/etc/pacman.d/repman.conf"
#define MAX_REPOSITORIES 1024

typedef struct {
    const char* name;
    const char* url;
    const char* siglevel;
    bool remove;
} simple_repository;

simple_repository repositories[MAX_REPOSITORIES];
bool pacman_configured = false;
int repo_index;

static int parse_pacman_config(void* data, const char* section, const char* name, const char* value) {
    if (pacman_configured)
        return true;
    pacman_configured = strcmp(name, "Include") == 0 &&
#ifdef __CYGWIN__
        strcasecmp(value, CONFIG_FILE) == 0;
#else
        strcmp(value, CONFIG_FILE) == 0;
#endif
    return true;
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

static void write_repository(simple_repository repository, FILE* ini) {
    if (repository.remove)
        return;
    fprintf(ini, "[%s]\n", repository.name);
    fprintf(ini, "Server = %s\n", repository.url);
    fprintf(ini, "SigLevel = %s\n", repository.siglevel);
    fprintf(ini, "\n");
}

static bool write_repositories() {
    FILE* ini = fopen(CONFIG_FILE, "w");
    if (ini == NULL)
        return false;
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        write_repository(repositories[repo_index], ini);
    fclose(ini);
    return true;
}

static bool pacman_refresh(simple_repository repository) {
    char temp_ini_path[] = "/tmp/repman.XXXXXX";
    char command[256];
    int pacman_return_code;
    int temp_descriptor;
    FILE* temp_ini;
    if ((temp_descriptor = mkstemp(temp_ini_path)) == -1)
        return false;
    if ((temp_ini = fdopen(temp_descriptor, "w")) == NULL)
        return false;
    write_repository(repository, temp_ini);
    snprintf(command, sizeof(command), "pacman --sync --refresh --config %s", temp_ini_path);
    fclose(temp_ini);
    pacman_return_code = system(command);
    remove(temp_ini_path);
    return (pacman_return_code == 0);
}

static bool add_repository(const char* name, const char* url, const char* siglevel) {
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (0 == strcmp(name, repositories[repo_index].name))
            break;
    repositories[repo_index].name = strdup(name);
    repositories[repo_index].url = strdup(url);
    repositories[repo_index].siglevel = strdup(siglevel);
    return pacman_refresh(repositories[repo_index]);
}

static bool remove_repository(const char* name) {
    char database[1024];
    for (repo_index = 0; repo_index < MAX_REPOSITORIES && repositories[repo_index].name != NULL; repo_index++)
        if (0 == strcmp(name, repositories[repo_index].name)) {
            repositories[repo_index].remove = true;
            snprintf(database, sizeof(database), "/var/lib/pacman/sync/%s.db", name);
            return (access(database, F_OK) != 0) || (remove(database) == 0);
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

int main(int argc, char** argv) {
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

    /* Configure pacman */
    if (ini_parse(PACMAN_CONF, parse_pacman_config, NULL) < 0) {
        printf("Could not read %s.\n", PACMAN_CONF);
        return EXIT_FAILURE;
    }
    if (!pacman_configured) {
        FILE* pacman_conf = fopen(PACMAN_CONF, "ab+");
        fprintf(pacman_conf, "\n# Automatically included by repman\n");
        fprintf(pacman_conf, "Include = %s\n", CONFIG_FILE);
        fclose(pacman_conf);
        pacman_configured = true;
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
        if (!add_repository(argv[2], argv[3], "Optional")) {
            printf("Could not add repository %s.\n", argv[2]);
            return EXIT_FAILURE;
        }
    } else if (strcmp(argv[1], "remove") == 0) {
        if (argc < 3) {
            printf("Please specify the repository to remove.\n");
            return EXIT_FAILURE;
        }
        if (!remove_repository(argv[2])) {
            printf("Could not remove repository %s.\n", argv[2]);
            return EXIT_FAILURE;
        }
    } else {
        printf("Unknown command %s.\n%s", argv[1], HELP);
        return EXIT_FAILURE;
    }

    /* Save repositories */
    if (!write_repositories()) {
        printf("Could not write %s.\n", CONFIG_FILE);
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
