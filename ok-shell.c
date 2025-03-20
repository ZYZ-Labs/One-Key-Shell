#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

// 根据 HOME 环境变量动态获取目录路径
const char* get_home() {
    const char* home = getenv("HOME");
    return home ? home : "/root";
}

void get_scripts_dir(char *buffer, size_t size) {
    const char *home = get_home();
    snprintf(buffer, size, "%s/.one-key-shell/scripts", home);
}

void get_install_script_path(char *buffer, size_t size) {
    const char *home = get_home();
    snprintf(buffer, size, "%s/.one-key-shell/install-ok-shell.sh", home);
}

void get_install_path(char *buffer, size_t size) {
    const char *home = get_home();
    snprintf(buffer, size, "%s/.local/bin/ok-shell", home);
}

// 显示帮助信息
void show_help() {
    printf("欢迎使用 One-Key-Shell!\n");
    printf("可用的命令:\n");
    printf("  install             - 安装或重新安装 One-Key-Shell\n");
    printf("  uninstall           - 卸载 One-Key-Shell\n");
    printf("  list                - 列出所有可用的脚本\n");
    printf("  update              - 更新脚本库并重新安装\n");
    printf("  silent_check_update - 静默检查更新\n");
    printf("  help                - 显示此帮助信息\n");
}

// 安装或重新安装 One-Key-Shell（调用安装脚本）
void install_ok_shell() {
    char install_script[1024];
    get_install_script_path(install_script, sizeof(install_script));
    printf("执行安装脚本: bash %s\n", install_script);
    char command[2048];
    snprintf(command, sizeof(command), "bash %s", install_script);
    system(command);
}

// 卸载 One-Key-Shell（删除仓库和安装的二进制文件）
void uninstall_ok_shell() {
    const char *home = get_home();
    char target_dir[1024], install_path[1024];
    snprintf(target_dir, sizeof(target_dir), "%s/.one-key-shell", home);
    snprintf(install_path, sizeof(install_path), "%s/.local/bin/ok-shell", home);
    printf("正在卸载 One-Key-Shell...\n");
    char command[2048];
    snprintf(command, sizeof(command), "rm -rf %s", target_dir);
    system(command);
    snprintf(command, sizeof(command), "rm -f %s", install_path);
    system(command);
    printf("卸载完成。\n");
    printf("请手动移除 shell 配置文件中的 alias 配置（例如 ~/.bashrc 或 ~/.zshrc）。\n");
}

// 静默检查更新，并在有更新时调用安装脚本重新安装
void silent_check_update() {
    system("git -C ~/.one-key-shell fetch");
    char local[41], remote[41];
    FILE *fp = popen("git -C ~/.one-key-shell rev-parse @", "r");
    fgets(local, sizeof(local), fp);
    pclose(fp);
    fp = popen("git -C ~/.one-key-shell rev-parse @{u}", "r");
    fgets(remote, sizeof(remote), fp);
    pclose(fp);

    if (strcmp(local, remote) != 0) {
        char response;
        printf("有可用更新，是否更新？ [Y/n] ");
        response = getchar();
        // 清理输入缓冲区
        while(getchar() != '\n');
        if (response == '\n' || response == 'Y' || response == 'y') {
            system("git -C ~/.one-key-shell pull");
            printf("更新完成。\n");
            printf("重新执行安装脚本...\n");
            install_ok_shell();
        } else {
            printf("已跳过更新。\n");
        }
    }
}

// 递归收集所有脚本的完整路径到数组中，返回收集的脚本数量
int collect_scripts(const char *dir, char **scripts, int max_scripts) {
    DIR *dp = opendir(dir);
    if (!dp) {
        perror("opendir");
        return 0;
    }
    struct dirent *entry;
    int count = 0;
    while ((entry = readdir(dp))) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
            continue;
        char path[1024];
        snprintf(path, sizeof(path), "%s/%s", dir, entry->d_name);
        if (entry->d_type == DT_DIR) {
            count += collect_scripts(path, scripts + count, max_scripts - count);
        } else if (entry->d_type == DT_REG) {
            if (count < max_scripts) {
                scripts[count] = strdup(path);
                count++;
            }
        }
    }
    closedir(dp);
    return count;
}

// 列出所有脚本，并根据用户输入执行对应的脚本
void list_scripts() {
    char scripts_dir[1024];
    get_scripts_dir(scripts_dir, sizeof(scripts_dir));
    
    char *scripts[1024];
    int count = collect_scripts(scripts_dir, scripts, 1024);
    if (count == 0) {
        printf("没有找到任何脚本。\n");
        return;
    }
    printf("可用的脚本:\n");
    for (int i = 0; i < count; i++) {
        printf("%d) %s\n", i + 1, scripts[i]);
    }
    printf("请输入你想运行的脚本编号: ");
    int script_number;
    if (scanf("%d", &script_number) != 1) {
        printf("输入无效。\n");
        for (int i = 0; i < count; i++) {
            free(scripts[i]);
        }
        return;
    }
    if (script_number < 1 || script_number > count) {
        printf("脚本编号超出范围。\n");
        for (int i = 0; i < count; i++) {
            free(scripts[i]);
        }
        return;
    }
    char command[2048];
    snprintf(command, sizeof(command), "bash %s", scripts[script_number - 1]);
    system(command);

    for (int i = 0; i < count; i++) {
        free(scripts[i]);
    }
}

// 主程序，根据命令行参数选择操作
int main(int argc, char *argv[]) {
    if (argc > 1) {
        if (strcmp(argv[1], "install") == 0) {
            install_ok_shell();
        } else if (strcmp(argv[1], "uninstall") == 0) {
            uninstall_ok_shell();
        } else if (strcmp(argv[1], "update") == 0) {
            system("git -C ~/.one-key-shell pull");
            printf("更新完成。\n");
            printf("重新执行安装脚本...\n");
            install_ok_shell();
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

