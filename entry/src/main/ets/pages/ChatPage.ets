/**
 * ChatPage - 路由页面入口
 * 替换 Android: ChatActivity
 */
import { ChatPage } from '../ui/chat/ChatPage'

@Entry
@Component
export struct ChatPageEntry {
  build() {
    ChatPage()
  }
}