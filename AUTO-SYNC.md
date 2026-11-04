# HuskSync 自动同步 + 自动构建仓库说明（中文）

这是 [HuskSync](https://github.com/WiIIiam278/HuskSync)（作者 William278）的**自动跟随上游 + 自动构建**仓库模板。
本仓库只加了两个 GitHub Actions 工作流和这份说明，**没有修改任何一行上游源码**，因此可以无冲突地长期跟随上游。

- 上游仓库：<https://github.com/WiIIiam278/HuskSync>
- 跟随分支：`master`
- 构建产物：`target/*.jar`（HuskSync 的 Gradle 构建会把成品复制到 `target/`，文件名形如 `HuskSync-Bukkit-4.1.0+mc.26.3.jar`）

---

## 一、两个工作流分别做什么

### 1. `.github/workflows/sync-upstream.yml` —— 自动同步上游

| 项目 | 说明 |
| --- | --- |
| 触发 | 每 6 小时（UTC 00:10 / 06:10 / 12:10 / 18:10，即北京时间 08:10 / 14:10 / 20:10 / 次日 02:10）；也可在 Actions 页面手动 `Run workflow` |
| 动作 | `git fetch upstream master` → `git merge`（**不是** `reset --hard`，所以本仓库自己的 workflow 文件不会被冲掉）→ 有变化才 `git push` |
| 结果 | 上游有更新 → 本仓库 `master` 多出一个 `chore: 同步上游 @<sha>` 提交 → 自动触发下面的构建 |

> 为什么用 merge 而不是强制覆盖：强制 `reset` 会把本仓库新增的 `.github/workflows/*` 一起抹掉；merge 只在真有冲突时才会失败，失败时工作流会红叉报警，需要你手动处理。

### 2. `.github/workflows/build.yml` —— 自动构建

| 项目 | 说明 |
| --- | --- |
| 触发 | `master` 分支 push（含上面同步产生的提交）、手动触发、每天 UTC 04:30（北京 12:30）兜底一次 |
| 环境 | Ubuntu + Temurin **JDK 25**（上游 `gradle.properties` 里 `javaVersion=25`）+ Gradle 缓存 |
| 命令 | `./gradlew build -x test --no-daemon --stacktrace` |
| 产物 | ① Actions 运行页面的 Artifacts：`HuskSync-build-<sha>`（保留 30 天）<br>② Releases 里滚动更新的 `auto-build` 预发布（每次都覆盖，永远是最新 master 的 jar） |
| 跳过测试 | 上游 `test` 需要数据库/真实环境，自动构建里用 `-x test` 保证稳定；想跑测试把 `-x test` 删掉即可 |

---

## 二、怎么把它用起来（3 步）

### 第 1 步：在 GitHub 上建一个空仓库

- 打开 <https://github.com/new>
- 仓库名随意（例如 `HuskSync-auto`），**不要**勾选 "Add a README / .gitignore / license"（要空仓库）
- 建议设为 **Public**：公开仓库的 Actions 分钟数完全免费；私有仓库会消耗你的额度（这个构建大约每次 3~6 分钟）

### 第 2 步：把本目录推上去

本目录已经是一个完整的 git 仓库（含上游全部历史），只需换 remote 再 push：

```powershell
cd <本目录>
git remote set-url origin https://github.com/<你的用户名>/HuskSync-auto.git
git push -u origin master
```

如果 GitHub 要凭据，用 **Personal Access Token**（classic 勾 `repo`，或 fine-grained 勾 `Contents: Read and write`）当密码；
或者在本机用 `git credential-manager` 登录一次后直接 push。

### 第 3 步：启用 Actions

1. 打开仓库的 **Actions** 标签页，如果提示 *"Workflows aren't being run on this forked repository"*，点 **I understand my workflows, go ahead and enable them**。
2. 进入 **Sync upstream** → **Run workflow** 手动跑一次，确认能拉取上游。
3. 进入 **Build** → **Run workflow** 手动跑一次，确认能出 jar。

> 注意：GitHub 对 fork 仓库的 `schedule` 有额外限制——**fork 仓库的定时工作流默认是关闭的**，必须在 Actions 页面手动启用一次（上面第 1 点），之后定时任务才会生效。若你的仓库是从本模板"导入"而非 fork，则没有这个限制。

---

## 三、日常使用

- **拿最新 jar**：打开 **Releases** → `auto-build` → 下载 `HuskSync-Bukkit-*.jar`。
- **看某次构建**：Actions → Build → 选一次运行 → 底部 Artifacts。
- **改同步频率**：编辑 `.github/workflows/sync-upstream.yml` 里的 `cron`（UTC 时间，比北京时间早 8 小时）。
- **临时停掉自动同步**：Actions → Sync upstream → 右上角 `...` → Disable workflow。
- **只想同步不想构建**：把 `build.yml` 里的 `push:` 触发删掉，只保留 `workflow_dispatch`。
- **上游改了构建方式导致构建失败**：Actions 会红叉；看日志里 `Collect jars` 那步，通常只需调整 `target/` 之外的备用查找路径（脚本里已经用 `find . -path '*/build/libs/*.jar'` 兜底）。

---

## 四、许可与合规

- HuskSync 采用 **Apache-2.0** 许可（见仓库根目录 `LICENSE`）。
- 本仓库只是自动跟随上游并重新构建，**未修改源码**；分发 jar 时请保留原作者的许可与署名，并遵守 Apache-2.0 的要求（保留版权声明、变更说明）。
- 请勿把本仓库当作"自己的作品"发布；如需改动功能，建议在 fork 里单独开分支，并明确标注修改内容。
