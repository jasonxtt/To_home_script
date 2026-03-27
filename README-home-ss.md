# home 脚本说明

## 增量更新行为（2026-03-20 起）

`install-home.sh` 现在区分 **首次安装** 和 **已有安装上的增量更新**，并把交互顺序调整为：

1. 先检查当前环境
2. 先展示现状
3. 若已安装且服务在运行，再询问是否覆盖更新二进制
4. 再选择这次要安装的协议
5. 展示配置增量计划
6. 再问是否重置已有协议
7. 最后才收集本次真正需要的参数（host / 端口 / ACME）

### 1) 启动后先做环境检查并展示现状

脚本会先检查并显示：

- `sing-box` 二进制是否已安装
- systemd service 是否存在
- service 当前是否运行中
- `config.json` 是否存在
- 当前已配置了哪些协议

### 2) 已检测到 sing-box 运行时

如果检测到：

- `sing-box` 二进制已存在
- systemd service 已存在
- service 当前正在运行

脚本会先询问：

```text
检测到已安装并运行 sing-box，是否覆盖更新二进制？ [y/N]
```

- 默认 **N**
- 选 **N**：
  - 不解析 latest 版本
  - 不去 GitHub 下载 tarball
  - 不替换现有二进制
  - 直接进入配置增量更新流程
- 选 **Y**：
  - 才执行原有下载 / 解压 / 覆盖 / 回滚逻辑

非交互模式下同样走保守策略：

- 默认 **不更新二进制**
- 只有显式传 `--force-binary-update` 才会更新

### 3) 配置更新默认是“只新增，不修改，不删除”

脚本会优先读取：

- `/usr/local/etc/sing-box/installer-state.json`

如果这个状态文件不存在，则回退解析现有 `config.json` 里的 inbound tag，至少识别：

- `hy2`
- `ss`
- `trojan`
- `anytls`
- `vgr`
- `vbr`

然后把这次用户选择拆成三类：

- **keep**：原来已有，这次也选中
- **add**：原来没有，这次新选中
- **existing_not_selected**：原来已有，但这次没选

默认处理规则：

- `keep`：保留，不重置
- `add`：新增
- `existing_not_selected`：继续保留，不删除

脚本会展示一个简短计划，例如：

```text
配置计划：保留=Hysteria2, Shadowsocks；新增=Trojan；未选但保留=VLESS gRPC Reality
```

之后再问：

```text
是否重置已有协议？ [y/N]
```

- 默认 **N**
- 如果选 **Y**，可继续输入要重置的协议编号
- 只允许输入 `keep` 集合里的协议
- 回车默认不重置任何

### 4) 不提供“重建整个配置 / 删除协议”模式

当前脚本明确保持保守：

- 不会因为你这次没选某个旧协议就自动删掉它
- 不会提供“重建整个配置”交互
- 不会提供“删除某协议”交互

### 5) installer-state.json 记录内容

状态文件默认路径：

- `/usr/local/etc/sing-box/installer-state.json`

当前至少记录：

- `script_version`：安装脚本版本标记
- `deployed_at`：最近一次部署时间
- `enabled_protocols`：当前启用协议列表
- `ports`：各协议端口
- `shared_credentials`：共享 UUID / Reality short-id / public key 等简化信息
- `paths`：证书、env 文件等关键路径

---

现在这套脚本分两层：

- `gen-home.sh`
  - 配置生成器
  - 生成 sing-box 服务端配置、systemd 模板、客户端片段、manifest
- `install-home.sh`
  - 一键安装部署器
  - 在目标 Linux 机器上下载 sing-box、准备证书/凭据、生成配置、写入 systemd、校验并启动

当前服务端已支持的协议顺序统一为：

1. `Hysteria2`
2. `Shadowsocks`
3. `VLESS gRPC Reality`
4. `Trojan`（需申请证书，仅支持域名挂靠 Cloudflare）
5. `AnyTLS`（需申请证书，仅支持域名挂靠 Cloudflare）
6. `VLESS Brutal Reality`
7. `安装所有`

其中：

- 选择 `7) 安装所有` 等价于一次启用当前全部协议
- 如果输入里同时混用 `7` 与其他编号，脚本会按“全选”处理，不会重复添加

---

## 交互流程（最新）

交互模式：

```bash
sudo ./install-home.sh

# 非交互直接卸载
sudo ./install-home.sh --uninstall
```

流程：

1. 先检查并展示当前环境状态
   - `sing-box` 是否已安装
   - service 是否存在 / 是否运行中
   - `config.json` 是否存在
   - 当前已配置了哪些协议
2. 显示主菜单
   - `1) 配置 sing-box 回家`
   - `2) 卸载`
   - `3) 退出脚本`
   - `4) 导出客户端节点信息`
   - 选择 `2) 卸载` 会二次确认，并删除脚本管理的 `sing-box`、service、配置目录与 ACME 域名证书数据（不处理 brutal）
   - 选择 `4) 导出客户端节点信息` 会复用最近一次安装产物目录，先在 shell 展示节点信息，再询问是否导出
   - 导出询问里回车默认导出到 `/root`，也支持输入其他目录
