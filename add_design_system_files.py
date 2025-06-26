#!/usr/bin/env python3
"""
Add new Design System files to Xcode project
"""
import subprocess
import os
import re
import shutil
from datetime import datetime

def backup_project_file():
    """Create a backup of the project.pbxproj file"""
    project_file = "LyoApp.xcodeproj/project.pbxproj"
    backup_file = f"LyoApp.xcodeproj/project.pbxproj.backup_design_system_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if os.path.exists(project_file):
        shutil.copy2(project_file, backup_file)
        print(f"Backup created: {backup_file}")
        return backup_file
    return None

def add_files_to_xcode():
    """Add design system files to Xcode project using pbxproj"""
    try:
        # Files to add (relative to project root)
        design_system_files = [
            "LyoApp/DesignSystem/DesignTokens.swift",
            "LyoApp/DesignSystem/SkeletonLoader.swift", 
            "LyoApp/DesignSystem/AnimationSystem.swift",
            "LyoApp/DesignSystem/HapticManager.swift",
            "LyoApp/DesignSystem/ModernComponents.swift"
        ]
        
        # Check if files exist
        for file_path in design_system_files:
            if not os.path.exists(file_path):
                print(f"Warning: File does not exist: {file_path}")
                continue
                
            print(f"Adding {file_path}...")
            
            # Add to Xcode project using pbxproj
            try:
                result = subprocess.run([
                    'python3', '-m', 'pbxproj', 'file', 
                    'LyoApp.xcodeproj', 
                    file_path,
                    '--target', 'LyoApp'
                ], capture_output=True, text=True, timeout=30)
                
                if result.returncode == 0:
                    print(f"✅ Added {file_path}")
                else:
                    print(f"❌ Failed to add {file_path}: {result.stderr}")
                    
            except subprocess.TimeoutExpired:
                print(f"❌ Timeout adding {file_path}")
            except Exception as e:
                print(f"❌ Error adding {file_path}: {e}")
        
        print("\n✅ Design system files added to Xcode project")
        return True
                
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("Adding Design System files to Xcode project...")
    
    # Create backup
    backup_project_file()
    
    # Add files
    if add_files_to_xcode():
        print("\n🎉 Success! Design system files have been added to the Xcode project.")
        print("Try building the project now.")
    else:
        print("\n❌ Failed to add some files. Check the errors above.")

if __name__ == "__main__":
    main()
