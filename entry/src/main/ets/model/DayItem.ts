/**
 * DayItem - 日子数据模型
 * 对标 Android: DayItem.kt (Room entity)
 */
export enum Priority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2
}

export enum Mood {
  UNKNOWN = 0,
  HAPPY = 1,
  NEUTRAL = 2,
  SAD = 3,
  ANGRY = 4,
  EXCITED = 5
}

export enum PreviewContentPriority {
  TEXT = 0,
  IMAGE = 1
}

export interface DayItem {
  id: number
  userId: string
  startAt: string           // ISO-8601，"从这一天起"
  title: string
  content: string           // HTML 富文本
  author: string
  mood: Mood
  priority: Priority
  location: string
  createdAt: string
  updatedAt: string
  previewContentPriority: PreviewContentPriority
}

export const DEFAULT_DAY_ITEM: DayItem = {
  id: 0,
  userId: '',
  startAt: '',
  title: '',
  content: '',
  author: '',
  mood: Mood.UNKNOWN,
  priority: Priority.NORMAL,
  location: '',
  createdAt: '',
  updatedAt: '',
  previewContentPriority: PreviewContentPriority.TEXT
}
