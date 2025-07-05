#!/usr/bin/env python3

import uuid

# Generate UUID for AnimationSystem.swift
animation_file_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]
animation_build_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]

print(f"File UUID: {animation_file_uuid}")
print(f"Build UUID: {animation_build_uuid}")

# Read project file
with open("LyoApp.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Add file reference
file_ref = f'\t\t{animation_file_uuid} /* AnimationSystem.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AnimationSystem.swift; sourceTree = "<group>"; }};'

# Find the end of PBXFileReference section
pbx_file_ref_end = content.find('/* End PBXFileReference section */')
if pbx_file_ref_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_file_ref_end)
    content = content[:insertion_point] + '\n' + file_ref + content[insertion_point:]

# Add build file
build_file = f'\t\t{animation_build_uuid} /* AnimationSystem.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {animation_file_uuid} /* AnimationSystem.swift */; }};'

# Find the end of PBXBuildFile section
pbx_build_file_end = content.find('/* End PBXBuildFile section */')
if pbx_build_file_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_build_file_end)
    content = content[:insertion_point] + '\n' + build_file + content[insertion_point:]

# Add to DesignSystem group (find the group and add the file)
design_system_group_id = "1EDE9C732A326B470F4A35F9"
import re
group_pattern = rf'({design_system_group_id} /\* DesignSystem \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
match = re.search(group_pattern, content, re.DOTALL)
if match:
    insertion_point = match.end()
    file_entry = f'\n\t\t\t\t{animation_file_uuid} /* AnimationSystem.swift */,'
    content = content[:insertion_point] + file_entry + content[insertion_point:]

# Add to Sources build phase
sources_phase_pattern = r'(92A5145C75D5A57ABAFEE26F /\* Sources \*/ = \{[^}]+files = \([^)]+)'
match = re.search(sources_phase_pattern, content, re.DOTALL)
if match:
    insertion_point = match.end()
    build_entry = f'\n\t\t\t\t{animation_build_uuid} /* AnimationSystem.swift in Sources */,'
    content = content[:insertion_point] + build_entry + content[insertion_point:]

# Write back to file
with open("LyoApp.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Added AnimationSystem.swift to Xcode project")
