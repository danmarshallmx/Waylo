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

if __name__ == '__main__':
    patch_build_gradle()
    patch_android_manifest()
