# CLIProxyAPIPlus 架构设计文档

## 项目概述

**CLIProxyAPIPlus** 是一个高级代理API服务，为CLI模型提供与OpenAI、Claude、Gemini等标准AI API兼容的接口。该项目支持多个第三方提供商（GitHub Copilot、Kiro、Antigravity等），并提供灵活的认证、存储和扩展机制。

### 核心特性
- **API兼容性**：支持OpenAI、Claude、Gemini兼容API
- **多提供商支持**：GitHub Copilot、Kiro(AWS CodeWhisperer)、Antigravity等
- **灵活认证**：OAuth 2.0、设备代码流、Cookie等多种认证方式
- **多存储后端**：文件系统、PostgreSQL、Git仓库、S3/Minio对象存储
- **模块化设计**：可插拔的路由模块系统
- **企业特性**：配置热更新、使用统计、访问控制、请求缓存等

---

## 系统架构层级

### 第1层：演示层（Presentation Layer）
负责与客户端的交互

```
├── REST API (HTTP endpoints: /v1/chat/completions等)
├── WebSocket API (流式响应)
└── Management UI (仪表板)
```

### 第2层：API适配层（API Adapter Layer）
提供多个AI提供商的兼容性接口

```
├── OpenAI 兼容接口
│  ├── Chat Completions
│  ├── Embeddings
│  └── Responses
├── Claude 兼容接口
│  ├── Messages API
│  └── Code API
├── Gemini 兼容接口
│  ├── REST API
│  └── CLI API
└── 自定义提供商接口
   ├── Antigravity
   ├── Kiro (Codex)
   └── GitHub Copilot
```

### 第3层：翻译和执行层（Translation & Execution Layer）
标准化请求/响应格式，执行实际API调用

```
├── 请求翻译器 (Request Translator)
│  └── 将任何格式转换为内部统一格式
├── 执行器链 (Executor Pipeline)
│  ├── Gemini Executor
│  ├── Claude Executor
│  ├── OpenAI Executor
│  ├── Codex Executor (Kiro)
│  ├── Antigravity Executor
│  └── GitHub Copilot Executor
└── 响应翻译器 (Response Translator)
   └── 将内部格式转换回客户端格式
```

### 第4层：提供商层（Provider Layer）
与上游AI服务的实际连接

```
├── Google Gemini (REST API)
├── Anthropic Claude (REST API)
├── OpenAI (REST API)
├── AWS CodeWhisperer (Kiro)
├── GitHub Copilot (Device Code Flow)
└── 其他第三方提供商
```

### 第5层：认证层（Authentication Layer）
处理令牌管理和用户认证

```
├── OAuth 2.0 流程 (浏览器-based)
├── 设备代码流 (终端-based)
├── 令牌管理 (刷新、验证)
├── 认证提供商
│  ├── Google Auth
│  ├── Claude Auth
│  ├── Kiro Auth (AWS/Google)
│  ├── GitHub Copilot Auth
│  └── 其他提供商
└── 令牌存储 (多后端支持)
```

### 第6层：持久化层（Persistence Layer）
多种存储后端支持

```
├── 文件存储 (本地文件系统)
├── PostgreSQL (云数据库)
├── Git仓库 (版本控制)
└── 对象存储 (S3/Minio)
```

### 第7层：基础设施层（Infrastructure）
支撑系统运行的各种工具

```
├── 配置管理 (YAML配置)
├── 请求缓存 (性能优化)
├── 结构化日志 (Logrus)
├── 使用统计 (遥测)
├── 配置监听 (热重载)
└── 访问控制 (权限管理)
```

---

## 目录结构

