from setuptools import setup

APP = ['calendar_app.py']
OPTIONS = {
    'argv_emulation': False,
    'packages': ['jpholiday'],
    'includes': ['objc', 'AppKit', 'Foundation', 'calendar', 'datetime'],
    'plist': {
        'LSUIElement': True,              # Dockに表示しない（メニューバーアプリ）
        'NSHighResolutionCapable': True,
        'CFBundleName': 'QuickCalendar',
        'CFBundleDisplayName': 'Quick Calendar',
        'CFBundleIdentifier': 'com.local.quickcalendar',
        'CFBundleVersion': '1.0',
        'CFBundleShortVersionString': '1.0',
    },
}

setup(
    name='QuickCalendar',
    app=APP,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
