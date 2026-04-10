from setuptools import setup

APP = ['calendar_app.py']
OPTIONS = {
    'argv_emulation': False,
    'packages': ['jpholiday'],
    'includes': ['objc', 'AppKit', 'Foundation', 'calendar', 'datetime'],
    'plist': {
        'LSUIElement': True,              # Dockに表示しない（メニューバーアプリ）
        'NSHighResolutionCapable': True,
        'CFBundleName': 'MenuBarCalendar',
        'CFBundleDisplayName': 'メニューバーカレンダー',
        'CFBundleIdentifier': 'com.local.menubarcalendar',
        'CFBundleVersion': '1.0',
        'CFBundleShortVersionString': '1.0',
    },
}

setup(
    name='MenuBarCalendar',
    app=APP,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
