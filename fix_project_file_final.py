#!/usr/bin/env python3

import os
import re
import uuid

def main():
    project_path = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    
    # Create a timestamped backup first
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = project_path + f".backup_safe_{timestamp}"
    
    # Read the current project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Backup the original with timestamp
    with open(backup_path, 'w') as f:
        f.write(content)
        
    print(f"Created backup: {backup_path}")
    
    # Validate the project file format first
    if not content.startswith('// !$*UTF8*$!'):
        print("❌ Project file doesn't have valid header")
        return
        
    if 'objectVersion' not in content or 'archiveVersion' not in content:
        print("❌ Project file missing required version info")
        return
    
    print("✅ Project file format is valid")
    print("Safely adding missing Swift files to project...")
    
    # Find all Swift files in the LyoApp directory
    swift_files = []
    for root, dirs, files in os.walk("/Users/republicalatuya/Desktop/LyoJune/LyoApp"):
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, "/Users/republicalatuya/Desktop/LyoJune/LyoApp")
                swift_files.append((file, rel_path, full_path))
    
    print(f"Found {len(swift_files)} Swift files")
    
    # Check which files are missing from the project
    missing_files = []
    for filename, rel_path, full_path in swift_files:
        if f'/* {filename} */' not in content:
            missing_files.append((filename, rel_path, full_path))
    
    print(f"Found {len(missing_files)} files missing from project")
    
    if len(missing_files) == 0:
        print("✅ All Swift files are already in the project!")
        return
    
    # Find the sections we need to modify using more precise patterns
    build_files_start = content.find("/* Begin PBXBuildFile section */")
    build_files_end = content.find("/* End PBXBuildFile section */")
    file_refs_start = content.find("/* Begin PBXFileReference section */")
    file_refs_end = content.find("/* End PBXFileReference section */")
    
    # Find sources build phase more carefully
    sources_pattern = r'92A5145C75D5A57ABAFEE26F /\* Sources \*/ = \{[^}]*?files = \([^)]*?\);[^}]*?\};'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    
    if build_files_start == -1 or build_files_end == -1 or file_refs_start == -1 or file_refs_end == -1:
        print("❌ Could not find required sections in project file")
        return
        
    if not sources_match:
        print("❌ Could not find Sources build phase")
        return
    
    print("✅ Found all required sections")
    
    # Generate new entries for missing files only
    new_build_files = []
    new_file_refs = []
    new_sources_refs = []
    
    for filename, rel_path, full_path in missing_files:
        # Generate UUIDs using a simpler method
        import random
        build_file_uuid = ''.join([f'{random.randint(0,255):02X}' for _ in range(12)])
        file_ref_uuid = ''.join([f'{random.randint(0,255):02X}' for _ in range(12)])
        
        # Create entries for this missing file
        build_file_entry = f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"
        file_ref_entry = f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
        sources_ref = f"\t\t\t\t{build_file_uuid} /* {filename} in Sources */,"
        
        new_build_files.append(build_file_entry)
        new_file_refs.append(file_ref_entry)
        new_sources_refs.append(sources_ref)
        
        print(f"  Adding: {filename}")
    
    # Safely insert new entries
    if new_build_files:
        # Insert build files before the end marker
        build_insert_pos = build_files_end
        new_build_content = '\n'.join(new_build_files) + '\n'
        content = content[:build_insert_pos] + new_build_content + content[build_insert_pos:]
        
        # Update positions after insertion
        adjustment = len(new_build_content)
        file_refs_start += adjustment
        file_refs_end += adjustment
        
        # Insert file references before the end marker  
        file_refs_insert_pos = file_refs_end
        new_file_refs_content = '\n'.join(new_file_refs) + '\n'
        content = content[:file_refs_insert_pos] + new_file_refs_content + content[file_refs_insert_pos:]
        
        # Update sources section
        sources_text = sources_match.group(0)
        files_end_pos = sources_text.rfind(");")
        if files_end_pos != -1:
            new_sources_content = '\n' + '\n'.join(new_sources_refs) + '\n'
            new_sources_text = sources_text[:files_end_pos] + new_sources_content + sources_text[files_end_pos:]
            content = content.replace(sources_text, new_sources_text)
    
    # Validate the result before writing
    if not content.startswith('// !$*UTF8*$!'):
        print("❌ Content validation failed - file header corrupted")
        return
        
    # Write the updated content
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Successfully added {len(new_build_files)} files to the project")
    print("✅ Project file updated safely!")

if __name__ == "__main__":
    main()
