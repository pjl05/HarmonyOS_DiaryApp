/**
 * SimpleStorage - 轻量级内存存储替代 AppStorageV2
 * 用于跨组件状态共享
 * 使用模块级单例避免 ArkTS 静态方法中的 this 问题
 */

// Module-level singleton - no class, no this in static context
const storageData: Map<string, Object> = new Map()

export function storageGet(key: string): Object | undefined {
  return storageData.get(key)
}

export function storageSet(key: string, value: Object | null | undefined): void {
  storageData.set(key, value as Object)
}

export function storageRemove(key: string): void {
  storageData.delete(key)
}

export function storageHas(key: string): boolean {
  return storageData.has(key)
}

export function storageClear(): void {
  storageData.clear()
}

// Backwards compatibility wrapper - deprecated, use storageGet/storageSet instead
export class SimpleStorage {
  static get<T>(key: string): T | undefined {
    return storageData.get(key) as T | undefined
  }

  static set<T>(key: string, value: T): void {
    storageData.set(key, value as Object)
  }

  static setOrCreate<T>(key: string, value: T): void {
    storageData.set(key, value as Object)
  }

  static remove(key: string): void {
    storageData.delete(key)
  }

  static has(key: string): boolean {
    return storageData.has(key)
  }

  static clear(): void {
    storageData.clear()
  }
}