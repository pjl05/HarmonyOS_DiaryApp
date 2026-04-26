/**
 * MessageBubbleAi - AI 消息气泡
 * 替换 Android: item_chat_left.xml (AI 消息)
 */
import { ChatMessageWrapper } from './MessageBubbleUser'

@Component
export struct MessageBubbleAi {
  @ObjectLink wrapper: ChatMessageWrapper
  @Prop aiName: string = 'AI Companion'

  build() {
    Row() {
      Column() {
        Text(this.wrapper.msg.message || '正在输入...')
          .fontSize(15)
          .fontColor('#FF333333')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFFFF')
          .borderRadius(18)
          .constraintSize({ maxWidth: 260 })
          .shadow({
            radius: 4,
            color: '#1A000000',
            offsetX: 1,
            offsetY: 1
          })

        Text(formatTime(this.wrapper.msg.timestamp))
          .fontSize(11)
          .fontColor('#FF999999')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

function formatTime(timestamp: number): string {
  const d = new Date(timestamp)
  const now = new Date()
  const sameDay = d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  if (sameDay) {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
  }
  return `${d.getMonth() + 1}月${d.getDate()}日 ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
}