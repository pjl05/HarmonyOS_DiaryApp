/**
 * ChatAdapter - 消息列表适配器
 * 替换 Android: ChatAdapter (RecyclerView.Adapter)
 */
import { ChatMessage } from '../../model/ChatMessageModel'
import { ChatMessageWrapper } from './MessageBubbleUser'

export class ChatAdapter {
  private wrappers: ChatMessageWrapper[] = []

  setMessages(msgs: ChatMessage[]): void {
    this.wrappers = msgs.map(m => new ChatMessageWrapper(m))
  }

  getMessages(): ChatMessageWrapper[] {
    return this.wrappers
  }

  appendMessage(msg: ChatMessage): void {
    this.wrappers = [...this.wrappers, new ChatMessageWrapper(msg)]
  }

  updateLastMessage(text: string): void {
    if (this.wrappers.length === 0) return
    const last = this.wrappers[this.wrappers.length - 1]
    last.msg = { ...last.msg, message: text }
    this.wrappers = [...this.wrappers]
  }

  removeLast(): void {
    if (this.wrappers.length === 0) return
    this.wrappers = this.wrappers.slice(0, -1)
  }
}