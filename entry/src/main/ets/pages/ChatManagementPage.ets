/**
 * ChatManagementPage - 路由页面入口
 * 替换 Android: ChatManagementActivity
 */
import { preferences } from '@kit.ArkData'
import router from '@ohos.router'

const PREF_NAME = 'chat_settings'
const KEY_AI_NAME = 'ai_name'
const KEY_ROLE_SETTING = 'role_setting'
const KEY_CHAT_HISTORY_LIMIT = 'chat_history_limit'
const KEY_AI_DIARY_READ_LIMIT = 'ai_diary_read_limit'

@Entry
@Component
export struct ChatManagementPage {
  @State aiName: string = 'AI Companion'
  @State roleSetting: string = ''
  @State chatHistoryLimit: number = 24
  @State aiDiaryReadLimit: number = 10

  private prefs: preferences.Preferences | null = null

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this)
    this.prefs = await preferences.getPreferences(ctx, { name: PREF_NAME })
    await this.loadSettings()
  }

  async loadSettings(): Promise<void> {
    if (!this.prefs) return
    this.aiName = await this.prefs.get(KEY_AI_NAME, 'AI Companion') as string
    this.roleSetting = await this.prefs.get(KEY_ROLE_SETTING, '') as string
    this.chatHistoryLimit = await this.prefs.get(KEY_CHAT_HISTORY_LIMIT, 24) as number
    this.aiDiaryReadLimit = await this.prefs.get(KEY_AI_DIARY_READ_LIMIT, 10) as number
  }

  async saveSettings(): Promise<void> {
    if (!this.prefs) return
    await this.prefs.put(KEY_AI_NAME, this.aiName)
    await this.prefs.put(KEY_ROLE_SETTING, this.roleSetting)
    await this.prefs.put(KEY_CHAT_HISTORY_LIMIT, this.chatHistoryLimit)
    await this.prefs.put(KEY_AI_DIARY_READ_LIMIT, this.aiDiaryReadLimit)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          this.buildAINameSection()
          this.buildRoleSection()
          this.buildHistoryLimitSection()
          this.buildDiaryReadLimitSection()
        }
        .width('100%')
        .padding(16)
      }
    }
    .title('AI 设置')
    .onBackPressed(() => {
      this.saveSettings()
      router.back()
      return true
    })
  }

  @Builder
  buildAINameSection() {
    Column() {
      Text('AI 名称')
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        Row() {
          Text('名称').fontSize(15).fontColor('#FF333333')
          Blank()
          TextInput({ text: this.aiName })
            .fontSize(14)
            .textAlign(TextAlign.End)
            .width(200)
            .onChange((val: string) => { this.aiName = val })
        }
        .width('100%')
        .height(48)
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }

  @Builder
  buildRoleSection() {
    Column() {
      Text('系统提示词')
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        Text('提示词').fontSize(15).fontColor('#FF333333').width('100%').margin({ bottom: 8 })
        TextArea({ text: this.roleSetting })
          .fontSize(14)
          .height(100)
          .width('100%')
          .onChange((val: string) => { this.roleSetting = val })
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }

  @Builder
  buildHistoryLimitSection() {
    Column() {
      Text('历史记录限制')
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        Row() {
          Text('读取最近 N 条消息').fontSize(15).fontColor('#FF333333')
          Blank()
          Text(`${this.chatHistoryLimit}`).fontSize(14).fontColor('#FF4A90D9')
        }
        .width('100%')

        Slider({
          value: this.chatHistoryLimit,
          min: 0,
          max: 50,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .onChange((val: number) => { this.chatHistoryLimit = Math.round(val) })
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }

  @Builder
  buildDiaryReadLimitSection() {
    Column() {
      Text('日记读取限制')
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        Row() {
          Text('读取最近 N 篇日记').fontSize(15).fontColor('#FF333333')
          Blank()
          Text(`${this.aiDiaryReadLimit}`).fontSize(14).fontColor('#FF4A90D9')
        }
        .width('100%')

        Slider({
          value: this.aiDiaryReadLimit,
          min: 1,
          max: 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .onChange((val: number) => { this.aiDiaryReadLimit = Math.round(val) })
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }
}