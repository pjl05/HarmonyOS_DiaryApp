# Day 2-3: 登录/注册模块 - 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 完成登录页面、注册页面、忘记密码页面的开发，实现完整的用户认证流程，包括界面、API 对接、动画效果和生物识别登录。

**架构：** 采用 MVVM 架构，使用 ArkTS 编写页面，使用 @State 管理表单状态。HTTP 请求通过 HttpClient 封装调用后端 API。

**技术栈：** ArkTS + HarmonyOS HTTP API + HarmonyOS FaceAuth/FingerprintAuth

---

## 文件结构设计

```
entry/src/main/ets/
├── models/                          # 数据模型
│   ├── UserModel.ets               # 用户数据模型
│   ├── ApiModels.ets               # API 请求/响应模型
│   └── AuthModels.ets              # 认证相关模型
├── services/                        # 服务层
│   ├── auth/                       # 认证服务
│   │   └── AuthService.ets         # 认证服务（登录/注册/发送验证码）
├── viewmodels/                      # ViewModel 层
│   ├── LoginViewModel.ets          # 登录 ViewModel
│   └── ForgotPasswordViewModel.ets  # 忘记密码 ViewModel
├── components/                      # 公共组件
│   └── common/
│       ├── DanmakuView.ets        # 弹幕动画组件
│       └── ToastDialog.ets         # 提示对话框
├── pages/                           # 页面
│   ├── LoginPage.ets              # 登录页面
│   └── ForgotPasswordPage.ets      # 忘记密码页面
└── utils/
    ├── BiometricHelper.ets         # 生物识别工具
    └── FormValidator.ets           # 表单验证工具
```

---

## Android 参考文件分析

### API 接口对照

| Android API 端点 | HTTP 方法 | 鸿蒙实现 |
|-----------------|----------|----------|
| `api/auth/login` | POST | `HttpClient.post('api/auth/login', body)` |
| `api/auth/register` | POST | `HttpClient.post('api/auth/register', body)` |
| `api/auth/send-code` | POST | `HttpClient.post('api/auth/send-code', body)` |
| `api/auth/reset-password` | POST | `HttpClient.post('api/auth/reset-password', body)` |

### 数据模型对照

| Android Model | 鸿蒙 Model |
|--------------|----------|
| `LoginRequest(loginName, password)` | `LoginRequest(loginName: string, password: string)` |
| `RegisterRequest(username, email, password, verificationCode)` | `RegisterRequest(username: string, email: string, password: string, verificationCode: string)` |
| `SendCodeRequest(email, type, username?)` | `SendCodeRequest(email: string, type: string, username?: string)` |
| `LoginResponse(success, data: UserData, message)` | `LoginResponse(success: boolean, data: UserData, message: string)` |
| `UserData(userId, username, email, nickname, avatar_url, token)` | `UserData(userId: number, username: string, email: string, nickname: string, avatar_url: string, token: string)` |

---

## Task 1: 创建数据模型

**Files:**
- Create: `entry/src/main/ets/models/UserModel.ets`
- Create: `entry/src/main/ets/models/ApiModels.ets`
- Create: `entry/src/main/ets/models/AuthModels.ets`

- [ ] **Step 1: 创建 UserModel.ets**

```typescript
/**
 * 用户数据模型
 * 对标 Android UserData
 */

export class UserData {
  userId: number = 0
  username: string = ''
  email: string = ''
  nickname: string = ''
  avatar_url: string = ''
  token: string = ''

  constructor(data?: Partial<UserData>) {
    if (data) {
      this.userId = data.userId ?? 0
      this.username = data.username ?? ''
      this.email = data.email ?? ''
      this.nickname = data.nickname ?? ''
      this.avatar_url = data.avatar_url ?? ''
      this.token = data.token ?? ''
    }
  }
}

export class UserProfile {
  id: number = 0
  username: string = ''
  email: string = ''
  nickname: string | null = null
  avatar_url: string | null = null
  gender: string | null = null
  signature: string | null = null
  membership_tier: string | null = null
  membership_expires_at: string | null = null
}
```

- [ ] **Step 2: 创建 AuthModels.ets**

