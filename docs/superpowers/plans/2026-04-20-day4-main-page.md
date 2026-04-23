# Day 4：主界面 + 导航框架 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 MainPage 主界面，包括顶部 Tab 导航（日记/日程/日子/日历）、左侧抽屉菜单、底部操作栏、头像/搜索栏，完整对标 Android `MainActivity.kt` 的所有功能。

**Architecture:** MainPage 作为登录后的核心容器，使用 ArkUI `Tabs` + `TabContent` 管理 4 个子页面（占位），`Panel` 或 `Stack + offset` 实现左侧抽屉，`@State` 驱动所有 UI 状态，ViewModel 管理用户信息和成员状态。

**Tech Stack:** ArkTS 4.x, ArkUI Swiper/Tabs/Stack, HarmonyOS Preferences, @ohos/net http, @ohos.router, @ohos.promptAction

---

## 文件结构

```
entry/src/main/ets/
├── pages/
│   ├── MainPage.ets                         # 主界面（本 Day 核心）
│   ├── diary/
│   │   └── DiaryPagerPage.ets               # 日记 Tab 占位（Day 5-7 填充）
│   ├── schedule/
│   │   └── SchedulePagerPage.ets            # 日程 Tab 占位（Day 11 填充）
│   ├── day/
│   │   └── DayPagerPage.ets                 # 日子 Tab 占位（Day 12 填充）
│   └── calendar/
│       └── CalendarPage.ets                 # 日历 Tab 占位（Day 10 填充）
├── viewmodel/
│   └── MainViewModel.ets                    # 用户信息 + 成员状态 + 更新检查
├── components/
│   ├── DrawerMenu.ets                       # 左侧抽屉菜单组件
│   ├── TopBar.ets                           # 顶部搜索/头像/功能栏
│   └── BottomBar.ets                        # 底部操作栏（新建/聊天/我的）
└── model/
    └── UpdateModels.ets                     # 版本更新数据模型
```

> **注意：** DiaryPagerPage、SchedulePagerPage、DayPagerPage、CalendarPage 在本 Day 只创建空壳，Day 5-12 分别填充实现。

---

## Task 1：创建空壳子页面（Tab 占位）

**Files:**
- Create: `entry/src/main/ets/pages/diary/DiaryPagerPage.ets`
- Create: `entry/src/main/ets/pages/schedule/SchedulePagerPage.ets`
- Create: `entry/src/main/ets/pages/day/DayPagerPage.ets`
- Create: `entry/src/main/ets/pages/calendar/CalendarPage.ets`

- [ ] **Step 1: 创建日记占位页**

文件路径：`entry/src/main/ets/pages/diary/DiaryPagerPage.ets`

```typescript
@Component
export struct DiaryPagerPage {
  build() {
    Column() {
      Text('日记列表（Day 5-7 实现）')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}
```

- [ ] **Step 2: 创建日程占位页**

文件路径：`entry/src/main/ets/pages/schedule/SchedulePagerPage.ets`

```typescript
@Component
export struct SchedulePagerPage {
  build() {
    Column() {
      Text('日程列表（Day 11 实现）')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}
```

- [ ] **Step 3: 创建日子占位页**

文件路径：`entry/src/main/ets/pages/day/DayPagerPage.ets`

```typescript
@Component
export struct DayPagerPage {
  build() {
    Column() {
      Text('日子记录（Day 12 实现）')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}
```

- [ ] **Step 4: 创建日历占位页**

文件路径：`entry/src/main/ets/pages/calendar/CalendarPage.ets`

```typescript
@Component
export struct CalendarPage {
  build() {
    Column() {
      Text('日历视图（Day 10 实现）')
        .fontSize(16)
        .fontColor('#888888')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/pages/diary/DiaryPagerPage.ets \
        entry/src/main/ets/pages/schedule/SchedulePagerPage.ets \
        entry/src/main/ets/pages/day/DayPagerPage.ets \
        entry/src/main/ets/pages/calendar/CalendarPage.ets
git commit -m "feat: add placeholder pages for main tabs (diary/schedule/day/calendar)"
```

---

## Task 2：版本更新数据模型

**Files:**
- Create: `entry/src/main/ets/model/UpdateModels.ets`

对标 Android `UpdateInfoResponse` 数据类。

- [ ] **Step 1: 创建版本更新模型**

文件路径：`entry/src/main/ets/model/UpdateModels.ets`

```typescript
export interface UpdateInfoResponse {
  versionCode: number
  versionName: string
  apkUrl: string
  fullApkUrl: string
  releaseNotes: string
  requestBaseUrl: string
  serverUpgradeRequired: boolean
  serverUpgradeMessage: string
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/model/UpdateModels.ets
git commit -m "feat: add UpdateInfoResponse model"
```

---

## Task 3：MainViewModel（用户信息 + 成员状态 + 更新检查）

