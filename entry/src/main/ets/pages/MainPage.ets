/**
 * 主页面框架
 * 对标 Android 的 MainActivity
 */

import router from '@ohos.router'
import { getLogger } from '../utils/Logger.ets'

const logger = getLogger('MainPage')

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  private tabController: TabsController = new TabsController()

  aboutToAppear() {
    logger.info('MainPage aboutToAppear')
  }

  onPageShow() {
    logger.info('MainPage onPageShow')
  }

  onPageHide() {
    logger.info('MainPage onPageHide')
  }

  build() {
    Tabs({ controller: this.tabController, index: this.currentIndex }) {
      TabContent() {
        Column() {
          Text('日记')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日记')

      TabContent() {
        Column() {
          Text('日历')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日历')

      TabContent() {
        Column() {
          Text('聊天')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('聊天')

      TabContent() {
        Column() {
          Text('日程')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('日程')

      TabContent() {
        Column() {
          Text('我的')
            .fontSize(30)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .tabBar('我的')
    }
    .onChange((index: number) => {
      this.currentIndex = index
      logger.info(`Tab changed to index: ${index}`)
    })
    .barPosition(BarPosition.End)
    .barHeight(60)
  }
}