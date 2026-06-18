import { LifeIndex } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { lifeIconResource } from './WeatherIcon'

@Component
export struct LifeIndexGrid {
  @Prop lifeIndex: LifeIndex[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()

  build() {
    Column() {
      Text('生活指数')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textColor)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })

      Scroll() {
        Row() {
          ForEach(this.lifeIndex, (item: LifeIndex, index: number) => {
            Column() {
              Image(lifeIconResource(item.iconKey))
                .width(34)
                .height(34)
                .fillColor(index === 1 ? this.themeColors.warmAccent : this.themeColors.accent)

              Text(item.name)
                .fontSize(12)
                .fontColor(this.themeColors.textSecondary)
                .margin({ top: 10 })

              Text(item.brief)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textColor)
                .margin({ top: 4 })
                .maxLines(1)
            }
            .width(92)
            .height(116)
            .justifyContent(FlexAlign.Center)
            .border({ width: { right: index < this.lifeIndex.length - 1 ? 1 : 0 }, color: this.themeColors.divider })
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: `${item.name}：${item.detail}`, duration: 2200 })
            })
            .accessibilityText(`${item.name}${item.brief}，${item.detail}`)
          }, (item: LifeIndex, index: number) => `${index}_${item.name}`)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ top: 20, bottom: 18 })
  }
}
