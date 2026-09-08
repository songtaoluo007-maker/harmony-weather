export class SnowFlake {
  x: number = 0
  y: number = 0
  radius: number = 1
  opacity: number = 0.6
}

/** Deterministic, seamless 18-second field. No fixed device-size coordinates. */
export class SnowField {
  static frame(width: number, height: number, phase: number): SnowFlake[] {
    if (width <= 0 || height <= 0) return []
    const progress: number = ((phase % 1) + 1) % 1
    const flakes: SnowFlake[] = []
    for (let i: number = 0; i < 42; i++) {
      const flake: SnowFlake = new SnowFlake()
      const depth: number = i % 3
      const seedX: number = (i * 0.61803398875) % 1
      const seedY: number = (i * 0.38196601125 + 0.07) % 1
      flake.x = seedX * width + Math.sin(progress * Math.PI * 2 + i) * (3 + depth * 3)
      flake.y = ((seedY + progress * (depth + 1)) % 1) * (height + 16) - 8
      flake.radius = 0.9 + depth * 0.7
      flake.opacity = 0.35 + depth * 0.22
      flakes.push(flake)
    }
    return flakes
  }
}
