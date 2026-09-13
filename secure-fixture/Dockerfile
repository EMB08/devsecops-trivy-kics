FROM alpine:3.24.1

RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/* && \
    addgroup -S appgroup && \
    adduser -S appuser -G appgroup

USER appuser
