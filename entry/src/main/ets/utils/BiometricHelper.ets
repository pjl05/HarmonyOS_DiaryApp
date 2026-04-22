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
