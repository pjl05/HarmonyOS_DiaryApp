/**
 * 表单验证工具
 */

export class FormValidator {
  /**
   * 验证邮箱格式
   */
  static isValidEmail(email: string): boolean {
    if (!email || email.trim().length === 0) {
      return false
    }
    const trimmed = email.trim()
    return trimmed.includes('@') && trimmed.toLowerCase().includes('.com')
  }

  /**
   * 验证用户名
   */
  static isValidUsername(username: string): boolean {
    return username && username.trim().length > 0
  }

  /**
   * 验证密码
   */
  static isValidPassword(password: string): boolean {
    return password && password.length > 0
  }

  /**
   * 验证验证码（4-6位数字）
   */
  static isValidCode(code: string): boolean {
    return code && /^\d{4,6}$/.test(code)
  }

  /**
   * 验证登录表单
   */
  static validateLogin(loginName: string, password: string): { valid: boolean, error: string } {
    if (!loginName || loginName.trim().length === 0) {
      return { valid: false, error: '请输入用户名或邮箱' }
    }
    if (!password || password.length === 0) {
      return { valid: false, error: '请输入密码' }
    }
    return { valid: true, error: '' }
  }

  /**
   * 验证注册表单
   */
  static validateRegister(username: string, email: string, password: string, code: string): { valid: boolean, error: string } {
    if (!username || username.trim().length === 0) {
      return { valid: false, error: '请输入昵称' }
    }
    if (!this.isValidEmail(email)) {
      return { valid: false, error: '请输入有效的邮箱地址' }
    }
    if (!password || password.length === 0) {
      return { valid: false, error: '请输入密码' }
    }
    if (!this.isValidCode(code)) {
      return { valid: false, error: '请输入4-6位验证码' }
    }
    return { valid: true, error: '' }
  }

  /**
   * 验证忘记密码表单
   */
  static validateResetPassword(email: string, code: string, newPassword: string): { valid: boolean, error: string } {
    if (!this.isValidEmail(email)) {
      return { valid: false, error: '请输入有效的邮箱地址' }
    }
    if (!this.isValidCode(code)) {
      return { valid: false, error: '请输入4-6位验证码' }
    }
    if (!newPassword || newPassword.length === 0) {
      return { valid: false, error: '请输入新密码' }
    }
    return { valid: true, error: '' }
  }
}