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