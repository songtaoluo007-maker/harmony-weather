import { WeatherData } from './WeatherModels'

export class SolarReading {
  valid: boolean = false
  rise: string = '--:--'
  set: string = '--:--'
  duration: string = ''
  progress: number = 0
  sunVisible: boolean = false
}

// Geometry derived from reported values. No synthetic history or meteorological estimates.
export class WeatherInstruments {
  static bearing(direction: string): number {
    const directions: string[] = ['北风', '东北风', '东风', '东南风', '南风', '西南风', '西风', '西北风']
    const index: number = directions.indexOf(direction)
    return index < 0 ? -1 : index * 45
  }

  static fraction(value: number): number {
    return Number.isFinite(value) ? Math.max(0, Math.min(1, value / 100)) : -1
  }

  static aqiPosition(value: number): number {
    if (!Number.isFinite(value) || value < 0) return -1
    const edges: number[] = [0, 50, 100, 150, 200, 300, 500]
    for (let index: number = 0; index < 6; index++) {
      if (value <= edges[index + 1]) {
        return (index + (value - edges[index]) / (edges[index + 1] - edges[index])) / 6
      }
    }
    return 1
  }

  static aqiBand(value: number): number {
    if (!Number.isFinite(value) || value < 0) return -1
    const edges: number[] = [50, 100, 150, 200, 300]
    const band: number = edges.findIndex(edge => value <= edge)
    return band < 0 ? 5 : band
  }

  static solar(data: WeatherData, now: number): SolarReading {
    const reading: SolarReading = new SolarReading()
    const date: string = WeatherData.localDate(now, data.utcOffsetSeconds).toISOString().substring(0, 10)
    const day = data.daily.find(item => item.date === date)
    if (!day || !Number.isFinite(day.sunriseAt) || !Number.isFinite(day.sunsetAt) ||
      day.sunriseAt <= 0 || day.sunsetAt <= day.sunriseAt || day.sunsetAt - day.sunriseAt >= 86400000) return reading
    reading.valid = true
    reading.rise = WeatherData.localTime(day.sunriseAt, data.utcOffsetSeconds)
    reading.set = WeatherData.localTime(day.sunsetAt, data.utcOffsetSeconds)
    const minutes: number = Math.round((day.sunsetAt - day.sunriseAt) / 60000)
    reading.duration = `${Math.floor(minutes / 60)}小时${minutes % 60 ? (minutes % 60) + '分' : ''}`
    reading.progress = Math.max(0, Math.min(1, (now - day.sunriseAt) / (day.sunsetAt - day.sunriseAt)))
    reading.sunVisible = now >= day.sunriseAt && now < day.sunsetAt
    return reading
  }
}
