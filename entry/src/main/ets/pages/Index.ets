import router from '@ohos.router'
import TokenManager from '../utils/TokenManager.ets'
import PreferencesHelper from '../utils/PreferencesHelper.ets'
import { getLogger } from '../utils/Logger.ets'

const logger = getLogger('Index')

@Entry
@Component
struct Index {
  async aboutToAppear() {
    logger.info('Index page loading...')

    // 初始化 PreferencesHelper
    const context = getContext(this)
    await PreferencesHelper.init(context)
    logger.info('PreferencesHelper initialized')

    // 检测登录状态
    const isLoggedIn = await TokenManager.isLoggedIn()
    logger.info(`Login status: ${isLoggedIn}`)

    if (isLoggedIn) {
      // 已登录，跳转到主页
      router.replaceUrl({ url: 'pages/MainPage' })
    } else {
      // 未登录，先跳转到主页（后续创建 LoginPage）
      router.replaceUrl({ url: 'pages/MainPage' })
    }
  }

  build() {
    Column() {
      Text('DiaryApp')
        .fontSize(30)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}