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