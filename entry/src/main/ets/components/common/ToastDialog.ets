/**
 * Toast 提示组件
 * 对标 Android Toast
 */

import promptAction from '@ohos.promptAction'

export class ToastHelper {
  private static instance: ToastHelper

  static getInstance(): ToastHelper {
    if (!ToastHelper.instance) {
      ToastHelper.instance = new ToastHelper()
    }
    return ToastHelper.instance
  }

  showShort(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      })
    } catch (error) {
      console.error(`Toast error: ${JSON.stringify(error)}`)
    }
  }

  showLong(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 3500
      })
    } catch (error) {
      console.error(`Toast error: ${JSON.stringify(error)}`)
    }
  }

  showSuccess(message: string): void {
    this.showShort(message)
  }

  showError(message: string): void {
    this.showShort(message)
  }
}

export default ToastHelper.getInstance()