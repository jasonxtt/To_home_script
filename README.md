# to_home_script

用于在 Linux 服务器上部署和维护 sing-box 回家节点的脚本仓库。

## 包含内容

- `install-sing-box-home.sh`：一键安装/增量更新/卸载脚本（交互优先）
- `generate-sing-box-config.sh`：配置与产物生成脚本
- `PROJECT_CONTEXT.md`：项目上下文说明（面向 AI 快速理解）

## curl 一键运行（无需 git clone）

直接运行（默认就是当前仓库）：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | bash
```

说明：上述管道方式会自动回连 `/dev/tty`，可正常进入交互安装。

给 `install-sing-box-home.sh` 透传参数时，直接写在后面即可：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --uninstall
```

如果你想完全非交互运行（避免任何提问），可直接透传参数：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --host <你的域名或公网IP>
```

如果未来仓库地址或分支变化，也支持覆盖：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --repo <owner>/<repo> --ref <branch-or-tag>
```

## 本地运行（需先把脚本放到本地）

方式 1：`git clone`

```bash
git clone https://github.com/jasonxtt/To_home_script.git
cd To_home_script
chmod +x install-sing-box-home.sh generate-sing-box-config.sh
```

方式 2：仅下载脚本

```bash
curl -fsSLO https://raw.githubusercontent.com/jasonxtt/To_home_script/main/install-sing-box-home.sh
curl -fsSLO https://raw.githubusercontent.com/jasonxtt/To_home_script/main/generate-sing-box-config.sh
chmod +x install-sing-box-home.sh generate-sing-box-config.sh
```

准备好两个脚本后，再执行：

```bash
sudo ./install-sing-box-home.sh
```

脚本启动后会先让你选择模式：

- 独立部署回家 sing-box
- 合并到已有 sing-box 配置（仅追加 `inbounds`）

安装完成后，脚本会：

- 在 shell 里直接打印本次生成的客户端节点片段
- 默认导出到 `/root/sing-box-nodes.json`
- 如果生成了 mihomo/clash 片段，也会默认导出到 `/root/clash-nodes.yaml`

非交互强制合并模式：

```bash
sudo ./install-sing-box-home.sh --merge-into-existing
```

如果自动探测已有配置失败或有歧义，可指定配置路径（`config.json` 或 `conf` 目录）：

```bash
sudo ./install-sing-box-home.sh --merge-into-existing --merge-config-dir /path/to/sing-box/config.json
```

如果机器上有多个 sing-box service，且无法自动判断该重启哪一个，也可以显式指定：

```bash
sudo ./install-sing-box-home.sh --merge-into-existing --merge-config-dir /path/to/sing-box/conf --merge-service-name sing-box
```

非交互卸载：

```bash
sudo ./install-sing-box-home.sh --uninstall
```

## 文档

详细用法与最新交互流程请查看：

- [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)
