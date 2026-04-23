/**
 * 版本更新数据模型
 * 对标 Android UpdateInfoResponse
 */

export interface UpdateInfoResponse {
  versionCode: number
  versionName: string
  apkUrl: string
  fullApkUrl: string
  releaseNotes: string
  requestBaseUrl: string
  serverUpgradeRequired: boolean
  serverUpgradeMessage: string
}