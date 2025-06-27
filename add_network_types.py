#!/usr/bin/env python3
import re
import uuid

# Read the project file
with open("LyoApp.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Look for an existing shared file reference for pattern
api_models_match = re.search(r"([A-F0-9]{24})\s*/\* APIModels\.swift \*/ = \{isa = PBXFileReference.*?path = APIModels\.swift.*?\};", content)
if not api_models_match:
    print("Could not find APIModels.swift reference pattern")
    exit(1)

api_models_ref = api_models_match.group(1)
print(f"Found APIModels.swift reference: {api_models_ref}")

# Generate new UUID for NetworkTypes.swift
network_types_ref = uuid.uuid4().hex.upper()[:24]

# Add NetworkTypes.swift file reference
file_ref_section = re.search(r"(\/\* Begin PBXFileReference section \*\/.*?)\/\* End PBXFileReference section \*\/", content, re.DOTALL)
if file_ref_section:
    new_file_ref = f"\t\t{network_types_ref} /* NetworkTypes.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NetworkTypes.swift; sourceTree = \"<group>\"; }};"
    content = content.replace(
        "/* End PBXFileReference section */",
        new_file_ref + "\n\t/* End PBXFileReference section */"
    )
    print(f"Added NetworkTypes.swift file reference with ID: {network_types_ref}")

# Find the Core/Shared group and add NetworkTypes.swift  
shared_group_match = re.search(r"([A-F0-9]{24})\s*/\* Shared \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(([^)]*)\);", content)
if shared_group_match:
    shared_group_id = shared_group_match.group(1)
    children_content = shared_group_match.group(2)
    
    # Add NetworkTypes.swift to the children list
    new_children = children_content.rstrip() + f"\n\t\t\t\t{network_types_ref} /* NetworkTypes.swift */,"
    content = re.sub(
        rf"{shared_group_id}\s*/\* Shared \*/ = \{{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \([^)]*\);",
        f"{shared_group_id} /* Shared */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ({new_children}\n\t\t\t);",
        content
    )
    print(f"Added NetworkTypes.swift to Shared group")

# Find the LyoApp target and add NetworkTypes.swift to build phase
lyoapp_target_match = re.search(r"([A-F0-9]{24})\s*/\* Sources \*/ = \{\n\t\t\tisa = PBXSourcesBuildPhase;[^}]*files = \(([^)]*)\);", content)
if lyoapp_target_match:
    sources_group_id = lyoapp_target_match.group(1)
    sources_files = lyoapp_target_match.group(2)
    
    # Generate build file UUID
    network_types_build_ref = uuid.uuid4().hex.upper()[:24]
    
    # Add build file reference
    build_file_section = re.search(r"(\/\* Begin PBXBuildFile section \*\/.*?)\/\* End PBXBuildFile section \*\/", content, re.DOTALL)
    if build_file_section:
        new_build_file = f"\t\t{network_types_build_ref} /* NetworkTypes.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {network_types_ref} /* NetworkTypes.swift */; }};"
        content = content.replace(
            "/* End PBXBuildFile section */",
            new_build_file + "\n\t/* End PBXBuildFile section */"
        )
        print(f"Added NetworkTypes.swift build file reference")
    
    # Add to sources build phase
    new_sources = sources_files.rstrip() + f"\n\t\t\t\t{network_types_build_ref} /* NetworkTypes.swift in Sources */,"
    content = re.sub(
        rf"{sources_group_id}\s*/\* Sources \*/ = \{{\n\t\t\tisa = PBXSourcesBuildPhase;[^}}]*files = \([^)]*\);",
        f"{sources_group_id} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ({new_sources}\n\t\t\t);\n\t\t\tinputFileListPaths = (\n\t\t\t);\n\t\t\tinputPaths = (\n\t\t\t);\n\t\t\toutputFileListPaths = (\n\t\t\t);\n\t\t\toutputPaths = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        content
    )
    print(f"Added NetworkTypes.swift to LyoApp target sources")

# Write back to file
with open("LyoApp.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Successfully added NetworkTypes.swift to Xcode project")
