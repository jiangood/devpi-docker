# devpi Docker 镜像

用 Docker 快速启动一个 [devpi](https://devpi.net/docs/devpi/devpi/stable/%2Bd/index.html) 服务作为内部 pip 源：

- **按需缓存**：首次 pip 安装时从上游源下载并缓存，之后直接命中本地缓存，不占满硬盘。
- **可指定上游**：只需一个环境变量 `SOURCE_MIRROR_URL` 即可切换上游源（内网用国内源更快）。
- **无需登录**：不配置账号密码，所有人可匿名下载与上传。

## 快速开始

```bash
docker run -d --name devpi \
  -p 7104:7104 \
  -v data:/var/lib/devpi \
  ghcr.io/jiangood/devpi:latest
```

启动后访问 http://0.0.0.0:7104 即可打开 devpi 页面。

也可以用 docker compose：

```yaml
services:
  devpi:
    image: ghcr.io/jiangood/devpi:latest
    ports:
      - "7104:7104"
    volumes:
      - ./data:/var/lib/devpi
```

## 环境变量

只需配置 `SOURCE_MIRROR_URL`，其余都有默认值：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `SOURCE_MIRROR_URL` | `https://mirror.sjtu.edu.cn/pypi/web/simple` | 上游镜像源 |
| `DEVPISERVER_HOST` | `0.0.0.0` | 监听地址 |
| `DEVPISERVER_PORT` | `7104` | 监听端口 |
| `DEVPISERVER_MIRROR_INDEX` | `pypi` | 镜像 index |
| `DEVPISERVER_LIB_INDEX` | `devpi` | 业务 index |

## pip 使用

不区分用户，所有人匿名访问（`root/devpi` 为默认业务 index，`root/pypi` 为镜像 index）：

```bash
pip install <包名> -i http://<主机>:7104/root/devpi/+simple/ --trusted-host <主机>:7104
```

## 上传包

安装 `devpi-client`（>=6.0.3）后匿名上传即可：

```bash
devpi use http://<主机>:7104/root/devpi
devpi upload
```

## 构建与发布

```bash
cd docker
docker login ghcr.io
./build.sh   # 构建并推送到 ghcr.io/jiangood/devpi:latest
```