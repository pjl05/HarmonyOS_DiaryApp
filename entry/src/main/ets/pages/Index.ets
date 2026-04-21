import router from '@ohos.router'
import TokenManager from '../utils/TokenManager.ets'
import { getLogger } from '../utils/Logger.ets'

const logger = getLogger('Index')

@Entry
@Component
struct Index {
  async aboutToAppear() {
    logger.info('Index page loading...')

    // 检测登录状态
    const isLoggedIn = await TokenManager.isLoggedIn()
    logger.info(`Login status: ${isLoggedIn}`)

    if (isLoggedIn) {
      // 已登录，跳转到主页
      router.replaceUrl({ url: 'pages/MainPage' })
    } else {
      // 未登录，跳转到登录页（后续创建）
      router.replaceUrl({ url: 'pages/LoginPage' })
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