# Day 1: HarmonyOS 项目框架搭建 - 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 搭建可运行的 HarmonyOS 项目框架，包含基础工具类、HTTP/WebSocket 客户端，能够编译通过。

**架构：** 基于 HarmonyOS ArkTS 语言，采用 MVVM + Repository 架构模式。项目命名为 `DiaryApp`，包名 `com.vhenge.diaryapp`，对标现有 Android 项目的模块结构。

**技术栈：** ArkTS + HarmonyOS SDK API 9 + HarmonyOS HTTP API + WebSocket

---

## 文件结构设计

```
entry/src/main/
├── ets/
│   ├── pages/                    # 页面
│   │   └── Index.ets            # 默认入口页（暂时保留）
│   │   └── MainPage.ets         # 主页面框架（Day 1 创建）
│   ├── components/              # 公共组件
│   │   └── common/              # 通用组件
│   ├── viewmodels/              # ViewModel 层
│   ├── models/                  # 数据模型
│   ├── services/                # 服务层
│   │   ├── http/               # HTTP 服务
│   │   │   └── HttpClient.ets   # HTTP 客户端封装
│   │   ├── websocket/           # WebSocket 服务
│   │   │   └── WebSocketClient.ets
│   │   └── auth/                # 认证服务
│   │       └── AuthService.ets
│   ├── repositories/            # Repository 层
│   ├── utils/                   # 工具类
│   │   ├── Logger.ets           # 日志工具
│   │   ├── PreferencesHelper.ets # 轻量存储（对标 SharedPreferences）
│   │   ├── Router.ets           # 路由工具
│   │   └── TokenManager.ets     # Token 管理
│   └── common/                  # 常量/类型定义
│       └── Constants.ets         # 常量定义
├── module.json5                 # 模块配置
└── resources/                    # 资源文件
```
自动生成报告
---

## Task 1: 安装 DevEco Studio 并创建项目

**Files:**
- Create: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/module.json5`

- [ ] **Step 1: 下载安装 DevEco Studio**

下载链接: https://developer.huawei.com/consumer/cn/deveco-studio/

选择 Windows 版本下载，安装过程中勾选 "HarmonyOS SDK"。

- [ ] **Step 2: 创建 HarmonyOS 项目**

打开 DevEco Studio → Create Project → Empty Ability → Next

| 配置项 | 值 |
|--------|-----|
| Project Name | DiaryApp |
| Bundle Name | com.vhenge.diaryapp |
| Language | ArkTS |
| API Version | 9 |
| Device Type | Phone |

- [ ] **Step 3: 验证项目结构**

创建完成后，确认以下目录存在：

```
entry/src/main/ets/
├── pages/
│   └── Index.ets
├── module.json5
└── resources/
```

- [ ] **Step 4: 配置开发板（可选）**

若使用模拟器：Tools → Device Manager → Install emulator

若使用真机：开启开发者模式，连接电脑

- [ ] **Step 5: 编译验证**

Run → Run 'entry' 或点击 ▶ 按钮

确认 BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git init  # 如果尚未初始化
git add .
git commit -m "feat(day1): initial HarmonyOS project scaffold"
```

---

## Task 2: 创建项目目录结构

**Files:**
- Create: `entry/src/main/ets/viewmodels/`
- Create: `entry/src/main/ets/models/`
- Create: `entry/src/main/ets/services/http/`
- Create: `entry/src/main/ets/services/websocket/`
- Create: `entry/src/main/ets/services/auth/`
- Create: `entry/src/main/ets/repositories/`
- Create: `entry/src/main/ets/utils/`
- Create: `entry/src/main/ets/components/common/`
- Create: `entry/src/main/ets/common/Constants.ets`

- [ ] **Step 1: 创建目录**

在 `entry/src/main/ets/` 下创建以下目录结构：

```
ets/
├── utils/
│   ├── Logger.ets           # 日志工具
│   ├── PreferencesHelper.ets # 轻量存储
│   ├── Router.ets           # 路由工具
│   └── TokenManager.ets     # Token管理
├── services/
│   ├── http/
│   │   └── HttpClient.ets   # HTTP客户端封装
│   └── websocket/
│       └── WebSocketClient.ets
├── common/
│   └── Constants.ets        # 常量定义
└── (其他目录后续使用)
```

