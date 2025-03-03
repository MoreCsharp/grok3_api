# 构建阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装依赖（如果需要系统级别的依赖）
# RUN apk add --no-cache git make gcc musl-dev

# 复制并下载依赖（假设使用 Go Modules）
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建静态二进制文件（匹配你的 CI 配置）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o grok3_api

# 运行时阶段
FROM gcr.io/distroless/static-debian12:latest

# 设置非 root 用户（增强安全性）
USER nonroot:nonroot

# 设置工作目录并复制二进制文件
WORKDIR /app
COPY --from=builder --chown=nonroot:nonroot /app/grok3_api .

# 暴露端口（根据你的实际应用端口修改）
EXPOSE 8080

# 启动应用
ENTRYPOINT ["/app/grok3_api"]
