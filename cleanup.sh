#!/bin/bash

# Move all unnecessary files to Archive folder
cd /Users/republicalatuya/Desktop/LyoJune

# Move Python scripts
mv *.py Archive/ 2>/dev/null || true

# Move shell scripts
mv *.sh Archive/ 2>/dev/null || true

# Move log files
mv *.log Archive/ 2>/dev/null || true

# Move txt files
mv *.txt Archive/ 2>/dev/null || true

# Move yml files
mv *.yml Archive/ 2>/dev/null || true

# Move markdown files
mv *.md Archive/ 2>/dev/null || true

# Move DerivedData
mv DerivedData Archive/ 2>/dev/null || true

# Move the corrupted Xcode project
mv LyoApp.xcodeproj Archive/LyoApp.xcodeproj.corrupted 2>/dev/null || true

echo "Cleanup completed!"
echo "Files archived. Remaining structure:"
ls -la
