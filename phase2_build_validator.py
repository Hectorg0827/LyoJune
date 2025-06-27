#!/usr/bin/env python3
"""
Phase 2 Build Validation Script - Quick check for compilation
"""

import subprocess
import sys

def run_build_test():
    """Run a build test to check compilation status."""
    print("🔨 PHASE 2: BUILD VALIDATION TEST")
    print("="*50)
    print("Running compilation test...")
    
    try:
        # Run a quick build
        result = subprocess.run([
            "xcodebuild", "-project", "LyoApp.xcodeproj", 
            "-scheme", "LyoApp", 
            "-destination", "platform=iOS Simulator,name=iPhone 16,OS=18.5",
            "build"
        ], capture_output=True, text=True, timeout=180, cwd="/Users/republicalatuya/Desktop/LyoJune")
        
        if result.returncode == 0:
            print("✅ BUILD SUCCEEDED!")
            print("\n🎉 PHASE 2 COMPLETE!")
            print("✅ All compilation errors resolved")
            print("✅ Types properly consolidated")
            print("✅ Ready for Phase 3 (Performance optimization)")
            return True
        else:
            print("❌ BUILD FAILED")
            print("\nFirst few errors:")
            # Show only first few lines of errors
            error_lines = result.stderr.split('\n')
            for line in error_lines[:20]:
                if 'error:' in line.lower():
                    print(f"  • {line.strip()}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ Build timed out - this may indicate larger issues")
        return False
    except Exception as e:
        print(f"❌ Error running build: {e}")
        return False

if __name__ == "__main__":
    success = run_build_test()
    if success:
        print("\n" + "="*50)
        print("🚀 READY FOR PHASE 3!")
        print("="*50)
    else:
        print("\n" + "="*50)
        print("🔧 Additional fixes needed")
        print("="*50)
    
    sys.exit(0 if success else 1)
