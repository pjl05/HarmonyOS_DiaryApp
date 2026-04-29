/**
 * ChatViewModel - 聊天状态管理 + 发送逻辑
 * 替换 Android: ChatViewModel (StateFlow 管理)
 */
import { ChatMessage } from '../model/ChatMessageModel'
import { chatRepository } from '../data/repository/ChatRepository'
import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ChatViewModel'

// ===== Settings Preferences Keys =====
const PREF_NAME = 'chat_settings'
const KEY_AI_ROLE_PRESET_ID = 'ai_role_preset_id'
const KEY_AI_NAME = 'ai_name'
const KEY_ROLE_SETTING = 'role_setting'
const KEY_CHAT_SESSION_ID = 'chat_session_id'
const KEY_CHAT_HISTORY_LIMIT = 'chat_history_limit'
const KEY_AI_DIARY_READ_LIMIT = 'ai_diary_read_limit'
const KEY_AI_CONFIG_MODE = 'ai_config_mode'

@Observed
export class ChatViewModel {
  messages: ChatMessage[] = []
  inputText: string = ''
  isLoading: boolean = false
  currentSessionId: string = ''
  aiName: string = 'AI Companion'

  aiRolePresetId: number = 0
  roleSetting: string = ''
  chatHistoryLimit: number = 24
  aiDiaryReadLimit: number = 10
  aiConfigMode: string = 'default'

  private prefs: preferences.Preferences | null = null
  private currentAiMessageId: number = -1
  private currentAiContent: string = ''

  async aboutToAppear(): Promise<void> {
    await this.loadSettings()
    const msgs = await chatRepository.getAllMessages(this.currentSessionId)
    this.messages = msgs
  }

  async loadSettings(): Promise<void> {
    const ctx = getContext(this)
    this.prefs = await preferences.getPreferences(ctx, { name: PREF_NAME })
    this.aiRolePresetId = await this.prefs.get(KEY_AI_ROLE_PRESET_ID, 0) as number
    this.aiName = await this.prefs.get(KEY_AI_NAME, 'AI Companion') as string
    this.roleSetting = await this.prefs.get(KEY_ROLE_SETTING, '') as string
    this.chatHistoryLimit = await this.prefs.get(KEY_CHAT_HISTORY_LIMIT, 24) as number
    this.aiDiaryReadLimit = await this.prefs.get(KEY_AI_DIARY_READ_LIMIT, 10) as number
    this.aiConfigMode = await this.prefs.get(KEY_AI_CONFIG_MODE, 'default') as string
    this.currentSessionId = await this.prefs.get(KEY_CHAT_SESSION_ID, '') as string
    if (!this.currentSessionId) {
      this.currentSessionId = `session_${Date.now()}`
      await this.prefs.put(KEY_CHAT_SESSION_ID, this.currentSessionId)
    }
  }

  async saveSettings(): Promise<void> {
    if (!this.prefs) return
    await this.prefs.put(KEY_AI_ROLE_PRESET_ID, this.aiRolePresetId)
    await this.prefs.put(KEY_AI_NAME, this.aiName)
    await this.prefs.put(KEY_ROLE_SETTING, this.roleSetting)
    await this.prefs.put(KEY_CHAT_HISTORY_LIMIT, this.chatHistoryLimit)
    await this.prefs.put(KEY_AI_DIARY_READ_LIMIT, this.aiDiaryReadLimit)
    await this.prefs.put(KEY_AI_CONFIG_MODE, this.aiConfigMode)
  }

  updateInputText(text: string): void {
    this.inputText = text
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (!text || this.isLoading) return

    this.inputText = ''
    this.isLoading = true

    try {
      const userMsg = await chatRepository.sendUserMessage(text, this.currentSessionId)
      this.messages = this.messages.concat(userMsg)

      this.currentAiMessageId = -1
      this.currentAiContent = ''

      const aiMsg = await chatRepository.insertAiMessage('', this.currentSessionId)
      this.currentAiMessageId = aiMsg.id
      this.currentAiContent = ''
      this.messages = this.messages.concat(aiMsg)

      await this.callAiService(text, (chunk: string, done: boolean) => {
        if (done) {
          this.currentAiContent += chunk
          this.updateLastAiMessage()
        } else {
          this.currentAiContent += chunk
          this.updateLastAiMessageStreaming()
        }
      })

      await chatRepository.appendToAiMessage(this.currentAiMessageId, this.currentAiContent)
    } catch (e) {
      hilog.error(0, TAG, 'sendMessage error: %{public}s', JSON.stringify(e))
      if (this.currentAiMessageId > 0) {
        await chatRepository.deleteMessage(this.currentAiMessageId)
        const deletedId = this.currentAiMessageId
        this.messages = this.messages.filter((m: ChatMessage) => m.id !== deletedId)
      }
    } finally {
      this.isLoading = false
      this.currentAiMessageId = -1
    }
  }

  private updateLastAiMessage(): void {
    if (this.messages.length === 0) return
    const last = this.messages[this.messages.length - 1]
    if (last.role === 'assistant' && last.id === this.currentAiMessageId) {
      const updated: ChatMessage = { id: last.id, message: this.currentAiContent, role: last.role, timestamp: last.timestamp, sessionId: last.sessionId }
      this.messages = this.messages.slice(0, -1).concat(updated)
    }
  }

  private updateLastAiMessageStreaming(): void {
    this.updateLastAiMessage()
  }

  private async callAiService(
    userMessage: string,
    onChunk: (chunk: string, done: boolean) => void
  ): Promise<void> {
    // 模拟流式 AI 回复（后续替换为 AiChatService WebSocket）
    const response = `这是一条模拟 AI 回复：${userMessage}`
    for (let i = 0; i < response.length; i += 5) {
      await new Promise<void>(resolve => setTimeout(resolve, 50))
      onChunk(response.slice(i, i + 5), false)
    }
    onChunk('', true)
  }

  async loadHistory(): Promise<void> {
    const msgs = await chatRepository.getAllMessages(this.currentSessionId)
    this.messages = msgs
  }

  async clearChat(): Promise<void> {
    await chatRepository.clearSession(this.currentSessionId)
    this.messages = []
  }

  async deleteMessage(id: number): Promise<void> {
    await chatRepository.deleteMessage(id)
    this.messages = this.messages.filter(m => m.id !== id)
  }
}