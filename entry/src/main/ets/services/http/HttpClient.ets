/**
 * HTTP 客户端封装
 * 对标 Android 的 Retrofit + OkHttp
 */

import http from '@ohos.net.http'
import { ApiConstants } from '../../common/Constants.ets'
import { getLogger } from '../../utils/Logger.ets'
import PreferencesHelper from '../../utils/PreferencesHelper.ets'
import { StorageKeys } from '../../common/Constants.ets'

const logger = getLogger('HttpClient')

export interface HttpRequestOptions {
  url: string
  method: http.RequestMethod
  headers?: Record<string, string>
  body?: string | Object
}

export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

class HttpClient {
  private static instance: HttpClient

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient()
    }
    return HttpClient.instance
  }

  async request<T>(options: HttpRequestOptions): Promise<ApiResponse<T>> {
    const fullUrl = options.url.startsWith('http') ? options.url : ApiConstants.BASE_URL + options.url

    logger.info(`HTTP Request: ${options.method} ${fullUrl}`)

    let httpRequest = http.createHttp()
    try {
      // 获取 Token
      const token = await PreferencesHelper.getString(StorageKeys.TOKEN, '')

      // 构建 headers
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      }
      if (options.headers) {
        Object.keys(options.headers).forEach((key: string) => {
          headers[key] = options.headers![key]
        })
      }

      if (token) {
        headers['Authorization'] = `Bearer ${token}`
      }

      // 发送请求
      const result = await httpRequest.request(fullUrl, {
        method: options.method,
        header: headers,
        extraData: options.body ? JSON.stringify(options.body) : undefined,
        connectTimeout: ApiConstants.CONNECT_TIMEOUT,
        readTimeout: ApiConstants.READ_TIMEOUT
      })

      // 解析响应
      const response = JSON.parse(result.result as string) as ApiResponse<T>
      logger.info(`HTTP Response: ${JSON.stringify(response)}`)

      return response
    } catch (error) {
      logger.error(`HTTP Error: ${JSON.stringify(error)}`)
      throw new Error(error instanceof Error ? error.message : 'HTTP request failed')
    } finally {
      httpRequest.destroy()
    }
  }

  get<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.GET,
      headers
    })
  }

  post<T>(url: string, body?: Object, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.POST,
      body,
      headers
    })
  }

  put<T>(url: string, body?: Object, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.PUT,
      body,
      headers
    })
  }

  delete<T>(url: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>({
      url,
      method: http.RequestMethod.DELETE,
      headers
    })
  }
}

export default HttpClient.getInstance()