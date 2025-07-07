#!/usr/bin/env python3

import uuid

# Generate UUIDs
file_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]
build_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]

print(f"File UUID: {file_uuid}")
print(f"Build UUID: {build_uuid}")

project_file = "/Users/republicalatuya/Desktop/LyoJune/LyoApp.xcodeproj/project.pbxproj"

# Read the project file
with open(project_file, "r") as f:
    content = f.read()

# 1. Add PBXFileReference
file_ref_line = f"\t\t{file_uuid} /* NetworkingProtocols.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NetworkingProtocols.swift; sourceTree = \"<group>\"; }};"

# Find the last line in PBXFileReference section
pbx_file_ref_end = content.find('/* End PBXFileReference section */')
if pbx_file_ref_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_file_ref_end)
    content = content[:insertion_point] + '\n' + file_ref_line + content[insertion_point:]

# 2. Add PBXBuildFile  
build_file_line = f"\t\t{build_uuid} /* NetworkingProtocols.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* NetworkingProtocols.swift */; }};"

pbx_build_file_end = content.find('/* End PBXBuildFile section */')
if pbx_build_file_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_build_file_end)
    content = content[:insertion_point] + '\n' + build_file_line + content[insertion_point:]

# 3. Add to Networking group
networking_section = "EB1AB25F7A8A449FB806F6BB /* EnhancedNetworkManager.swift */,"
replacement = f"EB1AB25F7A8A449FB806F6BB /* EnhancedNetworkManager.swift */,\n\t\t\t\t{file_uuid} /* NetworkingProtocols.swift */,"

if networking_section in content:
    content = content.replace(networking_section, replacement)

# 4. Add to Sources build phase - need to find the correct build phase
# Look for the Sources build phase
sources_build_phase_pattern = "7CCDE3E310FD4F9C9D863936 /* ErrorTypes.swift in Sources */,"
sources_replacement = f"7CCDE3E310FD4F9C9D863936 /* ErrorTypes.swift in Sources */,\n\t\t\t\t{build_uuid} /* NetworkingProtocols.swift in Sources */,"

if sources_build_phase_pattern in content:
    content = content.replace(sources_build_phase_pattern, sources_replacement)

# Write the updated content
with open(project_file, "w") as f:
    f.write(content)

print("Successfully added NetworkingProtocols.swift to the project!")
