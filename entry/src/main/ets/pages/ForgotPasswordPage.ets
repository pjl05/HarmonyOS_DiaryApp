/**
 * 忘记密码页面
 * 对标 Android ForgotPasswordActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'
import { ForgotPasswordViewModel, ResetState } from '../viewmodels/ForgotPasswordViewModel.ets'
import DanmakuView from '../components/common/DanmakuView.ets'
import ToastHelper from '../components/common/ToastDialog.ets'

const logger = getLogger('ForgotPasswordPage')

@Entry
@Component
struct ForgotPasswordPage {
  @State viewModel: ForgotPasswordViewModel = new ForgotPasswordViewModel()
  @State codeCountdown: number = 0
  @State isDanmakuRunning: boolean = false

  private countdownTimer: number = -1

  aboutToAppear() {
    logger.info('ForgotPasswordPage aboutToAppear')
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer)
    }
  }

  onPageShow() {
    this.isDanmakuRunning = true
  }

  onPageHide() {
    this.isDanmakuRunning = false
  }

  handleBack(): void {
    router.back()
  }

  async handleSendCode(): Promise<void> {
    if (this.codeCountdown > 0) return
    const success = await this.viewModel.sendCode()
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
    const success = await this.viewModel.resetPassword()
    if (success) {
      setTimeout(() => {
        router.back()
      }, 1500)
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
              this.viewModel.username = value
            })

          TextInput({ placeholder: '请输入邮箱' })
            .width('100%')
            .height(48)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 })
            .onChange((value: string) => {
              this.viewModel.email = value
            })

          Row() {
            TextInput({ placeholder: '请输入验证码' })
              .layoutWeight(1)
              .height(48)
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .onChange((value: string) => {
                this.viewModel.code = value
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
              this.viewModel.newPassword = value
            })

          Button('重置密码')
            .width('100%')
            .height(48)
            .backgroundColor(this.viewModel.state === ResetState.LOADING ? '#CCCCCC' : '#00BCD4')
            .fontColor('#FFFFFF')
            .fontSize(18)
            .borderRadius(24)
            .enabled(this.viewModel.state !== ResetState.LOADING)
            .onClick(() => this.handleReset())
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