- [ ] **Step 2: Commit**

```bash
git add ets/
git commit -m "feat(day1): create project directory structure"
```

---

## Task 3: 配置网络权限

**Files:**
- Modify: `entry/src/main/module.json5`

- [ ] **Step 1: 打开 module.json5**

在 `module` 节点下添加 `requestPermissions`：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.ACCESS_NETWORK_STATE"
      }
    ]
  }
}
```

- [ ] **Step 2: 添加明文 HTTP 支持（开发环境）**

在 `module` 节点下添加 `securityConfig`：

```json5
{
  "module": {
    "securityConfig": {
      "domainSettings": {
        "cleartextPermitted": true,
        "domains": [
          {
            "subdomains": true,
            "name": "39.97.46.231"
          }
        ]
      }
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add module.json5
git commit -m "feat(day1): configure network permissions and cleartext HTTP"
```

---

## Task 4: 实现 Logger 工具类

**Files:**
- Create: `entry/src/main/ets/utils/Logger.ets`

- [ ] **Step 1: 编写 Logger.ets**

```typescript
/**
 * 日志工具类
 * 对标 Android 的 Log 工具
 */

const TAG_PREFIX = 'DiaryApp_'

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

class Logger {
  private static logLevel: LogLevel = LogLevel.DEBUG
  private tag: string = ''

  constructor(tag: string) {
    this.tag = TAG_PREFIX + tag
  }

  static setLogLevel(level: LogLevel): void {
    Logger.logLevel = level
  }

  debug(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.DEBUG) {
      console.debug(this.formatMessage(message, args))
    }
  }

  info(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.INFO) {
      console.info(this.formatMessage(message, args))
    }
  }

  warn(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.WARN) {
      console.warn(this.formatMessage(message, args))
    }
  }

  error(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.ERROR) {
      console.error(this.formatMessage(message, args))
    }
  }

  private formatMessage(message: string, args: Object[]): string {
    if (args.length === 0) {
      return `[${this.tag}] ${message}`
    }
    return `[${this.tag}] ${message} ${JSON.stringify(args)}`
  }
}

export function getLogger(tag: string): Logger {
  return new Logger(tag)
}

export default Logger
```

- [ ] **Step 2: 测试 Logger**

在 `Index.ets` 中添加测试代码验证 Logger 可用。

- [ ] **Step 3: 编译验证**

Run → Run 'entry'

- [ ] **Step 4: Commit**

```bash
git add ets/utils/Logger.ets
git commit -m "feat(day1): implement Logger utility class"
```

---

## Task 5: 实现 PreferencesHelper（轻量存储）

**Files:**
- Create: `entry/src/main/ets/utils/PreferencesHelper.ets`

- [ ] **Step 1: 编写 PreferencesHelper.ets**

```typescript
/**
 * 轻量存储工具
 * 对标 Android 的 SharedPreferences
 */

import data_preferences from '@ohos.data.preferences'

const PREFERENCES_NAME = 'diary_prefs'

class PreferencesHelper {
  private static instance: PreferencesHelper
  private preferences: data_preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): PreferencesHelper {
    if (!PreferencesHelper.instance) {
      PreferencesHelper.instance = new PreferencesHelper()
    }
    return PreferencesHelper.instance
  }

  async init(context: Context): Promise<void> {
    if (!this.preferences) {
      this.preferences = await data_preferences.getPreferences(context, PREFERENCES_NAME)
    }
  }

  async putString(key: string, value: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as string
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as boolean
  }

  async putNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as number
  }

  async remove(key: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.delete(key)
    await this.preferences.flush()
  }

  async clear(): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.clear()
    await this.preferences.flush()
  }

  async hasKey(key: string): Promise<boolean> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.has(key)
  }
}

export default PreferencesHelper.getInstance()
```

- [ ] **Step 2: 在 App.ets 中初始化**

修改 `App.ets`（应用入口）：

```typescript
import hilog from '@ohos.hilog'
import PreferencesHelper from '../utils/PreferencesHelper.ets'

AppStorage.setOrCreate('context', getContext(this))