**Files:**
- Create: `entry/src/main/ets/viewmodel/MainViewModel.ets`
- Create: `entry/src/test/ets/viewmodel/MainViewModelTest.ets`

对标 Android `MainActivity.kt` 中 `fetchUserProfile()`、`startMembershipRefreshLoop()`、`fetchLatestUpdate()` 逻辑。

- [ ] **Step 1: 写失败测试**

文件路径：`entry/src/test/ets/viewmodel/MainViewModelTest.ets`

```typescript
import { describe, it, expect } from '@ohos/hypium'
import { MainViewModel } from '../../main/ets/viewmodel/MainViewModel'

export default function MainViewModelTest() {
  describe('MainViewModelTest', () => {
    it('initial state has empty username', 0, () => {
      const vm = new MainViewModel()
      expect(vm.username).assertEqual('')
    })

    it('initial membershipTier is normal', 0, () => {
      const vm = new MainViewModel()
      expect(vm.membershipTier).assertEqual('normal')
    })

    it('checkHasUpdate returns false when versionCode equals local', 0, () => {
      const vm = new MainViewModel()
      const result = vm.checkHasUpdate(100, 100)
      expect(result).assertFalse()
    })

    it('checkHasUpdate returns true when server versionCode is greater', 0, () => {
      const vm = new MainViewModel()
      const result = vm.checkHasUpdate(200, 100)
      expect(result).assertTrue()
    })

    it('isMember returns false for normal tier', 0, () => {
      const vm = new MainViewModel()
      vm.membershipTier = 'normal'
      expect(vm.isMember()).assertFalse()
    })

    it('isMember returns true for premium tier with future expiry', 0, () => {
      const vm = new MainViewModel()
      vm.membershipTier = 'premium'
      vm.membershipExpiresAt = Date.now() + 86400000
      expect(vm.isMember()).assertTrue()
    })

    it('isMember returns false for expired premium', 0, () => {
      const vm = new MainViewModel()
      vm.membershipTier = 'premium'
      vm.membershipExpiresAt = Date.now() - 86400000
      expect(vm.isMember()).assertFalse()
    })
  })
}
```

- [ ] **Step 2: 运行测试，确认失败**

在 DevEco Studio 中右键 `MainViewModelTest.ets` → Run，预期 FAIL（MainViewModel 未创建）。

- [ ] **Step 3: 实现 MainViewModel**

文件路径：`entry/src/main/ets/viewmodel/MainViewModel.ets`

```typescript
import http from '@ohos.net.http'
import { PreferencesHelper } from '../utils/PreferencesHelper'
import { Constants } from '../utils/Constants'
import { Logger } from '../utils/Logger'
import { UpdateInfoResponse } from '../model/UpdateModels'

export class MainViewModel {
  username: string = ''
  email: string = ''
  membershipTier: string = 'normal'
  membershipExpiresAt: number = 0
  avatarUri: string = ''
  updateInfo: UpdateInfoResponse | null = null

  /**
   * 从 Preferences 加载本地缓存的用户信息（登录时已保存）
   */
  async loadUserInfo(): Promise<void> {
    try {
      const prefs = await PreferencesHelper.getPreferences()
      this.username = await prefs.get('username', '') as string
      this.email = await prefs.get('email', '') as string
      this.membershipTier = await prefs.get('membership_tier', 'normal') as string
      this.membershipExpiresAt = await prefs.get('membership_expires_at', 0) as number
      this.avatarUri = await prefs.get('avatar_uri', '') as string
    } catch (err) {
      Logger.error('MainViewModel', 'loadUserInfo failed: ' + JSON.stringify(err))
    }
  }

  /**
   * 从服务端刷新用户档案，同步写入 Preferences
   * 对标 Android fetchUserProfile()
   */
  async refreshProfile(): Promise<void> {
    try {
      const prefs = await PreferencesHelper.getPreferences()
      const token = await prefs.get('token', '') as string
      if (!token) return

      const request = http.createHttp()
      const response = await request.request(
        `${Constants.BASE_URL}/api/user/profile`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      )
      request.destroy()

      if (response.responseCode !== 200) return

      const data = JSON.parse(response.result as string)
      if (!data.success || !data.data) return

      const profile = data.data
      const nickname: string = profile.nickname ?? profile.username ?? ''
      const emailVal: string = profile.email ?? ''
      const tier: string = profile.membership_tier ?? 'normal'
      const expiresAt: number = profile.membership_expires_at
        ? new Date(profile.membership_expires_at).getTime()
        : 0

      this.username = nickname
      this.email = emailVal
      this.membershipTier = tier
      this.membershipExpiresAt = expiresAt

      await prefs.put('username', nickname)
      await prefs.put('email', emailVal)
      await prefs.put('membership_tier', tier)
      await prefs.put('membership_expires_at', expiresAt)
      await prefs.flush()
    } catch (err) {
      Logger.error('MainViewModel', 'refreshProfile failed: ' + JSON.stringify(err))
    }
  }

  /**
   * 判断服务端版本是否大于本地版本
   * @param serverVersionCode 服务端版本号
   * @param localVersionCode 本地版本号
   */
  checkHasUpdate(serverVersionCode: number, localVersionCode: number): boolean {
    return serverVersionCode > localVersionCode
  }

  /**
   * 拉取最新版本信息
   * 对标 Android fetchLatestUpdate()
   */
  async fetchLatestUpdate(): Promise<UpdateInfoResponse | null> {
    try {
      const request = http.createHttp()
      const response = await request.request(
        `${Constants.BASE_URL}/api/version/latest`,
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      )
      request.destroy()

      if (response.responseCode !== 200) return null

      const data = JSON.parse(response.result as string) as UpdateInfoResponse
      this.updateInfo = data
      return data
    } catch (err) {
      Logger.error('MainViewModel', 'fetchLatestUpdate failed: ' + JSON.stringify(err))
      return null
    }
  }

  /**
   * 判断是否为有效会员
   * 对标 Android TokenManager.getEffectiveMembershipTier()
   */
  isMember(): boolean {
    if (this.membershipTier === 'normal') return false
    if (this.membershipExpiresAt <= 0) return true
    return Date.now() < this.membershipExpiresAt
  }

  /**
   * 退出登录：清除所有 Preferences 数据
   * 对标 Android TokenManager.clearToken()
   */
  async logout(): Promise<void> {
    try {
      const prefs = await PreferencesHelper.getPreferences()
      await prefs.clear()
      await prefs.flush()
      this.username = ''
      this.email = ''
      this.membershipTier = 'normal'
      this.membershipExpiresAt = 0
      this.avatarUri = ''
    } catch (err) {
      Logger.error('MainViewModel', 'logout failed: ' + JSON.stringify(err))
    }
  }
}
```

