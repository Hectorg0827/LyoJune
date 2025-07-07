#!/usr/bin/env python3

import os
import subprocess

def main():
    print("=== Project Repair Status ===")
    
    project_dir = "/Users/republicalatuya/Desktop/LyoJune"
    os.chdir(project_dir)
    
    # Check if project file is valid
    try:
        import plistlib
        with open('LyoApp.xcodeproj/project.pbxproj', 'rb') as f:
            data = plistlib.load(f)
        print("✅ Project file is valid plist format")
        
        # Count Swift file references
        objects = data.get('objects', {})
        swift_files = 0
        build_files = 0
        
        for obj_id, obj_data in objects.items():
            if isinstance(obj_data, dict):
                if obj_data.get('isa') == 'PBXFileReference' and obj_data.get('path', '').endswith('.swift'):
                    swift_files += 1
                elif obj_data.get('isa') == 'PBXBuildFile':
                    build_files += 1
        
        print(f"✅ Found {swift_files} Swift file references")
        print(f"✅ Found {build_files} build file entries")
        
    except Exception as e:
        print(f"❌ Project file validation failed: {e}")
        return False
    
    # Test xcodebuild
    try:
        result = subprocess.run([
            "xcodebuild", "-project", "LyoApp.xcodeproj", "-list"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            print("✅ xcodebuild can read the project")
            if "LyoApp" in result.stdout:
                print("✅ LyoApp scheme found")
            else:
                print("⚠️  LyoApp scheme not found in output")
        else:
            print("❌ xcodebuild failed to read project")
            print(f"Error: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ xcodebuild timed out")
        return False
    except Exception as e:
        print(f"❌ xcodebuild error: {e}")
        return False
    
    print("\n🎉 Project appears to be repaired and functional!")
    return True

if __name__ == "__main__":
    main()
