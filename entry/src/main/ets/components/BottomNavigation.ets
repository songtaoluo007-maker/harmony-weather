import { DesignTokens as T } from '../theme/DesignTokens'

@Component
export struct BottomNavigation {
  @Prop selected: string = 'weather'
  @State navigating: boolean = false

  private async open(key: string, route: string): Promise<void> {
    if (this.selected === key || this.navigating) return
    this.navigating = true
    try { await this.getUIContext().getRouter().replaceUrl({ url: route }) }
    catch (error) {
      try { this.getUIContext().getPromptAction().showToast({ message: '页面暂时无法打开，请重试' }) } catch (ignored) {}
    }
    finally { this.navigating = false }
  }

  @Builder
  item(label: string, key: string, route: string, icon: Resource) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 5 }) {
        Image(icon).width(22).height(22).fillColor(this.selected === key ? T.accent : T.muted)
        Text(label).fontSize(11).fontWeight(this.selected === key ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.selected === key ? T.accent : T.muted)
      }.width('100%').padding({ top: 10, bottom: 8 })
    }.layoutWeight(1).height(58).borderRadius(16).backgroundColor(Color.Transparent)
      .enabled(!this.navigating).onClick(() => this.open(key, route))
      .accessibilityText(`${label}，${this.selected === key ? '已选择' : '未选择'}`)
  }

  build() {
    Row() {
      this.item('天气', 'weather', 'pages/Index', $r('app.media.weather_partly_cloudy'))
      this.item('资讯', 'news', 'pages/News', $r('app.media.newspaper'))
      this.item('设置', 'settings', 'pages/Settings', $r('app.media.cog'))
    }.width('100%').padding({ left: 30, right: 30, bottom: 22, top: 2 })
      .backgroundColor(T.page).border({ width: { top: 0.5 }, color: T.border })
  }
}
