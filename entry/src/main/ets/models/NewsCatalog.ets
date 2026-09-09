export class NewsChannel {
  id: string
  title: string
  description: string
  source: string = '中国天气网'
  url: string

  constructor(id: string, title: string, description: string, url: string) {
    this.id = id
    this.title = title
    this.description = description
    this.url = url
  }
}

// Fixed channel entry points, verified in the publisher's navigation. No article data is bundled.
export class NewsCatalog {
  static channels(): NewsChannel[] {
    return [
      new NewsChannel('news', '天气新闻', '关注天气变化与气象动态', 'https://m.weather.com.cn/news/index.shtml'),
      new NewsChannel('science', '气象科普', '认识天气现象，了解防灾知识', 'https://m.weather.com.cn/news/kp.shtml')
    ]
  }

  static channel(id: string | undefined): NewsChannel | null {
    if (typeof id !== 'string') return null
    const channels = NewsCatalog.channels()
    for (const channel of channels) {
      if (channel.id === id) return channel
    }
    return null
  }

  // Deliberately narrow absolute-URL grammar, not a substring or suffix allowlist.
  // Reject parser-normalized credentials, encoded authorities, backslashes, controls and odd ports.
  // Legacy HTTP article links are upgraded before Web is allowed to navigate.
  static httpsUrl(value: string): string {
    if (typeof value !== 'string' || /[\s\x00-\x1f\x7f\\]/.test(value) ||
      /%(?:0[0-9a-f]|1[0-9a-f]|7f|5c)/i.test(value) || /%(?![0-9a-f]{2})/i.test(value)) return ''
    const match = /^(https?):\/\/(news\.weather\.com\.cn|www\.weather\.com\.cn|m\.weather\.com\.cn)(?::([0-9]+))?([/?#].*)?$/i.exec(value)
    if (!match) return ''
    const scheme = match[1].toLowerCase()
    const port = match[3]
    if (port && port !== (scheme === 'https' ? '443' : '80')) return ''
    const suffix = match[4] || '/'
    return `https://${match[2].toLowerCase()}${suffix.startsWith('/') ? '' : '/'}${suffix}`
  }

  static origin(value: string): string {
    const safe = NewsCatalog.httpsUrl(value)
    return safe ? safe.substring(0, safe.indexOf('/', 8)) : ''
  }

  static externalUrl(channelId: string | undefined, currentUrl: string): string {
    const channel = NewsCatalog.channel(channelId)
    return channel ? NewsCatalog.httpsUrl(currentUrl) || channel.url : ''
  }
}

// Pure load state is exercised by the Node harness; the page owns controller effects and timers.
export class NewsLoadState {
  static readonly timeoutMs: number = 20000
  url: string = ''
  loading: boolean = false
  error: string = ''
  private startedAt: number = 0

  begin(value: string, now: number): boolean {
    const safe = NewsCatalog.httpsUrl(value)
    if (!safe) {
      this.url = ''
      this.fail('此链接不在官方阅读范围内')
      return false
    }
    // Redirects are part of the same load; they must not extend the 20-second deadline.
    if (!this.loading) this.startedAt = now
    this.url = safe
    this.error = ''
    this.loading = true
    return true
  }

  isCurrent(value: string): boolean {
    const safe = NewsCatalog.httpsUrl(value)
    return safe !== '' && safe.split('#')[0] === this.url.split('#')[0]
  }

  finish(value: string): boolean {
    if (!this.loading || !this.isCurrent(value)) return false
    this.loading = false
    return true
  }

  fail(message: string): void {
    this.loading = false
    this.error = message
  }

  expire(now: number): boolean {
    if (!this.loading || now - this.startedAt < NewsLoadState.timeoutMs) return false
    this.fail('加载已超过 20 秒，请检查网络后重试')
    return true
  }
}