```
.
├── cmd/
│   └── server/
│       └── main.go                 # 应用入口点
├── internal/
│   ├── api/                        # HTTP API服务器
│   │   ├── server.go               # 服务器实现
│   │   ├── middleware/             # 中间件 (CORS, Auth)
│   │   ├── handlers/               # HTTP处理器
│   │   │   └── management/         # 管理接口
│   │   └── modules/                # 可插拔模块系统
│   │       ├── modules.go          # 模块接口定义
│   │       └── amp/                # Amp模块实现
│   ├── auth/                       # 认证实现
│   │   ├── gemini/                 # Google Gemini认证
│   │   ├── claude/                 # Claude认证
│   │   ├── codex/                  # Codex/OpenAI认证
│   │   ├── kiro/                   # Kiro(AWS)认证
│   │   ├── copilot/                # GitHub Copilot认证
│   │   └── ...
│   ├── cmd/                        # 命令行命令
│   │   ├── run.go                  # 服务启动
│   │   ├── login.go                # OAuth登录
│   │   ├── auth_manager.go         # 认证管理器
│   │   ├── kiro_login.go           # Kiro登录
│   │   ├── github_copilot_login.go # Copilot登录
│   │   └── ...
│   ├── config/                     # 配置系统
│   │   ├── config.go               # 配置结构体
│   │   └── sdk_config.go           # SDK配置
│   ├── runtime/
│   │   └── executor/               # 执行器实现
│   │       ├── gemini_executor.go
│   │       ├── claude_executor.go
│   │       ├── openai_executor.go
│   │       ├── codex_executor.go
│   │       ├── kiro_executor.go
│   │       ├── antigravity_executor.go
│   │       └── ...
│   ├── translator/                 # 格式转换逻辑
│   │   └── (多个翻译器实现)
│   ├── store/                      # 令牌存储实现
│   │   ├── postgresstore.go        # PostgreSQL后端
│   │   ├── gitstore.go             # Git后端
│   │   └── objectstore.go          # S3/Minio后端
│   ├── registry/                   # 模型注册表
│   │   ├── model_registry.go
│   │   └── model_definitions.go
│   ├── cache/                      # 请求缓存
│   ├── usage/                      # 使用统计
│   ├── logging/                    # 日志系统
│   ├── watcher/                    # 配置监听
│   ├── wsrelay/                    # WebSocket中继
│   ├── browser/                    # 浏览器集成
│   ├── access/                     # 访问控制
│   ├── interfaces/                 # 接口定义
│   ├── constant/                   # 常量定义
│   └── util/                       # 工具函数
├── sdk/                            # SDK实现
│   ├── api/                        # API处理器
│   │   └── handlers/               # 处理器实现
│   │       ├── handlers.go         # 基础处理器
│   │       ├── openai/             # OpenAI处理器
│   │       ├── claude/             # Claude处理器
│   │       └── gemini/             # Gemini处理器
│   ├── auth/                       # 认证SDK
│   │   ├── auth.go                 # 认证接口
│   │   └── token_store.go          # 令牌存储接口
│   ├── cliproxy/                   # 核心SDK
│   └── access/                     # 访问控制SDK
├── auths/                          # 存储认证凭证
├── config.yaml                     # 配置文件
├── config.example.yaml             # 配置示例
├── Dockerfile                      # 容器镜像
├── docker-compose.yml              # 容器编排
└── go.mod                          # Go模块定义
```

---

## 核心数据流

### 1. API请求处理流程

```
客户端请求
  ↓
[路由匹配] (Gin路由)
  ↓
[身份验证] (API Key验证)
  ↓
[请求解析] (JSON/Proto解析)
  ↓
[格式标准化] (Request Translator)
  ↓
[提供商选择] (根据model决定使用哪个执行器)
  ↓
[令牌检索和刷新] (从TokenStore获取/刷新令牌)
  ↓
[调用上游API] (HTTP/gRPC请求)
  ↓
[缓存响应] (可选)
  ↓
[统计使用] (记录使用指标)
  ↓
[格式转换] (Response Translator)
  ↓
[流式/HTTP响应] (WebSocket或HTTP)
  ↓
[请求日志] (审计跟踪)
  ↓
客户端接收响应
```

### 2. 认证流程

```
用户发起登录命令
  ↓
[选择认证方法]
  ├─→ OAuth 2.0 (浏览器流程)
  │     ↓
  │   [打开浏览器]
  │     ↓
  │   [用户授权]
  │     ↓
  │   [回调并获取令牌]
  │
  └─→ 设备代码流 (Kiro/Copilot)
        ↓
      [显示验证代码]
        ↓
      [用户在网页认证]
        ↓
      [轮询获取令牌]

      ↓
[令牌存储] (根据配置选择存储后端)
  ├─→ 文件系统 (本地)
  ├─→ PostgreSQL (远程数据库)
  ├─→ Git仓库 (版本控制)
  └─→ S3/Minio (对象存储)
      ↓
完成登录
```

