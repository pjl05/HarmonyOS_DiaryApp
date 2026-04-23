/**
 * 草稿日记数据模型
 * 对标 Android DraftDiary.kt (Room Entity)
 */
export interface DraftDiary {
  id: number
  userId: string
  title: string
  content: string
  mood: string
  weather: string
  date: number
  createdAt: number
  updatedAt: number
}

export function createEmptyDraft(dateMillis?: number): DraftDiary {
  const now = Date.now()
  return {
    id: 0,
    userId: '',
    title: '',
    content: '',
    mood: 'neutral',
    weather: 'sunny',
    date: dateMillis ?? now,
    createdAt: now,
    updatedAt: now
  }
}
