# devpi Docker 镜像

用 Docker 快速启动一个 [devpi](https://devpi.net/docs/devpi/devpi/stable/%2Bd/index.html) 服务作为内部 pip 源：

- **按需缓存**：首次 pip 安装时从上游源下载并缓存，之后直接命中本地缓存，不占满硬盘。
- **可指定上游**：只需一个环境变量 `SOURCE_MIRROR_URL` 即可切换上游源（内网用国内源更快）。

## 快速开始

```bash
docker run -d --name devpi \
  -p 7104:7104 \
  -v volume:/var/lib/devpi \
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
      - ./volume:/var/lib/devpi
```

## 环境变量

只需配置 `SOURCE_MIRROR_URL`，其余都有默认值：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `SOURCE_MIRROR_URL` | `https://mirror.sjtu.edu.cn/pypi/web/simple` | 上游镜像源 |
| `DEVPISERVER_HOST` | `0.0.0.0` | 监听地址 |
| `DEVPISERVER_PORT` | `7104` | 监听端口 |
| `DEVPISERVER_ROOT_PASSWORD` | `password` | root 用户密码 |
| `DEVPISERVER_USER` | `devpi` | 业务用户 |
| `DEVPISERVER_PASSWORD` | `password` | 业务用户密码 |
| `DEVPISERVER_MIRROR_INDEX` | `pypi` | 镜像 index |
| `DEVPISERVER_LIB_INDEX` | `devpi` | 业务 index |

## pip 使用

```bash
pip install <包名> -i http://<主机>:7104/devpi/devpi/+simple/ --trusted-host <主机>:7104
```

## 构建与发布

```bash
cd docker
docker login ghcr.io
./build.sh   # 构建并推送到 ghcr.io/jiangood/devpi:latest
```

## 截图

![](./pics/1.png)

![](./pics/2.png)

![](./pics/3.png)

![](./pics/download.png)