### 3. 配置更新流程（热重载）

```
配置文件变更
  ↓
[文件监听器检测]
  ↓
[重新加载配置]
  ↓
[通知各模块]
  ├─→ API模块
  ├─→ 执行器
  ├─→ 模块系统
  └─→ 其他组件
      ↓
应用新配置 (无需重启)
```

---

## 关键组件详解

### 1. HTTP服务器 (`internal/api/server.go`)

**职责**：
- 使用Gin框架处理HTTP请求
- 管理中间件链（认证、CORS、日志）
- 注册API路由
- 热加载配置

**主要方法**：
- `New(cfg *config.Config, ...) *Server` - 创建服务器
- `Start(addr string) error` - 启动HTTP服务器
- `RegisterModule(mod modules.RouteModule) error` - 注册模块

### 2. 请求翻译器 (`internal/translator/`)

**职责**：
- 标准化不同格式的请求到内部格式
- 标准化响应回到客户端期望的格式
- 支持流式和非流式响应

**实现**：
- OpenAI→Gemini翻译器
- Claude→任何格式翻译器
- Gemini→OpenAI兼容格式
- 等等

### 3. 执行器链 (`internal/runtime/executor/`)

**职责**：
- 实现提供商特定的API调用逻辑
- 管理令牌生命周期
- 处理缓存、日志、指标

**执行器类型**：
```go
// 每个执行器都有类似的接口
type Executor interface {
    Execute(ctx context.Context, req *Request) (*Response, error)
    RefreshToken(ctx context.Context) error
    GetUsage() Usage
}
```

### 4. 令牌存储 (`internal/store/`)

**职责**：
- 持久化认证令牌
- 支持多个存储后端
- 提供统一的接口

**支持的后端**：
- **文件存储**：本地JSON文件
- **PostgreSQL**：关系数据库
- **Git存储**：Git版本控制
- **对象存储**：S3/Minio兼容

### 5. 模块系统 (`internal/api/modules/`)

**职责**：
- 提供可插拔的路由扩展机制
- 支持动态模块注册
- 模块间相对独立

**模块接口**：
```go
type RouteModuleV2 interface {
    Name() string
    Register(ctx Context) error
    OnConfigUpdated(cfg *config.Config) error
}
```

**现有模块**：
- **Amp模块**：Amp代码集成
- **管理模块**：仪表板和管理接口

### 6. 认证系统 (`internal/auth/`, `sdk/auth/`)

**职责**：
- 处理不同提供商的认证流程
- 管理令牌刷新
- 提供统一的认证接口

**认证提供商**：
- Google/Gemini (OAuth)
- Anthropic/Claude (OAuth)
- OpenAI/Codex (API Key)
- AWS/Kiro (设备代码流、AWS Builder ID)
- GitHub/Copilot (设备代码流)
- Antigravity (OAuth)

### 7. 配置系统 (`internal/config/`)

**配置结构**：
```yaml
port: 8080                    # HTTP服务器端口
auth_dir: ./auths            # 认证凭证目录
log:
  level: info
  output: stdout
providers:
  gemini:
    enabled: true
  claude:
    enabled: true
```

**特性**：
- 支持环境变量覆盖
- 云部署模式支持
- 配置热重载
- 远程管理支持

---

## 工作流程示例

### 示例1：处理OpenAI兼容的聊天请求

```
1. 客户端发送: POST /v1/chat/completions (OpenAI格式)
   
2. 服务器接收:
   - 路由匹配到ChatCompletionsHandler
   - 验证API密钥
   
3. 翻译请求:
   - OpenAI格式 → 内部格式
   - 确定目标提供商 (根据model参数)
   
4. 选择执行器:
   - model="gpt-4" → OpenAI Executor
   - model="claude-3" → Claude Executor
   - model="gemini-pro" → Gemini Executor
   
5. 执行流程:
   - 从TokenStore检索令牌
   - 检查缓存 (如果启用)
   - 调用上游API
   
6. 处理响应:
   - 缓存响应 (如果启用)
   - 记录使用统计
   - 翻译为OpenAI兼容格式
   
7. 返回结果:
   - 流式: 通过WebSocket推送
   - 非流式: 一次性返回JSON
   
8. 记录日志
```

