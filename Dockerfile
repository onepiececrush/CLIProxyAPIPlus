FROM golang:1.24-alpine AS builder

ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY} https_proxy=${HTTPS_PROXY}

WORKDIR /app

# 使用阿里云 Go 代理
ENV GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

COPY go.mod go.sum ./

RUN go mod download

# 清除代理设置
ENV http_proxy= https_proxy=

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w -X 'main.Version=${VERSION}-plus' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o ./CLIProxyAPIPlus ./cmd/server/

FROM alpine:3.22.0

RUN apk add --no-cache tzdata

RUN mkdir /CLIProxyAPI

COPY --from=builder ./app/CLIProxyAPIPlus /CLIProxyAPI/CLIProxyAPIPlus

COPY config.example.yaml /CLIProxyAPI/config.example.yaml

WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

CMD ["./CLIProxyAPIPlus"]