// 初始化 Preferences
PreferencesHelper.init(getContext(this)).then(() => {
  hilog.info(0x0000, 'DiaryApp', 'Preferences initialized')
}).catch((err) => {
  hilog.error(0x0000, 'DiaryApp', 'Failed to init Preferences: %{public}s', JSON.stringify(err))
})
```

- [ ] **Step 3: Commit**

```bash
git add ets/utils/PreferencesHelper.ets ets/App.ets
git commit -m "feat(day1): implement PreferencesHelper for local storage"
```

---

## Task 6: 实现 Constants 常量定义

**Files:**
- Create: `entry/src/main/ets/common/Constants.ets`

- [ ] **Step 1: 编写 Constants.ets**

```typescript
/**
 * 常量定义
 */

export class ApiConstants {
  // 服务器地址
  static readonly BASE_URL: string = 'http://39.97.46.231:3000/'

  // API 端点
  static readonly API_AUTH_LOGIN: string = 'api/auth/login'
  static readonly API_AUTH_REGISTER: string = 'api/auth/register'
  static readonly API_AUTH_SEND_CODE: string = 'api/auth/sendCode'
  static readonly API_AUTH_FORGOT_PASSWORD: string = 'api/auth/forgotPassword'

  static readonly API_DIARY: string = 'api/diary'
  static readonly API_DIARY_EXPORT: string = 'api/diary/export'

  static readonly API_CHAT: string = 'api/chat'

  static readonly API_SCHEDULE: string = 'api/schedule'
  static readonly API_MEMBER_PLANS: string = 'api/member/plans'

  // WebSocket 地址
  static readonly WS_AI_URL: string = 'ws://39.97.46.231:3000/ws/ai'

  // 超时配置（毫秒）
  static readonly CONNECT_TIMEOUT: number = 30000
  static readonly READ_TIMEOUT: number = 30000
}

export class StorageKeys {
  static readonly TOKEN: string = 'auth_token'
  static readonly USER_ID: string = 'user_id'
  static readonly USERNAME: string = 'username'
  static readonly IS_LOGGED_IN: string = 'is_logged_in'
  static readonly THEME_MODE: string = 'theme_mode'
  static readonly LANGUAGE: string = 'language'
}

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

export enum ApiCode {
  SUCCESS = 200,
  UNAUTHORIZED = 401,
  NOT_FOUND = 404,
  SERVER_ERROR = 500
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/common/Constants.ets
git commit -m "feat(day1): add Constants for API endpoints and storage keys"
```

---

## Task 7: 实现 HTTP 客户端封装

**Files:**
- Create: `entry/src/main/ets/services/http/HttpClient.ets`

- [ ] **Step 1: 编写 HttpClient.ets**

```typescript
/**
 * HTTP 客户端封装
 * 对标 Android 的 Retrofit + OkHttp
 */

import http from '@ohos.net.http'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import PreferencesHelper from '../../utils/PreferencesHelper.ets'
import { StorageKeys } from '../../common/Constants.ets'

const logger = getLogger('HttpClient')

export interface HttpRequestOptions {
  url: string
  method: http.RequestMethod
  headers?: Record<string, string>
  body?: string | Object
}

export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

class HttpClient {
  private static instance: HttpClient

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient()
    }
    return HttpClient.instance
  }

  async request<T>(options: HttpRequestOptions): Promise<ApiResponse<T>> {
    const fullUrl = options.url.startsWith('http') ? options.url : ApiConstants.BASE_URL + options.url

    logger.info(`HTTP Request: ${options.method} ${fullUrl}`)

    let httpRequest = http.createHttp()
    try {
      // 获取 Token
      const token = await PreferencesHelper.getString(StorageKeys.TOKEN, '')

      // 构建 headers
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        ...options.headers
      }

      if (token) {
        headers['Authorization'] = `Bearer ${token}`
      }

      // 发送请求
      const result = await httpRequest.request(fullUrl, {
        method: options.method,
        header: headers,
        extraData: options.body ? JSON.stringify(options.body) : undefined,
        connectTimeout: ApiConstants.CONNECT_TIMEOUT,
        readTimeout: ApiConstants.READ_TIMEOUT
      })

      // 解析响应
      const response = JSON.parse(result.result as string) as ApiResponse<T>
      logger.info(`HTTP Response: ${JSON.stringify(response)}`)

      return response
    } catch (error) {
      logger.error(`HTTP Error: ${JSON.stringify(error)}`)
      throw error
    } finally {
      httpRequest.destroy()
    }
  }

  get<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.GET,
      headers
    })
  }

  post<T>(url: string, body?: Object, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.POST,
      body,
      headers
    })
  }

  put<T>(url: string, body?: Object, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.PUT,
      body,
      headers
    })
  }

  delete<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.DELETE,
      headers
    })
  }
}