- [ ] **Step 4: 运行测试，确认通过**

在 DevEco Studio 中重新运行 `MainViewModelTest`，预期全部 PASS。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/MainViewModel.ets \
        entry/src/test/ets/viewmodel/MainViewModelTest.ets
git commit -m "feat: add MainViewModel with user profile, membership, and update check"
```

---

## Task 4：DrawerMenu 抽屉菜单组件

**Files:**
- Create: `entry/src/main/ets/components/DrawerMenu.ets`

对标 Android `MainActivity.kt` 中 `setupDrawer()` 以及 Navigation Menu 的 14 个菜单项，含抽屉头（头像、用户名、邮箱、背景图）和带动画的菜单列表。

- [ ] **Step 1: 创建 DrawerMenu 组件**

文件路径：`entry/src/main/ets/components/DrawerMenu.ets`

```typescript
export interface DrawerMenuItem {
  id: string
  title: string
  iconRes: Resource
}

@Component
export struct DrawerMenu {
  @Prop username: string = ''
  @Prop email: string = ''
  @Prop avatarUri: string = ''
  @Prop isDarkMode: boolean = false
  onItemClick: (itemId: string) => void = () => {}
  onAvatarClick: () => void = () => {}
  onEditBgClick: () => void = () => {}

  // 对标 Android nav_menu.xml 中的菜单项
  private get menuItems(): DrawerMenuItem[] {
    return [
      { id: 'favorites',     title: '收藏',      iconRes: $r('app.media.ic_favorite') },
      { id: 'vault',         title: '保险箱',     iconRes: $r('app.media.ic_vault') },
      { id: 'recycle_bin',   title: '回收站',     iconRes: $r('app.media.ic_delete') },
      { id: 'drafts',        title: '草稿箱',     iconRes: $r('app.media.ic_drafts') },
      { id: 'export_history',title: '导出历史',   iconRes: $r('app.media.ic_export') },
      { id: 'transfer_data', title: '数据迁移',   iconRes: $r('app.media.ic_transfer') },
      { id: 'membership',    title: '会员中心',   iconRes: $r('app.media.ic_membership') },
      { id: 'check_update',  title: '检查更新',   iconRes: $r('app.media.ic_update') },
      { id: 'theme_toggle',  title: this.isDarkMode ? '日间模式' : '夜间模式', iconRes: $r('app.media.ic_theme') },
      { id: 'settings',      title: '设置',       iconRes: $r('app.media.ic_settings') },
      { id: 'about',         title: '关于',       iconRes: $r('app.media.ic_about') },
      { id: 'love_zone',     title: '爱情区',     iconRes: $r('app.media.ic_favorite') },
      { id: 'special_thanks',title: '特别感谢',   iconRes: $r('app.media.ic_about') },
      { id: 'logout',        title: '退出登录',   iconRes: $r('app.media.ic_logout') },
    ]
  }

