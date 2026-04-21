/**
 * 日志工具类
 * 对标 Android 的 Log 工具
 */

const TAG_PREFIX = 'DiaryApp_'

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

class Logger {
  private static logLevel: LogLevel = LogLevel.DEBUG
  private tag: string = ''

  constructor(tag: string) {
    this.tag = TAG_PREFIX + tag
  }

  static setLogLevel(level: LogLevel): void {
    Logger.logLevel = level
  }

  debug(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.DEBUG) {
      console.debug(this.formatMessage(message, args))
    }
  }

  info(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.INFO) {
      console.info(this.formatMessage(message, args))
    }
  }

  warn(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.WARN) {
      console.warn(this.formatMessage(message, args))
    }
  }

  error(message: string, ...args: Object[]): void {
    if (Logger.logLevel <= LogLevel.ERROR) {
      console.error(this.formatMessage(message, args))
    }
  }

  private formatMessage(message: string, args: Object[]): string {
    if (args.length === 0) {
      return `[${this.tag}] ${message}`
    }
    return `[${this.tag}] ${message} ${JSON.stringify(args)}`
  }
}

export function getLogger(tag: string): Logger {
  return new Logger(tag)
}

export default Logger