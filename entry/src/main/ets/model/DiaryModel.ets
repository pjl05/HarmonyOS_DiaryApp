/**
 * 日记数据模型
 * 对标 Android Diary.kt (Room Entity)
 */
export interface Diary {
  id: number
  userId: string
  author: string | null
  title: string
  content: string       // 支持富文本 HTML
  mood: string          // 心情标签（happy, sad, neutral, angry, worried, excited）
  weather: string       // 天气标签（sunny, cloudy, rainy, snowy, windy, foggy）
  location: string | null
  date: number          // 时间戳（毫秒）
  createdAt: number     // 创建时间戳
  synced: boolean       // 是否已同步到服务端
  isFavorite: boolean   // 是否收藏
  isVaulted: boolean    // 是否移入保险箱
  isTrashed: boolean    // 是否在回收站
  trashedAt: number | null
  previewContentPriority: string  // "text" | "image" | "video"
}

export function createEmptyDiary(dateMillis?: number): Diary {
  const now = Date.now()
  return {
    id: 0,
    userId: '',
    author: null,
    title: '',
    content: '',
    mood: 'neutral',
    weather: 'sunny',
    location: null,
    date: dateMillis ?? now,
    createdAt: now,
    synced: false,
    isFavorite: false,
    isVaulted: false,
    isTrashed: false,
    trashedAt: null,
    previewContentPriority: 'text'
  }
}

/**
 * 系统日记内容判断（不可删除/移动/收藏）
 * 对标 Android SystemDiary.isSystemDiaryContent()
 */
export function isSystemDiaryContent(content: string): boolean {
  if (!content) return false
  return content.startsWith('<!-- SYSTEM_DIARY:welcome -->')
}
