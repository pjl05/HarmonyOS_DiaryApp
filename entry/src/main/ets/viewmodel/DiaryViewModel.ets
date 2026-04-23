/**
 * 日记列表 ViewModel
 * 对标 Android DiaryViewModel
 */
import { Diary, isSystemDiaryContent } from '../model/DiaryModel'
import { DiaryRepository } from '../repository/DiaryRepository'
import { Logger } from '../utils/Logger'

export class DiaryViewModel {
  diaries: Diary[] = []
  favoriteDiaries: Diary[] = []
  searchQuery: string = ''
  jumpToDateMillis: number | null = null
  isLoading: boolean = false

  private repository: DiaryRepository
  private context: Context

  constructor(context: Context, repository?: DiaryRepository) {
    this.context = context
    this.repository = repository ?? new DiaryRepository(context)
  }

  async loadAll(): Promise<void> {
    this.isLoading = true
    try {
      this.diaries = await this.repository.allDiaries()
    } catch (err) {
      Logger.error('DiaryViewModel', 'loadAll failed: ' + JSON.stringify(err))
    } finally {
      this.isLoading = false
    }
  }

  async loadFavorites(): Promise<void> {
    try {
      this.favoriteDiaries = await this.repository.favoriteDiaries()
    } catch (err) {
      Logger.error('DiaryViewModel', 'loadFavorites failed: ' + JSON.stringify(err))
    }
  }

  setSearchQuery(query: string): void {
    this.searchQuery = query
    if (!query) {
      this.loadAll()
    } else {
      this.search(query)
    }
  }

  private async search(query: string): Promise<void> {
    try {
      this.diaries = await this.repository.searchDiaries(query)
    } catch (err) {
      Logger.error('DiaryViewModel', 'search failed: ' + JSON.stringify(err))
    }
  }

  requestJumpToDate(millis: number): void {
    this.jumpToDateMillis = millis
  }

  clearJumpToDate(): void {
    this.jumpToDateMillis = null
  }

  async deleteDiary(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.delete(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'deleteDiary failed: ' + JSON.stringify(err))
    }
  }

  async toggleFavorite(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.toggleFavorite(diary)
      const updated = await this.repository.findById(diary.id)
      if (updated) {
        this.diaries = this.diaries.map(d => d.id === diary.id ? updated : d)
      }
    } catch (err) {
      Logger.error('DiaryViewModel', 'toggleFavorite failed: ' + JSON.stringify(err))
    }
  }

  async moveToVault(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.moveToVault(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'moveToVault failed: ' + JSON.stringify(err))
    }
  }

  async moveToTrash(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.moveToTrash(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'moveToTrash failed: ' + JSON.stringify(err))
    }
  }
}