```typescript
/**
 * 认证相关数据模型
 * 对标 Android LoginRequest, RegisterRequest 等
 */

export class LoginRequest {
  loginName: string
  password: string

  constructor(loginName: string, password: string) {
    this.loginName = loginName
    this.password = password
  }
}

export class RegisterRequest {
  username: string
  email: string
  password: string
  verificationCode: string

  constructor(username: string, email: string, password: string, verificationCode: string) {
    this.username = username
    this.email = email
    this.password = password
    this.verificationCode = verificationCode
  }
}

export class SendCodeRequest {
  email: string
  type: string
  username: string | null = null

  constructor(email: string, type: string, username: string | null = null) {
    this.email = email
    this.type = type
    this.username = username
  }
}

export class ResetPasswordRequest {
  email: string
  verificationCode: string
  newPassword: string

  constructor(email: string, verificationCode: string, newPassword: string) {
    this.email = email
    this.verificationCode = verificationCode
    this.newPassword = newPassword
  }
}

export class GenericResponse {
  success: boolean = false
  message: string = ''

  constructor(success: boolean, message: string = '') {
    this.success = success
    this.message = message
  }
}

export class LoginResponse {
  success: boolean = false
  data: UserData | null = null
  message: string = ''

  constructor(success: boolean, data: UserData | null = null, message: string = '') {
    this.success = success
    this.data = data
    this.message = message
  }
}

export class RegisterResponse {
  success: boolean = false
  data: UserData | null = null
  message: string = ''

  constructor(success: boolean, data: UserData | null = null, message: string = '') {
    this.success = success
    this.data = data
    this.message = message
  }
}
```

- [ ] **Step 3: 创建 ApiModels.ets**

```typescript
/**
 * API 响应模型
 */

export { UserData, UserProfile } from './UserModel.ets'
export { LoginRequest, RegisterRequest, SendCodeRequest, ResetPasswordRequest, GenericResponse, LoginResponse, RegisterResponse } from './AuthModels.ets'
```

- [ ] **Step 4: Commit**

```bash
git add ets/models/
git commit -m "feat(day2): add user and auth data models"
```

---

## Task 2: 创建 API 服务层

**Files:**
- Create: `entry/src/main/ets/services/auth/AuthService.ets`

- [ ] **Step 1: 创建 AuthService.ets**

