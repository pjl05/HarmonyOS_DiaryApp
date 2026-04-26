/**
 * ChatManagementPage - AI 设置页面
 * 替换 Android: ChatManagementActivity
 */
import { preferences } from '@kit.ArkData'
import { router } from '@kit.RouterKit'

const PREF_NAME = 'chat_settings'
const KEY_AI_NAME = 'ai_name'
const KEY_ROLE_SETTING = 'role_setting'
const KEY_CHAT_HISTORY_LIMIT = 'chat_history_limit'
const KEY_AI_DIARY_READ_LIMIT = 'ai_diary_read_limit'

@Component
export struct ChatManagementPage {
  @State aiName: string = 'AI Companion'
  @State roleSetting: string = ''
  @State chatHistoryLimit: number = 24
  @State aiDiaryReadLimit: number = 10

  private prefs: preferences.Preferences | null = null

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this)
    this.prefs = preferences.getPreferences(ctx, { name: PREF_NAME })
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
          this.buildSection('AI 名称', [
            this.buildInputRow('名称', this.aiName, (val) => { this.aiName = val })
          ])

          this.buildSection('系统提示词', [
            this.buildTextAreaRow('提示词', this.roleSetting, (val) => { this.roleSetting = val })
          ])

          this.buildSection('历史记录限制', [
            this.buildSliderRow('读取最近 N 条消息', this.chatHistoryLimit, (val) => { this.chatHistoryLimit = val }, 0, 50)
          ])

          this.buildSection('日记读取限制', [
            this.buildSliderRow('读取最近 N 篇日记', this.aiDiaryReadLimit, (val) => { this.aiDiaryReadLimit = val }, 1, 100)
          ])
        }
        .width('100%')
        .padding(16)
      }
    }
    .title('AI 设置')
    .titleMode(NavDestinationTitleMode.Medium)
    .onBackPressed(() => {
      this.saveSettings()
      router.pop()
      return true
    })
  }

  @Builder
  buildSection(title: string, items: ESObject[]): Column {
    return Column() {
      Text(title)
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        items.forEach((item: ESObject) => item())
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }

  @Builder
  buildInputRow(label: string, value: string, onChange: (v: string) => void): Row {
    return Row() {
      Text(label).fontSize(15).fontColor('#FF333333')
      Blank()
      TextInput({ text: value })
        .fontSize(14)
        .textAlign(TextAlign.End)
        .width(200)
        .onChange((v) => onChange(v))
    }
    .width('100%')
    .height(48)
  }

  @Builder
  buildTextAreaRow(label: string, value: string, onChange: (v: string) => void): Column {
    return Column() {
      Text(label).fontSize(15).fontColor('#FF333333').width('100%').margin({ bottom: 8 })
      TextArea({ text: value })
        .fontSize(14)
        .height(100)
        .width('100%')
        .onChange((v) => onChange(v))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildSliderRow(label: string, currentValue: number, onChange: (v: number) => void, min: number, max: number): Column {
    return Column() {
      Row() {
        Text(label).fontSize(15).fontColor('#FF333333')
        Blank()
        Text(`${currentValue}`).fontSize(14).fontColor('#FF4A90D9')
      }
      .width('100%')

      Slider({
        value: currentValue,
        min: min,
        max: max,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .onChange((val) => onChange(Math.round(val)))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}