export default HttpClient.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/services/http/HttpClient.ets
git commit -m "feat(day1): implement HTTP client wrapper"
```

---

## Task 8: 实现 Token 管理器

**Files:**
- Create: `entry/src/main/ets/utils/TokenManager.ets`

- [ ] **Step 1: 编写 TokenManager.ets**

```typescript
/**
 * Token 管理器
 * 对标 Android 的 TokenManager
 */

import { getLogger } from './Logger.ets'
import PreferencesHelper from './PreferencesHelper.ets'
import { StorageKeys } from '../common/Constants.ets'

const logger = getLogger('TokenManager')

class TokenManager {
  private static instance: TokenManager

  private constructor() {}

  static getInstance(): TokenManager {
    if (!TokenManager.instance) {
      TokenManager.instance = new TokenManager()
    }
    return TokenManager.instance
  }

  async getToken(): Promise<string> {
    const token = await PreferencesHelper.getString(StorageKeys.TOKEN, '')
    logger.info(`Token retrieved: ${token ? 'exists' : 'empty'}`)
    return token
  }

  async setToken(token: string): Promise<void> {
    await PreferencesHelper.putString(StorageKeys.TOKEN, token)
    logger.info('Token saved')
  }

  async removeToken(): Promise<void> {
    await PreferencesHelper.remove(StorageKeys.TOKEN)
    logger.info('Token removed')
  }

  async hasToken(): Promise<boolean> {
    const token = await this.getToken()
    return !!token && token.length > 0
  }

  async getUserId(): Promise<string> {
    return await PreferencesHelper.getString(StorageKeys.USER_ID, '')
  }

  async setUserId(userId: string): Promise<void> {
    await PreferencesHelper.putString(StorageKeys.USER_ID, userId)
  }

  async getUsername(): Promise<string> {
    return await PreferencesHelper.getString(StorageKeys.USERNAME, '')
  }

  async setUsername(username: string): Promise<void> {
    await PreferencesHelper.putString(StorageKeys.USERNAME, username)
  }

  async isLoggedIn(): Promise<boolean> {
    return await PreferencesHelper.getBoolean(StorageKeys.IS_LOGGED_IN, false)
  }

  async setLoggedIn(loggedIn: boolean): Promise<void> {
    await PreferencesHelper.putBoolean(StorageKeys.IS_LOGGED_IN, loggedIn)
  }

  async clearAll(): Promise<void> {
    await PreferencesHelper.clear()
    logger.info('All auth data cleared')
  }
}

export default TokenManager.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/utils/TokenManager.ets
git commit -m "feat(day1): implement TokenManager for auth token handling"
```

---

## Task 9: 实现 WebSocket 客户端

**Files:**
- Create: `entry/src/main/ets/services/websocket/WebSocketClient.ets`

- [ ] **Step 1: 编写 WebSocketClient.ets**

```typescript
/**
 * WebSocket 客户端封装
 * 对标 Android 的 ServerAiWebSocketService
 */

import webSocket from '@ohos.net.webSocket'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import TokenManager from '../../utils/TokenManager.ets'

const logger = getLogger('WebSocketClient')

export enum WebSocketState {
  CONNECTING = 0,
  CONNECTED = 1,
  DISCONNECTED = 2,
  RECONNECTING = 3
}

export interface WebSocketListener {
  onOpen(): void
  onMessage(message: string): void
  onError(error: string): void
  onClose(code: number, reason: string): void
  onStateChange(state: WebSocketState): void
}

class WebSocketClient {
  private static instance: WebSocketClient
  private webSocket: webSocket.WebSocket | null = null
  private listeners: Set<WebSocketListener> = new Set()
  private state: WebSocketState = WebSocketState.DISCONNECTED
  private reconnectAttempts: number = 0
  private maxReconnectAttempts: number = 5
  private reconnectDelay: number = 3000

  private constructor() {}

