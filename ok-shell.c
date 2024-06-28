#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

#define SCRIPTS_DIR "/root/.one-key-shell/scripts"

// 显示帮助信息
void show_help() {
    printf("欢迎使用 One-Key-Shell!\n");
    printf("可用的命令:\n");
    printf("  list    - 列出所有可用的脚本\n");
    printf("  update  - 更新脚本库\n");
    printf("  help    - 显示此帮助信息\n");
}

// 静默检查更新
void silent_check_update() {
    system("git -C /root/.one-key-shell fetch");
    char local[41], remote[41];
    FILE *fp = popen("git -C /root/.one-key-shell rev-parse @", "r");
    fgets(local, 41, fp);
    pclose(fp);
    fp = popen("git -C /root/.one-key-shell rev-parse @{u}", "r");
    fgets(remote, 41, fp);
    pclose(fp);

    if (strcmp(local, remote) != 0) {
        char response;
        printf("有可用更新，是否更新？ [Y/n] ");
        response = getchar();
        if (response == '\n' || response == 'Y' || response == 'y') {
            system("git -C /root/.one-key-shell pull");
            printf("更新完成。\n");
        } else {
            printf("已跳过更新。\n");
        }
    }
}

// 递归列出脚本
void list_scripts_recursive(const char *dir, int *counter) {
    struct dirent *entry;
    DIR *dp = opendir(dir);

    if (dp == NULL) {
        perror("opendir");
        return;
    }

    while ((entry = readdir(dp))) {
        if (entry->d_type == DT_DIR) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
                continue;
            printf("目录: %s\n", entry->d_name);
            char path[1024];
            snprintf(path, sizeof(path), "%s/%s", dir, entry->d_name);
            list_scripts_recursive(path, counter);
        } else {
            printf("%d) %s\n", (*counter)++, entry->d_name);
        }
    }

    closedir(dp);
}

// 列出脚本
void list_scripts() {
    int counter = 1;
    printf("可用的脚本:\n");
    list_scripts_recursive(SCRIPTS_DIR, &counter);

    printf("请输入你想运行的脚本编号: ");
    int script_number;
    scanf("%d", &script_number);

    int current_counter = 1;
    char script_path[1024];
    DIR *dp = opendir(SCRIPTS_DIR);
    struct dirent *entry;

    while ((entry = readdir(dp))) {
        if (entry->d_type == DT_DIR) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
                continue;
            char path[1024];
            snprintf(path, sizeof(path), "%s/%s", SCRIPTS_DIR, entry->d_name);
            DIR *subdp = opendir(path);
            struct dirent *subentry;

            while ((subentry = readdir(subdp))) {
                if (subentry->d_type == DT_REG) {
                    if (current_counter == script_number) {
                        snprintf(script_path, sizeof(script_path), "%s/%s", path, subentry->d_name);
                        break;
                    }
                    current_counter++;
                }
            }

            closedir(subdp);
        } else {
            if (current_counter == script_number) {
                snprintf(script_path, sizeof(script_path), "%s/%s", SCRIPTS_DIR, entry->d_name);
                break;
            }
            current_counter++;
        }
    }

    closedir(dp);

    if (script_path[0] != '\0') {
        char command[1024];
        snprintf(command, sizeof(command), "bash %s", script_path);
        system(command);
    } else {
        printf("脚本未找到!\n");
    }
}

// 主程序
int main(int argc, char *argv[]) {
    if (argc > 1) {
        if (strcmp(argv[1], "update") == 0) {
            system("git -C /root/.one-key-shell pull");
            printf("更新完成。\n");
        } else if (strcmp(argv[1], "list") == 0) {
            list_scripts();
        } else if (strcmp(argv[1], "silent_check_update") == 0) {
            silent_check_update();
        } else {
            show_help();
        }
    } else {
        silent_check_update();
        show_help();
    }

    return 0;
}
