import { AtmospherePalette } from './AtmosphereTokens'

// Secondary pages inherit the last selected city palette, never the device timezone.
export class DesignTokens {
  private static palette: AtmospherePalette = new AtmospherePalette()
  static usePalette(palette: AtmospherePalette): void { DesignTokens.palette = palette }
  static get current(): AtmospherePalette { return DesignTokens.palette }
  static barInk(isLight: boolean, overScene: boolean = false): string {
    return isLight && !overScene ? '#172F50' : '#FFFFFF'
  }
  static get page(): string { return DesignTokens.palette.page }
  static get surface(): string { return DesignTokens.palette.panelTop }
  static get selected(): string { return DesignTokens.palette.panelBottom }
  static get text(): string { return DesignTokens.palette.text }
  static get muted(): string { return DesignTokens.palette.muted }
  static get accent(): string { return DesignTokens.palette.accent }
  static get border(): string { return DesignTokens.palette.border }
  static readonly gutter: number = 24
  static readonly radius: number = 22
  static readonly touch: number = 44
}
