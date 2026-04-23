/**
 * 日历视图页面（占位）
 * Day 10 实现完整日历功能
 */

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