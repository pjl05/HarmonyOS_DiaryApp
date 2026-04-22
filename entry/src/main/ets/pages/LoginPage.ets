/**
 * 登录页面
 * 对标 Android LoginActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'
import { LoginViewModel, LoginState } from '../viewmodels/LoginViewModel.ets'
import { DanmakuView } from '../components/common/DanmakuView.ets'
import { ToastHelper } from '../components/common/ToastDialog.ets'
import { BiometricHelper, BiometricError } from '../utils/BiometricHelper.ets'

const logger = getLogger('LoginPage')

@Entry
@Component
struct LoginPage {
  // 直接使用 @State 管理所有状态
  @State loginName: string = ''
  @State password: string = ''
  @State isLoginMode: boolean = true
  @State loginState: LoginState = LoginState.IDLE
  @State errorMessage: string = ''
  @State biometricAvailable: boolean = false

  // 注册相关状态
  @State registerUsername: string = ''
  @State registerEmail: string = ''
  @State registerCode: string = ''
  @State agreePrivacy: boolean = false
  @State codeCountdown: number = 0
  @State isDanmakuRunning: boolean = false

  private viewModel: LoginViewModel = new LoginViewModel()
  private countdownTimer: number = -1

  aboutToAppear(): void {
    logger.info('LoginPage aboutToAppear')
    this.checkBiometricAvailability()
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

  async checkBiometricAvailability(): Promise<void> {
    try {
      const biometricHelper = BiometricHelper.getInstance()
      this.biometricAvailable = await biometricHelper.isBiometricSupported()
    } catch {
      this.biometricAvailable = false
    }
  }

  async handleSubmit(): Promise<void> {
    if (!this.agreePrivacy) {
      ToastHelper.showShort('请先同意隐私政策')
      return
    }

    if (this.isLoginMode) {
      logger.info(`Login attempt: ${this.loginName}`)
      const success = await this.viewModel.login(this.loginName, this.password)
      logger.info(`Login result: ${success}, state: ${this.loginState}`)
      if (success) {
        ToastHelper.showShort('登录成功！')
        this.navigateToMain()
      } else {
        this.errorMessage = this.viewModel.errorMessage
      }
    } else {
      logger.info(`Register attempt: ${this.registerUsername}, ${this.registerEmail}`)
      const success = await this.viewModel.register(
        this.registerUsername,
        this.registerEmail,
        this.password,
        this.registerCode
      )
      if (success) {
        ToastHelper.showShort('注册成功！')
        this.navigateToMain()
      } else {
        this.errorMessage = this.viewModel.errorMessage
      }
    }
  }

  async handleSendCode(): Promise<void> {
    if (this.codeCountdown > 0) return

    const success = await this.viewModel.sendCode(
      this.registerEmail,
      this.registerUsername,
      'register'
    )

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

  handleBiometricLogin(): void {
    const helper = BiometricHelper.getInstance()
    helper.authenticate(
      '身份验证',
      '验证后即可登录',
      () => {
        ToastHelper.showShort('验证成功')
        this.navigateToMain()
      },
      (error: BiometricError, message: string): void => {
        if (error !== BiometricError.USER_CANCEL) {
          ToastHelper.showShort(message)
        }
      }
    )
  }

  navigateToMain(): void {
    logger.info('Navigating to MainPage')
    const result = router.replaceUrl({ url: 'pages/MainPage' })
    logger.info(`replaceUrl called, result: ${result}`)
    logger.info('After replaceUrl call')
  }

  navigateToForgotPassword(): void {
    router.pushUrl({ url: 'pages/ForgotPasswordPage' })
  }

  toggleMode(): void {
    this.isLoginMode = !this.isLoginMode
    this.errorMessage = ''
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景弹幕动画
      if (this.isDanmakuRunning) {
        DanmakuView()
          .width('100%')
          .height('100%')
      }

      // 登录表单
      Scroll() {
        Column() {
          // Logo
          Column() {
            Text('DiaryApp')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('记录美好生活')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 8 })
          }
          .margin({ top: 80, bottom: 60 })

          // 表单
          Column() {
            if (this.isLoginMode) {
              this.buildLoginForm()
            } else {
              this.buildRegisterForm()
            }

            // 隐私协议
            Row() {
              Checkbox()
                .select(this.agreePrivacy)
                .onChange((value: boolean) => {
                  this.agreePrivacy = value
                })
                .width(20)
                .height(20)
              Text('我已阅读并同意')
                .fontSize(12)
                .fontColor('#666666')
              Text('《隐私政策》')
                .fontSize(12)
                .fontColor('#00BCD4')
            }
            .margin({ top: 16 })

            // 提交按钮
            Button(this.isLoginMode ? '登录' : '注册')
              .width('100%')
              .height(48)
              .backgroundColor(this.loginState === LoginState.LOADING ? '#CCCCCC' : '#00BCD4')
              .fontColor('#FFFFFF')
              .fontSize(18)
              .borderRadius(24)
              .enabled(this.loginState !== LoginState.LOADING)
              .onClick(() => this.handleSubmit())
              .margin({ top: 24 })

            // 错误提示
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(12)
                .fontColor('#FF5252')
                .margin({ top: 8 })
            }

            // 切换模式
            Row() {
              if (this.isLoginMode) {
                Text('忘记密码？')
                  .fontSize(14)
                  .fontColor('#00BCD4')
                  .onClick(() => this.navigateToForgotPassword())
              }
              Blank()
              Text(this.isLoginMode ? '没有账号？去注册' : '已有账号？去登录')
                .fontSize(14)
                .fontColor('#00BCD4')
                .onClick(() => this.toggleMode())
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .width('85%')
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildLoginForm() {
    TextInput({ placeholder: '请输入用户名或邮箱' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.loginName = value
      })

    TextInput({ placeholder: '请输入密码' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .type(InputType.Password)
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.password = value
      })

    if (this.biometricAvailable) {
      Button('使用生物识别登录')
        .width('100%')
        .height(44)
        .backgroundColor('#FFFFFF')
        .fontColor('#00BCD4')
        .fontSize(14)
        .borderRadius(12)
        .borderWidth(1)
        .borderColor('#00BCD4')
        .margin({ top: 8 })
        .onClick(() => this.handleBiometricLogin())
    }
  }

  @Builder
  buildRegisterForm() {
    TextInput({ placeholder: '请输入昵称' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.registerUsername = value
      })

    TextInput({ placeholder: '请输入邮箱' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.registerEmail = value
      })

    Row() {
      TextInput({ placeholder: '请输入验证码' })
        .layoutWeight(1)
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.registerCode = value
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

    TextInput({ placeholder: '请输入密码' })
      .width('100%')
      .height(48)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
      .type(InputType.Password)
      .margin({ bottom: 16 })
      .onChange((value: string) => {
        this.password = value
      })
  }
}