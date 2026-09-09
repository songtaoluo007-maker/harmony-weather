import { DesignTokens as T } from '../theme/DesignTokens'

@Component
export struct PageHeader {
  @Prop heading: string = ''
  build() {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.chevron_left')).width(23).height(23).fillColor(T.text)
      }.width(44).height(44).backgroundColor(Color.Transparent)
        .onClick(() => this.getUIContext().getRouter().back()).accessibilityText('返回')
      Text(this.heading).fontSize(22).fontWeight(FontWeight.Medium).fontColor(T.text).layoutWeight(1)
    }.width('100%').padding({ left: 12, right: 24, top: 42, bottom: 18 })
  }
}
