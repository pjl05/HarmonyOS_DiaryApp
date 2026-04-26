/**
 * ChatMessage - 本地聊天消息模型
 * 替换 Android: ChatMessage (Room Entity)
 * 表名: chat_messages
 */
export interface ChatMessage {
  id: number          // 自增主键，0 = 未持久化
  message: string    // 消息内容
  role: string       // "user" | "assistant"
  timestamp: number  // 时间戳（毫秒）
  sessionId: string  // 会话 ID（用于区分不同对话）
}

export function createUserMessage(text: string, sessionId: string): ChatMessage {
  return {
    id: 0,
    message: text,
    role: 'user',
    timestamp: Date.now(),
    sessionId: sessionId
  }
}

export function createAiMessage(text: string, sessionId: string, timestamp: number = Date.now()): ChatMessage {
  return {
    id: 0,
    message: text,
    role: 'assistant',
    timestamp: timestamp,
    sessionId: sessionId
  }
}
