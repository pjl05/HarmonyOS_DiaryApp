/**
 * AiChatService - WebSocket AI 服务
 * 替换 Android: ServerAiWebSocketService / DeepseekService
 */
import webSocket from '@ohos.net.webSocket'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ChatMessage } from '../model/ChatMessageModel'

const TAG = 'AiChatService'

export interface AiChatListener {
  onMessage(text: string): void
  onError(error: string): void
  onClosed(): void
}

export class AiChatService {
  private ws: webSocket.WebSocket | null = null
  private listener: AiChatListener | null = null
  private currentRequestId: string | null = null
  private baseUrl: string = ''

  setBaseUrl(url: string): void {
    this.baseUrl = url.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://') + '/api/ai/ws'
  }

  connect(listener: AiChatListener): void {
    this.listener = listener
    this.ws?.close(1000, 'Reconnecting')
    this.ws = null

    try {
      this.ws = webSocket.createWebSocket()
      this.ws.on('open', (_, webSocket) => {
        hilog.info(0, TAG, 'WebSocket connected')
      })
      this.ws.on('message', (_, message) => {
        this.handleMessage(message as string)
      })
      this.ws.on('close', (_, code, reason) => {
        hilog.info(0, TAG, 'WebSocket closed: %{public}d %{public}s', code, reason)
        this.listener?.onClosed()
      })
      this.ws.on('error', (_, error) => {
        hilog.error(0, TAG, 'WebSocket error: %{public}s', JSON.stringify(error))
        this.listener?.onError((error as Error).message || 'Connection failed')
      })

      this.ws.connect(this.baseUrl, (err, _) => {
        if (err) {
          hilog.error(0, TAG, 'WebSocket connect failed: %{public}s', JSON.stringify(err))
          this.listener?.onError((err as Error).message || 'Connection failed')
        }
      })
    } catch (e) {
      this.listener?.onError((e as Error).message || 'Unknown error')
    }
  }

  private handleMessage(text: string): void {
    try {
      const obj = JSON.parse(text)
      const type = obj.type as string
      const requestId = obj.requestId as string | undefined
      const active = this.currentRequestId
      if (active != null && requestId != null && requestId !== active) return

      switch (type) {
        case 'delta':
          this.listener?.onMessage(obj.delta as string || '')
          break
        case 'done':
          this.listener?.onClosed()
          break
        case 'error':
          this.listener?.onError(obj.message as string || 'Unknown error')
          break
      }
    } catch (e) {
      // ignore parse error
    }
  }

  sendMessage(
    userMessage: string,
    contextDiaries: string[],
    conversationHistory: ChatMessage[],
    systemPrompt: string,
    chatId: string,
    historyLimit: number,
    token: string
  ): void {
    if (!this.ws) return

    this.currentRequestId = `req_${Date.now()}`
    const historyItems = conversationHistory
      .filter(m => m.role === 'user' || m.role === 'assistant')
      .filter(m => m.message.length > 0)
      .map(m => ({ role: m.role, message: m.message }))

    const payload = {
      type: 'chat',
      requestId: this.currentRequestId,
      userMessage: userMessage,
      contextDiaries: contextDiaries,
      conversationHistory: historyItems,
      systemPrompt: systemPrompt,
      historyLimit: historyLimit,
      chatId: chatId,
      usageType: 'chat'
    }

    this.ws.send(JSON.stringify(payload), (err) => {
      if (err) {
        hilog.error(0, TAG, 'send failed: %{public}s', JSON.stringify(err))
        this.listener?.onError((err as Error).message || 'Send failed')
      }
    })
  }

  close(): void {
    this.ws?.close(1000, 'Normal closure')
    this.ws = null
    this.currentRequestId = null
  }
}