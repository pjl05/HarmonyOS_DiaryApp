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