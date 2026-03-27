# to_home_script

用于在 Linux 服务器上部署和维护 sing-box 回家节点的脚本仓库。

## 包含内容

- `install-home.sh`：一键安装/增量更新/卸载脚本（交互优先）
- `gen-home.sh`：配置与产物生成脚本
- `README-home-ss.md`：详细说明（协议、交互流程、增量更新行为等）

## 快速开始

```bash
sudo ./install-home.sh
```

非交互卸载：

```bash
sudo ./install-home.sh --uninstall
```

## curl 一键运行（无需 git clone）

当前仓库示例：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --repo jasonxtt/To_home_script
```

说明：上述管道方式会自动回连 `/dev/tty`，可正常进入交互安装。

给 `install-home.sh` 传参时，在后面加 `--`：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --repo jasonxtt/To_home_script -- --uninstall
```

如果你想完全非交互运行（避免任何提问），可直接透传参数：

```bash
curl -fsSL https://raw.githubusercontent.com/jasonxtt/To_home_script/main/bootstrap.sh | \
  bash -s -- --repo jasonxtt/To_home_script -- --host <你的域名或公网IP>
```

## 文档

详细用法与最新交互流程请查看：

- [README-home-ss.md](./README-home-ss.md)
