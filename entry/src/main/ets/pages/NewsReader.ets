import { common } from '@kit.AbilityKit'
import { webview } from '@kit.ArkWeb'
import { NewsCatalog, NewsLoadState } from '../models/NewsCatalog'
import { DesignTokens as T } from '../theme/DesignTokens'

interface NewsReaderParams {
  channelId?: string
}

// A fresh keyed Web after failure keeps old native callbacks out of the new attempt.
class ReaderView {
  id: number
  url: string
  controller: webview.WebviewController = new webview.WebviewController()
  downloads: webview.WebDownloadDelegate = new webview.WebDownloadDelegate()
  attached: boolean = false

  constructor(id: number, url: string) {
    this.id = id
    this.url = url
  }
}

@Entry
@Component
struct NewsReaderPage {
  @State title: string = '官方原文'
  @State channelId: string = ''
  @State currentUrl: string = ''
  @State loading: boolean = false
  @State error: string = ''
  @State openingBrowser: boolean = false
  @State views: ReaderView[] = []
  private load: NewsLoadState = new NewsLoadState()
  private generation: number = 0
  private timeout: number = -1
  private upgradeTimer: number = -1

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as NewsReaderParams | undefined
    const channel = NewsCatalog.channel(params?.channelId)
    if (!channel) {
      this.error = '频道无效，请返回资讯重新选择'
      return
    }
    this.channelId = channel.id
    this.title = channel.title
    this.open(channel.url)
  }

  aboutToDisappear(): void {
    this.disposeWeb()
  }

  private active(view: ReaderView): boolean {
    return view.id === this.generation && this.views.length > 0
  }

  private clearTimers(): void {
    if (this.timeout !== -1) clearTimeout(this.timeout)
    if (this.upgradeTimer !== -1) clearTimeout(this.upgradeTimer)
    this.timeout = -1
    this.upgradeTimer = -1
  }

  private disposeWeb(): void {
    this.clearTimers()
    this.generation++
    for (const view of this.views) {
      if (view.attached) {
        try { view.controller.stop() } catch (error) { /* Already detached. */ }
      }
    }
    this.views = []
  }

  private syncLoad(): void {
    this.loading = this.load.loading
    this.error = this.load.error
    this.currentUrl = this.load.url
  }

  private fail(message: string): void {
    this.load.fail(message)
    this.syncLoad()
    this.disposeWeb()
  }

  private begin(url: string): void {
    if (!this.load.begin(url, Date.now())) {
      this.fail(this.load.error)
      return
    }
    this.syncLoad()
    if (this.timeout === -1) {
      this.timeout = setTimeout(() => {
        this.timeout = -1
        if (this.load.expire(Date.now())) this.fail(this.load.error)
      }, NewsLoadState.timeoutMs)
    }
  }

  private open(url: string): void {
    const safe = NewsCatalog.externalUrl(this.channelId, url)
    if (!safe) return
    this.disposeWeb()
    this.load = new NewsLoadState()
    this.begin(safe)
    this.views = [new ReaderView(this.generation, safe)]
  }

  private refresh(): void {
    if (!this.channelId || this.loading) return
    if (this.views.length === 0) {
      this.open(this.currentUrl)
      return
    }
    const view = this.views[0]
    this.begin(this.currentUrl)
    try { view.controller.refresh() }
    catch (error) { this.fail('暂时无法刷新，请重试') }
  }

  // Applies to top-level and subframe navigation. Never dispatch a page-supplied scheme to the OS.
  private blockedNotice(message: string): void {
    // A rejected link must not destroy the already validated document or its back stack.
    try { this.getUIContext().getPromptAction().showToast({ message: message }) } catch (ignored) {}
  }

  private intercept(view: ReaderView, request: WebResourceRequest): boolean {
    if (!this.active(view)) return true
    const url = request.getRequestUrl()
    const safe = NewsCatalog.httpsUrl(url)
    if (!safe) {
      if (request.isMainFrame()) this.blockedNotice('此链接不在官方阅读范围内')
      return true
    }
    if (/^http:/i.test(url)) {
      if (request.isMainFrame()) {
        if (request.getRequestMethod() !== 'GET') {
          this.blockedNotice('已阻止不安全的表单请求')
          return true
        }
        this.begin(safe)
        if (this.upgradeTimer !== -1) clearTimeout(this.upgradeTimer)
        // Return cancellation first, then load a DIFFERENT, validated HTTPS URL.
        this.upgradeTimer = setTimeout(() => {
          this.upgradeTimer = -1
          if (!this.active(view)) return
          try { view.controller.loadUrl(safe) }
          catch (error) { this.fail('无法建立安全连接，请重试') }
        }, 0)
      }
      return true
    }
    return false
  }

  private goBackInWeb(): boolean {
    if (this.views.length === 0) return false
    const view = this.views[0]
    try {
      if (view.attached && view.controller.accessBackward()) {
        view.controller.backward()
        return true
      }
    } catch (error) { /* Router back remains available if Web has exited. */ }
    return false
  }

  onBackPress(): boolean {
    return this.goBackInWeb()
  }

  private back(): void {
    if (!this.goBackInWeb()) this.getUIContext().getRouter().back()
  }

  private async openBrowser(): Promise<void> {
    const safe = NewsCatalog.externalUrl(this.channelId, this.currentUrl)
    if (!safe || this.openingBrowser) return
    this.openingBrowser = true
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      // Only this native button invokes an external, browsable HTTPS intent.
      await context.startAbility({ action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'], uri: safe })
    } catch (error) {
      try { this.getUIContext().getPromptAction().showToast({ message: '未能打开浏览器，请确认已安装浏览器后重试' }) } catch (ignored) {}
    } finally {
      this.openingBrowser = false
    }
  }

  @Builder
  webContent(view: ReaderView) {
    Web({ src: view.url, controller: view.controller, incognitoMode: true })
      .width('100%').height('100%')
      // Publisher scripts may run; there is no injected script, proxy, message port or native JS bridge.
      .javaScriptAccess(true).fileAccess(false).domStorageAccess(false)
      .mixedMode(MixedMode.None).cacheMode(CacheMode.Online)
      .geolocationAccess(false).mediaPlayGestureAccess(true)
      .multiWindowAccess(false).allowWindowOpenMethod(false)
      .onControllerAttached(() => {
        if (this.active(view)) {
          view.attached = true
          try {
            view.downloads.onBeforeDownload((item: webview.WebDownloadItem) => { item.cancel() })
            view.controller.setDownloadDelegate(view.downloads)
          } catch (error) { this.fail('安全阅读初始化失败，请重试') }
        }
      })
      .onLoadIntercept((event) => this.intercept(view, event.data))
      .onOverrideUrlLoading((request) => this.intercept(view, request))
      .onInterceptRequest((event) => {
        const url = event.request.getRequestUrl()
        // Only HTTPS subresources (including the publisher's CDN) can load. Local resfile access
        // is rejected here too: SDK fileAccess(false) alone exempts packaged resfile resources.
        if (this.active(view) && /^https:\/\//i.test(url) &&
          (!event.request.isMainFrame() || NewsCatalog.httpsUrl(url) !== '')) return null
        const response = new WebResourceResponse()
        response.setResponseData('')
        response.setResponseCode(403)
        response.setReasonMessage('Blocked')
        response.setResponseMimeType('text/plain')
        response.setResponseEncoding('UTF-8')
        return response
      })
      .onPageBegin((event) => {
        if (this.active(view)) {
          if (!/^https:/i.test(event.url)) this.fail('已阻止不安全的连接')
          else this.begin(event.url)
        }
      })
      .onPageEnd((event) => {
        if (this.active(view) && this.load.finish(event.url)) {
          this.clearTimers()
          this.syncLoad()
        }
      })
      .onNavigationEntryCommitted((event) => {
        if (this.active(view) && event.isMainFrame) {
          const safe = NewsCatalog.httpsUrl(event.url)
          if (!safe || !/^https:/i.test(event.url)) this.fail('已阻止不安全的页面跳转')
          else if (event.isSameDocument) this.currentUrl = safe
        }
      })
      .onErrorReceive((event) => {
        if (this.active(view) && event.request.isMainFrame() && this.load.isCurrent(event.request.getRequestUrl())) {
          this.fail('原网站暂时无法连接，请检查网络后重试')
        }
      })
      .onHttpErrorReceive((event) => {
        if (this.active(view) && event.request.isMainFrame() && this.load.isCurrent(event.request.getRequestUrl())) {
          this.fail('原网站暂时无法提供此页面，请稍后重试')
        }
      })
      .onSslErrorEventReceive((event) => {
        event.handler.handleCancel()
        if (this.active(view)) this.fail('网站证书验证失败，已停止加载；不会忽略证书错误')
      })
      .onSslErrorEvent((event) => {
        event.handler.handleCancel()
        if (this.active(view) && event.isMainFrame) this.fail('网站证书验证失败，已停止加载；不会忽略证书错误')
      })
      .onPermissionRequest((event) => { event.request.deny() })
      .onScreenCaptureRequest((event) => { event.handler.deny() })
      .onGeolocationShow((event) => { event.geolocation.invoke(event.origin, false, false) })
      .onShowFileSelector((event) => { event.result.handleFileList([]); return true })
      .onContextMenuShow((event) => { event.result.closeContextMenu(); return true })
      .onDownloadStart(() => {
        if (this.active(view)) this.getUIContext().getPromptAction().showToast({ message: '在线阅读不支持下载' })
      })
      .onRenderExited(() => { if (this.active(view)) this.fail('阅读页面已退出，请重试') })
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.chevron_left')).width(23).height(23).fillColor(T.text)
        }.width(T.touch).height(T.touch).backgroundColor(Color.Transparent)
          .onClick(() => this.back()).accessibilityText('返回上一页')
        Text(this.title).fontSize(20).fontWeight(FontWeight.Medium).fontColor(T.text)
          .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.refresh')).width(22).height(22).fillColor(T.accent)
        }.width(T.touch).height(T.touch).backgroundColor(Color.Transparent)
          .enabled(this.channelId !== '' && !this.loading).onClick(() => this.refresh()).accessibilityText('刷新原网站')
      }.width('100%').padding({ left: 12, right: 12, top: 42, bottom: 8 })
      Column({ space: 4 }) {
        Text(this.channelId ? '来源：中国天气网 · 原网站在线阅读' : '未加载网站')
          .fontSize(12).fontColor(T.muted)
        if (this.currentUrl) {
          Text(NewsCatalog.origin(this.currentUrl)).fontSize(12).fontColor(T.accent)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }.width('100%').alignItems(HorizontalAlign.Start)
        .padding({ left: T.gutter, right: T.gutter, bottom: 14 })
      if (this.loading) {
        Row({ space: 10 }) {
          LoadingProgress().width(18).height(18).color(T.accent)
          Text('正在连接原网站…').fontSize(12).fontColor(T.muted)
        }.width('100%').padding({ left: T.gutter, right: T.gutter, top: 8, bottom: 12 })
      }
      Stack() {
        ForEach(this.views, (view: ReaderView) => { this.webContent(view) }, (view: ReaderView) => `${view.id}`)
        if (this.error) {
          Column({ space: 18 }) {
            Image($r('app.media.information_outline')).width(36).height(36).fillColor(T.accent)
            Text(this.channelId ? '暂时无法阅读' : '频道无法打开').fontSize(21).fontColor(T.text)
            Text(this.error).fontSize(14).fontColor(T.muted).lineHeight(23).textAlign(TextAlign.Center)
            if (this.channelId) {
              Button('重新加载', { type: ButtonType.Normal }).height(T.touch).borderRadius(14)
                .fontColor(T.page).backgroundColor(T.accent).onClick(() => this.open(this.currentUrl))
            }
            Button('返回资讯', { type: ButtonType.Normal }).height(T.touch).borderRadius(14)
              .fontColor(T.accent).backgroundColor(T.selected).onClick(() => this.getUIContext().getRouter().back())
          }.width('100%').padding(T.gutter)
        }
      }.width('100%').layoutWeight(1).clip(true)
      if (this.channelId) {
        Row() {
          Text('内容与更新以原站为准').fontSize(11).fontColor(T.muted).layoutWeight(1)
          Button('浏览器打开', { type: ButtonType.Normal }).height(T.touch).borderRadius(12)
            .fontSize(12).fontColor(T.accent).backgroundColor(Color.Transparent)
            .enabled(!this.openingBrowser).onClick(() => this.openBrowser())
            .accessibilityText('在外部浏览器打开当前官方网页')
        }.width('100%').padding({ left: T.gutter, right: 12, top: 4, bottom: 22 })
          .border({ width: { top: 0.5 }, color: T.border })
      }
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
