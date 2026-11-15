#!/usr/bin/env python3
import os
import re

def patch_build_gradle():
    path = os.path.join('android', 'app', 'build.gradle')
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        txt = f.read()

    # 1. Ensure coreLibraryDesugaringEnabled is true inside compileOptions
    if 'coreLibraryDesugaringEnabled' not in txt:
        txt = re.sub(r'(compileOptions\s*\{)', r'\1\n        coreLibraryDesugaringEnabled true', txt)
    
    # 2. Ensure desugar_jdk_libs is declared in dependencies
    if 'coreLibraryDesugaring' not in txt:
        if 'dependencies {' in txt:
            txt = re.sub(r'(dependencies\s*\{)', r'\1\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"', txt)
        else:
            txt += '\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"\n}\n'

    with open(path, 'w', encoding='utf-8') as f:
        f.write(txt)
    print("Patched app/build.gradle successfully")

def patch_android_manifest():
    path = os.path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r', encoding='utf-8') as f:
        txt = f.read()

    perms = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
"""
    if 'android.permission.ACCESS_FINE_LOCATION' not in txt:
        txt = txt.replace('<application', perms + '\n    <application')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(txt)
        print("Patched AndroidManifest.xml successfully")
    else:
        print("AndroidManifest.xml already contains permissions")

def patch_icons():
    import shutil
    backup_dir = os.path.join('assets', 'icons')
    res_dir = os.path.join('android', 'app', 'src', 'main', 'res')
    if os.path.exists(backup_dir) and os.path.exists(res_dir):
        for folder in ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi']:
            src = os.path.join(backup_dir, f'{folder}.png')
            dst_folder = os.path.join(res_dir, folder)
            os.makedirs(dst_folder, exist_ok=True)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(dst_folder, 'ic_launcher.png'))
        
        colors_xml = os.path.join(res_dir, 'values', 'colors.xml')
        os.makedirs(os.path.join(res_dir, 'values'), exist_ok=True)
        with open(colors_xml, 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#7C3AED</color>\n</resources>\n')
        
        anydpi_xml = os.path.join(res_dir, 'mipmap-anydpi-v26', 'ic_launcher.xml')
        os.makedirs(os.path.join(res_dir, 'mipmap-anydpi-v26'), exist_ok=True)
        with open(anydpi_xml, 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@color/ic_launcher_background"/>\n    <foreground android:drawable="@mipmap/ic_launcher"/>\n</adaptive-icon>\n')
        print("Patched Waylo purple icons and adaptive icon XML successfully")

def cleanup_kts():
    for root, dirs, files in os.walk('android'):
        for f in files:
            if f.endswith('.gradle.kts'):
                try:
                    os.remove(os.path.join(root, f))
                    print(f"Removed redundant {f}")
                except Exception:
                    pass

if __name__ == '__main__':
    cleanup_kts()
    patch_build_gradle()
    patch_android_manifest()
    patch_icons()
