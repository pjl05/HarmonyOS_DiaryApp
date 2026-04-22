/**
 * 认证相关数据模型
 * 对标 Android LoginRequest, RegisterRequest 等
 */

import { UserData } from './UserModel.ets'

export class LoginRequest {
  loginName: string
  password: string

  constructor(loginName: string, password: string) {
    this.loginName = loginName
    this.password = password
  }
}

export class RegisterRequest {
  username: string
  email: string
  password: string
  verificationCode: string

  constructor(username: string, email: string, password: string, verificationCode: string) {
    this.username = username
    this.email = email
    this.password = password
    this.verificationCode = verificationCode
  }
}

export class SendCodeRequest {
  email: string
  type: string
  username: string | null = null

  constructor(email: string, type: string, username: string | null = null) {
    this.email = email
    this.type = type
    this.username = username
  }
}

export class ResetPasswordRequest {
  email: string
  verificationCode: string
  newPassword: string

  constructor(email: string, verificationCode: string, newPassword: string) {
    this.email = email
    this.verificationCode = verificationCode
    this.newPassword = newPassword
  }
}

export class GenericResponse {
  success: boolean = false
  message: string = ''

  constructor(success: boolean, message: string = '') {
    this.success = success
    this.message = message
  }
}

export class LoginResponse {
  success: boolean = false
  data: UserData | null = null
  message: string = ''

  constructor(success: boolean, data: UserData | null = null, message: string = '') {
    this.success = success
    this.data = data
    this.message = message
  }
}

export class RegisterResponse {
  success: boolean = false
  data: UserData | null = null
  message: string = ''

  constructor(success: boolean, data: UserData | null = null, message: string = '') {
    this.success = success
    this.data = data
    this.message = message
  }
}