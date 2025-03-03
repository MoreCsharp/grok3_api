# 使用官方 Go 基础镜像。
FROM golang:latest AS builder

# 设置容器内的工作目录。
WORKDIR /app

# 复制 Go 模块文件。这样做是为了利用 Docker 的层缓存。
# 如果 go.mod 和 go.sum 文件没有改变，那么这一层和下一层 ('go mod download') 将被缓存，
# 如果只有源文件发生变化，这将显著加快构建速度。
COPY go.mod go.sum ./

# 下载 Go 模块依赖。这也使用了层缓存。
RUN go mod download

# 复制整个项目的源代码。
COPY . .

# 构建 Go 应用程序（静态链接）。
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o grok3_api

# --- 最终镜像 ---

# 使用一个更小、更精简的基础镜像作为最终的运行时镜像，以减小体积。
# scratch 是最小的，但 alpine 通常更受欢迎，因为它包含一些调试工具。
# 这里使用 alpine。
FROM alpine:latest

# 从 builder 阶段复制已构建的二进制文件。
COPY --from=builder /app/grok3_api /usr/local/bin/grok3_api

# 可选：设置一个非 root 用户以提高安全性。这是一个很好的做法。
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 公开你的应用程序侦听的端口（请替换为你实际的端口）。
# 你需要确定 grok3_api 使用的端口并将其放在这里。
EXPOSE 8180  # 将 8080 替换为 grok3_api 使用的实际端口！

# 定义容器的入口点。
ENTRYPOINT ["/usr/local/bin/grok3_api"]

# 可选：设置默认的命令参数（如果你的应用程序使用它们）。
# CMD ["--some-flag", "some-value"]
