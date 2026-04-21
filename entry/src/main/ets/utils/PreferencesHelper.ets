/**
 * 轻量存储工具
 * 对标 Android 的 SharedPreferences
 */

import data_preferences from '@ohos.data.preferences'

const PREFERENCES_NAME = 'diary_prefs'

class PreferencesHelper {
  private static instance: PreferencesHelper
  private preferences: data_preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): PreferencesHelper {
    if (!PreferencesHelper.instance) {
      PreferencesHelper.instance = new PreferencesHelper()
    }
    return PreferencesHelper.instance
  }

  async init(context: Context): Promise<void> {
    if (!this.preferences) {
      this.preferences = await data_preferences.getPreferences(context, PREFERENCES_NAME)
    }
  }

  async putString(key: string, value: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as string
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as boolean
  }

  async putNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.get(key, defaultValue) as number
  }

  async remove(key: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.delete(key)
    await this.preferences.flush()
  }

  async clear(): Promise<void> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    await this.preferences.clear()
    await this.preferences.flush()
  }

  async hasKey(key: string): Promise<boolean> {
    if (!this.preferences) {
      throw new Error('Preferences not initialized. Call init() first.')
    }
    return await this.preferences.has(key)
  }
}

export default PreferencesHelper.getInstance()