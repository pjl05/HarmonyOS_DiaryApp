/**
 * 主页面框架
 * 对标 Android 的 MainActivity
 * Day 4 实现：顶部导航 + 左侧抽屉 + 底部操作栏
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { MainViewModel } from '../viewmodel/MainViewModel'
import { DrawerMenu } from '../components/DrawerMenu'
import { TopBar } from '../components/TopBar'
import { BottomBar } from '../components/BottomBar'
import { DiaryPagerPage } from './diary/DiaryPagerPage'
import { SchedulePagerPage } from './schedule/SchedulePagerPage'
import { DayPagerPage } from './day/DayPagerPage'
import { CalendarPage } from './calendar/CalendarPage'
import { getLogger } from '../utils/Logger'

const logger = getLogger('MainPage')

interface TabConfig {
  id: string
  title: string
  icon: Resource
}

@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 0
  @State isDrawerOpen: boolean = false
  @State searchQuery: string = ''
  @State calendarYearMonthText: string = ''
  @State isDarkMode: boolean = false
  @State username: string = ''
  @State email: string = ''
  @State avatarUri: string = ''
  @State membershipTier: string = 'normal'

  private vm: MainViewModel = new MainViewModel()

  private tabs: TabConfig[] = [
    { id: 'diary', title: '日记', icon: $r('app.media.ic_tab_diary') },
    { id: 'schedule', title: '日程', icon: $r('app.media.ic_tab_schedule') },
    { id: 'day', title: '日子', icon: $r('app.media.ic_tab_day') },
    { id: 'calendar', title: '日历', icon: $r('app.media.ic_tab_calendar') },
  ]

  aboutToAppear() {
    logger.info('MainPage aboutToAppear')
    this.loadUserInfo()
    this.refreshCalendarTitle()

    // 后台异步刷新用户档案
    this.vm.refreshProfile().then(() => {
      this.username = this.vm.username
      this.email = this.vm.email
      this.membershipTier = this.vm.membershipTier
    }).catch(() => {})

    // 检查服务端升级
    this.checkServerUpgrade()
  }

  async loadUserInfo() {
    await this.vm.loadUserInfo()
    this.username = this.vm.username
    this.email = this.vm.email
    this.avatarUri = this.vm.avatarUri
    this.membershipTier = this.vm.membershipTier
  }

  private refreshCalendarTitle() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    this.calendarYearMonthText = `${year}年${month}月`
  }

  private async checkServerUpgrade() {
    try {
      const info = await this.vm.fetchLatestUpdate()
      if (info?.serverUpgradeRequired) {
        const msg = info.serverUpgradeMessage ||
          '当前软件服务器升级，继续使用将无法连接到新服务器，请立即检查更新！'
        promptAction.showDialog({
          title: '服务器升级通知',
          message: msg,
          buttons: [
            { text: '检查更新', color: '#00BCD4' },
            { text: '退出', color: '#FF5722' }
          ]
        }).catch(() => {})
      }
    } catch (err) {
      logger.error('checkServerUpgrade error: ' + JSON.stringify(err))
    }
  }

  private getSearchHint(): string {
    switch (this.currentTabIndex) {
      case 0: return '搜索日记...'
      case 1: return '搜索日程...'
      case 2: return '搜索日子...'
      default: return '搜索...'
    }
  }

  private handleDrawerItemClick(itemId: string) {
    this.isDrawerOpen = false
    switch (itemId) {
      case 'favorites':
        promptAction.showToast({ message: '收藏页面（Day 5-7 实现）' })
        break
      case 'vault':
        if (this.membershipTier === 'normal') {
          promptAction.showToast({ message: '此功能需要会员权限' })
        } else {
          promptAction.showToast({ message: '保险箱（Day 14 实现）' })
        }
        break
      case 'recycle_bin':
        promptAction.showToast({ message: '回收站（Day 5-7 实现）' })
        break
      case 'drafts':
        promptAction.showToast({ message: '草稿箱（Day 5-7 实现）' })
        break
      case 'export_history':
        promptAction.showToast({ message: '导出历史（Day 5-7 实现）' })
        break
      case 'transfer_data':
        promptAction.showToast({ message: '数据迁移（Day 14 实现）' })
        break
      case 'membership':
        promptAction.showToast({ message: '会员中心（Day 14 实现）' })
        break
      case 'check_update':
        this.vm.fetchLatestUpdate().then((info) => {
          if (info) {
            promptAction.showToast({ message: `最新版本：${info.versionName}` })
          }
        }).catch(() => {})
        break
      case 'theme_toggle':
        this.isDarkMode = !this.isDarkMode
        break
      case 'settings':
        promptAction.showToast({ message: '设置（Day 13 实现）' })
        break
      case 'about':
        promptAction.showToast({ message: '关于（Day 13 实现）' })
        break
      case 'love_zone':
        promptAction.showToast({ message: '爱情区（Day 14 实现）' })
        break
      case 'special_thanks':
        promptAction.showToast({ message: '特别感谢（Day 13 实现）' })
        break
      case 'logout':
        this.handleLogout()
        break
    }
  }

  private async handleLogout() {
    await this.vm.logout()
    router.clear()
    router.replaceUrl({ url: 'pages/LoginPage' }).catch(() => {})
  }

  private handleNewClick() {
    switch (this.currentTabIndex) {
      case 0:
        promptAction.showToast({ message: '新建日记（Day 5 实现）' })
        break
      case 1:
        promptAction.showToast({ message: '新建日程（Day 11 实现）' })
        break
      case 2:
        promptAction.showToast({ message: '新建日子（Day 12 实现）' })
        break
    }
  }

  build() {
    Stack() {
      // 主体布局层
      Column() {
        // 顶部工具栏
        TopBar({
          avatarUri: this.avatarUri,
          searchHint: this.getSearchHint(),
          showCalendarYearMonth: this.currentTabIndex === 3,
          calendarYearMonthText: this.calendarYearMonthText,
          searchQuery: $searchQuery,
          onMenuClick: () => {
            this.isDrawerOpen = true
          },
          onAvatarClick: () => {
            promptAction.showToast({ message: '个人中心（Day 13 实现）' })
          },
          onStarfieldClick: () => {
            promptAction.showToast({ message: '星空页面（Day 14 实现）' })
          },
          onCalendarYearMonthClick: () => {
            promptAction.showToast({ message: '年月选择器（Day 10 实现）' })
          }
        })

        // 顶部 Tab 标签栏
        Row() {
          ForEach(this.tabs, (tab: TabConfig, index: number) => {
            Column({ space: 2 }) {
              Image(tab.icon)
                .width(22)
                .height(22)
                .fillColor(this.currentTabIndex === index ? '#00BCD4' : '#999999')
              Text(tab.title)
                .fontSize(11)
                .fontColor(this.currentTabIndex === index ? '#00BCD4' : '#999999')
                .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
            }
            .layoutWeight(1)
            .height(44)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentTabIndex = index
            })
          })
        }
        .width('100%')
        .height(44)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 3, color: '#0D000000', offsetX: 0, offsetY: 2 })

        // Tab 内容区
        Swiper() {
          DiaryPagerPage()
          SchedulePagerPage()
          DayPagerPage()
          CalendarPage()
        }
        .index(this.currentTabIndex)
        .loop(false)
        .layoutWeight(1)
        .width('100%')
        .onChange((index: number) => {
          this.currentTabIndex = index
        })

        // 底部操作栏
        BottomBar({
          currentTabIndex: this.currentTabIndex,
          chatLabel: 'AI 助手',
          onChatClick: () => {
            promptAction.showToast({ message: 'AI 聊天（Day 8-9 实现）' })
          },
          onNewClick: () => this.handleNewClick(),
          onProfileClick: () => {
            promptAction.showToast({ message: '个人中心（Day 13 实现）' })
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F5')

      // 抽屉遮罩层
      if (this.isDrawerOpen) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .onClick(() => {
            this.isDrawerOpen = false
          })
          .zIndex(10)
      }

      // 左侧抽屉面板
      Row() {
        DrawerMenu({
          username: this.username,
          email: this.email,
          avatarUri: this.avatarUri,
          isDarkMode: this.isDarkMode,
          onItemClick: (id: string) => this.handleDrawerItemClick(id),
          onAvatarClick: () => {
            promptAction.showToast({ message: '头像选择（Day 13 实现）' })
          },
          onEditBgClick: () => {
            promptAction.showToast({ message: '背景图选择（Day 13 实现）' })
          }
        })
          .width(280)
          .height('100%')
      }
      .width('100%')
      .height('100%')
      .offset({ x: this.isDrawerOpen ? 0 : -280 })
      .animation({ duration: 250, curve: Curve.EaseInOut })
      .zIndex(20)
    }
    .width('100%')
    .height('100%')
    .gesture(
      SwipeGesture({ direction: SwipeDirection.Horizontal, speed: 80 })
        .onAction((event: GestureEvent) => {
          const swipeAngle = event.angle
          if (swipeAngle > 0 && !this.isDrawerOpen) {
            this.isDrawerOpen = true
          } else if (swipeAngle < 0 && this.isDrawerOpen) {
            this.isDrawerOpen = false
          }
        })
    )
  }
}