#!/usr/bin/env python3

import uuid
import re

# Generate UUIDs for NetworkingProtocols.swift
file_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]
build_uuid = str(uuid.uuid4()).upper().replace('-', '')[:24]

print(f"Adding NetworkingProtocols.swift with UUID: {file_uuid}")

# Read project file
with open("LyoApp.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Add file reference
file_ref = f'\t\t{file_uuid} /* NetworkingProtocols.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NetworkingProtocols.swift; sourceTree = "<group>"; }};'

# Insert file reference
pbx_file_ref_end = content.find('/* End PBXFileReference section */')
if pbx_file_ref_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_file_ref_end)
    content = content[:insertion_point] + '\n' + file_ref + content[insertion_point:]

# Add build file
build_file = f'\t\t{build_uuid} /* NetworkingProtocols.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* NetworkingProtocols.swift */; }};'

# Insert build file
pbx_build_file_end = content.find('/* End PBXBuildFile section */')
if pbx_build_file_end != -1:
    insertion_point = content.rfind('\n', 0, pbx_build_file_end)
    content = content[:insertion_point] + '\n' + build_file + content[insertion_point:]

# Add to Networking group (CE7133B6BA7D44ABBB812638)
networking_group_id = "CE7133B6BA7D44ABBB812638"
group_pattern = rf'({networking_group_id} /\* Networking \*/ = \{{\s+isa = PBXGroup;\s+children = \([^)]+)'
match = re.search(group_pattern, content, re.DOTALL)
if match:
    insertion_point = match.end()
    file_entry = f'\n\t\t\t\t{file_uuid} /* NetworkingProtocols.swift */,'
    content = content[:insertion_point] + file_entry + content[insertion_point:]

# Add to Sources build phase
sources_phase_pattern = r'(92A5145C75D5A57ABAFEE26F /\* Sources \*/ = \{[^}]+files = \([^)]+)'
match = re.search(sources_phase_pattern, content, re.DOTALL)
if match:
    insertion_point = match.end()
    build_entry = f'\n\t\t\t\t{build_uuid} /* NetworkingProtocols.swift in Sources */,'
    content = content[:insertion_point] + build_entry + content[insertion_point:]

# Write back to file
with open("LyoApp.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Successfully added NetworkingProtocols.swift to Xcode project")
