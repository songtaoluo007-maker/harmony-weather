/** Structural first-load placeholder: no temperature or forecast is fabricated. */
@Component
export struct WeatherSkeleton {
  @Builder
  bar(width: Length, height: number, radius: number = 8) {
    Column().width(width).height(height).borderRadius(radius).backgroundColor('rgba(198,225,239,0.10)')
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Row() {
          this.bar(84, 27)
          Blank()
          this.bar(36, 36, 18)
          this.bar(36, 36, 18)
        }.width('100%').margin({ top: 42 })
        Row({ space: 9 }) {
          LoadingProgress().width(16).height(16).color('#AADCE9')
          Text('正在获取天气').fontSize(12).fontColor('#C4D7E4')
        }.width('100%').accessibilityText('天气加载中，请稍候')
        Column({ space: 20 }) {
          this.bar('50%', 112, 18)
          this.bar('40%', 28)
          this.bar('65%', 16)
        }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 30, bottom: 30 })
        this.bar('32%', 20)
        Row({ space: 8 }) {
          ForEach([0, 1, 2, 3, 4], () => {
            Column({ space: 16 }) {
              this.bar('60%', 12)
              this.bar(24, 24, 12)
              this.bar('65%', 18)
            }.layoutWeight(1).padding({ top: 14, bottom: 14 }).borderRadius(18)
              .backgroundColor('rgba(198,225,239,0.045)')
          })
        }.width('100%')
        this.bar('100%', 170, 20)
        Row({ space: 12 }) {
          Column() { this.bar('100%', 112, 20) }.layoutWeight(1)
          Column() { this.bar('100%', 112, 20) }.layoutWeight(1)
        }.width('100%')
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 24, right: 24, bottom: 30 })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor('#102333')
  }
}
