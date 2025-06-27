#!/usr/bin/env python3
"""
Script to add the centralized shared files to the Xcode project.
This fixes the "Cannot find type in scope" errors by ensuring all shared files
are properly included in the LyoApp target.
"""

import os
import uuid
import re

def add_files_to_xcode_project():
    """Add missing shared files to the Xcode project."""
    
    project_path = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"
    
    # Files that need to be added
    shared_files = [
        "LyoApp/Core/Shared/ErrorTypes.swift",
        "LyoApp/Core/Shared/APIModels.swift", 
        "LyoApp/Core/Shared/BundleExtensions.swift",
        "LyoApp/Core/Shared/AuthTypes.swift"
    ]
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Find the main group and sources build phase
    main_group_pattern = r'(\w+) \/\* LyoApp \*\/ = \{'
    sources_build_phase_pattern = r'(\w+) \/\* Sources \*\/ = \{[^}]+buildActionMask = [^;]+;[^}]+files = \([^)]+\);'
    
    main_group_match = re.search(main_group_pattern, content)
    sources_build_phase_match = re.search(sources_build_phase_pattern, content)
    
    if not main_group_match or not sources_build_phase_match:
        print("Could not find required project structure")
        return False
    
    # Generate UUIDs for new files
    file_refs = {}
    build_files = {}
    
    for file_path in shared_files:
        file_name = os.path.basename(file_path)
        file_ref_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        build_file_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        
        file_refs[file_path] = {
            'uuid': file_ref_uuid,
            'name': file_name,
            'build_uuid': build_file_uuid
        }
        build_files[file_path] = build_file_uuid
    
    # Find the Core group
    core_group_pattern = r'(\w+) \/\* Core \*\/ = \{[^}]+children = \([^)]+\);'
    core_group_match = re.search(core_group_pattern, content)
    
    if core_group_match:
        core_group_uuid = core_group_match.group(1)
        
        # Find or create Shared group under Core
        shared_group_pattern = rf'{core_group_uuid} \/\* Core \*\/ = \{{[^}}]+children = \(([^)]+)\);'
        shared_group_match = re.search(shared_group_pattern, content)
        
        if shared_group_match:
            children_content = shared_group_match.group(1)
            
            # Check if Shared group already exists
            if "/* Shared */" not in children_content:
                # Create Shared group
                shared_group_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
                
                # Add Shared group reference to Core group
                new_children = children_content.rstrip().rstrip(',') + f',\n\t\t\t\t{shared_group_uuid} /* Shared */,'
                content = content.replace(
                    f"children = ({children_content});",
                    f"children = ({new_children}\n\t\t\t);"
                )
                
                # Add Shared group definition
                shared_group_def = f"""\t\t{shared_group_uuid} /* Shared */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(f'\t\t\t\t{file_refs[fp]["uuid"]} /* {file_refs[fp]["name"]} */,' for fp in shared_files)}
\t\t\t);
\t\t\tpath = Shared;
\t\t\tsourceTree = "<group>";
\t\t}};"""
                
                # Find a good place to insert the group definition
                insert_point = content.find("/* End PBXGroup section */")
                if insert_point != -1:
                    content = content[:insert_point] + shared_group_def + "\n" + content[insert_point:]
    
    # Add file references
    file_refs_section = "/* Begin PBXFileReference section */"
    insert_point = content.find(file_refs_section)
    if insert_point != -1:
        insert_point += len(file_refs_section)
        
        file_ref_entries = []
        for file_path in shared_files:
            file_name = file_refs[file_path]['name']
            file_uuid = file_refs[file_path]['uuid']
            
            file_ref_entry = f"\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = \"<group>\"; }};"
            file_ref_entries.append(file_ref_entry)
        
        content = content[:insert_point] + "\n" + "\n".join(file_ref_entries) + content[insert_point:]
    
    # Add build files
    build_files_section = "/* Begin PBXBuildFile section */"
    insert_point = content.find(build_files_section)
    if insert_point != -1:
        insert_point += len(build_files_section)
        
        build_file_entries = []
        for file_path in shared_files:
            file_name = file_refs[file_path]['name']
            build_uuid = file_refs[file_path]['build_uuid']
            file_uuid = file_refs[file_path]['uuid']
            
            build_file_entry = f"\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};"
            build_file_entries.append(build_file_entry)
        
        content = content[:insert_point] + "\n" + "\n".join(build_file_entries) + content[insert_point:]
    
    # Add to sources build phase
    sources_match = re.search(r'(\w+) \/\* Sources \*\/ = \{[^}]+files = \(([^)]+)\);', content)
    if sources_match:
        build_phase_uuid = sources_match.group(1)
        files_content = sources_match.group(2)
        
        # Add new build file references
        new_files = []
        for file_path in shared_files:
            build_uuid = file_refs[file_path]['build_uuid']
            file_name = file_refs[file_path]['name']
            new_files.append(f"\t\t\t\t{build_uuid} /* {file_name} in Sources */,")
        
        new_files_content = files_content.rstrip().rstrip(',') + ',\n' + '\n'.join(new_files)
        
        content = content.replace(
            f"files = ({files_content});",
            f"files = (\n{new_files_content}\n\t\t\t);"
        )
    
    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("Successfully added shared files to Xcode project")
    return True

if __name__ == "__main__":
    add_files_to_xcode_project()
