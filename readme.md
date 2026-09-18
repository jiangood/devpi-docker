# devpi Docker 镜像

用 Docker 快速启动一个 [devpi](https://devpi.net/docs/devpi/devpi/stable/%2Bd/index.html) 服务作为内部 pip 缓存：

- **按需缓存**：首次 pip 安装时从上游源下载并缓存，之后直接命中本地缓存，不占满硬盘。
- **匿名只读**：下载无需登录；设置 `ROOT_PASSWORD` 后，写操作需 root 登录。

## 快速开始

```bash
docker run -d --name devpi \
  -p 7104:7104 \
  -v data:/var/lib/devpi \
  ghcr.io/jiangood/devpi:latest
```

启动后访问 http://0.0.0.0:7104 即可打开 devpi 页面。

## 配置

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MIRROR_URL` | `https://pypi.tuna.tsinghua.edu.cn/simple` | `root/pypi` 索引的上游源，容器每次启动时生效 |
| `NVIDIA_MIRROR_URL` | `https://pypi.nvidia.cn` | `root/nvidia` 索引的上游源（CUDA/NVIDIA 包），置空则不创建该索引 |
| `REQUEST_TIMEOUT` | `30` | devpi 请求上游源的超时秒数 |
| `ROOT_PASSWORD` | （空） | `root` 用户密码，仅在数据卷首次初始化时生效；设置后写操作需登录，读仍匿名 |

上游源访问慢或超时（日志出现 `ReadTimeout` / `UpstreamError`）时，可更换上游源或调大超时：

```yaml
services:
  devpi:
    ...
    environment:
      MIRROR_URL: https://mirrors.aliyun.com/pypi/simple
      REQUEST_TIMEOUT: "30"
```

其他常用源：`https://pypi.org/simple`、`https://pypi.tuna.tsinghua.edu.cn/simple`、`https://mirrors.aliyun.com/pypi/simple/`。

## 鉴权与写操作

默认可匿名**下载**，但写操作（`devpi upload/push`、创建/修改索引）必须登录：

- 未设置 `ROOT_PASSWORD` 时，密码为空：`devpi login root --password=""`。
- 已设置 `ROOT_PASSWORD` 时：`devpi login root --password=<你的密码>`。

> **注意**
> - `ROOT_PASSWORD` 只在数据卷**首次初始化**时生效（`/var/lib/devpi/.nodeinfo` 不存在）。对已有数据卷修改该变量不会改变密码，会因登录失败跳过镜像配置；此时需先用旧密码登录并执行 `devpi user -m root password=<新密码>`，或删除数据卷重建。
> - 未设置密码时，任何能访问 7104 端口的人都能以 `root` 写入，仅适合内网/可信环境。

## pip 使用


**全局配置（推荐）**：

```bash
pip config set global.index-url http://<主机>:7104/root/pypi/+simple/
pip config set global.trusted-host <主机>
```

由于走 HTTP（非 HTTPS），必须配置 `trusted-host` 才能信任该源，否则 pip 会拒绝明文访问。

**临时使用**：仅对当前这条命令生效，适合偶尔单次安装：

```bash
pip install <包名> -i http://<主机>:7104/root/pypi/+simple/ --trusted-host <主机>:7104
```

## requirements.txt 配置

pip 会把 `requirements.txt` 中以 `--` 开头的行当作命令行参数，因此可以直接在文件里声明索引，无需全局配置。**基础用法**（只用主源）：

```text
--index-url http://<主机>:7104/root/pypi/+simple/
--trusted-host <主机>

requests
numpy
```

**需要 CUDA/NVIDIA 包时**再加上 NVIDIA 索引：

```text
--index-url http://<主机>:7104/root/pypi/+simple/
--extra-index-url http://<主机>:7104/root/nvidia/+simple/
--trusted-host <主机>

torch
nvidia-cudnn-cu12
tensorrt-cu12
```

然后正常执行：

```bash
pip install -r requirements.txt
```

注意：`--index-url`、`--extra-index-url`、`--trusted-host` 必须各自单独成行，不能和包名写在同一行。

## NVIDIA / CUDA 源

容器启动时会自动创建 `root/nvidia` 镜像索引，上游为 `https://pypi.nvidia.cn`，用于缓存 CUDA 相关包（如 `nvidia-cudnn-cu12`、`nvidia-cuda-runtime-cu12`、`tensorrt`、`cudf-cu12` 等）。该源只收录 NVIDIA 包，需与主源配合使用：

```bash
pip config set global.extra-index-url http://<主机>:7104/root/nvidia/+simple/
```

pip 会同时查询主源与该索引。如需禁用，将 `NVIDIA_MIRROR_URL` 置空即可。

> 该索引的 `mirror_url` 是 `https://pypi.nvidia.cn`，**不要**加 `/simple` 后缀（NVIDIA 索引不含该路径，会 404）。

## 添加额外索引

需要缓存其他源（如 PyTorch CUDA wheel）时，进入容器后依次执行（以 cu130 为例）：

```bash
docker exec -it devpi sh
```

```bash
devpi use http://0.0.0.0:7104
devpi login root --password="${ROOT_PASSWORD:-}"
devpi index -c root/cu130 type=mirror \
  mirror_url=https://mirror.sjtu.edu.cn/pytorch-wheels/cu130 \
  mirror_web_url_fmt="https://mirror.sjtu.edu.cn/pytorch-wheels/cu130/{name}/"
devpi logout
```

创建用 `-c`，更新已有索引时去掉。客户端配合多索引：

```bash
pip config set global.extra-index-url http://<主机>:7104/root/cu130/+simple/
```

pip 会同时查询所有索引并优先取版本更高的包（如 `+cu130` > CPU 版）。

