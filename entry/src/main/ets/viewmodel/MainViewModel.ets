/**
 * MainPage ViewModel
 * 对标 Android MainActivity 中的用户信息、成员状态、版本更新检查逻辑
 */

import http from '@ohos.net.http'
import PreferencesHelper from '../utils/PreferencesHelper'
import { ApiConstants } from '../common/Constants'
import { getLogger } from '../utils/Logger'
import { UpdateInfoResponse } from '../model/UpdateModels'

const logger = getLogger('MainViewModel')

export class MainViewModel {
  username: string = ''
  email: string = ''
  membershipTier: string = 'normal'
  membershipExpiresAt: number = 0
  avatarUri: string = ''
  updateInfo: UpdateInfoResponse | null = null

  /**
   * 从 Preferences 加载本地缓存的用户信息（登录时已保存）
   */
  async loadUserInfo(): Promise<void> {
    try {
      const prefs = PreferencesHelper
      this.username = await prefs.getString('username', '')
      this.email = await prefs.getString('email', '')
      this.membershipTier = await prefs.getString('membership_tier', 'normal')
      const expiresStr = await prefs.getString('membership_expires_at', '0')
      this.membershipExpiresAt = parseInt(expiresStr) || 0
      this.avatarUri = await prefs.getString('avatar_uri', '')
    } catch (err) {
      logger.error('loadUserInfo failed: ' + JSON.stringify(err))
    }
  }

  /**
   * 从服务端刷新用户档案，同步写入 Preferences
   * 对标 Android fetchUserProfile()
   */
  async refreshProfile(): Promise<void> {
    let request = http.createHttp()
    try {
      const token = await PreferencesHelper.getString('token', '')
      if (!token) return

      const response = await request.request(
        ApiConstants.BASE_URL + 'api/user/profile',
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      )

      if (response.responseCode !== 200) return

      const data = JSON.parse(response.result as string) as Record<string, Object>
      if (!data.success || !data.data) return

      const profile = data.data as Record<string, Object>
      const nickname: string = (profile.nickname ?? profile.username ?? '') as string
      const emailVal: string = (profile.email ?? '') as string
      const tier: string = (profile.membership_tier ?? 'normal') as string
      const expiresAt: number = profile.membership_expires_at
        ? new Date(profile.membership_expires_at).getTime()
        : 0

      this.username = nickname
      this.email = emailVal
      this.membershipTier = tier
      this.membershipExpiresAt = expiresAt

      await PreferencesHelper.putString('username', nickname)
      await PreferencesHelper.putString('email', emailVal)
      await PreferencesHelper.putString('membership_tier', tier)
      await PreferencesHelper.putString('membership_expires_at', expiresAt.toString())
    } catch (err) {
      logger.error('refreshProfile failed: ' + JSON.stringify(err))
    } finally {
      request.destroy()
    }
  }

  /**
   * 判断服务端版本是否大于本地版本
   * @param serverVersionCode 服务端版本号
   * @param localVersionCode 本地版本号
   */
  checkHasUpdate(serverVersionCode: number, localVersionCode: number): boolean {
    return serverVersionCode > localVersionCode
  }

  /**
   * 拉取最新版本信息
   * 对标 Android fetchLatestUpdate()
   */
  async fetchLatestUpdate(): Promise<UpdateInfoResponse | null> {
    let request = http.createHttp()
    try {
      const response = await request.request(
        ApiConstants.BASE_URL + 'api/version/latest',
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      )

      if (response.responseCode !== 200) return null

      const data = JSON.parse(response.result as string) as UpdateInfoResponse
      this.updateInfo = data
      return data
    } catch (err) {
      logger.error('fetchLatestUpdate failed: ' + JSON.stringify(err))
      return null
    } finally {
      request.destroy()
    }
  }

  /**
   * 判断是否为有效会员
   * 对标 Android TokenManager.getEffectiveMembershipTier()
   */
  isMember(): boolean {
    if (this.membershipTier === 'normal') return false
    if (this.membershipExpiresAt <= 0) return true
    return Date.now() < this.membershipExpiresAt
  }

  /**
   * 退出登录：清除所有 Preferences 数据
   * 对标 Android TokenManager.clearToken()
   */
  async logout(): Promise<void> {
    try {
      await PreferencesHelper.clear()
      this.username = ''
      this.email = ''
      this.membershipTier = 'normal'
      this.membershipExpiresAt = 0
      this.avatarUri = ''
    } catch (err) {
      logger.error('logout failed: ' + JSON.stringify(err))
    }
  }
}