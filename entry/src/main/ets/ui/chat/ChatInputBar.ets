/**
 * ChatInputBar - 消息输入框 + 发送按钮
 * 替换 Android: chat_input_bar.xml
 */
@Component
export struct ChatInputBar {
  @Link inputText: string
  @Prop isLoading: boolean = false
  onSend: () => void

  build() {
    Row() {
      TextInput({ text: this.inputText, placeholder: '输入消息...' })
        .fontSize(15)
        .height(40)
        .layoutWeight(1)
        .backgroundColor('#FFFFFFFF')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val
        })
        .onSubmit(() => {
          if (!this.isLoading) this.onSend()
        })

      Button() {
        if (this.isLoading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#FFFFFFFF')
        } else {
          Text('发送')
            .fontSize(14)
            .fontColor('#FFFFFFFF')
        }
      }
      .width(60)
      .height(40)
      .backgroundColor(this.inputText.trim() ? '#FF4A90D9' : '#FFCCCCCC')
      .borderRadius(20)
      .enabled(!this.isLoading && !!this.inputText.trim())
      .onClick(() => {
        if (!this.isLoading && this.inputText.trim()) {
          this.onSend()
        }
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFF5F5F5')
    .alignItems(VerticalAlign.Center)
  }
}