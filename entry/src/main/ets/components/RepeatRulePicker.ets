/**
 * RepeatRulePicker - 重复规则选择器
 * 对标 Android: RepeatRulePicker
 */
interface RepeatTypeOption {
  value: string
  label: string
}

@Component
export struct RepeatRulePicker {
  @Link selectedType: string
  @Link selectedWeekday: number
  @Link selectedDayOfMonth: number
  @Link repeatRangeStart: number | null
  @Link repeatRangeEnd: number | null

  private repeatTypes: RepeatTypeOption[] = [
    { value: 'NONE', label: '不重复' },
    { value: 'DAILY', label: '每天' },
    { value: 'WEEKLY', label: '每周' },
    { value: 'MONTHLY', label: '每月' },
    { value: 'YEARLY', label: '每年' }
  ]

  private weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  private dayOptions: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]

  build() {
    Column() {
      Text('重复')
        .fontSize(14)
        .fontColor('#666')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      List() {
        ForEach(this.repeatTypes, (option: RepeatTypeOption) => {
          ListItem() {
            Row() {
              Text(option.label)
                .fontSize(15)
              Blank()
              if (this.selectedType === option.value) {
                Text('✓')
                  .fontColor('#1890FF')
              }
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.selectedType = option.value
            })
          }
        })
      }

      if (this.selectedType === 'WEEKLY') {
        Text('选择星期')
          .fontSize(14)
          .fontColor('#666')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 16, bottom: 8 })

        Row() {
          ForEach(this.weekdays, (label: string, index: number) => {
            Button(label)
              .fontSize(12)
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor(this.selectedWeekday === index + 1 ? '#1890FF' : '#F5F5F5')
              .fontColor(this.selectedWeekday === index + 1 ? '#FFF' : '#333')
              .onClick(() => {
                this.selectedWeekday = index + 1
              })
          })
        }
      }

      if (this.selectedType === 'MONTHLY') {
        Text('选择日期')
          .fontSize(14)
          .fontColor('#666')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 16, bottom: 8 })

        Grid() {
          ForEach(this.dayOptions, (day: number) => {
            GridItem() {
              Text(day.toString())
                .fontSize(14)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.selectedDayOfMonth === day ? '#1890FF' : '#F5F5F5')
                .fontColor(this.selectedDayOfMonth === day ? '#FFF' : '#333')
                .borderRadius(20)
                .onClick(() => {
                  this.selectedDayOfMonth = day
                })
            }
          })
        }
        .columnsTemplate('1 1 1 1 1 1 1')
        .rowsTemplate('1 1 1 1')
        .height(160)
      }
    }
    .width('100%')
    .padding(16)
  }
}