```typescript
/**
 * 认证服务
 * 对标 Android UserRepository 中的认证方法
 */

import HttpClient from '../http/HttpClient.ets'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import TokenManager from '../../utils/TokenManager.ets'
import { LoginRequest, RegisterRequest, SendCodeRequest, ResetPasswordRequest, GenericResponse, LoginResponse, RegisterResponse, UserData } from '../../models/ApiModels.ets'

const logger = getLogger('AuthService')

export class AuthService {
  private static instance: AuthService

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService()
    }
    return AuthService.instance
  }

  /**
   * 用户登录
   */
  async login(request: LoginRequest): Promise<LoginResponse> {
    logger.info(`Login request: ${request.loginName}`)

    try {
      const response = await HttpClient.post<LoginResponse>(
        ApiConstants.API_AUTH_LOGIN,
        request
      )

      if (response.code === 200 && response.data) {
        const loginResponse = response.data as LoginResponse
        if (loginResponse.success && loginResponse.data) {
          const userData = loginResponse.data as UserData
          await TokenManager.setToken(userData.token)
          await TokenManager.setUserId(userData.userId.toString())
          await TokenManager.setUsername(userData.username)
          await TokenManager.setLoggedIn(true)
          logger.info(`Login success: ${userData.username}`)
          return loginResponse
        } else {
          throw new Error(loginResponse.message || 'Login failed')
        }
      } else {
        throw new Error(response.message || 'Login failed')
      }
    } catch (error) {
      logger.error(`Login error: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 用户注册
   */
  async register(request: RegisterRequest): Promise<RegisterResponse> {
    logger.info(`Register request: ${request.username}, ${request.email}`)

    try {
      const response = await HttpClient.post<RegisterResponse>(
        ApiConstants.API_AUTH_REGISTER,
        request
      )

      if (response.code === 200 && response.data) {
        const registerResponse = response.data as RegisterResponse
        if (registerResponse.success && registerResponse.data) {
          const userData = registerResponse.data as UserData
          await TokenManager.setToken(userData.token)
          await TokenManager.setUserId(userData.userId.toString())
          await TokenManager.setUsername(userData.username)
          await TokenManager.setLoggedIn(true)
          logger.info(`Register success: ${userData.username}`)
          return registerResponse
        } else {
          throw new Error(registerResponse.message || 'Register failed')
        }
      } else {
        throw new Error(response.message || 'Register failed')
      }
    } catch (error) {
      logger.error(`Register error: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 发送验证码
   * @param type - 验证码类型: "register" | "reset_password"
   */
  async sendCode(email: string, type: string, username: string | null = null): Promise<GenericResponse> {
    logger.info(`SendCode request: ${email}, type=${type}`)

    try {
      const request = new SendCodeRequest(email, type, username)
      const response = await HttpClient.post<GenericResponse>(
        ApiConstants.API_AUTH_SEND_CODE,
        request
      )

      if (response.code === 200 && response.data) {
        const genericResponse = response.data as GenericResponse
        if (genericResponse.success) {
          logger.info('Code sent successfully')
          return genericResponse
        } else {
          throw new Error(genericResponse.message || 'Failed to send code')
        }
      } else {
        throw new Error(response.message || 'Failed to send code')
      }
    } catch (error) {
      logger.error(`SendCode error: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 重置密码
   */
  async resetPassword(request: ResetPasswordRequest): Promise<GenericResponse> {
    logger.info(`ResetPassword request: ${request.email}`)

    try {
      const response = await HttpClient.post<GenericResponse>(
        ApiConstants.API_AUTH_FORGOT_PASSWORD,
        request
      )

      if (response.code === 200 && response.data) {
        const genericResponse = response.data as GenericResponse
        if (genericResponse.success) {
          logger.info('Password reset successfully')
          return genericResponse
        } else {
          throw new Error(genericResponse.message || 'Failed to reset password')
        }
      } else {
        throw new Error(response.message || 'Failed to reset password')
      }
    } catch (error) {
      logger.error(`ResetPassword error: ${JSON.stringify(error)}`)
      throw error
    }
  }

  /**
   * 登出
   */
  async logout(): Promise<void> {
    logger.info('Logout')
    await TokenManager.clearAll()
  }

  /**
   * 检查是否已登录
   */
  async isLoggedIn(): Promise<boolean> {
    return await TokenManager.isLoggedIn()
  }
}

export default AuthService.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/services/auth/AuthService.ets
git commit -m "feat(day2): implement AuthService for login/register/logout"
```

---

## Task 3: 创建表单验证工具

**Files:**
- Create: `entry/src/main/ets/utils/FormValidator.ets`

- [ ] **Step 1: 创建 FormValidator.ets**

```typescript
/**
 * 表单验证工具
 */

export class FormValidator {
  /**
   * 验证邮箱格式
   */
  static isValidEmail(email: string): boolean {
    if (!email || email.trim().length === 0) {
      return false
    }
    const trimmed = email.trim()
    return trimmed.includes('@') && trimmed.toLowerCase().includes('.com')
  }

  /**
   * 验证用户名
   */
  static isValidUsername(username: string): boolean {
    return username && username.trim().length > 0
  }

  /**
   * 验证密码
   */
  static isValidPassword(password: string): boolean {
    return password && password.length > 0
  }

  /**
   * 验证验证码（4-6位数字）
   */
  static isValidCode(code: string): boolean {
    return code && /^\d{4,6}$/.test(code)
  }

  /**
   * 验证登录表单
   */
  static validateLogin(loginName: string, password: string): { valid: boolean, error: string } {
    if (!loginName || loginName.trim().length === 0) {
      return { valid: false, error: '请输入用户名或邮箱' }
    }
    if (!password || password.length === 0) {
      return { valid: false, error: '请输入密码' }
    }
    return { valid: true, error: '' }
  }

  /**
   * 验证注册表单
   */
  static validateRegister(username: string, email: string, password: string, code: string): { valid: boolean, error: string } {
    if (!username || username.trim().length === 0) {
      return { valid: false, error: '请输入昵称' }
    }
    if (!this.isValidEmail(email)) {
      return { valid: false, error: '请输入有效的邮箱地址' }
    }
    if (!password || password.length === 0) {
      return { valid: false, error: '请输入密码' }
    }
    if (!this.isValidCode(code)) {
      return { valid: false, error: '请输入4-6位验证码' }
    }
    return { valid: true, error: '' }
  }

  /**
   * 验证忘记密码表单
   */
  static validateResetPassword(email: string, code: string, newPassword: string): { valid: boolean, error: string } {
    if (!this.isValidEmail(email)) {
      return { valid: false, error: '请输入有效的邮箱地址' }
    }
    if (!this.isValidCode(code)) {
      return { valid: false, error: '请输入4-6位验证码' }
    }
    if (!newPassword || newPassword.length === 0) {
      return { valid: false, error: '请输入新密码' }
    }
    return { valid: true, error: '' }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/utils/FormValidator.ets
git commit -m "feat(day2): add FormValidator utility"
```

---

## Task 4: 创建生物识别工具

**Files:**
- Create: `entry/src/main/ets/utils/BiometricHelper.ets`

- [ ] **Step 1: 创建 BiometricHelper.ets**

```typescript
/**
 * 生物识别工具
 * 对标 Android BiometricPrompt
 */

import { getLogger } from './Logger.ets'

const logger = getLogger('BiometricHelper')

export enum BiometricError {
  NONE = 0,
  UNSUPPORTED = 1,
  NOT_ENROLLED = 2,
  FAILED = 3,
  USER_CANCEL = 4,
  TIMEOUT = 5
}

export class BiometricHelper {
  private static instance: BiometricHelper

  static getInstance(): BiometricHelper {
    if (!BiometricHelper.instance) {
      BiometricHelper.instance = new BiometricHelper()
    }
    return BiometricHelper.instance
  }

  /**
   * 检查是否支持生物识别
   */
  async isBiometricSupported(): Promise<boolean> {
    try {
      const faceAuth = await import('@kit.LocalAuthentication')
      const fingerprintAuth = await import('@kit.UserAuthentication')

      const faceSupport = faceAuth.getFaceAuthManager() != null
      const fingerprintSupport = fingerprintAuth.getFingerprintAuthManager() != null

      const supported = faceSupport || fingerprintSupport
      logger.info(`Biometric supported: ${supported}`)
      return supported
    } catch (error) {
      logger.error(`Biometric check error: ${JSON.stringify(error)}`)
      return false
    }
  }

  type AuthSuccessCallback = () => void
  type AuthFailCallback = (error: BiometricError, message: string) => void

  /**
   * 启动生物识别认证
   */
  async authenticate(
    title: string = '身份验证',
    subtitle: string = '验证后即可登录',
    successCallback: AuthSuccessCallback,
    failCallback: AuthFailCallback
  ): Promise<void> {
    logger.info('Starting biometric authentication')

    try {
      const supported = await this.isBiometricSupported()
      if (!supported) {
        failCallback(BiometricError.UNSUPPORTED, '设备不支持生物识别')
        return
      }

      // 使用 HarmonyOS 生物识别 API
      const faceAuth = await import('@kit.LocalAuthentication')
      const faceAuthManager = faceAuth.getFaceAuthManager()

      if (faceAuthManager) {
        const params: faceAuth.AuthParams = {
          challenge: new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]),
          authType: faceAuth.AuthType.FACE_ONLY,
          authTrustLevel: faceAuth.AuthTrustLevel.Trustful
        }

        faceAuthManager.auth(title, subtitle, params, {
          onResult: (result: number) => {
            if (result === 0) {
              successCallback()
            } else {
              failCallback(BiometricError.FAILED, '生物认证失败')
            }
          }
        })
      } else {
        failCallback(BiometricError.UNSUPPORTED, '生物识别不可用')
      }
    } catch (error) {
      logger.error(`Authenticate error: ${JSON.stringify(error)}`)
      failCallback(BiometricError.FAILED, '生物识别异常')
    }
  }
}

export default BiometricHelper.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/utils/BiometricHelper.ets
git commit -m "feat(day2): add BiometricHelper for face/fingerprint authentication"
```

---

## Task 5: 创建弹幕动画组件

**Files:**
- Create: `entry/src/main/ets/components/common/DanmakuView.ets`

- [ ] **Step 1: 创建 DanmakuView.ets**

```typescript
/**
 * 弹幕动画组件
 * 对标 Android BubbleDanmakuView
 */

import { getLogger } from '../../utils/Logger.ets'

const logger = getLogger('DanmakuView')

interface DanmakuBubble {
  id: number
  text: string
  y: number
  duration: number
}

@Component
export struct DanmakuView {
  @State private isRunning: boolean = false
  @State private bubbles: DanmakuBubble[] = []
  private intervalId: number = -1

  private greetings: string[] = [
    '欢迎回来', '今天也要加油', '祝你心情愉快', '愿你一切顺利',
    '保持微笑', '记录美好生活', '写下此刻的你', '愿你拥有好天气',
    '别忘了喝水', '慢慢来更快', '今天也很棒', '你好呀',
    '今天你写日记了吗', '给你100分'
  ]

  aboutToAppear() {
    logger.info('DanmakuView aboutToAppear')
  }

  aboutToDisappear() {
    this.stop()
  }

  start() {
    if (this.isRunning) return
    this.isRunning = true
    this.intervalId = setInterval(() => {
      if (this.isRunning) {
        this.spawnOne()
      }
    }, 1000 + Math.random() * 500)
  }

  stop() {
    this.isRunning = false
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId)
      this.intervalId = -1
    }
    this.bubbles = []
  }

  private spawnOne() {
    const text = this.greetings[Math.floor(Math.random() * this.greetings.length)]
    const id = Date.now() + Math.random()
    const newBubble: DanmakuBubble = {
      id: id,
      text: text,
      y: Math.random() * 80 + 10,
      duration: 9000 + Math.random() * 3500
    }
    this.bubbles.push(newBubble)
    setTimeout(() => {
      this.bubbles = this.bubbles.filter(b => b.id !== id)
    }, newBubble.duration)
  }

  build() {
    Stack() {
      ForEach(this.bubbles, (bubble: DanmakuBubble) => {
        Text(bubble.text)
          .fontSize(14)
          .fontColor('#00BCD4')
          .padding(10)
          .backgroundColor('#1A00BCD4')
          .borderRadius(15)
          .opacity(0.92)
          .position({ y: `${bubble.y}%` })
          .translate({ x: 300 })
          .animation({
            duration: bubble.duration,
            curve: Curve.Linear
          })
          .onAppear(() => {
            animateTo({
              duration: bubble.duration,
              curve: Curve.Linear,
              iterations: 1,
              playMode: PlayMode.Normal
            }, () => {
              // 动画逻辑
            })
          })
      })
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/components/common/DanmakuView.ets
git commit -m "feat(day2): add DanmakuView component for login page animation"
```

---

## Task 6: 创建 Toast 提示组件

**Files:**
- Create: `entry/src/main/ets/components/common/ToastDialog.ets`

- [ ] **Step 1: 创建 ToastDialog.ets**

```typescript
/**
 * Toast 提示组件
 * 对标 Android Toast
 */

import promptAction from '@ohos.promptAction'

export class ToastHelper {
  private static instance: ToastHelper

  static getInstance(): ToastHelper {
    if (!ToastHelper.instance) {
      ToastHelper.instance = new ToastHelper()
    }
    return ToastHelper.instance
  }

  showShort(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      })
    } catch (error) {
      console.error(`Toast error: ${JSON.stringify(error)}`)
    }
  }

  showLong(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 3500
      })
    } catch (error) {
      console.error(`Toast error: ${JSON.stringify(error)}`)
    }
  }

  showSuccess(message: string): void {
    this.showShort(message)
  }

  showError(message: string): void {
    this.showShort(message)
  }
}

