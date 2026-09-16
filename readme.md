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

上游镜像源已固定为上海交大 PyPI 源 `https://mirror.sjtu.edu.cn/pypi/web/simple`，不支持运行时通过环境变量切换；如需更换源头，请修改 `entrypoint.sh` 后重新构建镜像。

## pip 使用

所有人匿名访问（`root/pypi` 即镜像缓存索引）：

```bash
pip install <包名> -i http://<主机>:7104/root/pypi/+simple/ --trusted-host <主机>:7104
```

## 构建与发布

推送到 GitHub 会触发 `publish` workflow 自动构建并发布镜像：

```bash
git tag v1.0.0
git push origin v1.0.0
```