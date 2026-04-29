/**
 * ChatRepository - 聊天消息 Repository
 * 替换 Android: ChatRepository
 * 封装 ChatMessageDao，提供业务层友好的接口
 */
import { ChatMessage, createUserMessage, createAiMessage } from '../../model/ChatMessageModel'
import { chatMessageDao } from '../dao/ChatMessageDao'

export class ChatRepository {
  async getAllMessages(sessionId: string): Promise<ChatMessage[]> {
    return chatMessageDao.getAllMessages(sessionId)
  }

  async getRecentMessages(sessionId: string, limit: number): Promise<ChatMessage[]> {
    return chatMessageDao.getRecentMessages(sessionId, limit)
  }

  async sendUserMessage(text: string, sessionId: string): Promise<ChatMessage> {
    const msg = createUserMessage(text, sessionId)
    const id = await chatMessageDao.insert(msg)
    const result: ChatMessage = { id: id, message: msg.message, role: msg.role, timestamp: msg.timestamp, sessionId: msg.sessionId }
    return result
  }

  async insertAiMessage(text: string, sessionId: string): Promise<ChatMessage> {
    const msg = createAiMessage(text, sessionId)
    const id = await chatMessageDao.insert(msg)
    const result: ChatMessage = { id: id, message: msg.message, role: msg.role, timestamp: msg.timestamp, sessionId: msg.sessionId }
    return result
  }

  async appendToAiMessage(id: number, newContent: string): Promise<string> {
    await chatMessageDao.updateMessageContent(id, newContent)
    return newContent
  }

  async deleteMessage(id: number): Promise<void> {
    await chatMessageDao.deleteById(id)
  }

  async clearSession(sessionId: string): Promise<void> {
    await chatMessageDao.clearAll(sessionId)
  }

  async getLastUserTimestamp(sessionId: string): Promise<number | null> {
    return chatMessageDao.getLastUserTimestamp(sessionId)
  }

  async getLastAssistantTimestamp(sessionId: string): Promise<number | null> {
    return chatMessageDao.getLastAssistantTimestamp(sessionId)
  }
}

export const chatRepository = new ChatRepository()