export default ToastHelper.getInstance()
```

- [ ] **Step 2: Commit**

```bash
git add ets/components/common/ToastDialog.ets
git commit -m "feat(day2): add ToastHelper for user feedback"
```

---

## Task 7: 创建 LoginViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodels/LoginViewModel.ets`

- [ ] **Step 1: 创建 LoginViewModel.ets**

```typescript
/**
 * 登录 ViewModel
 */

import { getLogger } from '../utils/Logger.ets'
import AuthService from '../services/auth/AuthService.ets'
import { LoginRequest } from '../models/ApiModels.ets'
import { FormValidator } from '../utils/FormValidator.ets'
import ToastHelper from '../components/common/ToastDialog.ets'

const logger = getLogger('LoginViewModel')

export enum LoginState {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error'
}

@Observed
export class LoginViewModel {
  @State loginName: string = ''
  @State password: string = ''
  @State isLoginMode: boolean = true
  @State loginState: LoginState = LoginState.IDLE
  @State errorMessage: string = ''
  @State biometricAvailable: boolean = false

  private authService: AuthService = AuthService

  aboutToAppear() {
    logger.info('LoginViewModel aboutToAppear')
    this.checkBiometricAvailability()
  }

  async checkBiometricAvailability(): Promise<void> {
    try {
      const BiometricHelper = await import('../utils/BiometricHelper.ets')
      this.biometricAvailable = await BiometricHelper.default.isBiometricSupported()
    } catch {
      this.biometricAvailable = false
    }
  }

  async login(): Promise<boolean> {
    const validation = FormValidator.validateLogin(this.loginName, this.password)
    if (!validation.valid) {
      this.errorMessage = validation.error
      ToastHelper.showShort(validation.error)
      return false
    }

    this.loginState = LoginState.LOADING
    this.errorMessage = ''

    try {
      const request = new LoginRequest(this.loginName.trim(), this.password)
      await this.authService.login(request)
      this.loginState = LoginState.SUCCESS
      return true
    } catch (error) {
      this.loginState = LoginState.ERROR
      const message = error instanceof Error ? error.message : '登录失败'
      this.errorMessage = message
      ToastHelper.showShort(message)
      return false
    }
  }

  async register(username: string, email: string, password: string, code: string): Promise<boolean> {
    const validation = FormValidator.validateRegister(username, email, password, code)
    if (!validation.valid) {
      this.errorMessage = validation.error
      ToastHelper.showShort(validation.error)
      return false
    }

    this.loginState = LoginState.LOADING
    this.errorMessage = ''

    try {
      await this.authService.register({
        username: username.trim(),
        email: email.trim(),
        password: password,
        verificationCode: code.trim()
      })
      this.loginState = LoginState.SUCCESS
      return true
    } catch (error) {
      this.loginState = LoginState.ERROR
      const message = error instanceof Error ? error.message : '注册失败'
      this.errorMessage = message
      ToastHelper.showShort(message)
      return false
    }
  }

  async sendCode(email: string, username: string, type: string = 'register'): Promise<boolean> {
    if (!FormValidator.isValidEmail(email)) {
      ToastHelper.showShort('请输入有效的邮箱地址')
      return false
    }
    if (type === 'register' && !FormValidator.isValidUsername(username)) {
      ToastHelper.showShort('请输入昵称')
      return false
    }

    try {
      await this.authService.sendCode(email.trim(), type, username.trim() || null)
      ToastHelper.showShort('验证码已发送')
      return true
    } catch (error) {
      const message = error instanceof Error ? error.message : '发送验证码失败'
      ToastHelper.showShort(message)
      return false
    }
  }

  toggleMode(): void {
    this.isLoginMode = !this.isLoginMode
    this.errorMessage = ''
  }

  reset(): void {
    this.loginName = ''
    this.password = ''
    this.loginState = LoginState.IDLE
    this.errorMessage = ''
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/viewmodels/LoginViewModel.ets
git commit -m "feat(day2): add LoginViewModel with login/register logic"
```

