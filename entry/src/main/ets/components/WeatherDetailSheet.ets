import { WeatherDetailContent, WeatherDetailRow } from '../models/WeatherDetailPresentation'
import { AtmospherePalette, AtmosphereTokens as A } from '../theme/AtmosphereTokens'
import { lifeIconResource } from './WeatherIcon'

@Component
export struct WeatherDetailSheet {
  @Prop content: WeatherDetailContent = new WeatherDetailContent()
  @Prop palette: AtmospherePalette = new AtmospherePalette()
  onClose: () => void = () => {}

  build() {
    Column({ space: 0 }) {
      Row({ space: 12 }) {
        Column({ space: 5 }) {
          Text(this.content.title).fontSize(23).fontWeight(FontWeight.Medium).fontColor(A.ivory)
          Text(this.content.subtitle).fontSize(12).fontColor('#B6C9D1')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.close')).width(18).height(18).fillColor(A.ivory).accessibilityLevel('no')
        }.width(44).height(44).backgroundColor(this.palette.panelTop)
          .onClick(() => this.onClose()).accessibilityText('关闭详情')
      }.width('100%').padding({ left: 24, right: 20, top: 8, bottom: 18 })
      Divider().color(this.palette.border).strokeWidth(.5)
      Scroll() {
        Column({ space: 22 }) {
          Row({ space: 16 }) {
            if (this.content.iconKey) {
              Image(lifeIconResource(this.content.iconKey)).width(30).height(30)
                .fillColor(this.palette.accent).accessibilityLevel('no')
            }
            Text(this.content.headline).fontSize(32).fontWeight(300).fontColor(A.ivory)
              .layoutWeight(1)
          }.width('100%')
          if (this.content.context) {
            Text(this.content.context).fontSize(15).fontColor('#D0DDE1').lineHeight(25)
              .width('100%')
          }
          if (this.content.rows.length > 0 && this.content.layout === 'metrics') {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.content.rows, (item: WeatherDetailRow) => {
                Column({ space: 8 }) {
                  Text(item.label).fontSize(12).fontColor(this.palette.accent)
                  Text(item.value).fontSize(18).fontWeight(300).fontColor(A.ivory)
                  Text(item.unit).fontSize(11).fontColor('#A6BEC9')
                }.width('50%').alignItems(HorizontalAlign.Start)
                  .padding({ top: 14, bottom: 14, right: 12 })
                  .border({ width: { bottom: .5 }, color: this.palette.border })
                  .accessibilityGroup(true).accessibilityText(`${item.label}，${item.value} ${item.unit}`)
              }, (item: WeatherDetailRow) => `${item.label}:${item.value}`)
            }.width('100%')
          } else if (this.content.rows.length > 0) {
            Column({ space: 0 }) {
              ForEach(this.content.rows, (item: WeatherDetailRow) => {
                Column({ space: 7 }) {
                  Text(item.label).fontSize(12).fontColor(this.palette.accent)
                  Text(item.value).fontSize(18).fontColor(A.ivory)
                }.width('100%').alignItems(HorizontalAlign.Start)
                  .padding({ top: 14, bottom: 14 })
                  .border({ width: { bottom: .5 }, color: this.palette.border })
                  .accessibilityGroup(true).accessibilityText(`${item.label}，${item.value}`)
              }, (item: WeatherDetailRow) => `${item.label}:${item.value}`)
            }.width('100%')
          }
          Text(this.content.metadata).fontSize(12).fontColor('#A6BEC9').lineHeight(21)
            .width('100%')
        }.width('100%').padding({ left: 24, right: 24, top: 24, bottom: 36 })
      }.width('100%').layoutWeight(1).align(Alignment.TopStart)
        .scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None)
    }.width('100%').height('100%')
      .linearGradient({ angle: 150, colors: [[this.palette.panelTop, 0], [Color.Transparent, .65]] })
  }
}
