/**
 * 常量定义
 */

export class ApiConstants {
  // 服务器地址
  static readonly BASE_URL: string = 'http://39.97.46.231:3000/'

  // API 端点
  static readonly API_AUTH_LOGIN: string = 'api/auth/login'
  static readonly API_AUTH_REGISTER: string = 'api/auth/register'
  static readonly API_AUTH_SEND_CODE: string = 'api/auth/send-code'
  static readonly API_AUTH_FORGOT_PASSWORD: string = 'api/auth/reset-password'

  static readonly API_DIARY: string = 'api/diary'
  static readonly API_DIARY_EXPORT: string = 'api/diary/export'

  static readonly API_CHAT: string = 'api/chat'

  static readonly API_SCHEDULE: string = 'api/schedule'
  static readonly API_MEMBER_PLANS: string = 'api/member/plans'

  // WebSocket 地址
  static readonly WS_AI_URL: string = 'ws://39.97.46.231:3000/ws/ai'

  // 超时配置（毫秒）
  static readonly CONNECT_TIMEOUT: number = 30000
  static readonly READ_TIMEOUT: number = 30000
}

export class StorageKeys {
  static readonly TOKEN: string = 'auth_token'
  static readonly USER_ID: string = 'user_id'
  static readonly USERNAME: string = 'username'
  static readonly IS_LOGGED_IN: string = 'is_logged_in'
  static readonly THEME_MODE: string = 'theme_mode'
  static readonly LANGUAGE: string = 'language'
}

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

export enum ApiCode {
  SUCCESS = 200,
  UNAUTHORIZED = 401,
  NOT_FOUND = 404,
  SERVER_ERROR = 500
}