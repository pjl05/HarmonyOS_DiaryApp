/**
 * 日记编辑 ViewModel
 * 对标 Android DiaryEditActivity 的编辑逻辑
 */
import { Diary, createEmptyDiary } from '../model/DiaryModel'
import { DraftDiary, createEmptyDraft } from '../model/DraftDiaryModel'
import { DiaryRepository } from '../repository/DiaryRepository'
import { Logger } from '../utils/Logger'

export class DiaryEditViewModel {
  diary: Diary
  draft: DraftDiary
  isDirty: boolean = false
  currentDraftId: number = 0
  images: string[] = []

  private repository: DiaryRepository
  private isNew: boolean = true
  private context: Context

  constructor(context: Context, diaryId?: number) {
    this.context = context
    this.repository = new DiaryRepository(context)
    this.diary = createEmptyDiary()
    this.draft = createEmptyDraft()
    if (diaryId && diaryId > 0) {
      this.loadDiary(diaryId)
    }
  }

  async loadDiary(id: number): Promise<void> {
    try {
      const loaded = await this.repository.findById(id)
      if (loaded) {
        this.diary = loaded
        this.isNew = false
        this.isDirty = false
      }
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'loadDiary failed: ' + JSON.stringify(err))
    }
  }

  updateTitle(title: string): void {
    this.diary.title = title
    this.draft.title = title
    this.isDirty = true
  }

  updateContent(content: string): void {
    this.diary.content = content
    this.draft.content = content
    this.isDirty = true
  }

  updateMood(mood: string): void {
    this.diary.mood = mood
    this.draft.mood = mood
    this.isDirty = true
  }

  updateWeather(weather: string): void {
    this.diary.weather = weather
    this.draft.weather = weather
    this.isDirty = true
  }

  updateDate(dateMillis: number): void {
    this.diary.date = dateMillis
    this.draft.date = dateMillis
    this.isDirty = true
  }

  addImage(uri: string): void {
    this.images.push(uri)
    this.isDirty = true
  }

  removeImage(index: number): void {
    this.images.splice(index, 1)
    this.isDirty = true
  }

  async saveDraft(): Promise<void> {
    try {
      this.currentDraftId = await this.repository.saveDraft({
        ...this.draft,
        id: this.currentDraftId,
        updatedAt: Date.now()
      })
      this.isDirty = false
      Logger.info('DiaryEditViewModel', 'draft saved id=' + this.currentDraftId)
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'saveDraft failed: ' + JSON.stringify(err))
    }
  }

  async publish(): Promise<boolean> {
    if (!this.diary.title.trim() && !this.diary.content.trim()) {
      Logger.warn('DiaryEditViewModel', 'cannot publish empty diary')
      return false
    }
    try {
      if (this.isNew) {
        const id = await this.repository.insert(this.diary)
        this.diary.id = id
        this.isNew = false
      } else {
        await this.repository.update(this.diary)
      }
      if (this.currentDraftId > 0) {
        await this.repository.deleteDraft(this.currentDraftId)
        this.currentDraftId = 0
      }
      this.isDirty = false
      return true
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'publish failed: ' + JSON.stringify(err))
      return false
    }
  }

  async loadFromDraft(draftId: number): Promise<void> {
    try {
      const drafts = await this.repository.allDrafts()
      const draft = drafts.find(d => d.id === draftId)
      if (draft) {
        this.draft = draft
        this.currentDraftId = draftId
        this.diary.title = draft.title
        this.diary.content = draft.content
        this.diary.mood = draft.mood
        this.diary.weather = draft.weather
        this.diary.date = draft.date
        this.isNew = true
      }
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'loadFromDraft failed: ' + JSON.stringify(err))
    }
  }
}