---

## Task 8: 创建 LoginPage 页面

**Files:**
- Create: `entry/src/main/ets/pages/LoginPage.ets`

- [ ] **Step 1: 创建 LoginPage.ets**

```typescript
/**
 * 登录页面
 * 对标 Android LoginActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'
import { LoginViewModel, LoginState } from '../viewmodels/LoginViewModel.ets'
import DanmakuView from '../components/common/DanmakuView.ets'
import ToastHelper from '../components/common/ToastDialog.ets'
import { BiometricHelper, BiometricError } from '../utils/BiometricHelper.ets'

const logger = getLogger('LoginPage')

@Entry
@Component
struct LoginPage {
  @State viewModel: LoginViewModel = new LoginViewModel()
  @State registerUsername: string = ''
  @State registerEmail: string = ''
  @State registerCode: string = ''
  @State agreePrivacy: boolean = false
  @State codeCountdown: number = 0
  @State isDanmakuRunning: boolean = false

  private countdownTimer: number = -1

  aboutToAppear() {
    logger.info('LoginPage aboutToAppear')
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  onPageShow() {
    this.isDanmakuRunning = true
  }

  onPageHide() {
    this.isDanmakuRunning = false
  }

  async handleSubmit(): Promise<void> {
    if (!this.agreePrivacy) {
      ToastHelper.showShort('请先同意隐私政策')
      return
    }

    if (this.viewModel.isLoginMode) {
      const success = await this.viewModel.login()
      if (success) {
        this.navigateToMain()
      }
    } else {
      const success = await this.viewModel.register(
        this.registerUsername,
        this.registerEmail,
        this.viewModel.password,
        this.registerCode
      )
      if (success) {
        this.navigateToMain()
      }
    }
  }

  async handleSendCode(): Promise<void> {
    if (this.codeCountdown > 0) return

    const success = await this.viewModel.sendCode(
      this.registerEmail,
      this.registerUsername,
      'register'
    )

    if (success) {
      this.startCountdown()
    }
  }

  startCountdown(): void {
    this.codeCountdown = 60
    this.countdownTimer = setInterval(() => {
      this.codeCountdown--
      if (this.codeCountdown <= 0) {
        clearInterval(this.countdownTimer)
        this.countdownTimer = -1
      }
    }, 1000)
  }

  handleBiometricLogin(): void {
    BiometricHelper.authenticate(
      '身份验证',
      '验证后即可登录',
      () => {
        ToastHelper.showShort('验证成功')
        this.navigateToMain()
      },
      (error, message) => {
        if (error !== BiometricError.USER_CANCEL) {
          ToastHelper.showShort(message)
        }
      }
    )
  }

  navigateToMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' })
  }

  navigateToForgotPassword(): void {
    router.pushUrl({ url: 'pages/ForgotPasswordPage' })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景弹幕动画
      if (this.isDanmakuRunning) {
        DanmakuView()
          .width('100%')
          .height('100%')
      }

      // 登录表单
      Scroll() {
        Column() {
          // Logo
          Column() {
            Text('DiaryApp')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('记录美好生活')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 8 })
          }
          .margin({ top: 80, bottom: 60 })

          // 表单
          Column() {
            if (this.viewModel.isLoginMode) {
              this.buildLoginForm()
            } else {
              this.buildRegisterForm()
            }

            // 隐私协议
            Row() {
              Checkbox()
                .select(this.agreePrivacy)
                .onChange((value: boolean) => {
                  this.agreePrivacy = value
                })
                .width(20)
                .height(20)
              Text('我已阅读并同意')
                .fontSize(12)
                .fontColor('#666666')
              Text('《隐私政策》')
                .fontSize(12)
                .fontColor('#00BCD4')
            }
            .margin({ top: 16 })

            // 提交按钮
            Button(this.viewModel.isLoginMode ? '登录' : '注册')
              .width('100%')
              .height(48)
              .backgroundColor(this.viewModel.loginState === LoginState.LOADING ? '#CCCCCC' : '#00BCD4')
              .fontColor('#FFFFFF')
              .fontSize(18)
              .borderRadius(24)
              .enabled(this.viewModel.loginState !== LoginState.LOADING)
              .onClick(() => this.handleSubmit())
              .margin({ top: 24 })

            // 切换模式
            Row() {
              if (this.viewModel.isLoginMode) {
                Text('忘记密码？')
                  .fontSize(14)
                  .fontColor('#00BCD4')
                  .onClick(() => this.navigateToForgotPassword())
              }
              Blank()
              Text(this.viewModel.isLoginMode ? '没有账号？去注册' : '已有账号？去登录')
                .fontSize(14)
                .fontColor('#00BCD4')
                .onClick(() => this.viewModel.toggleMode())
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .width('85%')
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildLoginForm() {
    TextInput({ placeholder: '请输入用户名或邮箱' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.viewModel.loginName = value
      })

    TextInput({ placeholder: '请输入密码' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .type(InputType.Password)
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.viewModel.password = value
      })

    if (this.viewModel.biometricAvailable) {
      Button('使用生物识别登录')
        .width('100%')
        .height(44)
        .backgroundColor('#FFFFFF')
        .fontColor('#00BCD4')
        .fontSize(14)
        .borderRadius(12)
        .borderWidth(1)
        .borderColor('#00BCD4')
        .margin({ top: 8 })
        .onClick(() => this.handleBiometricLogin())
    }
  }

  @Builder
  buildRegisterForm() {
    TextInput({ placeholder: '请输入昵称' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.registerUsername = value
      })

    TextInput({ placeholder: '请输入邮箱' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.registerEmail = value
      })

    Row() {
      TextInput({ placeholder: '请输入验证码' })
        .layoutWeight(1)
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.registerCode = value
        })

      Button(this.codeCountdown > 0 ? `${this.codeCountdown}s` : '发送验证码')
        .width(120)
        .height(48)
        .backgroundColor(this.codeCountdown > 0 ? '#CCCCCC' : '#00BCD4')
        .fontColor('#FFFFFF')
        .fontSize(12)
        .borderRadius(12)
        .enabled(this.codeCountdown === 0)
        .onClick(() => this.handleSendCode())
    }
    .margin({ bottom: 16 })

    TextInput({ placeholder: '请输入密码' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .type(InputType.Password)
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.viewModel.password = value
      })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/pages/LoginPage.ets
git commit -m "feat(day2): implement LoginPage with login/register UI"
```