  static getInstance(): WebSocketClient {
    if (!WebSocketClient.instance) {
      WebSocketClient.instance = new WebSocketClient()
    }
    return WebSocketClient.instance
  }

  addListener(listener: WebSocketListener): void {
    this.listeners.add(listener)
  }

  removeListener(listener: WebSocketListener): void {
    this.listeners.delete(listener)
  }

  private notifyStateChange(state: WebSocketState): void {
    this.state = state
    this.listeners.forEach(listener => {
      listener.onStateChange(state)
    })
  }

  private notifyOpen(): void {
    this.listeners.forEach(listener => {
      listener.onOpen()
    })
  }

  private notifyMessage(message: string): void {
    this.listeners.forEach(listener => {
      listener.onMessage(message)
    })
  }

  private notifyError(error: string): void {
    logger.error(`WebSocket Error: ${error}`)
    this.listeners.forEach(listener => {
      listener.onError(error)
    })
  }

  private notifyClose(code: number, reason: string): void {
    logger.info(`WebSocket Closed: code=${code}, reason=${reason}`)
    this.listeners.forEach(listener => {
      listener.onClose(code, reason)
    })
  }

  async connect(url: string = ApiConstants.WS_AI_URL): Promise<void> {
    if (this.state === WebSocketState.CONNECTING || this.state === WebSocketState.CONNECTED) {
      logger.warn('WebSocket already connecting or connected')
      return
    }

    this.notifyStateChange(WebSocketState.CONNECTING)

    // 获取 Token
    const token = await TokenManager.getToken()

    this.webSocket = webSocket.createWebSocket()

    this.webSocket.on('open', async (err, value) => {
      if (err) {
        this.notifyError(`Open error: ${JSON.stringify(err)}`)
        this.notifyStateChange(WebSocketState.DISCONNECTED)
        return
      }

      logger.info('WebSocket connected')

      // 发送认证消息（如果需要）
      if (token) {
        this.send(JSON.stringify({ type: 'auth', token }))
      }

      this.reconnectAttempts = 0
      this.notifyStateChange(WebSocketState.CONNECTED)
      this.notifyOpen()
    })

    this.webSocket.on('message', (err, value) => {
      if (err) {
        this.notifyError(`Message error: ${JSON.stringify(err)}`)
        return
      }
      const message = typeof value === 'string' ? value : JSON.stringify(value)
      logger.info(`WebSocket message received: ${message}`)
      this.notifyMessage(message)
    })

    this.webSocket.on('error', (err) => {
      this.notifyError(`Error: ${JSON.stringify(err)}`)
    })

    this.webSocket.on('close', (err, value) => {
      this.notifyClose(value.code, value.reason)
      this.notifyStateChange(WebSocketState.DISCONNECTED)

      // 自动重连
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        this.scheduleReconnect(url)
      }
    })

    // 设置请求头
    const header: Record<string, string> = {}
    if (token) {
      header['Authorization'] = `Bearer ${token}`
    }

    this.webSocket.connect(url, header, (err, value) => {
      if (err) {
        logger.error(`Connect failed: ${JSON.stringify(err)}`)
        this.notifyStateChange(WebSocketState.DISCONNECTED)
      }
    })
  }

  private scheduleReconnect(url: string): void {
    this.reconnectAttempts++
    this.notifyStateChange(WebSocketState.RECONNECTING)
    logger.info(`Scheduling reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`)

    setTimeout(() => {
      logger.info('Attempting reconnect...')
      this.connect(url)
    }, this.reconnectDelay * this.reconnectAttempts)
  }

  send(message: string): boolean {
    if (!this.webSocket || this.state !== WebSocketState.CONNECTED) {
      logger.warn('WebSocket not connected, cannot send message')
      return false
    }

    const result = this.webSocket.send(message)
    if (!result) {
      logger.error('Failed to send message')
    }
    return result
  }

  close(): void {
    this.reconnectAttempts = this.maxReconnectAttempts // 防止自动重连
    if (this.webSocket) {
      this.webSocket.close()
      this.webSocket = null
    }
    this.notifyStateChange(WebSocketState.DISCONNECTED)
  }

  getState(): WebSocketState {
    return this.state
  }
}

