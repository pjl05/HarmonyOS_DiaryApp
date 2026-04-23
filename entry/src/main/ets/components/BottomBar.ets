/**
 * 底部操作栏组件
 * 对标 Android MainActivity 中的 setupBottomNav()
 * 包含 AI 聊天标签、新建大圆形按钮、我的按钮
 */

@Component
export struct BottomBar {
  @Prop currentTabIndex: number = 0
  @Prop chatLabel: string = 'AI 助手'
  onChatClick: () => void = () => {}
  onNewClick: () => void = () => {}
  onProfileClick: () => void = () => {}

  build() {
    Row() {
      // AI 聊天按钮（对标 btnChat + tvChatLabel）
      Column({ space: 3 }) {
        Image($r('app.media.ic_chat'))
          .width(26)
          .height(26)
          .fillColor('#666666')
        Text(this.chatLabel)
          .fontSize(10)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onChatClick())

      // 中间按钮（新建 or 日历方向指示）
      if (this.currentTabIndex === 3) {
        // 日历 Tab：简化版方向指示（对标 Android joystickNew，Day 10 完整实现）
        Column({ space: 3 }) {
          Image($r('app.media.ic_joystick'))
            .width(30)
            .height(30)
            .fillColor('#00BCD4')
          Text('导航')
            .fontSize(10)
            .fontColor('#00BCD4')
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
      } else {
        // 日记/日程/日子 Tab：新建大圆形按钮（对标 btnNew）
        Column() {
          Stack() {
            Circle({ width: 52, height: 52 })
              .fill('#00BCD4')
              .shadow({
                radius: 8,
                color: '#4400BCD4',
                offsetX: 0,
                offsetY: 3
              })
            Image($r('app.media.ic_add'))
              .width(28)
              .height(28)
              .fillColor('#FFFFFF')
          }
        }
        .layoutWeight(1)
        .height(60)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onNewClick())
      }

      // 我的按钮（对标 btnProfile）
      Column({ space: 3 }) {
        Image($r('app.media.ic_profile'))
          .width(26)
          .height(26)
          .fillColor('#666666')
        Text('我的')
          .fontSize(10)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onProfileClick())
    }
    .width('100%')
    .height(60)
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: -2
    })
  }
}