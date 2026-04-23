/**
 * 天气选择器
 * 对标 Android DiaryEditActivity 中的天气选择 UI
 */
@Component
export struct WeatherPicker {
  @Prop selected: string = 'sunny'
  onSelected: (weather: string) => void = () => {}

  private weathers: WeatherItem[] = [
    { id: 'sunny',  label: '晴' },
    { id: 'cloudy', label: '多云' },
    { id: 'rainy',  label: '雨' },
    { id: 'snowy',  label: '雪' },
    { id: 'windy',  label: '风' },
    { id: 'foggy',  label: '雾' },
  ]

  build() {
    Column({ space: 8 }) {
      Text('天气')
        .fontSize(13)
        .fontColor('#888888')

      Row({ space: 12 }) {
        ForEach(this.weathers, (w: WeatherItem) => {
          Column({ space: 4 }) {
            Stack() {
              Circle({ width: 40, height: 40 })
                .fill(this.selected === w.id ? '#E0F7FA' : '#F5F5F5')
              Circle({ width: 40, height: 40 })
                .stroke(this.selected === w.id ? '#00BCD4' : 'transparent')
                .strokeWidth(2)
              Text(this.getWeatherEmoji(w.id))
                .fontSize(20)
            }
            .onClick(() => {
              this.onSelected(w.id)
            })

            Text(w.label)
              .fontSize(10)
              .fontColor(this.selected === w.id ? '#00BCD4' : '#999999')
          }
        })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private getWeatherEmoji(id: string): string {
    const map: EmojiMap = {
      sunny: '☀️', cloudy: '⛅', rainy: '🌧️', snowy: '❄️', windy: '💨', foggy: '🌫️'
    }
    return map[id] ?? '☀️'
  }
}

interface WeatherItem {
  id: string
  label: string
}

interface EmojiMap {
  [key: string]: string
}