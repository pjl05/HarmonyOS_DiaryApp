/**
 * 忘记密码页面
 * 对标 Android ForgotPasswordActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'
import { ForgotPasswordViewModel, ResetState } from '../viewmodels/ForgotPasswordViewModel.ets'
import { DanmakuView } from '../components/common/DanmakuView.ets'
import { ToastHelper } from '../components/common/ToastDialog.ets'

const logger = getLogger('ForgotPasswordPage')

@Entry
@Component
struct ForgotPasswordPage {
  // 直接使用 @State 管理所有状态
  @State email: string = ''
  @State username: string = ''
  @State code: string = ''
  @State newPassword: string = ''
  @State state: ResetState = ResetState.IDLE
  @State errorMessage: string = ''
  @State codeCountdown: number = 0
  @State isDanmakuRunning: boolean = false

  private viewModel: ForgotPasswordViewModel = new ForgotPasswordViewModel()
  private countdownTimer: number = -1

  aboutToAppear(): void {
    logger.info('ForgotPasswordPage aboutToAppear')
  }

  aboutToDisappear(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  onPageShow(): void {
    this.isDanmakuRunning = true
  }

  onPageHide(): void {
    this.isDanmakuRunning = false
  }

  handleBack(): void {
    router.back()
  }

  async handleSendCode(): Promise<void> {
    if (this.codeCountdown > 0) return

    const success = await this.viewModel.sendCode(this.email, this.username)
    if (success) {
      this.startCountdown()
    }
  }

  startCountdown(): void {
    this.codeCountdown = 60
    this.countdownTimer = setInterval(() => {
      this.codeCountdown--
      if (this.codeCountdown <= 0) {
        clearInterval(this.countdownTimer)
        this.countdownTimer = -1
      }
    }, 1000)
  }

  async handleReset(): Promise<void> {
    const success = await this.viewModel.resetPassword(this.email, this.code, this.newPassword)
    if (success) {
      ToastHelper.showShort('密码重置成功，请重新登录')
      setTimeout(() => {
        router.back()
      }, 1500)
    } else {
      this.errorMessage = this.viewModel.errorMessage
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景弹幕
      if (this.isDanmakuRunning) {
        DanmakuView()
          .width('100%')
          .height('100%')
      }

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .onClick(() => this.handleBack())
          Text('忘记密码')
            .fontSize(20)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Blank().width(24)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .margin({ top: 20 })

        // 表单
        Column() {
          TextInput({ placeholder: '请输入用户名' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.username = value
            })

          TextInput({ placeholder: '请输入邮箱' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.email = value
            })

          Row() {
            TextInput({ placeholder: '请输入验证码' })
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.code = value
              })

            Button(this.codeCountdown > 0 ? `${this.codeCountdown}s` : '发送验证码')
              .width(120)
              .height(48)
              .backgroundColor(this.codeCountdown > 0 ? '#CCCCCC' : '#00BCD4')
              .fontColor('#FFFFFF')
              .fontSize(12)
              .borderRadius(12)
              .enabled(this.codeCountdown === 0)
              .onClick(() => this.handleSendCode())
          }
          .margin({ bottom: 16 })

          TextInput({ placeholder: '请输入新密码' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .type(InputType.Password)
            .margin({ bottom: 24 })
            .onChange((value: string) => {
              this.newPassword = value
            })

          Button('重置密码')
            .width('100%')
            .height(48)
            .backgroundColor(this.state === ResetState.LOADING ? '#CCCCCC' : '#00BCD4')
            .fontColor('#FFFFFF')
            .fontSize(18)
            .borderRadius(24)
            .enabled(this.state !== ResetState.LOADING)
            .onClick(() => this.handleReset())

          // 错误提示
          if (this.errorMessage) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#FF5252')
              .margin({ top: 8 })
          }
        }
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .width('85%')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}