---

## Task 9: 创建 ForgotPasswordViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodels/ForgotPasswordViewModel.ets`

- [ ] **Step 1: 创建 ForgotPasswordViewModel.ets**

```typescript
/**
 * 忘记密码 ViewModel
 */

import { getLogger } from '../utils/Logger.ets'
import AuthService from '../services/auth/AuthService.ets'
import { ResetPasswordRequest } from '../models/ApiModels.ets'
import { FormValidator } from '../utils/FormValidator.ets'
import ToastHelper from '../components/common/ToastDialog.ets'

const logger = getLogger('ForgotPasswordViewModel')

export enum ResetState {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error'
}

@Observed
export class ForgotPasswordViewModel {
  @State email: string = ''
  @State username: string = ''
  @State code: string = ''
  @State newPassword: string = ''
  @State state: ResetState = ResetState.IDLE
  @State errorMessage: string = ''

  private authService: AuthService = AuthService

  aboutToAppear() {
    logger.info('ForgotPasswordViewModel aboutToAppear')
  }

  async sendCode(): Promise<boolean> {
    if (!FormValidator.isValidEmail(this.email)) {
      ToastHelper.showShort('请输入有效的邮箱地址')
      return false
    }
    if (!FormValidator.isValidUsername(this.username)) {
      ToastHelper.showShort('请输入用户名')
      return false
    }

    this.state = ResetState.LOADING

    try {
      await this.authService.sendCode(this.email.trim(), 'reset_password', this.username.trim())
      ToastHelper.showShort('验证码已发送')
      this.state = ResetState.IDLE
      return true
    } catch (error) {
      this.state = ResetState.ERROR
      const message = error instanceof Error ? error.message : '发送验证码失败'
      ToastHelper.showShort(message)
      return false
    }
  }

  async resetPassword(): Promise<boolean> {
    const validation = FormValidator.validateResetPassword(this.email, this.code, this.newPassword)
    if (!validation.valid) {
      ToastHelper.showShort(validation.error)
      return false
    }

    this.state = ResetState.LOADING

    try {
      const request = new ResetPasswordRequest(this.email.trim(), this.code.trim(), this.newPassword)
      await this.authService.resetPassword(request)
      this.state = ResetState.SUCCESS
      ToastHelper.showShort('密码重置成功')
      return true
    } catch (error) {
      this.state = ResetState.ERROR
      const message = error instanceof Error ? error.message : '重置密码失败'
      ToastHelper.showShort(message)
      return false
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/viewmodels/ForgotPasswordViewModel.ets
git commit -m "feat(day3): add ForgotPasswordViewModel"
```

