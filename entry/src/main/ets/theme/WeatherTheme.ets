import { TimeOfDay, WeatherVisualState } from '../models/WeatherModels'

export class ThemeColors {
  textColor: string = '#FFFFFF'
  textSecondary: string = 'rgba(255,255,255,0.80)'
  textTertiary: string = 'rgba(255,255,255,0.66)'
  pageBackground: string = '#103B55'
  skyTop: string = '#3D7DA9'
  sectionTint: string = 'rgba(255,255,255,0.06)'
  strongTint: string = 'rgba(4,47,82,0.34)'
  divider: string = 'rgba(255,255,255,0.16)'
  scrimTop: string = 'rgba(0,38,72,0.08)'
  scrimBottom: string = 'rgba(0,38,72,0.52)'
  accent: string = '#55C7FF'
  warmAccent: string = '#FFB63D'
  success: string = '#6EE787'
  warning: string = '#FF745E'
  isLight: boolean = false
}

export class WeatherTheme {
  static getColors(state: WeatherVisualState, isNight: boolean = false): ThemeColors {
    const colors: ThemeColors = new ThemeColors()
    if (isNight || state === WeatherVisualState.CLEAR_NIGHT || state === WeatherVisualState.CLOUDY_NIGHT) {
      colors.pageBackground = '#081522'
      colors.skyTop = '#071323'
      colors.scrimTop = 'rgba(0,8,20,0.04)'
      colors.scrimBottom = '#081522'
      return colors
    }
    if (state === WeatherVisualState.HAZE || state === WeatherVisualState.SNOW) {
      colors.pageBackground = '#293C45'
      colors.skyTop = '#677E86'
      colors.scrimTop = 'rgba(24,43,54,0.30)'
      colors.scrimBottom = '#293C45'
      return colors
    }
    if (state === WeatherVisualState.RAIN || state === WeatherVisualState.STORM) {
      colors.sectionTint = 'rgba(8,29,62,0.20)'
      colors.pageBackground = '#234558'
      colors.skyTop = state === WeatherVisualState.STORM ? '#475E73' : '#718D9F'
      colors.strongTint = 'rgba(5,22,50,0.56)'
      colors.scrimTop = 'rgba(3,18,48,0.12)'
      colors.scrimBottom = 'rgba(3,18,48,0.76)'
      colors.accent = '#62D2FF'
      return colors
    }
    return colors
  }

  static getTimeOfDay(hour: number): TimeOfDay {
    if (hour >= 5 && hour < 7) return TimeOfDay.DAWN
    if (hour >= 7 && hour < 17) return TimeOfDay.DAY
    if (hour >= 17 && hour < 19) return TimeOfDay.DUSK
    return TimeOfDay.NIGHT
  }

  static getBackgroundResource(state: WeatherVisualState, hour: number, isNight: boolean = false): Resource {
    if (isNight) return $r('app.media.weather_bg_night')
    if (state === WeatherVisualState.RAIN || state === WeatherVisualState.STORM) {
      return $r('app.media.weather_bg_rain')
    }
    if (state === WeatherVisualState.HAZE || state === WeatherVisualState.SNOW) {
      return $r('app.media.weather_bg_fog')
    }
    if (state === WeatherVisualState.CLEAR_NIGHT || state === WeatherVisualState.CLOUDY_NIGHT) {
      return $r('app.media.weather_bg_night')
    }
    if (hour >= 17 && hour < 20) {
      return $r('app.media.weather_bg_dusk')
    }
    return $r('app.media.weather_bg_day')
  }

  static getWeatherOverlay(state: WeatherVisualState, hour: number, isNight: boolean = false): string {
    if (isNight) return 'rgba(3,12,25,0.08)'
    if (state === WeatherVisualState.STORM) return 'rgba(40,53,71,0.32)'
    if (state === WeatherVisualState.RAIN) return 'rgba(110,134,148,0.18)'
    if (state === WeatherVisualState.HAZE) return 'rgba(224,231,229,0.36)'
    if (state === WeatherVisualState.SNOW) return 'rgba(233,242,248,0.28)'
    if (state === WeatherVisualState.CLEAR_NIGHT) return 'rgba(4,18,48,0.08)'
    if (state === WeatherVisualState.CLOUDY_NIGHT) return 'rgba(7,23,48,0.10)'
    if (state === WeatherVisualState.CLOUDY_DAY) return 'rgba(69,91,105,0.20)'
    if (hour >= 17 && hour < 20) return 'rgba(92,45,20,0.12)'
    return 'rgba(16,83,128,0.08)'
  }

  static shouldShowCloudLayer(state: WeatherVisualState): boolean {
    return state !== WeatherVisualState.HAZE && state !== WeatherVisualState.SNOW
  }

  static getCloudOpacity(state: WeatherVisualState): number {
    if (state === WeatherVisualState.STORM) return 0.34
    if (state === WeatherVisualState.RAIN) return 0.27
    if (state === WeatherVisualState.CLOUDY_DAY || state === WeatherVisualState.CLOUDY_NIGHT) return 0.22
    return state === WeatherVisualState.CLEAR_NIGHT ? 0.07 : 0.12
  }

  static shouldShowRainLayer(state: WeatherVisualState): boolean {
    return state === WeatherVisualState.RAIN || state === WeatherVisualState.STORM
  }

  static getBackgroundBrightness(state: WeatherVisualState, isNight: boolean = false): number {
    if (isNight || state === WeatherVisualState.CLEAR_NIGHT || state === WeatherVisualState.CLOUDY_NIGHT) return 1.10
    if (state === WeatherVisualState.STORM) return 0.72
    if (state === WeatherVisualState.RAIN) return 0.84
    if (state === WeatherVisualState.HAZE) return 1.04
    return 1.16
  }
}
