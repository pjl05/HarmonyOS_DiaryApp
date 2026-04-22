/**
 * 认证服务
 * 对标 Android UserRepository 中的认证方法
 */

import HttpClient from '../http/HttpClient.ets'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import TokenManager from '../../utils/TokenManager.ets'
import { LoginRequest, RegisterRequest, SendCodeRequest, ResetPasswordRequest } from '../../models/ApiModels.ets'
import { UserData } from '../../models/UserModel.ets'

const logger = getLogger('AuthService')

// 内部响应数据接口
interface ResponseData {
  success?: boolean
  data?: UserData
  message?: string
}

export class AuthService {
  private static instance: AuthService

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService()
    }
    return AuthService.instance
  }

  private async saveUserData(userData: UserData): Promise<void> {
    await TokenManager.setToken(userData.token)
    await TokenManager.setUserId(userData.userId.toString())
    await TokenManager.setUsername(userData.username)
    await TokenManager.setLoggedIn(true)
  }

  /**
   * 用户登录
   */
  async login(request: LoginRequest): Promise<boolean> {
    logger.info(`Login request: ${request.loginName}`)

    try {
      const response = await HttpClient.post<ResponseData>(
        ApiConstants.API_AUTH_LOGIN,
        request
      )

      logger.info(`Login response: ${JSON.stringify(response)}`)

      // 解析响应数据
      let responseData: UserData | null = null
      let success = false
      let message = ''

      // response.data 存在，尝试解析
      if (response.data !== null && response.data !== undefined) {
        const dataObj = response.data as Record<string, Object>
        // 尝试作为 ResponseData 解析（包含 success 字段）
        const loginData = response.data as ResponseData
        if (loginData.success !== undefined) {
          success = loginData.success
          message = loginData.message ?? ''
          responseData = loginData.data ?? null
        } else {
          // 尝试作为 UserData 直接解析
          const userData = response.data as UserData
          if (userData.userId !== undefined) {
            responseData = userData
            success = true
            message = response.message ?? ''
          }
        }
      } else {
        // 没有 data，检查 response 本身
        if (response.code === 200) {
          success = true
          message = response.message ?? ''
        }
      }

      if (success && responseData) {
        await this.saveUserData(responseData)
        logger.info(`Login success: ${responseData.username}`)
        return true
      } else {
        throw new Error(message || 'Login failed')
      }
    } catch (error) {
      logger.error(`Login error: ${JSON.stringify(error)}`)
      throw new Error(error instanceof Error ? error.message : 'Login failed')
    }
  }

  /**
   * 用户注册
   */
  async register(request: RegisterRequest): Promise<boolean> {
    logger.info(`Register request: ${request.username}, ${request.email}`)

    try {
      const response = await HttpClient.post<ResponseData>(
        ApiConstants.API_AUTH_REGISTER,
        request
      )

      logger.info(`Register response: ${JSON.stringify(response)}`)

      // 解析响应数据
      let responseData: UserData | null = null
      let success = false
      let message = ''

      // response.data 存在，尝试解析
      if (response.data !== null && response.data !== undefined) {
        const loginData = response.data as ResponseData
        if (loginData.success !== undefined) {
          success = loginData.success
          message = loginData.message ?? ''
          responseData = loginData.data ?? null
        } else {
          // 尝试作为 UserData 直接解析
          const userData = response.data as UserData
          if (userData.userId !== undefined) {
            responseData = userData
            success = true
            message = response.message ?? ''
          }
        }
      } else {
        // 没有 data，检查 response 本身
        if (response.code === 200) {
          success = true
          message = response.message ?? ''
        }
      }

      if (success && responseData) {
        await this.saveUserData(responseData)
        logger.info(`Register success: ${responseData.username}`)
        return true
      } else {
        throw new Error(message || 'Register failed')
      }
    } catch (error) {
      logger.error(`Register error: ${JSON.stringify(error)}`)
      throw new Error(error instanceof Error ? error.message : 'Register failed')
    }
  }

  /**
   * 发送验证码
   * @param type - 验证码类型: "register" | "reset_password"
   */
  async sendCode(email: string, type: string, username: string | null = null): Promise<boolean> {
    logger.info(`SendCode request: ${email}, type=${type}`)

    try {
      const request = new SendCodeRequest(email, type, username)
      const response = await HttpClient.post<ResponseData>(
        ApiConstants.API_AUTH_SEND_CODE,
        request
      )

      logger.info(`SendCode response: ${JSON.stringify(response)}`)

      // 检查成功条件 - 根据 code 判断
      const success = response.code === 200
      const message = response.message ?? ''

      if (success) {
        logger.info('Code sent successfully')
        return true
      } else {
        throw new Error(message || 'Failed to send code')
      }
    } catch (error) {
      logger.error(`SendCode error: ${JSON.stringify(error)}`)
      throw new Error(error instanceof Error ? error.message : 'Failed to send code')
    }
  }

  /**
   * 重置密码
   */
  async resetPassword(request: ResetPasswordRequest): Promise<boolean> {
    logger.info(`ResetPassword request: ${request.email}`)

    try {
      const response = await HttpClient.post<ResponseData>(
        ApiConstants.API_AUTH_FORGOT_PASSWORD,
        request
      )

      logger.info(`ResetPassword response: ${JSON.stringify(response)}`)

      // 检查成功条件 - 根据 code 判断
      const success = response.code === 200
      const message = response.message ?? ''

      if (success) {
        logger.info('Password reset successfully')
        return true
      } else {
        throw new Error(message || 'Failed to reset password')
      }
    } catch (error) {
      logger.error(`ResetPassword error: ${JSON.stringify(error)}`)
      throw new Error(error instanceof Error ? error.message : 'Failed to reset password')
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
