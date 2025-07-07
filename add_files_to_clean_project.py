#!/usr/bin/env python3

import os
import re
import shutil

def generate_uuid():
    """Generate a 24-character hex UUID like Xcode uses"""
    return ''.join(f'{ord(c):02X}' for c in os.urandom(12))[:24]

def add_swift_files_to_project():
    """Add all Swift files from the existing LyoApp structure to the clean project"""
    
    base_path = "/Users/republicalatuya/Desktop/LyoJune"
    project_file = f"{base_path}/LyoApp.xcodeproj/project.pbxproj"
    source_base = f"{base_path}/LyoApp"
    
    # Read the current project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find all Swift files except the basic ones we already have
    swift_files = []
    exclude_files = {"LyoApp.swift", "ContentView.swift"}
    
    for root, dirs, files in os.walk(source_base):
        for file in files:
            if file.endswith('.swift') and file not in exclude_files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, source_base)
                swift_files.append((file, rel_path, full_path))
    
    print(f"Found {len(swift_files)} additional Swift files to add")
    
    # Find the sections we need to modify
    build_files_start = content.find("/* Begin PBXBuildFile section */")
    build_files_end = content.find("/* End PBXBuildFile section */")
    file_refs_start = content.find("/* Begin PBXFileReference section */")
    file_refs_end = content.find("/* End PBXFileReference section */")
    
    # Find the sources build phase
    sources_match = re.search(r'([A-F0-9]{24}) /\* Sources \*/ = \{[^}]*?files = \([^)]*?\);[^}]*?\};', content, re.DOTALL)
    
    if not all([build_files_start != -1, build_files_end != -1, file_refs_start != -1, file_refs_end != -1, sources_match]):
        print("❌ Could not find required sections in project file")
        return
    
    print("✅ Found all required sections in project file")
    
    # Generate new entries for all files
    new_build_files = []
    new_file_refs = []
    new_sources_refs = []
    
    for filename, rel_path, full_path in swift_files:
        # Generate UUIDs
        build_file_uuid = generate_uuid()
        file_ref_uuid = generate_uuid()
        
        # Create entries
        build_file_entry = f"\\t\\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"
        file_ref_entry = f"\\t\\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \\"<group>\\"; }};"
        sources_ref = f"\\t\\t\\t\\t{build_file_uuid} /* {filename} in Sources */,"
        
        new_build_files.append(build_file_entry)
        new_file_refs.append(file_ref_entry)
        new_sources_refs.append(sources_ref)
        
        print(f"  Adding: {filename}")
    
    # Insert new entries into the project file
    if new_build_files:
        # Insert build files
        build_insert_pos = content.find("/* End PBXBuildFile section */")
        new_build_content = '\\n' + '\\n'.join(new_build_files) + '\\n'
        content = content[:build_insert_pos] + new_build_content + content[build_insert_pos:]
        
        # Update positions after insertion
        adjustment = len(new_build_content)
        file_refs_end += adjustment
        
        # Insert file references
        file_refs_insert_pos = content.find("/* End PBXFileReference section */")
        new_file_refs_content = '\\n' + '\\n'.join(new_file_refs) + '\\n'
        content = content[:file_refs_insert_pos] + new_file_refs_content + content[file_refs_insert_pos:]
        
        # Update sources section
        sources_text = sources_match.group(0)
        files_end_pos = sources_text.rfind(");")
        if files_end_pos != -1:
            new_sources_content = '\\n' + '\\n'.join(new_sources_refs) + '\\n'
            new_sources_text = sources_text[:files_end_pos] + new_sources_content + sources_text[files_end_pos:]
            content = content.replace(sources_text, new_sources_text)
    
    # Write the updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"✅ Successfully added {len(new_build_files)} files to the project")
    print("✅ Clean project setup complete!")

if __name__ == "__main__":
    add_swift_files_to_project()
