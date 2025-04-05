FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libffi-dev libssl-dev && \
    pip install --no-cache-dir heralding && \
    apt-get remove -y gcc libffi-dev libssl-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /heralding
VOLUME /heralding/logs

COPY ./config/heralding.yml /etc/heralding/heralding.yml

EXPOSE 21 22 23 25 80 110 143 443 465 993 995 1080 5432 5900

CMD ["heralding", "-c", "/etc/heralding/heralding.yml"]