---

## Task 10: 创建 ForgotPasswordPage 页面

**Files:**
- Create: `entry/src/main/ets/pages/ForgotPasswordPage.ets`

- [ ] **Step 1: 创建 ForgotPasswordPage.ets**

```typescript
/**
 * 忘记密码页面
 * 对标 Android ForgotPasswordActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'
import { ForgotPasswordViewModel, ResetState } from '../viewmodels/ForgotPasswordViewModel.ets'
import DanmakuView from '../components/common/DanmakuView.ets'
import ToastHelper from '../components/common/ToastDialog.ets'

const logger = getLogger('ForgotPasswordPage')

@Entry
@Component
struct ForgotPasswordPage {
  @State viewModel: ForgotPasswordViewModel = new ForgotPasswordViewModel()
  @State codeCountdown: number = 0
  @State isDanmakuRunning: boolean = false

  private countdownTimer: number = -1

  aboutToAppear() {
    logger.info('ForgotPasswordPage aboutToAppear')
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  onPageShow() {
    this.isDanmakuRunning = true
  }

  onPageHide() {
    this.isDanmakuRunning = false
  }

  handleBack(): void {
    router.back()
  }

  async handleSendCode(): Promise<void> {
    if (this.codeCountdown > 0) return
    const success = await this.viewModel.sendCode()
    if (success) {
      this.startCountdown()
    }
  }

  startCountdown(): void {
    this.codeCountdown = 60
    this.countdownTimer = setInterval(() => {
      this.codeCountdown--
      if (this.codeCountdown <= 0) {
        clearInterval(this.countdownTimer)
        this.countdownTimer = -1
      }
    }, 1000)
  }

  async handleReset(): Promise<void> {
    const success = await this.viewModel.resetPassword()
    if (success) {
      setTimeout(() => {
        router.back()
      }, 1500)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景弹幕
      if (this.isDanmakuRunning) {
        DanmakuView()
          .width('100%')
          .height('100%')
      }

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .onClick(() => this.handleBack())
          Text('忘记密码')
            .fontSize(20)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Blank().width(24)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .margin({ top: 20 })

        // 表单
        Column() {
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.viewModel.username = value
            })

          TextInput({ placeholder: '请输入邮箱' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.viewModel.email = value
            })

          Row() {
            TextInput({ placeholder: '请输入验证码' })
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.viewModel.code = value
              })

            Button(this.codeCountdown > 0 ? `${this.codeCountdown}s` : '发送验证码')
              .width(120)
              .height(48)
              .backgroundColor(this.codeCountdown > 0 ? '#CCCCCC' : '#00BCD4')
              .fontColor('#FFFFFF')
              .fontSize(12)
              .borderRadius(12)
              .enabled(this.codeCountdown === 0)
              .onClick(() => this.handleSendCode())
          }
          .margin({ bottom: 16 })

          TextInput({ placeholder: '请输入新密码' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .type(InputType.Password)
            .margin({ bottom: 24 })
            .onChange((value: string) => {
              this.viewModel.newPassword = value
            })

          Button('重置密码')
            .width('100%')
            .height(48)
            .backgroundColor(this.viewModel.state === ResetState.LOADING ? '#CCCCCC' : '#00BCD4')
            .fontColor('#FFFFFF')
            .fontSize(18)
            .borderRadius(24)
            .enabled(this.viewModel.state !== ResetState.LOADING)
            .onClick(() => this.handleReset())
        }
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .width('85%')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ets/pages/ForgotPasswordPage.ets
git commit -m "feat(day3): implement ForgotPasswordPage"
```

