import { WeatherData, WeatherVisualState } from '../models/WeatherModels'

export class AtmospherePalette {
  key: string
  panelTop: string
  panelBottom: string
  border: string
  wash: string
  accent: string
  warm: string = '#E6BE8A'
  illustrationBase: string
  illustrationClear: string
  illustrationShade: string
  sheetBackground: string

  constructor(key: string = 'night', base: string = '18,41,52', light: string = '156,207,203',
    accent: string = '#A6D8D4', sheet: string = '#10242E') {
    this.key = key
    this.panelTop = `rgba(${light},0.18)`
    this.panelBottom = `rgba(${light},0.025)`
    this.border = `rgba(${light},0.19)`
    this.wash = `rgba(${light},0.045)`
    this.accent = accent
    this.illustrationBase = `rgb(${base})`
    this.illustrationClear = `rgba(${base},0)`
    this.illustrationShade = `rgba(${base},0.36)`
    this.sheetBackground = sheet
  }
}

// Cached, static palettes: the existing city clock chooses them; no new animation loop.
export class AtmosphereTokens {
  static readonly ivory: string = '#F4F1EA'
  static readonly teal: string = '#A6D8D4'
  static readonly gold: string = '#E6BE8A'
  static readonly border: string = 'rgba(218,235,237,0.12)'
  static readonly panelTop: string = 'rgba(132,170,180,0.16)'
  static readonly panelBottom: string = 'rgba(69,95,110,0.06)'
  static readonly track: string = 'rgba(205,226,230,0.12)'
  static readonly radius: number = 24

  private static readonly night: AtmospherePalette = new AtmospherePalette()
  private static readonly day: AtmospherePalette =
    new AtmospherePalette('day', '36,77,94', '229,227,210', '#DDE9DD', '#214350')
  private static readonly horizon: AtmospherePalette =
    new AtmospherePalette('horizon', '57,64,69', '237,192,139', '#EED0A8', '#303A43')
  private static readonly rain: AtmospherePalette =
    new AtmospherePalette('rain', '38,66,84', '160,193,219', '#B9D5E8', '#203644')
  private static readonly rainNight: AtmospherePalette =
    new AtmospherePalette('rain-night', '19,37,57', '137,171,209', '#AAC7E5', '#142538')
  private static readonly haze: AtmospherePalette =
    new AtmospherePalette('haze', '54,69,72', '200,207,196', '#D2DDD5', '#2A3B40')
  private static readonly hazeNight: AtmospherePalette =
    new AtmospherePalette('haze-night', '30,43,49', '164,185,181', '#BED2CB', '#1B2C33')
  private static readonly snow: AtmospherePalette =
    new AtmospherePalette('snow', '45,65,80', '218,235,242', '#D5EAF2', '#263D4A')

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
