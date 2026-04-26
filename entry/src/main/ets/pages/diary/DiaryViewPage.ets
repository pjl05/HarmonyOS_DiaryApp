/**
 * 日记查看页面
 * 对标 Android DiaryViewActivity
 * 显示日记完整内容，支持编辑/删除/收藏操作菜单
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { Diary } from '../../model/DiaryModel'
import { getLogger } from '../../utils/Logger'

const logger = getLogger('DiaryViewPage')

interface Button {
  text: string
  color: string
}

@Entry
@Component
struct DiaryViewPage {
  @State diary: Diary | null = null
  @State isLoading: boolean = true

  private diaryId: number = 0
  private repo: DiaryRepository | null = null

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>
    this.diaryId = (params?.diaryId as number) ?? 0

    if (this.diaryId <= 0) {
      promptAction.showToast({ message: '日记不存在' })
      router.back()
      return
    }

    this.repo = new DiaryRepository(getContext(this))
    this.diary = await this.repo.findById(this.diaryId)
    this.isLoading = false

    if (!this.diary) {
      promptAction.showToast({ message: '日记不存在' })
      router.back()
    }
  }

  private formatFullDate(millis: number): string {
    const d = new Date(millis)
    const weekday = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][d.getDay()]
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 ${weekday}`
  }

  private showOptionsMenu(): void {
    const diary = this.diary
    if (!diary) return

    promptAction.showActionMenu({
      buttons: [
        { text: '编辑', color: '#2196F3' },
        { text: diary.isFavorite ? '取消收藏' : '收藏', color: '#FF9800' },
        { text: '移至回收站', color: '#F44336' },
        { text: '取消', color: '#999999' }
      ] as [Button, Button?, Button?, Button?]
    }).then(async (result): Promise<void> => {
      if (!this.repo || !this.diary) return
      switch (result.index) {
        case 0:
          router.pushUrl({
            url: 'pages/diary/DiaryEditPage',
            params: { diaryId: this.diaryId }
          }).catch((): void => {})
          break
        case 1:
          await this.repo.toggleFavorite(this.diary)
          this.diary = await this.repo.findById(this.diaryId)
          break
        case 2:
          await this.repo.moveToTrash(this.diary)
          promptAction.showToast({ message: '已移至回收站' })
          router.back()
          break
      }
    }).catch((): void => {})
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick((): void => { router.back() })
        Blank()
        Text('⋮')
          .fontSize(22)
          .fontColor('#333333')
          .onClick((): void => { this.showOptionsMenu() })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.diary) {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 8 }) {
              Text(this.formatFullDate(this.diary.date))
                .fontSize(14)
                .fontColor('#888888')

              if (this.diary.title) {
                Text(this.diary.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
              }

              Row({ space: 12 }) {
                Text(`${this.getWeatherEmoji(this.diary.weather)} ${this.getWeatherLabel(this.diary.weather)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                Text(`${this.getMoodEmoji(this.diary.mood)} ${this.getMoodLabel(this.diary.mood)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                if (this.diary.location) {
                  Text(`📍 ${this.diary.location}`)
                    .fontSize(12)
                    .fontColor('#666666')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#F0F0F0')
                    .borderRadius(12)
                }
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ top: 20, left: 16, right: 16 })

            Divider().strokeWidth(0.5).color('#EEEEEE').margin({ left: 16, right: 16 })

            Text(this.diary.content)
              .fontSize(16)
              .fontColor('#333333')
              .lineHeight(26)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 20 })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private getWeatherEmoji(w: string): string {
    if (w === 'sunny') return '☀️'
    if (w === 'cloudy') return '⛅'
    if (w === 'rainy') return '🌧️'
    if (w === 'snowy') return '❄️'
    if (w === 'windy') return '💨'
    if (w === 'foggy') return '🌫️'
    return '☀️'
  }

  private getWeatherLabel(w: string): string {
    if (w === 'sunny') return '晴'
    if (w === 'cloudy') return '多云'
    if (w === 'rainy') return '雨'
    if (w === 'snowy') return '雪'
    if (w === 'windy') return '风'
    if (w === 'foggy') return '雾'
    return '晴'
  }

  private getMoodEmoji(m: string): string {
    if (m === 'happy') return '😊'
    if (m === 'neutral') return '😐'
    if (m === 'sad') return '😢'
    if (m === 'angry') return '😠'
    if (m === 'worried') return '😰'
    if (m === 'excited') return '🤩'
    return '😐'
  }

  private getMoodLabel(m: string): string {
    if (m === 'happy') return '开心'
    if (m === 'neutral') return '平静'
    if (m === 'sad') return '难过'
    if (m === 'angry') return '生气'
    if (m === 'worried') return '担心'
    if (m === 'excited') return '兴奋'
    return '平静'
  }
}