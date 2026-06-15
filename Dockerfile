FROM golang:1.22-alpine AS go-builder
WORKDIR /build
COPY go-proxy-cto/go.mod go-proxy-cto/go.sum ./
RUN go mod download
COPY go-proxy-cto/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o cto-proxy .

FROM python:3.11-slim
WORKDIR /app

# System deps for Playwright/Selenium (optional, for registration scripts)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg \
    && rm -rf /var/lib/apt/lists/*

# Copy Go binary
COPY --from=go-builder /build/cto-proxy /app/cto-proxy

# Copy Python scripts
COPY *.py /app/
COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Data directory (accounts.jsonl lives here, mounted as volume in EasyPanel)
RUN mkdir -p /data

# Entrypoint: run Go proxy, point baseDir at /data
ENV CTO_BASE_DIR=/data
ENV PROXY_API_KEY=xs2-cto-secret
ENV GIN_MODE=release

EXPOSE 9091

CMD ["/app/cto-proxy"]