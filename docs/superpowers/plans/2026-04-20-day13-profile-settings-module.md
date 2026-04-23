# 个人中心 + 设置模块 HarmonyOS 迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Android DiaryApp 的 ProfileActivity（个人中心）与 SettingsActivity（设置页）完整迁移至 HarmonyOS ArkTS，实现头像/昵称/签名编辑、数据统计概览、主题切换、AI 设置、金库密码+生物识别、日程通知开关、修改密码/邮箱、注销账户等全部功能。

**Architecture:** 两个独立 Page（ProfilePage + SettingsPage），各自有对应 ViewModel；Preferences（@ohos.data.preferences）替代 SharedPreferences；userAuth 替代 BiometricPrompt；promptAction.showDialog 替代 AlertDialog；图片选择使用 picker.PhotoViewPicker；HTTP 调用复用已有 ApiService。

**Tech Stack:** ArkTS / ArkUI、@ohos.data.preferences、@ohos.userIAM.userAuth、picker.PhotoViewPicker、promptAction、router、http（已有 ApiService）

---

## 文件结构

```
entry/src/main/ets/
├── util/
│   ├── PreferencesHelper.ets              # Preferences 封装（替代 SharedPreferences）
│   └── AvatarHelper.ets                   # 头像本地复制/读取
├── viewmodel/
│   ├── ProfileViewModel.ets               # 个人中心 ViewModel
│   └── SettingsViewModel.ets              # 设置页 ViewModel
└── pages/
    ├── ProfilePage.ets                     # 个人中心（对标 ProfileActivity.kt）
    └── SettingsPage.ets                    # 设置页（对标 SettingsActivity.kt）
```

---

## Task 1: PreferencesHelper.ets — Preferences 封装

**Files:**
- Create: `entry/src/main/ets/util/PreferencesHelper.ets`

对标 Android `SettingsManager`（SharedPreferences）；封装 `@ohos.data.preferences`，提供异步读写接口。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/PreferencesHelperTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { PreferencesHelper } from '../../main/ets/util/PreferencesHelper'