  build() {
    Column() {
      // ——— 抽屉头部（对标 drawer_header.xml）———
      Stack({ alignContent: Alignment.BottomStart }) {
        // 背景图
        Image($r('app.media.bg_default_world'))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)

        // 半透明遮罩（对标 viewHeaderOverlay）
        Column()
          .width('100%')
          .height(200)
          .backgroundColor('#66000000')

        // 用户信息区
        Column({ space: 6 }) {
          // 头像（可点击更换）
          Image(this.avatarUri ? this.avatarUri : $r('app.media.app_logo'))
            .width(64)
            .height(64)
            .borderRadius(32)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: '#FFFFFF' })
            .onClick(() => this.onAvatarClick())

          // 用户名
          Text(this.username || 'User Name')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 邮箱
          Text(this.email || 'user@example.com')
            .fontSize(12)
            .fontColor('#CCFFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .padding({ left: 16, bottom: 16 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 编辑背景按钮（对标 btnEditHeaderBg）
        Image($r('app.media.ic_edit'))
          .width(22)
          .height(22)
          .fillColor('#CCFFFFFF')
          .margin({ right: 12, bottom: 14 })
          .onClick(() => this.onEditBgClick())
          .position({ right: 0, bottom: 0 })
      }
      .width('100%')
      .height(200)

      // ——— 菜单列表（对标 NavigationView 菜单项）———
      Scroll() {
        Column() {
          ForEach(this.menuItems, (item: DrawerMenuItem) => {
            Column() {
              Row({ space: 16 }) {
                Image(item.iconRes)
                  .width(22)
                  .height(22)
                  .fillColor(this.isDarkMode ? '#CCCCCC' : '#555555')

                Text(item.title)
                  .fontSize(15)
                  .fontColor(
                    item.id === 'logout'
                      ? '#FF5722'
                      : (this.isDarkMode ? '#DDDDDD' : '#333333')
                  )
                  .layoutWeight(1)
              }
              .width('100%')
              .height(52)
              .padding({ left: 20, right: 20 })
              .onClick(() => this.onItemClick(item.id))

              Divider()
                .strokeWidth(0.5)
                .color(this.isDarkMode ? '#2A2A2A' : '#F0F0F0')
                .margin({ left: 58 })
            }
          })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#1A1A1A' : '#FFFFFF')
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/components/DrawerMenu.ets
git commit -m "feat: add DrawerMenu component with header (avatar/name/email/bg) and 14 menu items"
```

---

## Task 5：TopBar 顶部栏组件

**Files:**
- Create: `entry/src/main/ets/components/TopBar.ets`

对标 Android `setupTopBar()`，包含汉堡菜单按钮、头像按钮、搜索框（或日历年月文字）、星空按钮。

- [ ] **Step 1: 创建 TopBar 组件**

文件路径：`entry/src/main/ets/components/TopBar.ets`

```typescript
@Component
export struct TopBar {
  @Prop avatarUri: string = ''
  @Prop searchHint: string = '搜索日记...'
  @Prop showCalendarYearMonth: boolean = false
  @Prop calendarYearMonthText: string = ''
  @Link searchQuery: string
  onMenuClick: () => void = () => {}
  onAvatarClick: () => void = () => {}
  onStarfieldClick: () => void = () => {}
  onCalendarYearMonthClick: () => void = () => {}

  build() {
    Row({ space: 8 }) {
      // 汉堡菜单按钮（对标 btnMenu）
      Image($r('app.media.ic_menu'))
        .width(26)
        .height(26)
        .fillColor('#555555')
        .onClick(() => this.onMenuClick())

      // 头像（对标 ivAvatar）
      Image(this.avatarUri ? this.avatarUri : $r('app.media.app_logo'))
        .width(34)
        .height(34)
        .borderRadius(17)
        .objectFit(ImageFit.Cover)
        .onClick(() => this.onAvatarClick())

      if (this.showCalendarYearMonth) {
        // 日历 Tab 专属：年月文字按钮（对标 tvCalendarYearMonth）
        Text(this.calendarYearMonthText)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => this.onCalendarYearMonthClick())
      } else {
        // 搜索框（对标 etSearch）
        TextInput({ placeholder: this.searchHint, text: this.searchQuery })
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .height(36)
          .layoutWeight(1)
          .fontSize(14)
          .padding({ left: 14, right: 14 })
          .onChange((val: string) => {
            this.searchQuery = val
          })
      }

      // 星空按钮（对标 btnStarfield）
      Image($r('app.media.ic_starfield'))
        .width(26)
        .height(26)
        .fillColor('#555555')
        .onClick(() => this.onStarfieldClick())
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 2, color: '#0D000000', offsetX: 0, offsetY: 1 })
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/components/TopBar.ets
git commit -m "feat: add TopBar with hamburger/avatar/search/starfield"
```

---

## Task 6：BottomBar 底部操作栏组件

**Files:**
- Create: `entry/src/main/ets/components/BottomBar.ets`

对标 Android `setupBottomNav()`，包含 AI 聊天标签、新建大圆形按钮（日记/日程/日子语境感知）、我的按钮。日历 Tab 时新建替换为方向指示器（Day 10 完善）。

- [ ] **Step 1: 创建 BottomBar 组件**

文件路径：`entry/src/main/ets/components/BottomBar.ets`

```typescript
@Component
export struct BottomBar {
  @Prop currentTabIndex: number = 0
  // 对标 Android tvChatLabel，AI 名称可自定义
  @Prop chatLabel: string = 'AI 助手'
  onChatClick: () => void = () => {}
  onNewClick: () => void = () => {}
  onProfileClick: () => void = () => {}

  build() {
    Row() {
      // ——— AI 聊天按钮（对标 btnChat + tvChatLabel）———
      Column({ space: 3 }) {
        Image($r('app.media.ic_chat'))
          .width(26)
          .height(26)
          .fillColor('#666666')
        Text(this.chatLabel)
          .fontSize(10)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onChatClick())

      // ——— 中间按钮（新建 or 日历方向指示）———
      if (this.currentTabIndex === 3) {
        // 日历 Tab：简化版方向指示（对标 Android joystickNew，Day 10 完整实现）
        Column({ space: 3 }) {
          Image($r('app.media.ic_joystick'))
            .width(30)
            .height(30)
            .fillColor('#00BCD4')
          Text('导航')
            .fontSize(10)
            .fontColor('#00BCD4')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else {
        // 日记/日程/日子 Tab：新建大圆形按钮（对标 btnNew）
        Stack() {
          Circle({ width: 52, height: 52 })
            .fill('#00BCD4')
            .shadow({ radius: 8, color: '#4400BCD4', offsetX: 0, offsetY: 3 })
          Image($r('app.media.ic_add'))
            .width(28)
            .height(28)
            .fillColor('#FFFFFF')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onNewClick())
      }

      // ——— 我的按钮（对标 btnProfile）———
      Column({ space: 3 }) {
        Image($r('app.media.ic_profile'))
          .width(26)
          .height(26)
          .fillColor('#666666')
        Text('我的')
          .fontSize(10)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onProfileClick())
    }
    .width('100%')
    .height(60)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/components/BottomBar.ets
git commit -m "feat: add BottomBar with chat/new/profile actions and calendar joystick placeholder"
```

---

## Task 7：图标资源占位（确保编译通过）

**Files:**
- Add: `entry/src/main/resources/base/media/` 下各 `.svg` 文件

HarmonyOS 图标使用 SVG 格式。先创建最简 SVG 占位，正式设计图标可后期替换。

- [ ] **Step 1: 创建 Tab 图标**

`entry/src/main/resources/base/media/ic_tab_diary.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M4 4h16v16H4V4zm2 2v12h12V6H6zm2 3h8v1.5H8V9zm0 3h8v1.5H8V12zm0 3h5v1.5H8V15z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_tab_schedule.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M19 3h-1V1h-2v2H8V1H6v2H5C3.89 3 3 3.9 3 5v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zm0-13H5V5h14v1z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_tab_day.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67V7z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_tab_calendar.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M20 3h-1V1h-2v2H7V1H5v2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 18H4V8h16v13zm0-15H4V5h16v1z"/>
</svg>
```

- [ ] **Step 2: 创建界面功能图标**

`entry/src/main/resources/base/media/ic_menu.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_add.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_chat.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_profile.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_starfield.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_edit.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zm17.71-10.21a.996.996 0 000-1.41l-2.34-2.34a.996.996 0 00-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
</svg>
```

`entry/src/main/resources/base/media/ic_joystick.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v4h4v2h-4v4h-2v-4H7v-2h4V7z"/>
</svg>
```

- [ ] **Step 3: 批量创建抽屉菜单图标占位**

以下图标先以最简 SVG 占位（内容与 `ic_add.svg` 相同），后续 Day 13 替换正式图标：

创建文件列表（内容均使用下方通用占位 SVG）：
- `ic_favorite.svg`
- `ic_vault.svg`
- `ic_delete.svg`
- `ic_drafts.svg`
- `ic_export.svg`
- `ic_transfer.svg`
- `ic_membership.svg`
- `ic_update.svg`
- `ic_theme.svg`
- `ic_settings.svg`
- `ic_about.svg`
- `ic_logout.svg`

通用占位 SVG 内容（每个文件均用此内容）：
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2"/>
  <path d="M12 7v5l3 3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>
```

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/resources/base/media/
git commit -m "feat: add placeholder SVG icons for MainPage components"
```

---

## Task 8：主界面 MainPage（核心组装）

**Files:**
- Create: `entry/src/main/ets/pages/MainPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

这是 Day 4 的核心文件，组装所有组件，实现完整主界面逻辑。

- [ ] **Step 1: 创建 MainPage.ets**

文件路径：`entry/src/main/ets/pages/MainPage.ets`

```typescript
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
import { Logger } from '../utils/Logger'

interface TabConfig {
  id: string
  title: string
  icon: Resource
}

@Entry
@Component
struct MainPage {
  // ——— 状态变量 ———
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

  // Tab 配置（对标 Android setupViewPager() 中的 4 个 Fragment）
  private tabs: TabConfig[] = [
    { id: 'diary',    title: '日记', icon: $r('app.media.ic_tab_diary') },
    { id: 'schedule', title: '日程', icon: $r('app.media.ic_tab_schedule') },
    { id: 'day',      title: '日子', icon: $r('app.media.ic_tab_day') },
    { id: 'calendar', title: '日历', icon: $r('app.media.ic_tab_calendar') },
  ]

  async aboutToAppear() {
    // 加载本地用户信息
    await this.vm.loadUserInfo()
    this.username = this.vm.username
    this.email = this.vm.email
    this.avatarUri = this.vm.avatarUri
    this.membershipTier = this.vm.membershipTier
    this.refreshCalendarTitle()

    // 后台异步刷新（对标 fetchUserProfile + startMembershipRefreshLoop）
    this.vm.refreshProfile().then(() => {
      this.username = this.vm.username
      this.email = this.vm.email
      this.membershipTier = this.vm.membershipTier
    }).catch(() => {})

    // 检查服务端升级（对标 onCreate 中的 fetchLatestUpdate + serverUpgradeRequired）
    this.checkServerUpgrade()
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
            { text: '退出',     color: '#FF5722' }
          ]
        }).catch(() => {})
      }
    } catch (err) {
      Logger.error('MainPage', 'checkServerUpgrade error: ' + JSON.stringify(err))
    }
  }

  // 对标 Android applySearchHintAndRoute()
  private getSearchHint(): string {
    switch (this.currentTabIndex) {
      case 0: return '搜索日记...'
      case 1: return '搜索日程...'
      case 2: return '搜索日子...'
      default: return '搜索...'
    }
  }

  // 对标 Android navView.setNavigationItemSelectedListener
  private handleDrawerItemClick(itemId: string) {
    this.isDrawerOpen = false
    switch (itemId) {
      case 'favorites':
        router.pushUrl({ url: 'pages/diary/FavoritesPage' }).catch(() => {})
        break
      case 'vault':
        if (this.membershipTier === 'normal') {
          promptAction.showToast({ message: '此功能需要会员权限' })
        } else {
          router.pushUrl({ url: 'pages/VaultPage' }).catch(() => {})
        }
        break
      case 'recycle_bin':
        router.pushUrl({ url: 'pages/diary/RecycleBinPage' }).catch(() => {})
        break
      case 'drafts':
        router.pushUrl({ url: 'pages/diary/DraftsPage' }).catch(() => {})
        break
      case 'export_history':
        router.pushUrl({ url: 'pages/diary/ExportHistoryPage' }).catch(() => {})
        break
      case 'transfer_data':
        router.pushUrl({ url: 'pages/TransferDataPage' }).catch(() => {})
        break
      case 'membership':
        router.pushUrl({ url: 'pages/profile/MembershipPage' }).catch(() => {})
        break
      case 'check_update':
        this.vm.fetchLatestUpdate().then((info) => {
          if (info) {
            promptAction.showToast({
              message: `最新版本：${info.versionName}`
            })
          }
        }).catch(() => {})
        break
      case 'theme_toggle':
        this.isDarkMode = !this.isDarkMode
        break
      case 'settings':
        router.pushUrl({ url: 'pages/profile/SettingsPage' }).catch(() => {})
        break
      case 'about':
        router.pushUrl({ url: 'pages/profile/AboutPage' }).catch(() => {})
        break
      case 'love_zone':
        router.pushUrl({ url: 'pages/love/LoveZonePage' }).catch(() => {})
        break
      case 'special_thanks':
        router.pushUrl({ url: 'pages/profile/SpecialThanksPage' }).catch(() => {})
        break
      case 'logout':
        this.handleLogout()
        break
    }
  }

  private async handleLogout() {
    await this.vm.logout()
    // 对标 Android Intent.FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK
    router.clear()
    router.replaceUrl({ url: 'pages/LoginPage' }).catch(() => {})
  }

  // 对标 Android btnNew.setOnClickListener（语境感知：日记/日程/日子模式）
  private handleNewClick() {
    switch (this.currentTabIndex) {
      case 0:
        router.pushUrl({ url: 'pages/diary/DiaryEditPage' }).catch(() => {})
        break
      case 1:
        router.pushUrl({
          url: 'pages/diary/DiaryEditPage',
          params: { scheduleMode: true, scheduleDate: Date.now() }
        }).catch(() => {})
        break
      case 2:
        router.pushUrl({
          url: 'pages/diary/DiaryEditPage',
          params: { dayMode: true }
        }).catch(() => {})
        break
    }
  }

  build() {
    Stack() {
      // ————————————————————————————
      // 主体布局层
      // ————————————————————————————
      Column() {
        // 顶部工具栏（对标 toolbar + etSearch + ivAvatar + btnStarfield）
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
            router.pushUrl({ url: 'pages/profile/ProfilePage' }).catch(() => {})
          },
          onStarfieldClick: () => {
            router.pushUrl({ url: 'pages/StarfieldPage' }).catch(() => {})
          },
          onCalendarYearMonthClick: () => {
            // Day 10 实现完整年月选择器
            promptAction.showToast({ message: '年月选择器（Day 10 实现）' })
          }
        })

        // ——— 顶部 Tab 标签栏（对标 tabLayout）———
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
                .fontWeight(
                  this.currentTabIndex === index
                    ? FontWeight.Bold
                    : FontWeight.Normal
                )
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

        // ——— Tab 内容区（对标 viewPager，isUserInputEnabled=false）———
        Swiper() {
          DiaryPagerPage()
          SchedulePagerPage()
          DayPagerPage()
          CalendarPage()
        }
        .index(this.currentTabIndex)
        .disableSwipe(true)   // 对标 binding.viewPager.isUserInputEnabled = false
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
            router.pushUrl({ url: 'pages/chat/ChatPage' }).catch(() => {})
          },
          onNewClick: () => this.handleNewClick(),
          onProfileClick: () => {
            router.pushUrl({ url: 'pages/profile/ProfilePage' }).catch(() => {})
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.isDarkMode ? '#121212' : '#F5F5F5')

      // ————————————————————————————
      // 抽屉遮罩层（半透明黑色，点击关闭）
      // ————————————————————————————
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

      // ————————————————————————————
      // 左侧抽屉面板（对标 DrawerLayout + NavigationView）
      // 使用 Stack + offset + animation 模拟 DrawerLayout 侧滑效果
      // ————————————————————————————
      Row() {
        DrawerMenu({
          username: this.username,
          email: this.email,
          avatarUri: this.avatarUri,
          isDarkMode: this.isDarkMode,
          onItemClick: (id: string) => this.handleDrawerItemClick(id),
          onAvatarClick: () => {
            // Day 13 实现头像选择（文件选择器）
            promptAction.showToast({ message: '头像选择（Day 13 实现）' })
          },
          onEditBgClick: () => {
            // Day 13 实现背景图选择
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
    // 左边缘右滑手势打开抽屉（对标 Android dispatchTouchEvent 的边缘检测）
    .gesture(
      SwipeGesture({ direction: SwipeDirection.Horizontal, speed: 80 })
        .onAction((event: GestureEvent) => {
          // angle > 0 为向右滑（打开），< 0 为向左滑（关闭）
          if ((event as ESObject).angle > 0 && !this.isDrawerOpen) {
            this.isDrawerOpen = true
          } else if ((event as ESObject).angle < 0 && this.isDrawerOpen) {
            this.isDrawerOpen = false
          }
        })
    )
  }
}
```

- [ ] **Step 2: 注册所有路由到 main_pages.json**

读取 `entry/src/main/resources/base/profile/main_pages.json`，将新增页面加入 `src` 数组（已有的不重复添加）：

```json
{
  "src": [
    "pages/LoginPage",
    "pages/login/ForgotPasswordPage",
    "pages/MainPage",
    "pages/diary/DiaryPagerPage",
    "pages/schedule/SchedulePagerPage",
    "pages/day/DayPagerPage",
    "pages/calendar/CalendarPage"
  ]
}
```

- [ ] **Step 3: Build 验证**

在 DevEco Studio 中 Build → Build Hap，确认编译无错误。

常见错误处理：
- `Cannot find module '../components/DrawerMenu'`：确认文件路径和 `export struct` 名称拼写一致
- `Resource not found: app.media.ic_tab_diary`：确认 Task 7 中 SVG 已添加到 `resources/base/media/`
- `Property 'angle' does not exist on GestureEvent`：将 `event.angle` 改为 `(event as ESObject).angle`，HarmonyOS API 版本差异
- `Swiper.disableSwipe` 不存在：部分版本用 `disableSwipe(true)` 或 `loop(false)` + 不注册手势，查阅当前 DevEco SDK 版本文档

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/ets/pages/MainPage.ets \
        entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: implement MainPage with tabs, drawer, search bar, bottom bar"
```

---

## Task 9：LoginPage 跳转 MainPage（流程衔接）

**Files:**
- Modify: `entry/src/main/ets/pages/LoginPage.ets`

Day 2-3 的 LoginPage 登录成功回调中跳转 MainPage。

- [ ] **Step 1: 确认登录成功跳转目标**

读取 `entry/src/main/ets/pages/LoginPage.ets`，找到登录成功后的跳转代码，确保为：

```typescript
router.replaceUrl({ url: 'pages/MainPage' })
```

若原为占位字符串，将其替换为上述代码。

- [ ] **Step 2: 端到端手动验证流程**

在真机或模拟器上运行验证以下完整流程：

1. 启动 App → 显示 LoginPage（弹幕气泡动画运行中）
2. 输入正确账号/密码 → 点击登录按钮
3. 登录成功 → 无缝跳转到 MainPage
4. MainPage 显示 4 个 Tab（日记/日程/日子/日历）
5. 点击不同 Tab 标签 → 对应内容区切换
6. 点击汉堡菜单（左上角）→ 左侧抽屉滑入，显示头像、用户名、14 个菜单项
7. 点击遮罩或从右向左滑 → 抽屉关闭
8. 点击「退出登录」→ 清除本地数据，跳回 LoginPage
9. 点击底部「新建」按钮 → 路由跳转（页面不存在时 toast 提示正常）
10. 点击头像 → 路由跳转（同上）

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/pages/LoginPage.ets
git commit -m "feat: connect LoginPage to MainPage after successful login"
```

---

## Task 10：Day 4 收尾测试

**Files:**
- Modify: `entry/src/test/ets/viewmodel/MainViewModelTest.ets`

补充 `isMember` 和 `logout` 更多边界测试。

- [ ] **Step 1: 补充边界测试**

在 `entry/src/test/ets/viewmodel/MainViewModelTest.ets` 的 `describe` 块内追加：

```typescript
it('checkHasUpdate returns false when server version is less', 0, () => {
  const vm = new MainViewModel()
  const result = vm.checkHasUpdate(50, 100)
  expect(result).assertFalse()
})

it('isMember returns true for premium with 0 expiresAt (no expiry set)', 0, () => {
  const vm = new MainViewModel()
  vm.membershipTier = 'premium'
  vm.membershipExpiresAt = 0
  expect(vm.isMember()).assertTrue()
})

it('logout resets all state fields', 0, async (done: Function) => {
  const vm = new MainViewModel()
  vm.username = 'Alice'
  vm.email = 'alice@example.com'
  vm.membershipTier = 'premium'
  await vm.logout()
  expect(vm.username).assertEqual('')
  expect(vm.email).assertEqual('')
  expect(vm.membershipTier).assertEqual('normal')
  done()
})
```

- [ ] **Step 2: 运行全部测试**

预期所有 10 个测试用例全部 PASS。

- [ ] **Step 3: 提交**

```bash
git add entry/src/test/ets/viewmodel/MainViewModelTest.ets
git commit -m "test: add MainViewModel boundary tests for isMember and logout"
```

---

## Day 4 完成检查清单

- [ ] 4 个 Tab 子页面占位文件已创建
- [ ] `UpdateModels.ets` 定义 `UpdateInfoResponse` 接口
- [ ] `MainViewModel` 实现：`loadUserInfo` / `refreshProfile` / `checkHasUpdate` / `fetchLatestUpdate` / `isMember` / `logout`
- [ ] `DrawerMenu` 组件显示头像、用户名、邮箱、背景图、14 个菜单项
- [ ] `TopBar` 组件包含汉堡菜单、头像、搜索框（日历 Tab 时显示年月文字）、星空按钮
- [ ] `BottomBar` 组件包含聊天、新建圆形按钮（日历 Tab 时显示方向控制占位）、我的
- [ ] `MainPage` 正确组装所有组件，4 个 Tab 切换正常
- [ ] 左侧抽屉可通过汉堡按钮打开、点击遮罩关闭、左滑手势控制
- [ ] 退出登录清除本地数据并跳回 LoginPage
- [ ] 服务端升级通知对话框逻辑已实现
- [ ] 所有 SVG 图标资源已添加，编译无错误
- [ ] `main_pages.json` 已注册所有新页面路由
- [ ] 全部 10 个单元测试通过

---

## Day 4 → Day 5 衔接说明

Day 4 结束后的状态：
- `DiaryPagerPage` 为空壳 → **Day 5-7** 实现完整日记管理（列表、编辑、查看、收藏、回收站、草稿）
- `SchedulePagerPage` 为空壳 → **Day 11** 实现日程管理
- `DayPagerPage` 为空壳 → **Day 12** 实现日子记录
- `CalendarPage` 为空壳 → **Day 10** 实现日历视图
- `DrawerMenu` 中大部分菜单项路由目标页面尚未实现，点击时 router 报错可忽略（后续 Day 逐步实现）
