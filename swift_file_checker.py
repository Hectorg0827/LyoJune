#!/usr/bin/env python3
"""
Swift Compilation Error Checker
"""

import subprocess
import os

def check_swift_files():
    """Check specific Swift files for compilation issues."""
    print("🔍 CHECKING SWIFT FILES FOR COMPILATION ERRORS")
    print("="*50)
    
    # Files that were mentioned in the error report
    problematic_files = [
        "LyoApp/Core/Services/DataManager.swift",
        "LyoApp/Core/Services/APIServices.swift", 
        "LyoApp/Core/Services/GamificationAPIService.swift",
        "LyoApp/Core/Services/AIService.swift",
        "LyoApp/Core/Services/EnhancedAIService.swift",
        "LyoApp/Core/Models/AppModels.swift"
    ]
    
    os.chdir("/Users/republicalatuya/Desktop/LyoJune")
    
    for file_path in problematic_files:
        if os.path.exists(file_path):
            print(f"\n📄 Checking: {file_path}")
            
            # Try to check syntax
            try:
                result = subprocess.run([
                    "swift", "-frontend", "-parse", file_path
                ], capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0:
                    print("   ✅ Syntax OK")
                else:
                    print("   ❌ Syntax Errors:")
                    for line in result.stderr.split('\n')[:5]:
                        if line.strip():
                            print(f"      {line.strip()}")
                            
            except Exception as e:
                print(f"   ⚠️  Could not check: {e}")
        else:
            print(f"\n📄 {file_path}: ❌ File not found")

if __name__ == "__main__":
    check_swift_files()
    print("\n" + "="*50)
    print("📝 If you see syntax errors above, those need to be fixed first.")
    print("✅ If all files show 'Syntax OK', the project should compile.")
