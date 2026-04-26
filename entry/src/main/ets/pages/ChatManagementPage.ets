/**
 * ChatManagementPage - 路由页面入口
 * 替换 Android: ChatManagementActivity
 */
import { ChatManagementPage } from '../ui/chat/ChatManagementPage'

@Entry
@Component
export struct ChatManagementPageEntry {
  build() {
    ChatManagementPage()
  }
}