export default WebSocketClient.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/services/websocket/WebSocketClient.ets
git commit -m "feat(day1): implement WebSocket client wrapper"
```

---

## Task 10: 创建 MainPage 主页面框架

**Files:**
- Create: `entry/src/main/ets/pages/MainPage.ets`

- [ ] **Step 1: 编写 MainPage.ets**

```typescript
/**
 * 主页面框架
 * 对标 Android 的 MainActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'

const logger = getLogger('MainPage')

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  private tabController: TabsController = new TabsController()

  aboutToAppear() {
    logger.info('MainPage aboutToAppear')
  }

  onPageShow() {
    logger.info('MainPage onPageShow')
  }

  onPageHide() {
    logger.info('MainPage onPageHide')
  }

  build() {
    Tabs({ controller: this.tabController, index: this.currentIndex }) {
      TabContent() {
        Column() {
          Text('日记')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日记')

      TabContent() {
        Column() {
          Text('日历')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日历')

      TabContent() {
        Column() {
          Text('聊天')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('聊天')

      TabContent() {
        Column() {
          Text('日程')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日程')

      TabContent() {
        Column() {
          Text('我的')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('我的')
    }
    .onChange((index: number) => {
      this.currentIndex = index
      logger.info(`Tab changed to index: ${index}`)
    })
    .barPosition(BarPosition.End)
    .barHeight(60)
  }
}
```

- [ ] **Step 2: 修改 Index.ets 跳转到 MainPage**

修改 `Index.ets`，在入口页面检测登录状态并跳转：

```typescript
import router from '@ohos.router'
import TokenManager from '../utils/TokenManager.ets'
import { getLogger } from '../utils/Logger.ets'

const logger = getLogger('Index')

@Entry
@Component
struct Index {
  async aboutToAppear() {
    logger.info('Index page loading...')

    // 检测登录状态
    const isLoggedIn = await TokenManager.isLoggedIn()
    logger.info(`Login status: ${isLoggedIn}`)

    if (isLoggedIn) {
      // 已登录，跳转到主页
      router.replaceUrl({ url: 'pages/MainPage' })
    } else {
      // 未登录，跳转到登录页（后续创建）
      router.replaceUrl({ url: 'pages/LoginPage' })
    }
  }

  build() {
    Column() {
      Text('DiaryApp')
        .fontSize(30)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add ets/pages/MainPage.ets ets/pages/Index.ets
git commit -m "feat(day1): create MainPage with tab navigation framework"
```

---

## Task 11: 最终编译验证

- [ ] **Step 1: 完整编译**

Run → Run 'entry' 或快捷键 Shift + F10

确认控制台输出：

```
SUCCESS
openharmony
entry
Execution finished
```

- [ ] **Step 2: 检查日志输出**

打开 Log 面板，过滤 tag:DiaryApp，确认以下日志出现：

```
[DiaryApp_Test] Logger 测试成功
[DiaryApp_Preferences] Preferences initialized
[DiaryApp_Index] Index page loading...
[DiaryApp_Index] Login status: xxx
```

- [ ] **Step 3: 最终 Commit**

```bash
git status
git add .
git commit -m "feat(day1): complete HarmonyOS project scaffold with HTTP/WebSocket clients"
```

---

## 验证清单

Day 1 完成后，确认以下产出：

- [ ] DevEco Studio 可正常打开项目
- [ ] 项目可编译通过（BUILD SUCCESSFUL）
- [ ] `pages/MainPage.ets` 包含底部 TabBar 框架
- [ ] `utils/Logger.ets` 日志工具正常
- [ ] `utils/PreferencesHelper.ets` 存储工具正常
- [ ] `utils/TokenManager.ets` Token 管理正常
- [ ] `services/http/HttpClient.ets` HTTP 客户端可用
- [ ] `services/websocket/WebSocketClient.ets` WebSocket 客户端可用
- [ ] `common/Constants.ets` 常量定义完整
- [ ] 网络权限已配置
- [ ] Git 已提交

---

## 依赖关系图

```
Index.ets
    ↓
TokenManager.ets ← PreferencesHelper.ets, Logger.ets
    ↓
MainPage.ets
    ↓
HttpClient.ets ← TokenManager.ets, Logger.ets, Constants.ets
WebSocketClient.ets ← TokenManager.ets, Logger.ets, Constants.ets
```

---

**Plan 版本**: 1.0
**最后更新**: 2026-04-20