---

## Task 11: 更新路由配置

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: 更新 main_pages.json**

```json
{
  "src": [
    "pages/Index",
    "pages/LoginPage",
    "pages/ForgotPasswordPage",
    "pages/MainPage"
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add resources/base/profile/main_pages.json
git commit -m "feat(day3): update main_pages.json with new routes"
```

---

## Task 12: 编译验证

- [ ] **Step 1: 完整编译**

Run → Run 'entry' 或快捷键 Shift + F10

确认输出 `SUCCESS`

- [ ] **Step 2: 测试登录流程**

1. 启动应用 → 跳转到 LoginPage
2. 输入用户名/密码 → 点击登录 → 成功跳转 MainPage
3. 点击"没有账号？去注册" → 切换到注册模式
4. 输入信息 → 点击发送验证码
5. 输入验证码 → 点击注册 → 成功跳转 MainPage
6. 点击"忘记密码" → 跳转到 ForgotPasswordPage

- [ ] **Step 3: 最终 Commit**

```bash
git add .
git commit -m "feat(day2-3): complete login/register/forgot-password module"
```

---

## 验证清单

- [ ] `models/` 用户和认证数据模型
- [ ] `services/auth/AuthService.ets` 认证服务
- [ ] `utils/FormValidator.ets` 表单验证
- [ ] `utils/BiometricHelper.ets` 生物识别
- [ ] `components/common/DanmakuView.ets` 弹幕动画
- [ ] `components/common/ToastDialog.ets` Toast提示
- [ ] `viewmodels/LoginViewModel.ets` 登录ViewModel
- [ ] `viewmodels/ForgotPasswordViewModel.ets` 忘记密码ViewModel
- [ ] `pages/LoginPage.ets` 登录页面
- [ ] `pages/ForgotPasswordPage.ets` 忘记密码页面
- [ ] `main_pages.json` 路由配置更新
- [ ] 编译通过
- [ ] Git 已提交

---

**Plan 版本**: 1.0
**最后更新**: 2026-04-20
