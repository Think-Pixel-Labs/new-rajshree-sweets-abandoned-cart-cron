FROM alpine:3.19

RUN apk add --no-cache bash curl jq

WORKDIR /app

COPY notify-abandoned.sh .
RUN chmod +x notify-abandoned.sh

CMD ["bash", "/app/notify-abandoned.sh"]
