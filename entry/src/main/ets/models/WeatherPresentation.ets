import { AirQuality } from './WeatherModels'

export class PollutantValue {
  key: string
  label: string
  value: string
  unit: string

  constructor(key: string, label: string, value: string, unit: string) {
    this.key = key
    this.label = label
    this.value = value
    this.unit = unit
  }
}

/** Shared display contract: missing values never become plausible zero readings. */
export class WeatherPresentation {
  static windSpeed(value: number): string {
    return Number.isFinite(value) && value >= 0 ? `${Math.round(value * 10) / 10} km/h` : '暂无'
  }

  static pollutants(air: AirQuality): PollutantValue[] {
    const keys: string[] = ['pm25', 'pm10', 'no2', 'so2', 'co', 'o3']
    const labels: string[] = ['PM2.5', 'PM10', 'NO₂', 'SO₂', 'CO', 'O₃']
    const values: number[] = [air.pm25, air.pm10, air.no2, air.so2, air.co, air.o3]
    return keys.map((key: string, index: number) => new PollutantValue(key, labels[index],
      air.available && Number.isFinite(values[index]) && values[index] >= 0 ? String(values[index]) : '暂无',
      key === 'co' ? 'mg/m³' : 'μg/m³'))
  }
}
