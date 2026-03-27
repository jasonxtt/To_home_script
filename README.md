# to_home_script

用于在 Linux 服务器上部署和维护 sing-box 回家节点的脚本仓库。

## 包含内容

- `install-home.sh`：一键安装/增量更新/卸载脚本（交互优先）
- `gen-home.sh`：配置与产物生成脚本
- `README-home-ss.md`：详细说明（协议、交互流程、增量更新行为等）

## curl 一键运行（无需 git clone）

直接运行（默认就是当前仓库）：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | bash
```

说明：上述管道方式会自动回连 `/dev/tty`，可正常进入交互安装。

给 `install-home.sh` 透传参数时，直接写在后面即可：

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
chmod +x install-home.sh gen-home.sh
```

方式 2：仅下载脚本

```bash
curl -fsSLO https://raw.githubusercontent.com/jasonxtt/To_home_script/main/install-home.sh
curl -fsSLO https://raw.githubusercontent.com/jasonxtt/To_home_script/main/gen-home.sh
chmod +x install-home.sh gen-home.sh
```

准备好两个脚本后，再执行：

```bash
sudo ./install-home.sh
```

非交互卸载：

```bash
sudo ./install-home.sh --uninstall
```

## 文档

详细用法与最新交互流程请查看：

- [README-home-ss.md](./README-home-ss.md)
