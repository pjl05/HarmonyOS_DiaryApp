/**
 * WebSocket 客户端封装
 * 对标 Android 的 ServerAiWebSocketService
 */

import webSocket from '@ohos.net.webSocket'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import TokenManager from '../../utils/TokenManager.ets'

const logger = getLogger('WebSocketClient')

export enum WebSocketState {
  CONNECTING = 0,
  CONNECTED = 1,
  DISCONNECTED = 2,
  RECONNECTING = 3
}

export interface WebSocketListener {
  onOpen(): void
  onMessage(message: string): void
  onError(error: string): void
  onClose(code: number, reason: string): void
  onStateChange(state: WebSocketState): void
}

class WebSocketClient {
  private static instance: WebSocketClient
  private webSocket: webSocket.WebSocket | null = null
  private listeners: Set<WebSocketListener> = new Set()
  private state: WebSocketState = WebSocketState.DISCONNECTED
  private reconnectAttempts: number = 0
  private maxReconnectAttempts: number = 5
  private reconnectDelay: number = 3000

  private constructor() {}

  static getInstance(): WebSocketClient {
    if (!WebSocketClient.instance) {
      WebSocketClient.instance = new WebSocketClient()
    }
    return WebSocketClient.instance
  }

  addListener(listener: WebSocketListener): void {
    this.listeners.add(listener)
  }

  removeListener(listener: WebSocketListener): void {
    this.listeners.delete(listener)
  }

  private notifyStateChange(state: WebSocketState): void {
    this.state = state
    this.listeners.forEach(listener => {
      listener.onStateChange(state)
    })
  }

  private notifyOpen(): void {
    this.listeners.forEach(listener => {
      listener.onOpen()
    })
  }

  private notifyMessage(message: string): void {
    this.listeners.forEach(listener => {
      listener.onMessage(message)
    })
  }

  private notifyError(error: string): void {
    logger.error(`WebSocket Error: ${error}`)
    this.listeners.forEach(listener => {
      listener.onError(error)
    })
  }

  private notifyClose(code: number, reason: string): void {
    logger.info(`WebSocket Closed: code=${code}, reason=${reason}`)
    this.listeners.forEach(listener => {
      listener.onClose(code, reason)
    })
  }

  async connect(url: string = ApiConstants.WS_AI_URL): Promise<void> {
    if (this.state === WebSocketState.CONNECTING || this.state === WebSocketState.CONNECTED) {
      logger.warn('WebSocket already connecting or connected')
      return
    }

    this.notifyStateChange(WebSocketState.CONNECTING)

    // 获取 Token
    const token = await TokenManager.getToken()

    this.webSocket = webSocket.createWebSocket()

    this.webSocket.on('open', async (err, value) => {
      if (err) {
        this.notifyError(`Open error: ${JSON.stringify(err)}`)
        this.notifyStateChange(WebSocketState.DISCONNECTED)
        return
      }

      logger.info('WebSocket connected')

      // 发送认证消息（如果需要）
      if (token) {
        this.send(JSON.stringify({ type: 'auth', token }))
      }

      this.reconnectAttempts = 0
      this.notifyStateChange(WebSocketState.CONNECTED)
      this.notifyOpen()
    })

    this.webSocket.on('message', (err, value) => {
      if (err) {
        this.notifyError(`Message error: ${JSON.stringify(err)}`)
        return
      }
      const message = typeof value === 'string' ? value : JSON.stringify(value)
      logger.info(`WebSocket message received: ${message}`)
      this.notifyMessage(message)
    })

    this.webSocket.on('error', (err) => {
      this.notifyError(`Error: ${JSON.stringify(err)}`)
    })

    this.webSocket.on('close', (err, value) => {
      this.notifyClose(value.code, value.reason)
      this.notifyStateChange(WebSocketState.DISCONNECTED)

      // 自动重连
      if (this.reconnectAttempts < this.maxReconnectAttempts) {
        this.scheduleReconnect(url)
      }
    })

    // 设置请求头
    const header: Record<string, string> = {}
    if (token) {
      header['Authorization'] = `Bearer ${token}`
    }

    this.webSocket.connect(url, header, (err, value) => {
      if (err) {
        logger.error(`Connect failed: ${JSON.stringify(err)}`)
        this.notifyStateChange(WebSocketState.DISCONNECTED)
      }
    })
  }

  private scheduleReconnect(url: string): void {
    this.reconnectAttempts++
    this.notifyStateChange(WebSocketState.RECONNECTING)
    logger.info(`Scheduling reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`)

    setTimeout(() => {
      logger.info('Attempting reconnect...')
      this.connect(url)
    }, this.reconnectDelay * this.reconnectAttempts)
  }

  async send(message: string): Promise<boolean> {
    if (!this.webSocket || this.state !== WebSocketState.CONNECTED) {
      logger.warn('WebSocket not connected, cannot send message')
      return false
    }

    const result = await this.webSocket.send(message)
    if (!result) {
      logger.error('Failed to send message')
    }
    return result
  }

  close(): void {
    this.reconnectAttempts = this.maxReconnectAttempts // 防止自动重连
    if (this.webSocket) {
      this.webSocket.close()
      this.webSocket = null
    }
    this.notifyStateChange(WebSocketState.DISCONNECTED)
  }

  getState(): WebSocketState {
    return this.state
  }
}

export default WebSocketClient.getInstance()