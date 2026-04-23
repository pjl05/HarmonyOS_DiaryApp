/**
 * 日记编辑页面
 * 对标 Android DiaryEditActivity
 * 包含标题编辑、内容、天气心情选择、日期选择、图片添加、自动草稿保存
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryEditViewModel } from '../../viewmodel/DiaryEditViewModel'
import { WeatherPicker } from '../../components/WeatherPicker'
import { MoodPicker } from '../../components/MoodPicker'
import { Logger } from '../../utils/Logger'

@Entry
@Component
struct DiaryEditPage {
  @State title: string = ''
  @State content: string = ''
  @State mood: string = 'neutral'
  @State weather: string = 'sunny'
  @State dateText: string = ''
  @State images: string[] = []
  @State isDirty: boolean = false

  private vm: DiaryEditViewModel | null = null
  private autoSaveTimer: number = -1

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    const diaryId = (params?.diaryId as number) ?? 0
    const draftId = (params?.draftId as number) ?? 0

    this.vm = new DiaryEditViewModel(getContext(this), diaryId)

    if (diaryId > 0) {
      this.vm.loadDiary(diaryId).then((): void => {
        this.title = this.vm!.diary.title
        this.content = this.vm!.diary.content
        this.mood = this.vm!.diary.mood
        this.weather = this.vm!.diary.weather
        this.dateText = this.formatDate(this.vm!.diary.date)
      })
    } else if (draftId > 0) {
      this.vm.loadFromDraft(draftId).then((): void => {
        this.title = this.vm!.diary.title
        this.content = this.vm!.diary.content
        this.mood = this.vm!.diary.mood
        this.weather = this.vm!.diary.weather
        this.dateText = this.formatDate(this.vm!.diary.date)
      })
    } else {
      this.dateText = this.formatDate(Date.now())
    }

    this.autoSaveTimer = setInterval((): void => {
      if (this.isDirty) {
        this.vm?.saveDraft()
      }
    }, 30000) as number
  }

  aboutToDisappear(): void {
    if (this.autoSaveTimer >= 0) {
      clearInterval(this.autoSaveTimer)
    }
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  private async handlePublish(): Promise<void> {
    this.vm?.updateTitle(this.title)
    this.vm?.updateContent(this.content)
    this.vm?.updateMood(this.mood)
    this.vm?.updateWeather(this.weather)

    if (this.vm) {
      const success = await this.vm.publish()
      if (success) {
        promptAction.showToast({ message: '保存成功' })
        router.back()
      } else {
        promptAction.showToast({ message: '标题或内容不能全为空' })
      }
    }
  }

  build() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#666666')
          .onClick((): void => { router.pop() })

        Blank()

        Text('发布')
          .fontSize(16)
          .fontColor('#00BCD4')
          .fontWeight(FontWeight.Bold)
          .onClick((): void => { this.handlePublish() })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 8 }) {
            Text('📅')
              .fontSize(16)
            Text(this.dateText)
              .fontSize(15)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ top: 12 })

          TextInput({ placeholder: '标题（选填）', text: this.title })
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .placeholderColor('#BBBBBB')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .height(44)
            .padding({ left: 12, right: 12 })
            .onChange((val: string): void => {
              this.title = val
              this.isDirty = true
            })

          TextArea({ placeholder: '写下今天的故事...', text: this.content })
            .fontSize(15)
            .placeholderColor('#BBBBBB')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .height(240)
            .padding(12)
            .onChange((val: string): void => {
              this.content = val
              this.isDirty = true
            })

          if (this.images.length > 0) {
            Grid() {
              ForEach(this.images, (uri: string) => {
                GridItem() {
                  Image(uri)
                    .width('100%')
                    .height(100)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
            .height(Math.ceil(this.images.length / 3) * 108)
          }

          Row() {
            Text('🖼️')
              .fontSize(16)
            Text('添加图片')
              .fontSize(14)
              .fontColor('#00BCD4')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(44)
          .padding({ left: 12 })
          .backgroundColor('#F5F9FA')
          .borderRadius(8)
          .onClick((): void => {
            promptAction.showToast({ message: '图片选择（Day 6 完善）' })
          })

          WeatherPicker({
            selected: this.weather,
            onSelected: (w: string): void => {
              this.weather = w
              this.isDirty = true
            }
          })

          MoodPicker({
            selected: this.mood,
            onSelected: (m: string): void => {
              this.mood = m
              this.isDirty = true
            }
          })
        }
        .padding({ left: 16, right: 16, bottom: 40 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
