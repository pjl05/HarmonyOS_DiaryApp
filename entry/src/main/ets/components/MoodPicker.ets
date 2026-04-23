/**
 * 心情选择器
 * 对标 Android DiaryEditActivity 中的心情选择 UI
 */
@Component
export struct MoodPicker {
  @Prop selected: string = 'neutral'
  onSelected: (mood: string) => void = () => {}

  private moods = [
    { id: 'happy',   label: '开心' },
    { id: 'neutral', label: '平静' },
    { id: 'sad',     label: '难过' },
    { id: 'angry',   label: '生气' },
    { id: 'worried', label: '担心' },
    { id: 'excited', label: '兴奋' },
  ]

  build() {
    Column({ space: 8 }) {
      Text('心情')
        .fontSize(13)
        .fontColor('#888888')

      Row({ space: 12 }) {
        ForEach(this.moods, (m: { id: string; label: string }) => {
          Column({ space: 4 }) {
            Stack() {
              Circle({ width: 40, height: 40 })
                .fill(this.selected === m.id ? '#FFF3E0' : '#F5F5F5')
              Circle({ width: 40, height: 40 })
                .stroke(this.selected === m.id ? '#FF9800' : 'transparent')
                .strokeWidth(2)
              Text(this.getMoodEmoji(m.id))
                .fontSize(20)
            }
            .onClick(() => {
              this.onSelected(m.id)
            })

            Text(m.label)
              .fontSize(10)
              .fontColor(this.selected === m.id ? '#FF9800' : '#999999')
          }
        })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private getMoodEmoji(id: string): string {
    const map: Record<string, string> = {
      happy: '😊', neutral: '😐', sad: '😢', angry: '😠', worried: '😰', excited: '🤩'
    }
    return map[id] ?? '😐'
  }
}
