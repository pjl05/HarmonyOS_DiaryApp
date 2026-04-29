/**
 * CalendarWeekdayHeader - 星期标题栏
 * 替换 Android: weekday_header.xml
 */
@Component
export struct CalendarWeekdayHeader {
  @Prop zoomScale: number = 1.0;

  private weekdays: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  build() {
    Row() {
      ForEach(this.weekdays, (day: string, index: number) => {
        Text(day)
          .fontSize(12)
          .fontColor(index === 0 ? '#FFE53935' : index === 6 ? '#FF4A90D9' : '#FF999999')
          .fontWeight(index === 0 || index === 6 ? FontWeight.Medium : FontWeight.Normal)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      })
    }
    .width('100%')
    .height(32)
    .padding({ left: 8, right: 8 })
    .scale({ x: this.zoomScale, y: 1 })
  }
}