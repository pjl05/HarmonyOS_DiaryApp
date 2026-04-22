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

export type AuthSuccessCallback = () => void
export type AuthFailCallback = (error: BiometricError, message: string) => void

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
      const faceAuthManager = this.getFaceAuthManager()
      const fingerprintAuthManager = this.getFingerprintAuthManager()
      const faceSupport: boolean = faceAuthManager !== null
      const fingerprintSupport: boolean = fingerprintAuthManager !== null
      const supported: boolean = faceSupport || fingerprintSupport
      logger.info(`Biometric supported: ${supported}`)
      return supported
    } catch (error) {
      logger.error(`Biometric check error: ${JSON.stringify(error)}`)
      return false
    }
  }

  private getFaceAuthManager(): Object | null {
    return null
  }

  private getFingerprintAuthManager(): Object | null {
    return null
  }

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
      const supported: boolean = await this.isBiometricSupported()
      if (!supported) {
        failCallback(BiometricError.UNSUPPORTED, '设备不支持生物识别')
        return
      }

      const faceAuthManager = this.getFaceAuthManager()
      if (faceAuthManager !== null) {
        failCallback(BiometricError.UNSUPPORTED, '生物识别暂不可用')
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