/**
 * 日记卡片组件（列表项）
 * 对标 Android DiaryTimelineAdapter / DiaryGridAdapter 的列表项
 */
import { Diary } from '../model/DiaryModel'

/**
 * DiaryWrapper — 包装 Diary 供 @ObjectLink 使用
 * HarmonyOS @ObjectLink 要求 @Observed class
 */
@Observed
export class DiaryWrapper {
  diary: Diary

  constructor(diary: Diary) {
    this.diary = diary
  }
}

@Component
export struct DiaryCard {
  @ObjectLink diaryWrapper: DiaryWrapper

  onCardClick: () => void = () => {}
  onFavoriteClick: () => void = () => {}
  onCardLongPress: () => void = () => {}

  private formatDate(millis: number): string {
    const d = new Date(millis)
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${d.getFullYear()}-${month}-${day}`
  }

  private getPreviewText(): string {
    const content = this.diaryWrapper.diary.content
    const plain = content.replace(/<[^>]*>/g, '').trim()
    return plain.length > 80 ? plain.substring(0, 80) + '...' : plain
  }

  private getWeatherLabel(): string {
    const w = this.diaryWrapper.diary.weather
    if (w === 'sunny') return '☀️'
    if (w === 'cloudy') return '⛅'
    if (w === 'rainy') return '🌧️'
    if (w === 'snowy') return '❄️'
    if (w === 'windy') return '💨'
    if (w === 'foggy') return '🌫️'
    return '☀️'
  }

  private getMoodLabel(): string {
    const m = this.diaryWrapper.diary.mood
    if (m === 'happy') return '😊'
    if (m === 'neutral') return '😐'
    if (m === 'sad') return '😢'
    if (m === 'angry') return '😠'
    if (m === 'worried') return '😰'
    if (m === 'excited') return '🤩'
    return '😐'
  }

  build() {
    Column() {
      Row() {
        Text(this.formatDate(this.diaryWrapper.diary.date))
          .fontSize(12)
          .fontColor('#999999')
        Blank()
        Text(this.getWeatherLabel())
          .fontSize(11)
          .fontColor('#888888')
        Text(' ')
          .fontSize(11)
        Text(this.getMoodLabel())
          .fontSize(11)
          .fontColor('#888888')
      }
      .width('100%')

      Text(this.diaryWrapper.diary.title || '(无标题)')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')

      if (this.getPreviewText()) {
        Text(this.getPreviewText())
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
      }

      Row() {
        Blank()
        Text(this.diaryWrapper.diary.isFavorite ? '♥' : '♡')
          .fontSize(18)
          .fontColor(this.diaryWrapper.diary.isFavorite ? '#FF5722' : '#BBBBBB')
          .onClick(() => this.onFavoriteClick())
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 6, color: '#15000000', offsetX: 0, offsetY: 2 })
    .onClick(() => this.onCardClick())
    .gesture(LongPressGesture().onAction((): void => { this.onCardLongPress() }))
  }
}