### 示例2：Kiro(AWS CodeWhisperer)认证流程

```
1. 用户运行: ./cli --kiro-login
   
2. 系统检测:
   - 确定Kiro认证方法
   - 选择设备代码流或授权码流
   
3. 认证流程:
   - Kiro Login Handler启动
   - 生成设备代码
   - 显示验证URL给用户
   - 用户访问URL并授权
   - 后台轮询等待授权
   
4. 令牌获取:
   - AWS认证服务返回令牌
   - 刷新令牌 (如果需要)
   
5. 存储令牌:
   - 根据配置选择后端
   - 存储加密的凭证
   
6. 验证成功:
   - 显示确认信息
   - 用户可开始使用
```

---

## 扩展点

### 1. 添加新的AI提供商

步骤：
1. 在 `internal/auth/<provider>/` 创建认证实现
2. 在 `internal/runtime/executor/` 创建执行器
3. 在 `internal/translator/` 创建翻译器（如需要）
4. 在 `internal/cmd/` 添加登录命令
5. 注册到 `internal/registry/model_registry.go`

### 2. 添加新的存储后端

步骤：
1. 在 `internal/store/` 实现 `TokenStore` 接口
2. 在 `cmd/server/main.go` 中注册初始化逻辑
3. 添加环境变量支持

### 3. 添加新的模块

步骤：
1. 实现 `RouteModuleV2` 接口
2. 在初始化时调用 `modules.RegisterModule()`
3. 模块可自动接收配置更新通知

### 4. 自定义中间件

步骤：
1. 创建 `gin.HandlerFunc` 类型的中间件
2. 使用 `WithMiddleware()` ServerOption注册
3. 中间件将插入到默认中间件链中

---

## 配置管理

### 环境变量支持

```bash
# PostgreSQL后端
PGSTORE_DSN="postgresql://user:pass@host/db"
PGSTORE_SCHEMA="public"

# Git后端
GITSTORE_GIT_URL="https://github.com/user/repo.git"
GITSTORE_GIT_USERNAME="user"
GITSTORE_GIT_TOKEN="token"

# 对象存储后端
OBJECTSTORE_ENDPOINT="https://s3.amazonaws.com"
OBJECTSTORE_ACCESS_KEY="access"
OBJECTSTORE_SECRET_KEY="secret"
OBJECTSTORE_BUCKET="bucket-name"

# 云部署模式
DEPLOY="cloud"
```

### 配置文件结构

```yaml
port: 8080
auth_dir: ./auths
incognito_browser: true
disable_cooling: false
usage_statistics_enabled: true

providers:
  gemini:
    enabled: true
  claude:
    enabled: true
  openai:
    enabled: true

request_log:
  enabled: true
  format: json

streaming:
  enabled: true
  timeout: 300

routing:
  rules: []

amp_model_mapping: {}

payload_config:
  max_tokens_override: {}
```

---

## 安全考虑

1. **令牌管理**：
   - 令牌存储在安全的后端
   - 支持加密存储
   - 自动刷新过期令牌

2. **API密钥验证**：
   - 中间件验证所有请求
   - 支持自定义访问控制

3. **HTTPS支持**：
   - TLS配置支持
   - 证书管理

4. **日志安全**：
   - 敏感信息过滤
   - 审计跟踪

---

## 性能优化

1. **请求缓存**：
   - 减少重复调用
   - 可配置的缓存策略

2. **连接池**：
   - HTTP客户端连接复用
   - 数据库连接池

3. **异步处理**：
   - 流式响应
   - 后台任务处理

4. **资源限制**：
   - 请求超时配置
   - 并发限制

---

## 部署选项

### 本地部署
```bash
./cli --config config.yaml
```

### Docker部署
```bash
docker-compose up
```

### 云部署 (带自动配置)
```bash
DEPLOY=cloud ./cli
```

---

## 监控和诊断

### 日志
- 结构化日志 (Logrus)
- 可配置的日志级别
- 请求/响应日志

### 指标
- 使用统计追踪
- 令牌刷新计数
- API调用成功率

### 配置更新
- 文件监听器监控配置变更
- 自动热重载
- 错误恢复

---

## 许可证

MIT License - 详见 LICENSE 文件
