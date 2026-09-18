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
| `MIRROR_URL` | `https://mirror.sjtu.edu.cn/pypi/web/simple` | `root/pypi` 索引的上游源，容器每次启动时生效 |
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

其他常用源：`https://pypi.org/simple`、`https://mirrors.tuna.tsinghua.edu.cn/pypi/simple`、`https://mirrors.aliyun.com/pypi/simple/`。

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
  mirror_no_project_list=True \
  mirror_web_url_fmt="https://mirror.sjtu.edu.cn/pytorch-wheels/cu130/{name}/"
devpi logout
```

创建用 `-c`，更新已有索引时去掉。客户端配合多索引：

```bash
pip config set global.extra-index-url http://<主机>:7104/root/cu130/+simple/
```

pip 会同时查询所有索引并优先取版本更高的包（如 `+cu130` > CPU 版）。

