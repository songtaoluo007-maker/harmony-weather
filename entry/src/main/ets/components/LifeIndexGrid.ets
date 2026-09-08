import { LifeIndex } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { AtmosphereTokens as A } from '../theme/AtmosphereTokens'
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

  private isUnavailable(item: LifeIndex): boolean {
    return item.brief === '暂无数据'
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('生活气象').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
      }.width('100%')
      Row({ space: 12 }) {
        ForEach(this.featured(), (item: LifeIndex) => {
          Button({ type: ButtonType.Normal }) {
            Column() {
              Stack() {
                Image(this.illustration(item.iconKey))
                  .width('100%').height('100%').objectFit(ImageFit.Contain)
                  .opacity(this.isUnavailable(item) ? 0.60 : 1)
                  .accessibilityLevel('no')
                Row() {}
                  .width('100%').height('100%')
                  .linearGradient({
                    direction: GradientDirection.Bottom,
                    colors: [['rgba(20,43,61,0)', 0.58], ['rgba(20,43,61,0.35)', 0.82], ['#142B3D', 1]]
                  })
                  .hitTestBehavior(HitTestMode.None)
                  .accessibilityLevel('no')
              }
              .width('100%').aspectRatio(1)
              Column({ space: 6 }) {
                Text(item.name).fontSize(12).fontColor(this.themeColors.textSecondary)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.brief).fontSize(16).fontWeight(FontWeight.Medium)
                  .fontColor(this.isUnavailable(item) ? this.themeColors.textTertiary : this.themeColors.textColor)
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Start)
                  .constraintSize({ minHeight: '42fp' }).align(Alignment.TopStart)
              }
              .width('100%').constraintSize({ minHeight: 72 })
              .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
              .padding({ left: 12, right: 12, top: 2, bottom: 16 })
              .linearGradient({
                direction: GradientDirection.Bottom,
                colors: [[Color.Transparent, 0], [A.panelTop, 1]]
              })
            }.width('100%').borderRadius(22).clip(true)
          }
          .layoutWeight(1).constraintSize({ minWidth: 44, minHeight: 44 }).padding(0)
          .backgroundColor('#142B3D').borderRadius(22).clip(true)
          .border({ width: 0.75, color: A.border, radius: 22 })
          .stateEffect(true)
          .onClick(() => this.showDetail(item))
          .accessibilityGroup(true)
          .accessibilityText(`${item.name}，${item.brief}，点击查看建议`)
        }, (item: LifeIndex) => JSON.stringify(item))
      }.width('100%').alignItems(VerticalAlign.Top)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.remaining(), (item: LifeIndex, index: number) => {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 10 }) {
              Stack() {
                Image(lifeIconResource(item.iconKey)).width(16).height(16)
                  .fillColor(this.isUnavailable(item) ? this.themeColors.textTertiary :
                    (item.iconKey === 'temperature' ? A.gold : A.teal))
                  .opacity(this.isUnavailable(item) ? 0.68 : 0.90)
                  .accessibilityLevel('no')
              }
              .width(28).height(28).borderRadius(14).flexShrink(0)
              .backgroundColor(this.isUnavailable(item) ? this.themeColors.sectionTint : 'rgba(166,216,212,0.10)')
              Column({ space: 4 }) {
                Text(item.name).fontSize(12).fontColor(this.themeColors.textSecondary)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.brief).fontSize(16).fontWeight(FontWeight.Medium)
                  .fontColor(this.isUnavailable(item) ? this.themeColors.textTertiary : this.themeColors.textColor)
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ minHeight: '38fp' }).align(Alignment.TopStart)
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            }.width('100%')
          }
          .width('50%').constraintSize({ minHeight: 68 })
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(Color.Transparent).borderRadius(0)
          .border({ width: { left: index % 2 === 1 ? 0.5 : 0, top: index > 1 ? 0.5 : 0 }, color: A.border })
          .stateEffect(true)
          .onClick(() => this.showDetail(item))
          .accessibilityGroup(true)
          .accessibilityText(`${item.name}，${item.brief}，点击查看建议`)
        }, (item: LifeIndex) => JSON.stringify(item))
      }
      .width('100%').padding({ left: 6, right: 6, top: 4, bottom: 4 })
      .linearGradient({ direction: GradientDirection.Bottom, colors: [[A.panelTop, 0], [A.panelBottom, 1]] })
      .border({ width: 0.5, color: A.border }).borderRadius(A.radius).clip(true)
    }
    .width('100%').padding({ top: 24, bottom: 16 })
    .border({ width: { bottom: 0.5 }, color: this.themeColors.divider })
  }
}
