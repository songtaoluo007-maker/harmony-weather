export function weatherIconResource(text: string): Resource {
  if (text.includes('雷')) return $r('app.media.meteo_thunderstorms_rain')
  if (text.includes('雨')) return $r('app.media.meteo_rain')
  if (text.includes('雪')) return $r('app.media.meteo_snow')
  if (text.includes('雾') || text.includes('霾') || text.includes('沙')) return $r('app.media.meteo_fog')
  if (text.includes('多云')) return $r('app.media.meteo_partly_cloudy_day')
  if (text.includes('阴')) return $r('app.media.meteo_cloudy')
  return $r('app.media.meteo_clear_day')
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
  @Prop isNight: boolean = false

  private icon(): Resource {
    if (this.isNight && this.text.includes('多云')) return $r('app.media.meteo_partly_cloudy_night')
    if (this.isNight && this.text.includes('晴')) return $r('app.media.meteo_clear_night')
    return weatherIconResource(this.text)
  }

  build() {
    Image(this.icon())
      .width(this.iconSize * 1.25)
      .height(this.iconSize * 1.25)
      .objectFit(ImageFit.Contain)
      .accessibilityText(`${this.text}天气`)
  }
}
