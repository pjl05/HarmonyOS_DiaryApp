/**
 * 登录 ViewModel
 */

import { getLogger } from '../utils/Logger.ets'
import AuthService from '../services/auth/AuthService.ets'
import { LoginRequest, RegisterRequest } from '../models/ApiModels.ets'
import { FormValidator, ValidationResult } from '../utils/FormValidator.ets'
import { ToastHelper } from '../components/common/ToastDialog.ets'
import { BiometricHelper } from '../utils/BiometricHelper.ets'

const logger = getLogger('LoginViewModel')

export enum LoginState {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error'
}

export class LoginViewModel {
  loginName: string = ''
  password: string = ''
  isLoginMode: boolean = true
  loginState: LoginState = LoginState.IDLE
  errorMessage: string = ''
  biometricAvailable: boolean = false

  aboutToAppear(): void {
    logger.info('LoginViewModel aboutToAppear')
    this.checkBiometricAvailability()
  }

  async checkBiometricAvailability(): Promise<void> {
    try {
      const biometricHelper = BiometricHelper.getInstance()
      this.biometricAvailable = await biometricHelper.isBiometricSupported()
    } catch {
      this.biometricAvailable = false
    }
  }

  async login(loginName: string, password: string): Promise<boolean> {
    logger.info(`login called with: ${loginName}`)
    const validation: ValidationResult = FormValidator.validateLogin(loginName, password)
    if (!validation.valid) {
      logger.warn(`Validation failed: ${validation.error}`)
      this.errorMessage = validation.error
      ToastHelper.showShort(validation.error)
      return false
    }

    logger.info('Setting state to LOADING')
    this.loginState = LoginState.LOADING
    this.errorMessage = ''

    try {
      logger.info('Creating LoginRequest and calling AuthService.login()')
      const request = new LoginRequest(loginName.trim(), password)
      logger.info(`LoginRequest created: ${JSON.stringify(request)}`)
      const success: boolean = await AuthService.login(request)
      logger.info(`AuthService.login() returned: ${success}`)
      this.loginState = LoginState.SUCCESS
      logger.info('Login successful, returning true')
      return success
    } catch (error) {
      logger.error(`Login caught error: ${JSON.stringify(error)}`)
      this.loginState = LoginState.ERROR
      const message = error instanceof Error ? error.message : '登录失败'
      logger.error(`Error message: ${message}`)
      this.errorMessage = message
      ToastHelper.showShort(message)
      return false
    }
  }

  async register(username: string, email: string, password: string, code: string): Promise<boolean> {
    const validation: ValidationResult = FormValidator.validateRegister(username, email, password, code)
    if (!validation.valid) {
      this.errorMessage = validation.error
      ToastHelper.showShort(validation.error)
      return false
    }

    this.loginState = LoginState.LOADING
    this.errorMessage = ''

    try {
      const success: boolean = await AuthService.register(new RegisterRequest(username.trim(), email.trim(), password, code.trim()))
      this.loginState = LoginState.SUCCESS
      return success
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
      const success: boolean = await AuthService.sendCode(email.trim(), type, username.trim() || null)
      if (success) {
        ToastHelper.showShort('验证码已发送')
      }
      return success
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