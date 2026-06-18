export function weatherIconResource(text: string): Resource {
  if (text.includes('雷')) return $r('app.media.weather_lightning')
  if (text.includes('雨')) return $r('app.media.weather_rainy')
  if (text.includes('雪')) return $r('app.media.weather_snowy')
  if (text.includes('雾') || text.includes('霾') || text.includes('沙')) return $r('app.media.weather_fog')
  if (text.includes('多云')) return $r('app.media.weather_partly_cloudy')
  if (text.includes('阴')) return $r('app.media.weather_cloudy')
  return $r('app.media.weather_sunny')
}

export function weatherIconColor(text: string, fallback: string): string {
  if (text.includes('晴') || text.includes('多云')) return '#FFD052'
  if (text.includes('雷')) return '#E5C7FF'
  if (text.includes('雨')) return '#A9E1FF'
  if (text.includes('雪')) return '#FFFFFF'
  return fallback
}

export function lifeIconResource(key: string): Resource {
  if (key === 'clothing') return $r('app.media.tshirt')
  if (key === 'uv') return $r('app.media.weather_sunny')
  if (key === 'car') return $r('app.media.car_wash')
  if (key === 'cold') return $r('app.media.medical_bag')
  if (key === 'sport') return $r('app.media.run_fast')
  if (key === 'travel') return $r('app.media.map_marker')
  return $r('app.media.information_outline')
}

@Component
export struct WeatherIcon {
  @Prop text: string = '晴'
  @Prop iconSize: number = 28
  @Prop fallbackColor: string = '#FFFFFF'

  build() {
    Image(weatherIconResource(this.text))
      .width(this.iconSize)
      .height(this.iconSize)
      .fillColor(weatherIconColor(this.text, this.fallbackColor))
      .objectFit(ImageFit.Contain)
      .accessibilityText(`${this.text}天气`)
  }
}
