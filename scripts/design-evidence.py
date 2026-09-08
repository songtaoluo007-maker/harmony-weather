"""Compose honest screenshot evidence; motion frames retain real capture timing.

Requires Pillow. Run `python scripts/design-evidence.py motion` with the native
app showing a weather preview, then `python scripts/design-evidence.py board`.
No screenshot content is retouched; only resampling and labeled layout are used.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import time
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'design'
FONT = 'C:/Windows/Fonts/msyh.ttc'
HDC = 'D:/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe'


def board(names, labels, output, width=360):
    pictures = [Image.open(DESIGN / n).convert('RGB') for n in names]
    sizes = [(width, round(p.height * width / p.width)) for p in pictures]
    out = Image.new('RGB', (32 + (width + 20) * len(pictures), max(h for _, h in sizes) + 96), '#0D1C2A')
    draw = ImageDraw.Draw(out)
    font = ImageFont.truetype(FONT, 19)
    for index, (pic, size, label) in enumerate(zip(pictures, sizes, labels)):
        x = 26 + index * (width + 20)
        draw.text((x, 22), label, font=font, fill='#D4E5EC')
        out.paste(pic.resize(size, Image.Resampling.LANCZOS), (x, 64))
    out.save(DESIGN / output, quality=92)


def motion(prefix='redesign-rain'):
    frames, times = [], []
    with tempfile.TemporaryDirectory(prefix='harmony-motion-') as directory:
        for index in range(18):
            path = Path(directory) / f'{index:02d}.jpeg'
            subprocess.run([HDC, 'shell', 'snapshot_display', '-f', '/data/local/tmp/motion-frame.jpeg'], check=True, stdout=subprocess.DEVNULL)
            times.append(time.monotonic())
            subprocess.run([HDC, 'file', 'recv', '/data/local/tmp/motion-frame.jpeg', str(path)], check=True, stdout=subprocess.DEVNULL)
            frame = Image.open(path).convert('RGB')
            if index in (0, 17):
                frame.save(DESIGN / f'{prefix}-{"a" if index == 0 else "b"}.jpeg', quality=94)
            frames.append(frame.resize((440, 952), Image.Resampling.LANCZOS))
            time.sleep(0.35)
    durations = [max(20, round((b - a) * 1000)) for a, b in zip(times, times[1:])]
    durations.append(durations[-1])
    frames[0].save(DESIGN / f'{prefix}-motion.gif', save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=2)
    metadata = 'motion-capture.json' if prefix == 'redesign-rain' else f'{prefix}-capture.json'
    (DESIGN / metadata).write_text(json.dumps({'frames': len(frames), 'frame_duration_ms': durations, 'captured_span_seconds': round(times[-1] - times[0], 3), 'note': 'Native emulator screen captures. Playback timings match capture intervals; repeated GIF loop is not seamless.'}, indent=2), encoding='utf-8')
    print('Captured', len(frames), 'native frames over', round(times[-1] - times[0], 2), 'seconds')


def focus():
    out = Image.new('RGB', (1260, 1490), '#0D1C2A')
    draw = ImageDraw.Draw(out)
    font = ImageFont.truetype(FONT, 22)
    for index, (name, start, end, label) in enumerate([
        ('originos-weather-target.png', 0.42, 0.80, '参考 · 逐小时与逐日预报'),
        ('redesign-forecast-final.jpeg', 0.20, .72, '实现 · 可选择、可滚动预报')
    ]):
        picture = Image.open(DESIGN / name).convert('RGB')
        region = picture.crop((0, round(picture.height * start), picture.width, round(picture.height * end)))
        region = region.resize((600, round(region.height * 600 / region.width)), Image.Resampling.LANCZOS)
        draw.text((20 + index * 620, 20), label, font=font, fill='#D4E5EC')
        out.paste(region, (20 + index * 620, 66))
    out.crop((0, 0, 1260, 66 + round(2856 * .52 * 600 / 1320) + 24)).save(DESIGN / 'redesign-forecast-comparison.jpg', quality=94)


if __name__ == '__main__':
    if sys.argv[1] == 'motion':
        motion(sys.argv[2] if len(sys.argv) > 2 else 'redesign-rain')
    elif sys.argv[1] == 'live-board':
        board(['live-shenzhen-night.jpeg', 'live-beijing-night.jpeg', 'live-day-rain-preview.jpeg'], ['深圳 · 在线天气 / 自动夜景', '北京 · 切换城市 / 自动夜景', '白天雨 · 明确标注的背景预览'], 'live-weather-scenes.jpg')
    elif sys.argv[1] == 'board':
        board(['redesign-home-final.jpeg', 'redesign-life-final.jpeg', 'redesign-cities-final.jpeg', 'redesign-settings-final.jpeg'], ['首页 · 模拟器实拍', '生活气象 · 模拟器实拍', '城市管理 · 模拟器实拍', '设置 · 模拟器实拍'], 'redesign-overview.jpg')
        board(['originos-weather-target.png', 'redesign-home-final.jpeg'], ['已确认的视觉方向', '原生运行效果 · 当前演示数据'], 'redesign-reference-comparison.jpg', 440)
        focus()
    elif sys.argv[1] == 'night-assets':
        records = json.loads((DESIGN / 'city-night-selected.json').read_text(encoding='utf-8'))
        sheet = Image.new('RGB', (1300, 630), '#0D1C2A')
        draw = ImageDraw.Draw(sheet)
        font = ImageFont.truetype(FONT, 15)
        for index, item in enumerate(records):
            media = ROOT / 'entry/src/main/resources/base/media'
            photo = Image.open(next(media.glob(f'city_night_{item["id"]}.*'))).convert('RGB')
            photo.thumbnail((244, 175))
            x, y = 8 + (index % 5) * 260, 8 + (index // 5) * 210
            sheet.paste(photo, (x, y))
            draw.text((x, y + 180), item['name'], font=font, fill='white')
        sheet.save(DESIGN / 'city-night-assets-contact.jpg', quality=92)
