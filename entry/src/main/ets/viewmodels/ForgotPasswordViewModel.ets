/**
 * 忘记密码 ViewModel
 */

import { getLogger } from '../utils/Logger.ets'
import AuthService from '../services/auth/AuthService.ets'
import { ResetPasswordRequest } from '../models/ApiModels.ets'
import { FormValidator, ValidationResult } from '../utils/FormValidator.ets'
import { ToastHelper } from '../components/common/ToastDialog.ets'

const logger = getLogger('ForgotPasswordViewModel')

export enum ResetState {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error'
}

export class ForgotPasswordViewModel {
  email: string = ''
  username: string = ''
  code: string = ''
  newPassword: string = ''
  state: ResetState = ResetState.IDLE
  errorMessage: string = ''

  aboutToAppear(): void {
    logger.info('ForgotPasswordViewModel aboutToAppear')
  }

  async sendCode(email: string, username: string): Promise<boolean> {
    if (!FormValidator.isValidEmail(email)) {
      ToastHelper.showShort('请输入有效的邮箱地址')
      return false
    }
    if (!FormValidator.isValidUsername(username)) {
      ToastHelper.showShort('请输入用户名')
      return false
    }

    this.state = ResetState.LOADING

    try {
      const success: boolean = await AuthService.sendCode(email.trim(), 'reset_password', username.trim())
      if (success) {
        ToastHelper.showShort('验证码已发送')
      }
      this.state = ResetState.IDLE
      return success
    } catch (error) {
      this.state = ResetState.ERROR
      const message = error instanceof Error ? error.message : '发送验证码失败'
      ToastHelper.showShort(message)
      return false
    }
  }

  async resetPassword(email: string, code: string, newPassword: string): Promise<boolean> {
    const validation: ValidationResult = FormValidator.validateResetPassword(email, code, newPassword)
    if (!validation.valid) {
      ToastHelper.showShort(validation.error)
      return false
    }

    this.state = ResetState.LOADING

    try {
      const request = new ResetPasswordRequest(email.trim(), code.trim(), newPassword)
      const success: boolean = await AuthService.resetPassword(request)
      if (success) {
        this.state = ResetState.SUCCESS
        ToastHelper.showShort('密码重置成功')
      }
      return success
    } catch (error) {
      this.state = ResetState.ERROR
      const message = error instanceof Error ? error.message : '重置密码失败'
      ToastHelper.showShort(message)
      return false
    }
  }
}