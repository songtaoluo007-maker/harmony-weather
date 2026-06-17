import { WeatherType, TimeOfDay } from '../models/WeatherModels'

// ─── 天气主题：动态渐变 + 粒子配置 ──────────────────

export class ThemeColors {
  gradient: string[] = []
  particleColor: string = '#ffffff'
  glowColor: string = '#ffffff'
  textColor: string = '#ffffff'
  textSecondary: string = 'rgba(255,255,255,0.6)'
  cardBg: string = 'rgba(255,255,255,0.12)'
  cardBorder: string = 'rgba(255,255,255,0.18)'
}

export class WeatherTheme {
  static getColors(type: WeatherType, hour: number): ThemeColors {
    const isNight = hour < 6 || hour > 19
    const isDawn = hour >= 5 && hour < 7
    const isDusk = hour >= 17 && hour < 19

    const themes: Record<WeatherType, { day: string[], night: string[], dawn: string[], dusk: string[] }> = {
      [WeatherType.SUNNY]: {
        dawn: ['#FF6B35', '#FF8E53', '#FFB347'],
        day: ['#FF9500', '#FF5E3A', '#FF2D55'],
        dusk: ['#FF6B35', '#C0392B', '#8E44AD'],
        night: ['#0f0c29', '#302b63', '#24243e']
      },
      [WeatherType.CLOUDY]: {
        dawn: ['#5D6D7E', '#85929E', '#ABB2B9'],
        day: ['#4A90D9', '#74B9FF', '#A8D8EA'],
        dusk: ['#616A6B', '#7B7D7D', '#909497'],
        night: ['#1a1a2e', '#16213e', '#0f3460']
      },
      [WeatherType.RAINY]: {
        dawn: ['#2d3436', '#4a6fa5', '#636e72'],
        day: ['#2d3436', '#636e72', '#74b9ff'],
        dusk: ['#1a1a2e', '#2d3436', '#4a6fa5'],
        night: ['#0c0c1d', '#1a1a2e', '#16213e']
      },
      [WeatherType.SNOWY]: {
        dawn: ['#C5CAE9', '#D1C4E9', '#E8EAF6'],
        day: ['#e8eaf6', '#c5cae9', '#9fa8da'],
        dusk: ['#7986CB', '#9FA8DA', '#C5CAE9'],
        night: ['#2c3e50', '#34495e', '#4a6fa5']
      },
      [WeatherType.STORMY]: {
        dawn: ['#1a1a2e', '#2d3436', '#6c5ce7'],
        day: ['#2d3436', '#636e72', '#6c5ce7'],
        dusk: ['#0c0c1d', '#1a1a2e', '#6c5ce7'],
        night: ['#0c0c1d', '#0a0a1a', '#4a0080']
      },
      [WeatherType.FOGGY]: {
        dawn: ['#909497', '#ABB2B9', '#BDC3C7'],
        day: ['#a0a0a0', '#c0c0c0', '#d5d5d5'],
        dusk: ['#7B7D7D', '#909497', '#ABB2B9'],
        night: ['#2c3e50', '#34495e', '#7f8c8d']
      }
    }

    const t = themes[type]
    let colors: string[]
    if (isDawn) colors = t.dawn
    else if (isDusk) colors = t.dusk
    else if (isNight) colors = t.night
    else colors = t.day

    const result = new ThemeColors()
    result.gradient = colors

    if (type === WeatherType.SNOWY) {
      result.particleColor = '#ffffff'
      result.glowColor = '#e8eaf6'
      result.textColor = isNight ? '#ffffff' : '#1a1a2e'
      result.textSecondary = isNight ? 'rgba(255,255,255,0.6)' : 'rgba(0,0,0,0.5)'
      result.cardBg = isNight ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.35)'
      result.cardBorder = isNight ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.4)'
    } else if (type === WeatherType.FOGGY) {
      result.particleColor = 'rgba(200,200,200,0.3)'
      result.glowColor = '#bdc3c7'
      result.textColor = isNight ? '#ffffff' : '#2c3e50'
      result.textSecondary = isNight ? 'rgba(255,255,255,0.6)' : 'rgba(0,0,0,0.5)'
      result.cardBg = isNight ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.3)'
      result.cardBorder = isNight ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.35)'
    } else {
      result.particleColor = '#ffffff'
      result.glowColor = 'rgba(255,255,255,0.3)'
      result.textColor = '#ffffff'
      result.textSecondary = 'rgba(255,255,255,0.6)'
      result.cardBg = 'rgba(255,255,255,0.12)'
      result.cardBorder = 'rgba(255,255,255,0.18)'
    }

    return result
  }

  static getTimeOfDay(hour: number): TimeOfDay {
    if (hour >= 5 && hour < 7) return TimeOfDay.DAWN
    if (hour >= 7 && hour < 17) return TimeOfDay.DAY
    if (hour >= 17 && hour < 19) return TimeOfDay.DUSK
    return TimeOfDay.NIGHT
  }
}
