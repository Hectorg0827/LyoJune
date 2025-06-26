#!/usr/bin/env python3

import os
import sys
import re
import uuid
import shutil
from datetime import datetime

def generate_uuid():
    """Generate a UUID for Xcode project files."""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_file_to_project(project_path, file_path, group_name=None):
    """Add a file to an Xcode project."""
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Extract relative path from the project root
    rel_path = os.path.relpath(file_path, os.path.dirname(project_path))
    file_name = os.path.basename(file_path)
    
    # Generate UUIDs for the file reference and build file
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()
    
    # Check if file is already in the project
    if file_name in content:
        print(f"File {file_name} already exists in project")
        return False
    
    # Add file reference
    file_ref_line = f"\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {file_name}; path = {rel_path}; sourceTree = SOURCE_ROOT; }};"
    
    # Find the PBXFileReference section and add the new file
    file_ref_section = re.search(r'(/* Begin PBXFileReference section */.*?)(/* End PBXFileReference section */)', content, re.DOTALL)
    if file_ref_section:
        updated_content = content.replace(
            file_ref_section.group(2),
            f"\t\t{file_ref_line}\n\t\t{file_ref_section.group(2)}"
        )
        content = updated_content
    
    # Add build file
    build_file_line = f"\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};"
    
    # Find the PBXBuildFile section and add the new build file
    build_file_section = re.search(r'(/* Begin PBXBuildFile section */.*?)(/* End PBXBuildFile section */)', content, re.DOTALL)
    if build_file_section:
        updated_content = content.replace(
            build_file_section.group(2),
            f"\t\t{build_file_line}\n\t\t{build_file_section.group(2)}"
        )
        content = updated_content
    
    # Add to appropriate group (find Models group)
    if group_name:
        group_pattern = rf'({group_name} = {{.*?children = \()(.*?)(\);)'
        group_match = re.search(group_pattern, content, re.DOTALL)
        if group_match:
            updated_content = content.replace(
                group_match.group(0),
                f"{group_match.group(1)}{group_match.group(2)}\t\t\t\t{file_ref_uuid} /* {file_name} */,\n{group_match.group(3)}"
            )
            content = updated_content
    
    # Add to Sources build phase
    sources_pattern = r'(/* Sources */.*?files = \()(.*?)(\);)'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    if sources_match:
        updated_content = content.replace(
            sources_match.group(0),
            f"{sources_match.group(1)}{sources_match.group(2)}\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,\n{sources_match.group(3)}"
        )
        content = updated_content
    
    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Added {file_name} to project")
    return True

def main():
    # Define the project path
    project_path = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    
    # Files to add
    files_to_add = [
        "/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Models/NetworkTypes.swift",
        "/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Shared/AuthTypes.swift",
        "/Users/republicalatuya/Desktop/LyoJune/LyoApp/Shared/Utilities/KeychainHelper.swift",
        "/Users/republicalatuya/Desktop/LyoJune/LyoApp/Core/Models/AppModels.swift"
    ]
    
    # Backup the project file
    backup_path = f"{project_path}.backup_add_missing_files"
    shutil.copy2(project_path, backup_path)
    print(f"Created backup: {backup_path}")
    
    # Add each file
    for file_path in files_to_add:
        if os.path.exists(file_path):
            add_file_to_project(project_path, file_path)
        else:
            print(f"File not found: {file_path}")
    
    print("Done adding files to project")

if __name__ == "__main__":
    main()