3. 如果检测到 sing-box 已安装且 service 正在运行，先问：
   - `是否覆盖更新二进制？ [y/N]`
   - 默认仍是 **N**
4. 再选择协议组合
   - 回车默认：`1,2`
   - 也就是只默认启用 **Hy2 + SS**
   - 也可以直接输入 `7` 表示 **安装所有**
   - 交互会显示协议备注：
     - `Trojan / AnyTLS` 需申请证书，且仅支持域名挂靠 Cloudflare
     - `VLESS Brutal Reality` 需要安装证书与 brutal，若安装失败该协议不可用
   - 这是刻意保守的默认值：
     - 不默认开启需要 ACME 的 `Trojan / AnyTLS`
     - 也不默认开启需要 brutal 内核能力的 `VLESS Brutal Reality`
5. 展示配置增量计划
   - 当前已配置
   - 拟新增协议
   - 已存在并保留
   - 未选但仍保留
6. 再问是否重置已有协议
   - 默认 **不重置**
   - 会显示可重置协议的编号清单
   - 支持输入 `7` 一键重置“上述全部协议”
   - 若重置里包含 `Trojan/AnyTLS`，且检测到已有证书，会额外询问是否重置证书
   - 若选择“不重置证书”，脚本会优先复用已有证书和域名，通常不再要求重新输入 DDNS
7. 最后才收集参数
   - `DDNS 域名 / 公网 IP`（用于申请证书，并复用到客户端配置的 `server`）
   - 端口
   - 如果本次新增/重置了 `Trojan` 或 `AnyTLS`，才继续问 ACME / Cloudflare 参数
8. 如果只是保留已有协议、只新增部分协议，脚本会尽量只问本次确实需要的参数
   - 例如端口只会针对“新增或重置”的协议询问
   - 仅保留现有 `Trojan / AnyTLS` 时，若现有证书文件已存在，则直接复用，不重新申请 ACME 证书
   - 如果这次需要重新申请 ACME，但申请失败：
     - **不会让整个脚本退出**
     - 会自动跳过 `Trojan / AnyTLS`
     - 其他如 `SS / Hy2 / VLESS gRPC Reality / VLESS Brutal Reality` 继续安装
     - 终端会提示类似：`Trojan/AnyTLS skipped because ACME failed`
9. 如果启用了 `VLESS Brutal Reality`，脚本会先探测环境并尝试安装 brutal；失败则跳过该协议，其他协议继续
10. 安装完成后，进入客户端节点导出向导
   - 可选：`1) 生成 sing-box 节点` / `2) 生成 clash/mihomo 节点` / `3) 全部生成` / `0) 跳过`
   - 会先在终端展示本次已完成协议对应的客户端片段
   - 同时写入 `/root/sing-box-nodes.json` 和/或 `/root/clash-nodes.yaml`
   - `sing-box` 导出使用安装脚本内置模板
   - 模板中的 `server / server_port / uuid / password / reality(public_key, short_id)` 等会按本次安装结果自动填充
   - `VLESS Brutal Reality` 的 `multiplex.brutal.up_mbps/down_mbps` 固定写入 `1000/1000`
   - `clash/mihomo` 当前输出全协议模板（`Hy2 / SS / Trojan / AnyTLS / VLESS gRPC Reality / VLESS Brutal Reality`）

---

## 默认端口

按统一顺序：

- `Hysteria2 = 55501`
- `Shadowsocks = 55502`
- `Trojan = 55503`
- `AnyTLS = 55504`
- `VLESS gRPC Reality = 55505`
- `VLESS Brutal Reality = 55506`

---

## 证书与目录约定

### Hysteria2

使用单独目录：

- `/usr/local/etc/sing-box/certs/hysteria/private.key`
- `/usr/local/etc/sing-box/certs/hysteria/cert.pem`
- `/usr/local/etc/sing-box/certs/hysteria/cert.crt`

### Trojan / AnyTLS

共用统一证书目录：

- `/usr/local/etc/sing-box/certs/default/private.key`
- `/usr/local/etc/sing-box/certs/default/cert.crt`

通过 `acme.sh + Let's Encrypt + Cloudflare DNS API` 签发。

### VLESS gRPC Reality

不依赖 ACME 证书，凭据持久化到：

- `<config-dir>/credentials/vless-grpc-reality.env`

### VLESS Brutal Reality

`VLESS Brutal Reality` 仍然属于 **Reality** 方案，技术上不直接依赖 ACME 证书。

但为了和老大说的“域名和证书用 Trojan 那个”保持一致语义，脚本默认会：

- 复用与 `Trojan` 同源的 **域名 / server_name 默认值**
  - 即优先用 `ACME_DOMAIN`
  - 没有 ACME 域名时回落到 `--host`
- **不会**因为这个要求，硬把 Reality 配错成强依赖证书的 TLS 入站

也就是说：

