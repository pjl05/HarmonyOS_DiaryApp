/**
 * 左侧抽屉菜单组件
 * 对标 Android MainActivity 中的 setupDrawer() 和 Navigation Menu
 */

@Component
export struct DrawerMenu {
  @Prop username: string = ''
  @Prop email: string = ''
  @Prop avatarUri: string = ''
  @Prop isDarkMode: boolean = false
  onItemClick: (itemId: string) => void = () => {}
  onAvatarClick: () => void = () => {}
  onEditBgClick: () => void = () => {}

  // 对标 Android nav_menu.xml 中的菜单项
  private menuItems: DrawerMenuItem[] = [
    { id: 'favorites', title: '收藏', icon: $r('app.media.ic_favorite') },
    { id: 'vault', title: '保险箱', icon: $r('app.media.ic_vault') },
    { id: 'recycle_bin', title: '回收站', icon: $r('app.media.ic_delete') },
    { id: 'drafts', title: '草稿箱', icon: $r('app.media.ic_drafts') },
    { id: 'export_history', title: '导出历史', icon: $r('app.media.ic_export') },
    { id: 'transfer_data', title: '数据迁移', icon: $r('app.media.ic_transfer') },
    { id: 'membership', title: '会员中心', icon: $r('app.media.ic_membership') },
    { id: 'check_update', title: '检查更新', icon: $r('app.media.ic_update') },
    { id: 'theme_toggle', title: '夜间模式', icon: $r('app.media.ic_theme') },
    { id: 'settings', title: '设置', icon: $r('app.media.ic_settings') },
    { id: 'about', title: '关于', icon: $r('app.media.ic_about') },
    { id: 'love_zone', title: '爱情区', icon: $r('app.media.ic_love') },
    { id: 'special_thanks', title: '特别感谢', icon: $r('app.media.ic_thanks') },
    { id: 'logout', title: '退出登录', icon: $r('app.media.ic_logout') },
  ]

  build() {
    Column() {
      // 抽屉头部
      Stack({ alignContent: Alignment.BottomStart }) {
        // 背景图
        Image($r('app.media.background'))
          .width('100%')
          .height(180)
          .objectFit(ImageFit.Cover)

        // 半透明遮罩
        Column()
          .width('100%')
          .height(180)
          .backgroundColor('#66000000')

        // 用户信息区
        Column({ space: 6 }) {
          // 头像
          Image(this.avatarUri ? this.avatarUri : $r('app.media.startIcon'))
            .width(56)
            .height(56)
            .borderRadius(28)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: '#FFFFFF' })
            .onClick(() => this.onAvatarClick())

          // 用户名
          Text(this.username || 'User Name')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 邮箱
          Text(this.email || 'user@example.com')
            .fontSize(12)
            .fontColor('#CCFFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .padding({ left: 16, bottom: 16 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 编辑背景按钮
        Image($r('app.media.ic_edit'))
          .width(22)
          .height(22)
          .fillColor('#CCFFFFFF')
          .margin({ right: 12, bottom: 14 })
          .onClick(() => this.onEditBgClick())
          .position({ right: 0, bottom: 0 })
      }
      .width('100%')
      .height(180)

      // 菜单列表
      Scroll() {
        Column() {
          ForEach(this.menuItems, (item: DrawerMenuItem) => {
            Column() {
              Row({ space: 16 }) {
                Image(item.icon)
                  .width(22)
                  .height(22)
                  .fillColor(this.isDarkMode ? '#CCCCCC' : '#555555')

                Text(item.id === 'theme_toggle'
                      ? (this.isDarkMode ? '日间模式' : '夜间模式')
                      : item.title)
                  .fontSize(15)
                  .fontColor(
                    item.id === 'logout'
                      ? '#FF5722'
                      : (this.isDarkMode ? '#DDDDDD' : '#333333')
                  )
                  .layoutWeight(1)

                if (item.id === 'membership') {
                  Text('VIP')
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#FFD700')
                    .borderRadius(4)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }
              .width('100%')
              .height(52)
              .padding({ left: 20, right: 20 })
              .onClick(() => this.onItemClick(item.id))

              Divider()
                .strokeWidth(0.5)
                .color(this.isDarkMode ? '#2A2A2A' : '#F0F0F0')
                .margin({ left: 58 })
            }
          })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#1A1A1A' : '#FFFFFF')
  }
}

interface DrawerMenuItem {
  id: string
  title: string
  icon: Resource
}