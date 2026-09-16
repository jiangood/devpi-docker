FROM python:3.11-slim
RUN pip install --no-cache-dir \
    devpi-server==6.20.2 \
    devpi-web==5.1.1 \
    devpi-client==7.3.0
VOLUME /var/lib/devpi
EXPOSE 7104
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]