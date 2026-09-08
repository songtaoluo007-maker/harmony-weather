import { LifeIndex } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { lifeIconResource } from './WeatherIcon'

@Component
export struct LifeIndexGrid {
  @Prop lifeIndex: LifeIndex[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()

  private featured(): LifeIndex[] {
    return this.lifeIndex.filter((item: LifeIndex) =>
      item.iconKey === 'clothing' || item.iconKey === 'uv' || item.iconKey === 'sport')
  }

  private remaining(): LifeIndex[] {
    return this.lifeIndex.filter((item: LifeIndex) =>
      item.iconKey !== 'clothing' && item.iconKey !== 'uv' && item.iconKey !== 'sport')
  }

  private illustration(key: string): Resource {
    if (key === 'clothing') return $r('app.media.life_clothing')
    if (key === 'uv') return $r('app.media.life_uv')
    return $r('app.media.life_sport')
  }

  private showDetail(item: LifeIndex): void {
    this.getUIContext().showAlertDialog({
      title: `${item.name} · ${item.brief}`, message: item.detail,
      confirm: { value: '知道了', action: () => {} }
    })
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('生活气象').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
        Blank()
        Text('从天气，到生活').fontSize(11).fontColor(this.themeColors.textTertiary)
      }.width('100%')
      Row({ space: 8 }) {
        ForEach(this.featured(), (item: LifeIndex) => {
          Column({ space: 4 }) {
            Image(this.illustration(item.iconKey)).width('100%').aspectRatio(1).objectFit(ImageFit.Contain)
            Text(item.name).fontSize(11).fontColor(this.themeColors.textSecondary)
            Text(item.brief).fontSize(15).fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textColor).maxLines(2).textAlign(TextAlign.Center)
          }
          .layoutWeight(1).padding({ bottom: 16 })
          .backgroundColor('#142B3D').borderRadius(20).clip(true)
          .onClick(() => this.showDetail(item))
          .accessibilityText(`${item.name}，${item.brief}，点击查看建议`)
        }, (item: LifeIndex) => JSON.stringify(item))
      }.width('100%').alignItems(VerticalAlign.Top)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.remaining(), (item: LifeIndex) => {
          Row({ space: 10 }) {
            Image(lifeIconResource(item.iconKey)).width(24).height(24).fillColor(this.themeColors.accent)
            Column({ space: 4 }) {
              Text(item.name).fontSize(11).fontColor(this.themeColors.textSecondary)
              Text(item.brief).fontSize(14).fontColor(this.themeColors.textColor)
            }.alignItems(HorizontalAlign.Start)
          }
          .width('50%').constraintSize({ minHeight: 64 })
          .onClick(() => this.showDetail(item))
          .accessibilityText(`${item.name}，${item.brief}，点击查看建议`)
        }, (item: LifeIndex) => JSON.stringify(item))
      }.width('100%')
    }
    .width('100%').padding({ top: 24, bottom: 16 })
    .border({ width: { bottom: 0.5 }, color: this.themeColors.divider })
  }
}
