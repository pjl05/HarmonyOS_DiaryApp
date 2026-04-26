/**
 * ChatPage - 主聊天页面
 * 替换 Android: ChatActivity (NavDestination)
 */
import { ChatViewModel } from '../../viewmodel/ChatViewModel'
import { ChatMessage } from '../../model/ChatMessageModel'
import { ChatMessageWrapper } from './MessageBubbleUser'
import { MessageBubbleUser } from './MessageBubbleUser'
import { MessageBubbleAi } from './MessageBubbleAi'
import { ChatInputBar } from './ChatInputBar'
import { router } from '@kit.RouterKit'

@Component
export struct ChatPage {
  @State viewModel: ChatViewModel = new ChatViewModel()
  @State wrappers: ChatMessageWrapper[] = []

  aboutToAppear(): void {
    this.viewModel.aboutToAppear().then(() => {
      this.syncWrappers()
    })
  }

  private syncWrappers(): void {
    this.wrappers = this.viewModel.messages.map(m => new ChatMessageWrapper(m))
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        this.buildTopBar()

        // 消息列表
        List({ initialIndex: 0 }) {
          ForEach(this.wrappers, (wrapper: ChatMessageWrapper) => {
            ListItem() {
              this.buildMessageItem(wrapper)
            }
          }, (wrapper: ChatMessageWrapper) => `${wrapper.msg.id}_${wrapper.msg.timestamp}`)
        }
        .layoutWeight(1)
        .padding({ left: 12, right: 12 })
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.Center)

        // 输入栏
        ChatInputBar({
          inputText: $viewModel.inputText,
          isLoading: $viewModel.isLoading,
          onSend: () => {
            this.viewModel.sendMessage().then(() => {
              this.syncWrappers()
            })
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFF5F5F5')
    }
    .title('AI 聊天')
    .titleMode(NavDestinationTitleMode.Medium)
  }

  @Builder
  buildTopBar() {
    Row() {
      Text(this.viewModel.aiName)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF333333')

      Blank()

      Text('设置')
        .fontSize(14)
        .fontColor('#FF4A90D9')
        .onClick(() => {
          router.pushUrl({ url: 'pages/ChatManagementPage' }).catch(() => {})
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFFFF')
  }

  @Builder
  buildMessageItem(wrapper: ChatMessageWrapper) {
    if (wrapper.msg.role === 'user') {
      MessageBubbleUser({ wrapper: wrapper })
    } else {
      MessageBubbleAi({ wrapper: wrapper, aiName: this.viewModel.aiName })
    }
  }
}