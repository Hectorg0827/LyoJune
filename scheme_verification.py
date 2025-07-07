#!/usr/bin/env python3

import os
import subprocess
import xml.etree.ElementTree as ET

def main():
    print("=== Xcode Scheme Setup Verification ===")
    
    project_dir = "/Users/republicalatuya/Desktop/LyoJune"
    project_file = os.path.join(project_dir, "LyoApp.xcodeproj")
    
    # Check if project file exists
    if not os.path.exists(project_file):
        print("❌ Project file not found")
        return
    
    print("✅ Project file found")
    
    # Check shared scheme
    shared_scheme = os.path.join(project_file, "xcshareddata", "xcschemes", "LyoApp.xcscheme")
    if os.path.exists(shared_scheme):
        print("✅ Shared scheme found")
        
        # Validate scheme XML
        try:
            tree = ET.parse(shared_scheme)
            root = tree.getroot()
            
            # Check if it has proper structure
            build_action = root.find("BuildAction")
            if build_action is not None:
                build_entries = build_action.find("BuildActionEntries")
                if build_entries is not None:
                    print("✅ Scheme has valid build configuration")
                else:
                    print("❌ Scheme missing build entries")
            else:
                print("❌ Scheme missing build action")
                
        except Exception as e:
            print(f"❌ Scheme XML is invalid: {e}")
    else:
        print("❌ Shared scheme not found")
    
    # Check user data
    user_data_dir = os.path.join(project_file, "xcuserdata")
    if os.path.exists(user_data_dir):
        print("✅ xcuserdata directory exists")
        
        # Check for user schemes
        user_schemes = []
        for item in os.listdir(user_data_dir):
            if item.endswith(".xcuserdatad"):
                user_schemes.append(item)
        
        if user_schemes:
            print(f"✅ Found user data: {', '.join(user_schemes)}")
        else:
            print("⚠️  No user data found")
    else:
        print("❌ xcuserdata directory missing")
    
    # Test xcodebuild
    print("\n=== Testing xcodebuild ===")
    try:
        os.chdir(project_dir)
        result = subprocess.run([
            "xcodebuild", "-project", "LyoApp.xcodeproj", "-list"
        ], capture_output=True, text=True, timeout=15)
        
        if result.returncode == 0:
            print("✅ xcodebuild -list successful")
            print("Output:")
            print(result.stdout)
        else:
            print("❌ xcodebuild -list failed")
            print("Error:")
            print(result.stderr)
            
    except subprocess.TimeoutExpired:
        print("⏰ xcodebuild command timed out")
    except FileNotFoundError:
        print("❌ xcodebuild not found (Xcode not installed?)")
    except Exception as e:
        print(f"❌ Error running xcodebuild: {e}")

if __name__ == "__main__":
    main()