describe('PreferencesHelperTest', () => {
  let helper: PreferencesHelper

  beforeAll(async (done) => {
    helper = new PreferencesHelper('TestPrefs', globalThis.context)
    await helper.init()
    done()
  })

  it('should_set_and_get_string', async (done) => {
    await helper.setString('nickname', '测试用户')
    const val = await helper.getString('nickname', '')
    expect(val).assertEqual('测试用户')
    done()
  })

  it('should_set_and_get_boolean', async (done) => {
    await helper.setBoolean('scheduleNotify', true)
    const val = await helper.getBoolean('scheduleNotify', false)
    expect(val).assertTrue()
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: PreferencesHelper not found
```

- [ ] **Step 3: 实现 PreferencesHelper**

```typescript
// entry/src/main/ets/util/PreferencesHelper.ets
import dataPreferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'

export class PreferencesHelper {
  private name: string
  private context: common.UIAbilityContext
  private prefs: dataPreferences.Preferences | null = null

  constructor(name: string, context: common.UIAbilityContext) {
    this.name = name
    this.context = context
  }

  async init(): Promise<void> {
    this.prefs = await dataPreferences.getPreferences(this.context, this.name)
  }

  async getString(key: string, defaultVal: string): Promise<string> {
    if (!this.prefs) return defaultVal
    return (await this.prefs.get(key, defaultVal)) as string
  }

  async setString(key: string, value: string): Promise<void> {
    if (!this.prefs) return
    await this.prefs.put(key, value)
    await this.prefs.flush()
  }

  async getBoolean(key: string, defaultVal: boolean): Promise<boolean> {
    if (!this.prefs) return defaultVal
    return (await this.prefs.get(key, defaultVal)) as boolean
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    if (!this.prefs) return
    await this.prefs.put(key, value)
    await this.prefs.flush()
  }

  async getNumber(key: string, defaultVal: number): Promise<number> {
    if (!this.prefs) return defaultVal
    return (await this.prefs.get(key, defaultVal)) as number
  }

  async setNumber(key: string, value: number): Promise<void> {
    if (!this.prefs) return
    await this.prefs.put(key, value)
    await this.prefs.flush()
  }

  async remove(key: string): Promise<void> {
    if (!this.prefs) return
    await this.prefs.delete(key)
    await this.prefs.flush()
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: PreferencesHelperTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/util/PreferencesHelper.ets entry/src/test/PreferencesHelperTest.ets
git commit -m "feat(profile): add PreferencesHelper wrapping @ohos.data.preferences"
```

---

## Task 2: AvatarHelper.ets — 头像本地存储工具

**Files:**
- Create: `entry/src/main/ets/util/AvatarHelper.ets`

对标 Android `ProfileActivity.saveAvatarUri` / `loadAvatars`；将用户选中的图片复制到应用内部存储，避免 URI 失效。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/AvatarHelperTest.ets
import { describe, it, expect } from '@ohos/hypium'
import { AvatarHelper } from '../../main/ets/util/AvatarHelper'

describe('AvatarHelperTest', () => {
  it('should_return_path_containing_avatar', (done) => {
    const path = AvatarHelper.getAvatarPath('user', globalThis.context)
    expect(path.includes('avatar')).assertTrue()
    done()
  })

  it('should_return_false_when_no_file', (done) => {
    const exists = AvatarHelper.exists('nonexistent_user', globalThis.context)
    expect(exists).assertFalse()
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: AvatarHelper not found
```

- [ ] **Step 3: 实现 AvatarHelper**

```typescript
// entry/src/main/ets/util/AvatarHelper.ets
import common from '@ohos.app.ability.common'
import fs from '@ohos.file.fs'

export class AvatarHelper {
  /**
   * 返回头像文件的本地路径（不一定存在）。
   * 路径格式：<filesDir>/avatars/<role>_avatar.jpg
   */
  static getAvatarPath(role: string, context: common.UIAbilityContext): string {
    const dir = `${context.filesDir}/avatars`
    return `${dir}/${role}_avatar.jpg`
  }

  /**
   * 将 srcUri（picker 返回的 file:// 路径）复制到内部存储的头像路径。
   * 返回内部存储路径，或 null（失败）。
   */
  static async copyToInternal(
    srcUri: string,
    role: string,
    context: common.UIAbilityContext
  ): Promise<string | null> {
    try {
      const dir = `${context.filesDir}/avatars`
      try { fs.mkdirSync(dir) } catch (_) {}
      const destPath = `${dir}/${role}_avatar.jpg`
      try { fs.unlinkSync(destPath) } catch (_) {}
      await fs.copyFile(srcUri, destPath)
      return destPath
    } catch (e) {
      console.error('AvatarHelper.copyToInternal failed:', JSON.stringify(e))
      return null
    }
  }

  /**
   * 检查头像文件是否存在。
   */
  static exists(role: string, context: common.UIAbilityContext): boolean {
    const path = AvatarHelper.getAvatarPath(role, context)
    try {
      return fs.accessSync(path)
    } catch {
      return false
    }
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: AvatarHelperTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/util/AvatarHelper.ets entry/src/test/AvatarHelperTest.ets
git commit -m "feat(profile): add AvatarHelper for local avatar file management"
```

---

## Task 3: ProfileViewModel.ets — 个人中心 ViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/ProfileViewModel.ets`

持有昵称/签名/头像状态，调用 HTTP API 加载和保存；统计 diary/schedule/day 数量。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/ProfileViewModelTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { ProfileViewModel } from '../../main/ets/viewmodel/ProfileViewModel'

describe('ProfileViewModelTest', () => {
  let vm: ProfileViewModel

  beforeAll((done) => {
    vm = new ProfileViewModel()
    done()
  })

  it('should_have_default_empty_state', (done) => {
    expect(vm.nickname).assertEqual('')
    expect(vm.signature).assertEqual('')
    expect(vm.isDirty).assertFalse()
    done()
  })

  it('should_mark_dirty_when_nickname_changes', (done) => {
    vm.updateNickname('新昵称')
    expect(vm.isDirty).assertTrue()
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: ProfileViewModel not found
```

- [ ] **Step 3: 实现 ProfileViewModel**

```typescript
// entry/src/main/ets/viewmodel/ProfileViewModel.ets
import http from '@ohos.net.http'

export interface ProfileStats {
  diaryCount: number
  scheduleCount: number
  dayCount: number
  totalWords: number
  streakDays: number
}

export class ProfileViewModel {
  nickname: string = ''
  signature: string = ''
  avatarPath: string = ''
  isLoading: boolean = false
  error: string = ''
  stats: ProfileStats = {
    diaryCount: 0, scheduleCount: 0, dayCount: 0, totalWords: 0, streakDays: 0
  }

  private _initialNickname: string = ''
  private _initialSignature: string = ''

  get isDirty(): boolean {
    return this.nickname !== this._initialNickname ||
      this.signature !== this._initialSignature
  }

  updateNickname(value: string): void {
    this.nickname = value
  }

  updateSignature(value: string): void {
    this.signature = value
  }

  setInitialValues(nickname: string, signature: string): void {
    this._initialNickname = nickname
    this._initialSignature = signature
    this.nickname = nickname
    this.signature = signature
  }

  async loadProfile(token: string, baseUrl: string): Promise<void> {
    this.isLoading = true
    try {
      const req = http.createHttp()
      const resp = await req.request(`${baseUrl}/api/user/profile`, {
        method: http.RequestMethod.GET,
        header: { Authorization: `Bearer ${token}` }
      })
      req.destroy()
      if (resp.responseCode === 200) {
        const data = JSON.parse(resp.result as string) as {
          nickname?: string; signature?: string
        }
        const nick = data.nickname ?? ''
        const sign = data.signature ?? ''
        this.setInitialValues(nick, sign)
      }
    } catch (e) {
      this.error = e?.message ?? '加载失败'
    } finally {
      this.isLoading = false
    }
  }

  async saveProfile(token: string, baseUrl: string): Promise<boolean> {
    this.isLoading = true
    try {
      const req = http.createHttp()
      const resp = await req.request(`${baseUrl}/api/user/profile`, {
        method: http.RequestMethod.PUT,
        header: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({ nickname: this.nickname, signature: this.signature })
      })
      req.destroy()
      if (resp.responseCode === 200) {
        this.setInitialValues(this.nickname, this.signature)
        return true
      }
      return false
    } catch (e) {
      this.error = e?.message ?? '保存失败'
      return false
    } finally {
      this.isLoading = false
    }
  }

  updateStats(
    diaryCount: number, scheduleCount: number, dayCount: number,
    totalWords: number, streakDays: number
  ): void {
    this.stats = { diaryCount, scheduleCount, dayCount, totalWords, streakDays }
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: ProfileViewModelTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/ProfileViewModel.ets entry/src/test/ProfileViewModelTest.ets
git commit -m "feat(profile): add ProfileViewModel"
```

---

## Task 4: SettingsViewModel.ets — 设置页 ViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/SettingsViewModel.ets`

持有所有设置项状态（AI 配置、通知开关、金库密码、语言等），加载和保存均通过 PreferencesHelper。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/SettingsViewModelTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { SettingsViewModel } from '../../main/ets/viewmodel/SettingsViewModel'
import { PreferencesHelper } from '../../main/ets/util/PreferencesHelper'

describe('SettingsViewModelTest', () => {
  let vm: SettingsViewModel

  beforeAll(async (done) => {
    const prefs = new PreferencesHelper('SettingsVMTest', globalThis.context)
    await prefs.init()
    vm = new SettingsViewModel(prefs)
    await vm.load()
    done()
  })

  it('should_have_default_notification_disabled', (done) => {
    expect(vm.scheduleNotifyEnabled).assertFalse()
    done()
  })

  it('should_persist_notification_toggle', async (done) => {
    await vm.setScheduleNotifyEnabled(true)
    expect(vm.scheduleNotifyEnabled).assertTrue()
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: SettingsViewModel not found
```

- [ ] **Step 3: 实现 SettingsViewModel**

```typescript
// entry/src/main/ets/viewmodel/SettingsViewModel.ets
import { PreferencesHelper } from '../util/PreferencesHelper'

export class SettingsViewModel {
  private prefs: PreferencesHelper

  // AI 设置
  aiName: string = 'AI Companion'
  aiPrompt: string = ''
  aiConfigMode: string = 'default'   // 'default' | 'custom'
  appId: string = ''
  apiKey: string = ''
  apiSecret: string = ''
  modelId: string = ''

  // 通知设置
  scheduleNotifyEnabled: boolean = false
  scheduleNotifyLeadMinutes: number = 5

  // 位置 & 天气
  locationEnabled: boolean = false
  weatherAutoEnabled: boolean = false

  // 金库
  hasVaultPassword: boolean = false
  vaultBiometricEnabled: boolean = false

  // 语言
  language: string = 'zh'

  constructor(prefs: PreferencesHelper) {
    this.prefs = prefs
  }

  async load(): Promise<void> {
    this.aiName = await this.prefs.getString('aiName', 'AI Companion')
    this.aiPrompt = await this.prefs.getString('aiPrompt', '')
    this.aiConfigMode = await this.prefs.getString('aiConfigMode', 'default')
    this.appId = await this.prefs.getString('appId', '')
    this.apiKey = await this.prefs.getString('apiKey', '')
    this.apiSecret = await this.prefs.getString('apiSecret', '')
    this.modelId = await this.prefs.getString('modelId', '')
    this.scheduleNotifyEnabled = await this.prefs.getBoolean('scheduleNotify', false)
    this.scheduleNotifyLeadMinutes = await this.prefs.getNumber('scheduleNotifyLead', 5)
    this.locationEnabled = await this.prefs.getBoolean('locationEnabled', false)
    this.weatherAutoEnabled = await this.prefs.getBoolean('weatherAuto', false)
    this.hasVaultPassword = await this.prefs.getBoolean('hasVaultPassword', false)
    this.vaultBiometricEnabled = await this.prefs.getBoolean('vaultBiometric', false)
    this.language = await this.prefs.getString('language', 'zh')
  }

  async saveAiSettings(): Promise<void> {
    await this.prefs.setString('aiName', this.aiName)
    await this.prefs.setString('aiPrompt', this.aiPrompt)
    await this.prefs.setString('aiConfigMode', this.aiConfigMode)
    await this.prefs.setString('appId', this.appId)
    await this.prefs.setString('apiKey', this.apiKey)
    await this.prefs.setString('apiSecret', this.apiSecret)
    await this.prefs.setString('modelId', this.modelId)
  }

  async setScheduleNotifyEnabled(value: boolean): Promise<void> {
    this.scheduleNotifyEnabled = value
    await this.prefs.setBoolean('scheduleNotify', value)
  }

  async setScheduleNotifyLead(minutes: number): Promise<void> {
    this.scheduleNotifyLeadMinutes = minutes
    await this.prefs.setNumber('scheduleNotifyLead', minutes)
  }

  async setLocationEnabled(value: boolean): Promise<void> {
    this.locationEnabled = value
    await this.prefs.setBoolean('locationEnabled', value)
    if (!value) {
      this.weatherAutoEnabled = false
      await this.prefs.setBoolean('weatherAuto', false)
    }
  }

  async setWeatherAutoEnabled(value: boolean): Promise<void> {
    if (!this.locationEnabled) return
    this.weatherAutoEnabled = value
    await this.prefs.setBoolean('weatherAuto', value)
  }

  async setVaultPassword(hashedPwd: string): Promise<void> {
    await this.prefs.setString('vaultPasswordHash', hashedPwd)
    this.hasVaultPassword = true
    await this.prefs.setBoolean('hasVaultPassword', true)
  }

  async verifyVaultPassword(candidate: string): Promise<boolean> {
    const stored = await this.prefs.getString('vaultPasswordHash', '')
    return stored === this.simpleHash(candidate)
  }

  async clearVaultBiometric(): Promise<void> {
    this.vaultBiometricEnabled = false
    await this.prefs.setBoolean('vaultBiometric', false)
  }

  async setVaultBiometricEnabled(value: boolean): Promise<void> {
    this.vaultBiometricEnabled = value
    await this.prefs.setBoolean('vaultBiometric', value)
  }

  async setLanguage(lang: string): Promise<void> {
    this.language = lang
    await this.prefs.setString('language', lang)
  }

  // 公开给外部调用（用于密码哈希）
  simpleHash(input: string): string {
    let hash = 0
    for (let i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.charCodeAt(i)
      hash |= 0
    }
    return hash.toString(16)
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: SettingsViewModelTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/SettingsViewModel.ets entry/src/test/SettingsViewModelTest.ets
git commit -m "feat(settings): add SettingsViewModel with preferences persistence"
```

---

## Task 5: ProfilePage.ets — 个人中心页

**Files:**
- Create: `entry/src/main/ets/pages/ProfilePage.ets`

对标 Android `ProfileActivity.kt`；展示头像、昵称、签名（可编辑）、数据统计概览、快捷导航（设置、会员、收藏夹）、主题切换。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/ProfilePage.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import picker from '@ohos.file.picker'
import { ProfileViewModel } from '../viewmodel/ProfileViewModel'
import { AvatarHelper } from '../util/AvatarHelper'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct ProfilePage {
  @State private vm: ProfileViewModel = new ProfileViewModel()
  @State private avatarPath: string = ''
  @State private isDarkMode: boolean = false

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  private token: string = AppStorage.get('authToken') ?? ''
  private baseUrl: string = AppStorage.get('baseUrl') ?? ''

  aboutToAppear() {
    this.vm.loadProfile(this.token, this.baseUrl)
    this.loadAvatar()
    this.isDarkMode = AppStorage.get('isDarkMode') ?? false
  }

  private loadAvatar() {
    if (AvatarHelper.exists('user', this.context)) {
      this.avatarPath = AvatarHelper.getAvatarPath('user', this.context)
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.ic_back'))
          .width(24).height(24)
          .onClick(() => router.back())
        Text('个人中心')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Image($r('app.media.ic_support'))
          .width(24).height(24)
          .onClick(() => router.pushUrl({ url: 'pages/SupportChatPage' }))
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          this.buildProfileHeader()
          this.buildStatsSection()
          this.buildQuickActions()

          Button('退出登录')
            .width('90%').height(48)
            .backgroundColor('#F44336').fontColor(Color.White)
            .borderRadius(24).margin({ top: 24, bottom: 32 })
            .onClick(() => this.confirmLogout())
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  buildProfileHeader() {
    Column() {
      Stack() {
        if (this.avatarPath !== '') {
          Image(this.avatarPath).width(80).height(80)
            .borderRadius(40).objectFit(ImageFit.Cover)
        } else {
          Image($r('app.media.app_logo')).width(80).height(80).borderRadius(40)
        }
        Image($r('app.media.ic_edit'))
          .width(24).height(24).backgroundColor('#2C3E50')
          .borderRadius(12).padding(4).offset({ x: 28, y: 28 })
      }
      .onClick(() => this.pickAvatar()).margin({ top: 24, bottom: 12 })

      TextInput({ text: this.vm.nickname, placeholder: '输入昵称' })
        .width('80%').textAlign(TextAlign.Center)
        .fontSize(18).fontWeight(FontWeight.Bold)
        .backgroundColor(Color.Transparent).borderRadius(0)
        .onChange((val) => this.vm.updateNickname(val))

      TextInput({ text: this.vm.signature, placeholder: '输入个性签名' })
        .width('80%').textAlign(TextAlign.Center)
        .fontSize(13).fontColor('#9E9E9E')
        .backgroundColor(Color.Transparent).borderRadius(0)
        .onChange((val) => this.vm.updateSignature(val))

      if (this.vm.isDirty) {
        Button('保存')
          .width(120).height(36)
          .backgroundColor('#4CAF50').fontColor(Color.White)
          .borderRadius(18).margin({ top: 12 })
          .onClick(() => this.saveProfile())
      }
    }
    .width('100%').padding({ bottom: 16 })
    .backgroundColor(Color.White).margin({ bottom: 12 })
  }

  @Builder
  buildStatsSection() {
    Column() {
      Text('数据统计').fontSize(15).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 16, top: 12, bottom: 8 })

      Row() {
        this.statItem('日记', this.vm.stats.diaryCount.toString())
        Divider().vertical(true).height(40).color('#E0E0E0')
        this.statItem('日程', this.vm.stats.scheduleCount.toString())
        Divider().vertical(true).height(40).color('#E0E0E0')
        this.statItem('日子', this.vm.stats.dayCount.toString())
      }
      .width('100%').justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 8, bottom: 16 })
    }
    .width('90%').backgroundColor(Color.White)
    .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ bottom: 12 })
  }

  @Builder
  statItem(label: string, value: string) {
    Column() {
      Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#2C3E50')
      Text(label).fontSize(12).fontColor('#9E9E9E').margin({ top: 4 })
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildQuickActions() {
    Column() {
      Text('功能').fontSize(15).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 16, top: 12, bottom: 8 })

      this.actionRow('AI 设置', $r('app.media.ic_ai'),
        () => router.pushUrl({ url: 'pages/SettingsPage', params: { scrollTo: 'ai' } }))
      Divider().color('#F5F5F5').padding({ left: 16 })

      this.actionRow('会员', $r('app.media.ic_membership'),
        () => router.pushUrl({ url: 'pages/MembershipPage' }))
      Divider().color('#F5F5F5').padding({ left: 16 })

      this.actionRow('收藏夹', $r('app.media.ic_favorite'),
        () => router.pushUrl({ url: 'pages/FavoritesPage' }))
      Divider().color('#F5F5F5').padding({ left: 16 })

      this.actionRow('设置', $r('app.media.ic_settings'),
        () => router.pushUrl({ url: 'pages/SettingsPage' }))
      Divider().color('#F5F5F5').padding({ left: 16 })

      Row() {
        Image($r('app.media.ic_theme')).width(24).height(24).fillColor('#9E9E9E')
        Text(this.isDarkMode ? '切换白天模式' : '切换夜间模式')
          .fontSize(15).layoutWeight(1).margin({ left: 12 })
        Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode })
          .onChange((val) => {
            this.isDarkMode = val
            AppStorage.setOrCreate('isDarkMode', val)
          })
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
    }
    .width('90%').backgroundColor(Color.White)
    .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ bottom: 12 })
  }

  @Builder
  actionRow(label: string, icon: Resource, onClick: () => void) {
    Row() {
      Image(icon).width(24).height(24).fillColor('#9E9E9E')
      Text(label).fontSize(15).layoutWeight(1).margin({ left: 12 })
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
    }
    .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(onClick)
  }

  private async pickAvatar() {
    const photoPicker = new picker.PhotoViewPicker()
    const result = await photoPicker.select({
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
    })
    if (result.photoUris.length === 0) return
    const destPath = await AvatarHelper.copyToInternal(result.photoUris[0], 'user', this.context)
    if (destPath) this.avatarPath = destPath
  }

  private async saveProfile() {
    const ok = await this.vm.saveProfile(this.token, this.baseUrl)
    promptAction.showToast({ message: ok ? '保存成功' : '保存失败，请重试' })
  }

  private confirmLogout() {
    promptAction.showDialog({
      title: '退出登录',
      message: '确定要退出当前账号？',
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '退出', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        AppStorage.setOrCreate('authToken', '')
        AppStorage.setOrCreate('userId', '')
        router.replaceUrl({ url: 'pages/LoginPage' })
      }
    })
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/pages/ProfilePage.ets
git commit -m "feat(profile): add ProfilePage with avatar, stats, quick actions"
```

---

## Task 6: SettingsPage.ets — 设置页

**Files:**
- Create: `entry/src/main/ets/pages/SettingsPage.ets`

对标 Android `SettingsActivity.kt`；包含 AI 设置、日程提醒、位置与天气、金库安全、账号、语言六大区块。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/SettingsPage.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import picker from '@ohos.file.picker'
import { SettingsViewModel } from '../viewmodel/SettingsViewModel'
import { PreferencesHelper } from '../util/PreferencesHelper'
import { AvatarHelper } from '../util/AvatarHelper'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct SettingsPage {
  @State private vm: SettingsViewModel = new SettingsViewModel(
    new PreferencesHelper('DiaryAppSettings', getContext(this) as common.UIAbilityContext)
  )
  @State private aiAvatarPath: string = ''

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  aboutToAppear() {
    const prefs = new PreferencesHelper('DiaryAppSettings', this.context)
    prefs.init().then(async () => {
      this.vm = new SettingsViewModel(prefs)
      await this.vm.load()
    })
    if (AvatarHelper.exists('ai', this.context)) {
      this.aiAvatarPath = AvatarHelper.getAvatarPath('ai', this.context)
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('设置').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          this.buildSection('AI 设置', () => { this.buildAiSection() })
          this.buildSection('日程提醒', () => { this.buildNotifySection() })
          this.buildSection('位置与天气', () => { this.buildLocationSection() })
          this.buildSection('金库安全', () => { this.buildVaultSection() })
          this.buildSection('账号', () => { this.buildAccountSection() })
          this.buildSection('语言', () => { this.buildLanguageSection() })
        }
        .width('100%').padding({ bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  buildSection(title: string, content: () => void) {
    Column() {
      Text(title).fontSize(13).fontColor('#9E9E9E')
        .width('100%').padding({ left: 16, top: 16, bottom: 6 })
      Column() { content() }
        .width('90%').backgroundColor(Color.White)
        .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
        .margin({ bottom: 8 })
    }
    .width('100%')
  }

  // ===== AI 设置区块 =====
  @Builder
  buildAiSection() {
    Row() {
      Text('AI 头像').fontSize(15).layoutWeight(1)
      Stack() {
        if (this.aiAvatarPath !== '') {
          Image(this.aiAvatarPath).width(40).height(40)
            .borderRadius(20).objectFit(ImageFit.Cover)
        } else {
          Image($r('app.media.app_logo')).width(40).height(40).borderRadius(20)
        }
      }
      .onClick(() => this.pickAiAvatar())
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('AI 名称').fontSize(15).layoutWeight(1)
      TextInput({ text: this.vm.aiName, placeholder: 'AI Companion' })
        .width(160).textAlign(TextAlign.End)
        .backgroundColor(Color.Transparent)
        .onChange((val) => { this.vm.aiName = val })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('配置模式').fontSize(15).layoutWeight(1)
      Select([{ value: '默认配置' }, { value: '自定义' }])
        .selected(this.vm.aiConfigMode === 'default' ? 0 : 1)
        .onSelect((idx) => {
          this.vm.aiConfigMode = idx === 0 ? 'default' : 'custom'
        })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })

    if (this.vm.aiConfigMode === 'custom') {
      Divider().color('#F5F5F5').margin({ left: 16 })
      this.inputRow('App ID', this.vm.appId, (v) => { this.vm.appId = v })
      this.inputRow('API Key', this.vm.apiKey, (v) => { this.vm.apiKey = v })
      this.inputRow('API Secret', this.vm.apiSecret, (v) => { this.vm.apiSecret = v })
      this.inputRow('Model ID', this.vm.modelId, (v) => { this.vm.modelId = v })
    }

    Divider().color('#F5F5F5').margin({ left: 16 })
    Button('保存 AI 设置')
      .width('90%').height(40).margin({ top: 12, bottom: 12 })
      .backgroundColor('#2C3E50').fontColor(Color.White).borderRadius(20)
      .onClick(() => {
        this.vm.saveAiSettings()
        promptAction.showToast({ message: 'AI 设置已保存' })
      })
  }

  @Builder
  inputRow(label: string, value: string, onChange: (v: string) => void) {
    Row() {
      Text(label).fontSize(15).width(80)
      TextInput({ text: value, placeholder: label })
        .layoutWeight(1).backgroundColor(Color.Transparent)
        .onChange(onChange)
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    Divider().color('#F5F5F5').margin({ left: 16 })
  }

  // ===== 提醒区块 =====
  @Builder
  buildNotifySection() {
    Row() {
      Text('日程提醒').fontSize(15).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.vm.scheduleNotifyEnabled })
        .onChange((val) => { this.vm.setScheduleNotifyEnabled(val) })
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('提前提醒').fontSize(15).layoutWeight(1)
      Select([
        { value: '即时' }, { value: '5分钟前' }, { value: '15分钟前' },
        { value: '30分钟前' }, { value: '1小时前' }
      ])
        .selected([0, 5, 15, 30, 60].indexOf(this.vm.scheduleNotifyLeadMinutes))
        .onSelect((idx) => {
          const vals = [0, 5, 15, 30, 60]
          this.vm.setScheduleNotifyLead(vals[idx])
        })
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  // ===== 位置 & 天气区块 =====
  @Builder
  buildLocationSection() {
    Row() {
      Text('允许位置').fontSize(15).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.vm.locationEnabled })
        .onChange((val) => { this.vm.setLocationEnabled(val) })
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('天气自动填充').fontSize(15).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.vm.weatherAutoEnabled })
        .enabled(this.vm.locationEnabled)
        .onChange((val) => { this.vm.setWeatherAutoEnabled(val) })
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
  }

  // ===== 金库安全区块 =====
  @Builder
  buildVaultSection() {
    Row() {
      Column() {
        Text('金库密码').fontSize(15)
        Text(this.vm.hasVaultPassword ? '已设置' : '未设置')
          .fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showVaultPasswordDialog())
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Column() {
        Text('生物识别解锁').fontSize(15)
        Text(this.vm.vaultBiometricEnabled ? '已启用' : '未启用')
          .fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showVaultBiometricDialog())
  }

  // ===== 账号区块 =====
  @Builder
  buildAccountSection() {
    Row() {
      Text('修改密码').fontSize(15).layoutWeight(1)
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showChangePasswordDialog())
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('修改邮箱').fontSize(15).layoutWeight(1)
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showChangeEmailDialog())
    Divider().color('#F5F5F5').margin({ left: 16 })

    Row() {
      Text('注销账号').fontSize(15).fontColor('#F44336').layoutWeight(1)
      Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#F44336')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showDeleteAccountDialog())
  }

  // ===== 语言区块 =====
  @Builder
  buildLanguageSection() {
    Row() {
      Text('当前语言').fontSize(15).layoutWeight(1)
      Text(this.vm.language === 'zh' ? '中文' : 'English')
        .fontSize(14).fontColor('#9E9E9E')
      Image($r('app.media.ic_chevron_right'))
        .width(16).height(16).fillColor('#BDBDBD').margin({ left: 4 })
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => this.showLanguageDialog())
  }

  // ===== 操作方法 =====

  private async pickAiAvatar() {
    const photoPicker = new picker.PhotoViewPicker()
    const result = await photoPicker.select({
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
    })
    if (result.photoUris.length === 0) return
    const destPath = await AvatarHelper.copyToInternal(result.photoUris[0], 'ai', this.context)
    if (destPath) this.aiAvatarPath = destPath
  }

  private showVaultPasswordDialog() {
    if (!this.vm.hasVaultPassword) {
      promptAction.showTextInputDialog({
        title: '设置金库密码',
        placeholder: '请输入新密码（至少6位）',
        buttons: [
          { text: '取消', color: '#757575' },
          { text: '确认', color: '#2C3E50' }
        ]
      }).then(async (result) => {
        if (result.index === 1 && result.text && result.text.length >= 6) {
          const hashed = this.vm.simpleHash(result.text)
          await this.vm.setVaultPassword(hashed)
          promptAction.showToast({ message: '金库密码已设置' })
        }
      })
    } else {
      promptAction.showToast({ message: '金库密码已设置。如需修改请先验证旧密码。' })
    }
  }

  private async showVaultBiometricDialog() {
    if (!this.vm.hasVaultPassword) {
      promptAction.showToast({ message: '请先设置金库密码' })
      return
    }
    try {
      const userAuth = await import('@ohos.userIAM.userAuth')
      const auth = userAuth.default.getAuthInstance({
        challenge: new Uint8Array(16),
        authType: [userAuth.default.UserAuthType.FINGERPRINT],
        authTrustLevel: userAuth.default.AuthTrustLevel.ATL1
      })
      auth.on('result', {
        callback: async (result: { result: number }) => {
          if (result.result === userAuth.default.ResultCode.SUCCESS) {
            await this.vm.setVaultBiometricEnabled(true)
            promptAction.showToast({ message: '生物识别已启用' })
          }
        }
      })
      auth.start()
    } catch (e) {
      promptAction.showToast({ message: '设备不支持生物识别' })
    }
  }

  private showChangePasswordDialog() {
    promptAction.showDialog({
      title: '修改密码',
      message: '将通过邮箱验证码修改密码。请确保邮箱可用。',
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '继续', color: '#2C3E50' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        router.pushUrl({ url: 'pages/ChangePasswordPage' })
      }
    })
  }

  private showChangeEmailDialog() {
    promptAction.showDialog({
      title: '修改邮箱',
      message: '将通过验证码验证当前邮箱后修改。',
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '继续', color: '#2C3E50' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        router.pushUrl({ url: 'pages/ChangeEmailPage' })
      }
    })
  }

  private showDeleteAccountDialog() {
    promptAction.showDialog({
      title: '注销账号',
      message: '注销后所有数据将被永久删除，且不可恢复。是否继续？',
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '注销', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        router.pushUrl({ url: 'pages/DeleteAccountPage' })
      }
    })
  }

  private showLanguageDialog() {
    promptAction.showDialog({
      title: '选择语言',
      buttons: [
        { text: '中文', color: '#2C3E50' },
        { text: 'English', color: '#2C3E50' }
      ]
    }).then(async (result) => {
      const lang = result.index === 0 ? 'zh' : 'en'
      await this.vm.setLanguage(lang)
      promptAction.showToast({ message: '语言已切换，重启应用生效' })
    })
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/pages/SettingsPage.ets
git commit -m "feat(settings): add SettingsPage with AI/notify/location/vault/account/language"
```

---

## Task 7: 路由注册

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 1: 注册页面路由**

在 `main_pages.json` 的 `src` 数组中追加：

```json
"pages/ProfilePage",
"pages/SettingsPage"
```

完整示例：

```json
{
  "src": [
    "pages/Index",
    "pages/MainPage",
    "pages/LoginPage",
    "pages/DayPage",
    "pages/DayPagerPage",
    "pages/SchedulePage",
    "pages/ProfilePage",
    "pages/SettingsPage"
  ]
}
```

- [ ] **Step 2: 在 EntryAbility 初始化 PreferencesHelper 并存入 AppStorage**

```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
// 在 onCreate 中追加（与 dayRdb 初始化同级）：
import { PreferencesHelper } from '../util/PreferencesHelper'

const settingsPrefs = new PreferencesHelper('DiaryAppSettings', this.context)
settingsPrefs.init().then(() => {
  AppStorage.setOrCreate('settingsPrefs', settingsPrefs)
})
```

- [ ] **Step 3: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 4: 安装到真机/模拟器，手动验证**

```
验证清单：
□ ProfilePage 可从主页跳转，显示头像（默认图）、昵称、签名
□ 点击头像区域弹出图库选择器，选图后头像更新
□ 修改昵称或签名后，"保存"按钮出现；点击保存后显示"保存成功"
□ 数据统计区域显示日记/日程/日子数量（可为 0）
□ 点击"设置"跳转 SettingsPage
□ SettingsPage 中 AI 设置区各字段可编辑，"保存 AI 设置"点击后 Toast
□ 日程提醒开关可切换，切换后重新进入页面状态保持
□ 金库密码未设置时点击"金库密码"显示设置密码对话框
□ 语言切换弹出对话框，选择后 Toast 提示重启生效
□ 点击"修改密码"跳转到修改密码页（后续迭代实现）
□ 点击"注销账号"弹出二次确认对话框
□ 主题切换 Toggle 可正常切换白天/夜间模式
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/resources/base/profile/main_pages.json \
        entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "feat(profile): register ProfilePage and SettingsPage routes, init settingsPrefs"
```

---

## 自审检查

### Spec 覆盖
| Android 功能 | HarmonyOS 对应 | 任务 |
|---|---|---|
| SharedPreferences (SettingsManager) | PreferencesHelper | Task 1 |
| Glide 头像加载 + saveAvatarUri | AvatarHelper + fs.copyFile | Task 2 |
| ProfileActivity 数据/状态 | ProfileViewModel | Task 3 |
| SettingsActivity 设置状态 | SettingsViewModel | Task 4 |
| ProfileActivity 头像/昵称/签名/统计/主题/快捷导航 | ProfilePage | Task 5 |
| SettingsActivity AI/通知/位置/金库/账号/语言 | SettingsPage | Task 6 |
| AndroidManifest Activity 注册 | main_pages.json + EntryAbility | Task 7 |
| BiometricPrompt 生物识别 | @ohos.userIAM.userAuth | Task 6 (showVaultBiometricDialog) |
| AlertDialog | promptAction.showDialog / showTextInputDialog | Task 5/6 |
| ViewPager2（ProfileAnalysisPagerAdapter）| 简化为 Swiper（后续增量迭代可加图表）| 未包含（单独迭代）|

### 范围说明
ProfileActivity 中的 `ProfileAnalysisPagerAdapter`（SimplePieChartView / SimpleBarChartView / SimpleLineChartView）图表组件因需自定义 Canvas 绘制，工作量独立且不影响核心功能，未纳入本 Day 13 计划。建议在 Day 15 收尾阶段增量实现，或在核心功能验收后单独迭代。

### 类型一致性
- `PreferencesHelper.getString/setString` — Task 1 定义，Task 4 使用 ✓
- `AvatarHelper.getAvatarPath/copyToInternal/exists` — Task 2 定义，Task 5/6 使用 ✓
- `ProfileViewModel.isDirty` — Task 3 定义，Task 5 渲染保存按钮 ✓
- `SettingsViewModel.setScheduleNotifyEnabled` — Task 4 定义，Task 6 Toggle onChange 调用 ✓
- `SettingsViewModel.load()` — Task 4 定义，Task 6 aboutToAppear 调用 ✓
