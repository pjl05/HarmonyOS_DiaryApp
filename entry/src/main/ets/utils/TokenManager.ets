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