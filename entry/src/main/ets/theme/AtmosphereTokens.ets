import { WeatherData, WeatherVisualState } from '../models/WeatherModels'
import { ThemeColors } from './WeatherTheme'

export class AtmospherePalette {
  key: string
  panelTop: string
  panelBottom: string
  border: string
  wash: string
  accent: string
  warm: string
  isLight: boolean
  page: string
  text: string
  secondary: string
  muted: string
  track: string
  illustrationBase: string
  illustrationClear: string
  illustrationShade: string
  sheetBackground: string

  constructor(key: string = 'night', isLight: boolean = false, page: string = '#132640',
    top: string = '#29476E', bottom: string = '#1D3454', base: string = '#203C62', sheet: string = '#192F4F') {
    this.key = key
    this.isLight = isLight
    this.page = page
    this.text = isLight ? '#172F50' : '#F4F8FF'
    this.secondary = isLight ? '#425D80' : '#CFDCF0'
    this.muted = isLight ? '#506889' : '#C0D1E9'
    this.panelTop = top
    this.panelBottom = bottom
    this.border = isLight ? '#CBDCF2' : '#47638A'
    this.wash = isLight ? 'rgba(74,133,225,0.04)' : 'rgba(152,190,247,0.04)'
    this.accent = isLight ? '#225CAC' : '#B8D7FF'
    this.warm = isLight ? '#935411' : '#F0CB94'
    this.track = isLight ? '#A7BEDD' : '#6B83A4'
    this.illustrationBase = base
    const rgb: string = `${Number.parseInt(base.substring(1, 3), 16)},${Number.parseInt(base.substring(3, 5), 16)},${Number.parseInt(base.substring(5, 7), 16)}`
    this.illustrationClear = `rgba(${rgb},0)`
    this.illustrationShade = `rgba(${rgb},0.4)`
    this.sheetBackground = sheet
  }

  // Surface-only mapping; the photographed/animated sky keeps WeatherTheme unchanged.
  toTheme(): ThemeColors {
    const colors = new ThemeColors()
    colors.pageBackground = this.page
    colors.textColor = this.text
    colors.textSecondary = this.secondary
    colors.textTertiary = this.muted
    colors.divider = this.border
    colors.sectionTint = this.panelTop
    colors.strongTint = this.panelBottom
    colors.accent = this.accent
    colors.warmAccent = this.warm
    colors.isLight = this.isLight
    return colors
  }
}

// Cached, static palettes: the existing city clock chooses them; no new animation loop.
export class AtmosphereTokens {
  static readonly ivory: string = '#F4F8FF'
  static readonly teal: string = '#B8D7FF'
  static readonly gold: string = '#E6BE8A'
  static readonly border: string = 'rgba(218,235,237,0.12)'
  static readonly panelTop: string = 'rgba(132,170,180,0.16)'
  static readonly panelBottom: string = 'rgba(69,95,110,0.06)'
  static readonly track: string = 'rgba(205,226,230,0.12)'
  static readonly radius: number = 24

  private static readonly night: AtmospherePalette = new AtmospherePalette()
  private static readonly day: AtmospherePalette =
    new AtmospherePalette('day', true, '#EFF5FD', '#FFFFFF', '#E7F0FD', '#E6F0FF', '#F7FAFF')
  private static readonly horizon: AtmospherePalette =
    new AtmospherePalette('horizon', true, '#F0F4FC', '#F7FAFF', '#E9EFFB', '#E8EFFB', '#F4F7FD')
  private static readonly rain: AtmospherePalette =
    new AtmospherePalette('rain', true, '#EDF3FB', '#F8FAFF', '#E4EDFA', '#E3EDFB', '#F3F7FE')
  private static readonly rainNight: AtmospherePalette =
    new AtmospherePalette('rain-night', false, '#13233D', '#283E63', '#1C3051', '#20365C', '#182C4B')
  private static readonly haze: AtmospherePalette =
    new AtmospherePalette('haze', true, '#F0F3F9', '#FCFDFF', '#E9EEF8', '#E7EEFA', '#F5F7FC')
  private static readonly hazeNight: AtmospherePalette =
    new AtmospherePalette('haze-night', false, '#19283F', '#30435F', '#22344E', '#293D5B', '#20324B')
  private static readonly snow: AtmospherePalette =
    new AtmospherePalette('snow', true, '#F3F7FE', '#FFFFFF', '#EBF3FF', '#EAF2FF', '#F9FBFF')

  static forWeather(data: WeatherData, now: number = Date.now()): AtmospherePalette {
    if (!Number.isFinite(now) || !Number.isFinite(data.utcOffsetSeconds)) return AtmosphereTokens.night
    const scene = WeatherData.sceneAt(data, now)
    if (scene.visualState === WeatherVisualState.RAIN || scene.visualState === WeatherVisualState.STORM) {
      return scene.isNight ? AtmosphereTokens.rainNight : AtmosphereTokens.rain
    }
    if (scene.visualState === WeatherVisualState.HAZE) {
      return scene.isNight ? AtmosphereTokens.hazeNight : AtmosphereTokens.haze
    }
    if (scene.visualState === WeatherVisualState.SNOW) {
      return scene.isNight ? AtmosphereTokens.rainNight : AtmosphereTokens.snow
    }
    if (scene.isNight) return AtmosphereTokens.night
    const today: string = WeatherData.localDate(now, data.utcOffsetSeconds).toISOString().substring(0, 10)
    const day = data.daily.find(item => item.date === today)
    const rise: string = day && day.sunriseAt > 0 ? WeatherData.localTime(day.sunriseAt, data.utcOffsetSeconds) : data.current.sunrise
    const set: string = day && day.sunsetAt > 0 ? WeatherData.localTime(day.sunsetAt, data.utcOffsetSeconds) : data.current.sunset
    const riseHour: number = AtmosphereTokens.solarHour(rise)
    const setHour: number = AtmosphereTokens.solarHour(set)
    if (setHour > riseHour && riseHour >= 0 &&
      ((scene.hour >= riseHour && scene.hour < riseHour + .75) || (scene.hour >= setHour - .75 && scene.hour < setHour))) {
      return AtmosphereTokens.horizon
    }
    return AtmosphereTokens.day
  }

  private static solarHour(value: string): number {
    if (!/^\d{2}:\d{2}$/.test(value)) return -1
    const parts: string[] = value.split(':')
    const hours: number = Number(parts[0]), minutes: number = Number(parts[1])
    return hours < 24 && minutes < 60 ? hours + minutes / 60 : -1
  }
}
