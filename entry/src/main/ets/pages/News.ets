import { BottomNavigation } from '../components/BottomNavigation'
import { NewsCatalog, NewsChannel } from '../models/NewsCatalog'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct NewsPage {
  @State opening: boolean = false
  private channels: NewsChannel[] = NewsCatalog.channels()

  onBackPress(): boolean {
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '暂时无法返回天气，请重试' })
    })
    return true
  }

  private async openChannel(id: string): Promise<void> {
    if (this.opening || !NewsCatalog.channel(id)) return
    this.opening = true
    try {
      await this.getUIContext().getRouter().pushUrl({ url: 'pages/NewsReader', params: { channelId: id } })
    } catch (error) {
      try { this.getUIContext().getPromptAction().showToast({ message: '频道暂时无法打开，请重试' }) } catch (ignored) {}
    } finally {
      this.opening = false
    }
  }

  @Builder
  channelCard(channel: NewsChannel) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 18 }) {
        Row() {
          Image(channel.id === 'news' ? $r('app.media.newspaper') : $r('app.media.weather_sunny'))
            .width(28).height(28).fillColor(T.accent)
          Blank()
          Text(channel.id === 'news' ? '新闻' : '科普').fontSize(12).fontColor(T.accent)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 }).backgroundColor(T.selected).borderRadius(12)
        }.width('100%')
        Column({ space: 8 }) {
          Text(channel.title).fontSize(23).fontWeight(FontWeight.Medium).fontColor(T.text)
          Text(channel.description).fontSize(13).fontColor(T.muted).lineHeight(20)
        }.width('100%').alignItems(HorizontalAlign.Start)
        Row({ space: 8 }) {
          Text(`${channel.source} · 官方原文`).fontSize(12).fontColor(T.muted).layoutWeight(1)
          Text('在线阅读').fontSize(12).fontColor(T.accent)
          Image($r('app.media.chevron_right')).width(17).height(17).fillColor(T.accent)
        }.width('100%')
      }.width('100%').padding(22).alignItems(HorizontalAlign.Start)
    }.width('100%').backgroundColor(T.surface).borderRadius(T.radius)
      .enabled(!this.opening).onClick(() => this.openChannel(channel.id))
      .accessibilityText(`${channel.title}，${channel.source}，打开官方原网站在线阅读`)
  }

  build() {
    Column() {
      Column({ space: 9 }) {
        Text('资讯').fontSize(30).fontWeight(FontWeight.Medium).fontColor(T.text)
        Text('天气之外，多一分了解').fontSize(14).fontColor(T.muted)
      }.width('100%').alignItems(HorizontalAlign.Start)
        .padding({ left: T.gutter, right: T.gutter, top: 52, bottom: 26 })
      Scroll() {
        Column({ space: 16 }) {
          ForEach(this.channels, (channel: NewsChannel) => { this.channelCard(channel) },
            (channel: NewsChannel) => channel.id)
        }.width('100%').padding({ left: T.gutter, right: T.gutter, bottom: 20 })
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
      BottomNavigation({ selected: 'news' })
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