- `Trojan / AnyTLS` 真正使用 `/usr/local/etc/sing-box/certs/default/`
- `VLESS Brutal Reality` 默认只复用 Trojan 的 `server_name / 域名语义`
- 如果后面实际实现需要证书，再优先复用 `/usr/local/etc/sing-box/certs/default/`

---

## 共享身份参数策略

这里选的是更工程化、也更稳的方案：

- **复用现有 VLESS gRPC Reality 的 Reality keypair / UUID / short-id**
- `VLESS Brutal Reality` 默认直接复用这套参数
- `Trojan / AnyTLS` 继续复用共享 `ACCESS_UUID` 体系作为密码来源

这样做的好处：

- 不新增一套独立 `vless-brutal-reality.env`
- 凭据数量少，重跑脚本时更稳定
- `VLESS gRPC Reality` 和 `VLESS Brutal Reality` 客户端身份默认一致，便于管理
- 如果以后需要拆分，也可以再扩展为独立 env

manifest 里会记录 `vless_brutal_reality` 字段，以及它是否与 `vless_grpc_reality` 共用身份参数。

---

## brutal 依赖与跳过策略

当启用 `VLESS Brutal Reality` 时，安装脚本会：

1. 输出一些环境探测日志，例如：
   - 是否像是 LXC / 容器环境
   - `/dev/net/tun` 是否存在
   - `brutal` 是否已存在
2. 尝试安装 brutal 相关依赖：
   - `apt update`
   - `apt install clang llvm lld curl`
3. 尝试安装 brutal：
   - `bash <(curl -fsSL https://tcp.hy2.sh/)`

### 失败处理

如果 brutal 安装失败：

- **不会退出整个安装脚本**
- 会把 `VLESS Brutal Reality` 标记为 `skipped`
- 其他协议继续生成、继续部署
- 最终摘要会明确输出：
  - `brutal_status=skipped`
  - `brutal_skipped_reason=...`

运行过程中也会看到类似提示：

```text
[WARN] VLESS Brutal Reality: skipped
[WARN] VLESS Brutal Reality skip reason: brutal bootstrap failed (see /tmp/.../brutal-install.log)
```

### LXC / unprivileged 环境说明

`TCP Brutal` 依赖内核能力和 brutal 模块/脚本安装条件。

因此在这些环境里尤其容易失败：

- `LXC`
- `unprivileged container`
- 缺少所需内核能力的宿主机 / 容器

这类情况下，脚本设计就是：

- 尝试安装
- 安装不上就跳过
- 不拖垮 SS / Hy2 / Trojan / AnyTLS / VLESS gRPC Reality 的安装流程

---

## gen-home.sh 当前输出

客户端片段支持：

- `Shadowsocks`
  - sing-box outbound：有
  - mihomo：有
- `Hysteria2`
  - sing-box outbound：有
  - mihomo：有
- `Trojan`
  - sing-box outbound：有
  - mihomo：有
- `AnyTLS`
  - sing-box outbound：有
  - mihomo：有
- `VLESS gRPC Reality`
  - sing-box outbound：有
  - mihomo：有
- `VLESS Brutal Reality`
  - sing-box outbound：有
  - mihomo：有

---

## install-home.sh 输出摘要

安装完成后会输出：

- 一段更适合人看的中文摘要：
  - 已启用协议列表
  - 每个协议的端口映射建议
  - `Hy2` 走 **UDP**，其他协议走 **TCP**
  - 提醒去主路由做好端口映射
  - 如果有协议被跳过，也会显示跳过原因（例如 `ACME failed`）
- 服务名、二进制路径、配置路径
- artifact / backup 目录
- 各协议客户端片段路径
- VLESS / Trojan / AnyTLS 所需凭据
- `brutal_status=enabled|disabled|skipped`
- 若 ACME 失败跳过 `Trojan / AnyTLS`，还会输出：
  - `acme_skipped_protocols=...`
  - `acme_skip_reason=ACME failed`
- 若跳过 brutal，还会输出 `brutal_skipped_reason`

不会输出：

- `CF_Key`
- `CF_Email`
- `acme 注册邮箱`

---

## 本地验证建议

目前已做的静态验证目标应包括：

- `bash -n scripts/install-home.sh`
- `bash -n scripts/gen-home.sh`
- grep 检查以下关键点是否存在：
  - `VLESS Brutal Reality: skipped`
  - `--enable-vless-brutal-reality`
  - `vless_brutal_reality`
  - `brutal_status`

仍需在真实目标机继续验证的点：

1. brutal 安装脚本在实际 Debian / Ubuntu VPS 上是否能把 `brutal` 正确装出来
2. `sing-box check` 对 `multiplex.brutal` 字段在目标 sing-box 版本上的兼容性
3. 各客户端对 `VLESS Brutal Reality` 出站片段的实际连通性
4. LXC / unprivileged 环境里的跳过分支日志是否符合预期


## 输出模式
- 默认只显示中文安装摘要
- 若需要详细机器可读输出（`[OUT] ...`），请加 `--verbose`
