# devpi Docker 镜像

用 Docker 快速启动一个 [devpi](https://devpi.net/docs/devpi/devpi/stable/%2Bd/index.html) 服务作为内部 pip 缓存：

- **按需缓存**：首次 pip 安装时从上游源下载并缓存，之后直接命中本地缓存，不占满硬盘。
- **无需登录**：不配置账号密码，所有人可匿名下载。

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

## 上游源

上游镜像源固定为上海交大 PyPI 源 `https://mirror.sjtu.edu.cn/pypi/web/simple`，不支持运行时通过环境变量切换；如需更换源头，请修改 `entrypoint.sh` 后重新构建镜像。

> 上海交大镜像为 S3 后端，根路径不提供标准 PEP 503 项目清单，因此索引需启用 `mirror_no_project_list=True`（devpi-server 6.9.0+），改为按需向镜像拉取单个项目页面。

## pip 使用

所有人匿名访问（`root/pypi` 即镜像缓存索引）。

**全局配置（推荐）**：`pip config set` 会写入用户级配置文件（Linux/macOS 为 `~/.config/pip/pip.conf`，Windows 为 `%APPDATA%\pip\pip.ini`），一次配置永久生效，之后的 `pip install` 无需任何额外参数：

```bash
pip config set global.index-url http://<主机>:7104/root/pypi/+simple/
pip config set global.trusted-host <主机>
```

由于走 HTTP（非 HTTPS），必须配置 `trusted-host` 才能信任该源，否则 pip 会拒绝明文访问。

**临时使用**：仅对当前这条命令生效，适合偶尔单次安装：

```bash
pip install <包名> -i http://<主机>:7104/root/pypi/+simple/ --trusted-host <主机>:7104
```

## 添加额外镜像源

如需缓存其他 PyPI 兼容源（如 PyTorch CUDA wheel），可手动创建镜像索引。进入容器执行：

```bash
docker exec -it <容器名> sh -c '
  devpi use http://0.0.0.0:7104
  devpi login root --password=""
  devpi index -c root/cu130 type=mirror \
    mirror_url=https://mirror.sjtu.edu.cn/pytorch-wheels/cu130 \
    mirror_no_project_list=True \
    mirror_web_url_fmt="https://mirror.sjtu.edu.cn/pytorch-wheels/cu130/{name}/"
  devpi logout
'
```

`-c` 表示创建；更新已有索引时去掉即可。

**客户端 pip 配置**（同时使用主源和额外源）：

```bash
pip config set global.index-url http://<主机>:7104/root/pypi/+simple/
pip config set global.extra-index-url http://<主机>:7104/root/cu130/+simple/
pip config set global.trusted-host <主机>
```

验证索引是否就绪：

```bash
curl http://<主机>:7104/root/cu130/+simple/torch/
```

首次请求会触发按需拉取并缓存，之后直接命中本地。

## 添加额外索引

如需缓存其他 PyPI 源（如 PyTorch CUDA wheel），可在目标机上手动创建镜像索引：

```bash
docker exec -it <容器名> sh -c '
  devpi use http://0.0.0.0:7104
  devpi login root --password=""
  devpi index -c root/cu130 type=mirror \
    mirror_url=https://mirror.sjtu.edu.cn/pytorch-wheels/cu130 \
    mirror_no_project_list=True \
    mirror_web_url_fmt="https://mirror.sjtu.edu.cn/pytorch-wheels/cu130/{name}/"
  devpi logout
'
```

`-c` 表示创建新索引；更新已有索引时去掉 `-c` 即可。访问方式：`http://<主机>:7104/root/cu130/+simple/`。

**pip 同时使用多个索引**：`global.extra-index-url` 支持逗号分隔多个地址，或分别设置 `index-url` 和 `extra-index-url`：

```bash
pip config set global.index-url http://<主机>:7104/root/pypi/+simple/
pip config set global.extra-index-url http://<主机>:7104/root/cu130/+simple/
pip config set global.trusted-host <主机>
```

> pip 会同时查询所有索引，优先选择版本号更高的包（如 `+cu130` > CPU 版）。

## 构建与发布

推送到 GitHub 会触发 `publish` workflow 自动构建并发布镜像：

```bash
git tag v1.0.0
git push origin v1.0.0
```