FROM python:3.9-alpine
RUN apk add --update gcc python3-dev libffi-dev musl-dev && \
    pip3 wheel --wheel-dir=/srv/wheels pip 'devpi-server==6.20.2' 'devpi-client==7.3.0' 'devpi-web==5.1.1' 'devpi-semantic-ui-ng==0.3.2'

FROM python:3.9-alpine
COPY --from=0 /srv/wheels /srv/wheels
VOLUME /srv/devpi
ENV DEVPISERVER_SERVERDIR=/var/lib/devpi
ENV SOURCE_MIRROR_URL=https://mirror.sjtu.edu.cn/pypi/web/simple
RUN pip3 install --no-cache-dir --no-index --find-links=/srv/wheels devpi-server devpi-client devpi-web devpi-semantic-ui-ng
COPY entrypoint.sh /srv/entrypoint.sh
LABEL maintainer="jiangood"
ENTRYPOINT ["/srv/entrypoint.sh"]