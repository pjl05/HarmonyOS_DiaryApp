/**
 * 顶部工具栏组件
 * 对标 Android MainActivity 中的 setupTopBar()
 * 包含汉堡菜单按钮、头像按钮、搜索框、星空按钮
 */

@Component
export struct TopBar {
  @Prop avatarUri: string = ''
  @Prop searchHint: string = '搜索日记...'
  @Prop showCalendarYearMonth: boolean = false
  @Prop calendarYearMonthText: string = ''
  @Link searchQuery: string
  onMenuClick: () => void = () => {}
  onAvatarClick: () => void = () => {}
  onStarfieldClick: () => void = () => {}
  onCalendarYearMonthClick: () => void = () => {}

  build() {
    Row({ space: 8 }) {
      // 汉堡菜单按钮（对标 btnMenu）
      Image($r('app.media.ic_menu'))
        .width(26)
        .height(26)
        .fillColor('#555555')
        .onClick(() => this.onMenuClick())

      // 头像（对标 ivAvatar）
      Image(this.avatarUri ? this.avatarUri : $r('app.media.app_logo'))
        .width(34)
        .height(34)
        .borderRadius(17)
        .objectFit(ImageFit.Cover)
        .onClick(() => this.onAvatarClick())

      if (this.showCalendarYearMonth) {
        // 日历 Tab 专属：年月文字按钮（对标 tvCalendarYearMonth）
        Text(this.calendarYearMonthText)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .onClick(() => this.onCalendarYearMonthClick())
      } else {
        // 搜索框（对标 etSearch）
        TextInput({ placeholder: this.searchHint, text: this.searchQuery })
          .backgroundColor('#F0F0F0')
          .borderRadius(20)
          .height(36)
          .layoutWeight(1)
          .fontSize(14)
          .padding({ left: 14, right: 14 })
          .onChange((val: string) => {
            this.searchQuery = val
          })
      }

      // 星空按钮（对标 btnStarfield）
      Image($r('app.media.ic_starfield'))
        .width(26)
        .height(26)
        .fillColor('#555555')
        .onClick(() => this.onStarfieldClick())
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 1
    })
  }
}