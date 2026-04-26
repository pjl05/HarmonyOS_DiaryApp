/**
 * MessageBubbleUser - 用户消息气泡
 * 替换 Android: item_chat_right.xml (用户消息)
 */
import { ChatMessage } from '../../model/ChatMessageModel'

@Component
export struct MessageBubbleUser {
  @ObjectLink wrapper: ChatMessageWrapper

  build() {
    Row() {
      Blank()
      Column() {
        Text(this.wrapper.msg.message)
          .fontSize(15)
          .fontColor('#FFFFFFFF')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#FF4A90D9')
          .borderRadius(18)
          .constraintSize({ maxWidth: 260 })

        Text(formatTime(this.wrapper.msg.timestamp))
          .fontSize(11)
          .fontColor('#FF999999')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

@Observed
export class ChatMessageWrapper {
  msg: ChatMessage

  constructor(msg: ChatMessage) {
    this.msg = msg
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