#!/usr/bin/env python3
import uuid

def add_appmodels_to_project():
    # Generate unique IDs for Xcode
    file_ref_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    build_file_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    print(f'File Reference ID: {file_ref_id}')
    print(f'Build File ID: {build_file_id}')
    
    # Read the project file
    with open('LyoApp.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # Add the file reference and build file
    file_ref_line = f'\t\t{file_ref_id} /* AppModels.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppModels.swift; sourceTree = "<group>"; }};'
    build_file_line = f'\t\t{build_file_id} /* AppModels.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* AppModels.swift */; }};'
    
    # Find Models group (first look for a Models group)
    models_group_pattern = '/\\* Models \\*/ = {'
    models_group_pos = content.find(models_group_pattern)
    
    if models_group_pos != -1:
        # Find the children array for the Models group
        children_start = content.find('children = (', models_group_pos)
        if children_start != -1:
            # Find the end of the opening parenthesis line
            line_end = content.find('\n', children_start)
            # Insert the file reference after the opening line
            content = content[:line_end] + '\n\t\t\t\t' + file_ref_id + ' /* AppModels.swift */,' + content[line_end:]
    
    # Add to PBXFileReference section
    pbx_file_ref_section_start = content.find('/* Begin PBXFileReference section */')
    if pbx_file_ref_section_start != -1:
        # Find the end of the section header line
        line_end = content.find('\n', pbx_file_ref_section_start)
        content = content[:line_end] + '\n' + file_ref_line + content[line_end:]
    
    # Add to PBXBuildFile section
    pbx_build_file_section_start = content.find('/* Begin PBXBuildFile section */')
    if pbx_build_file_section_start != -1:
        line_end = content.find('\n', pbx_build_file_section_start)
        content = content[:line_end] + '\n' + build_file_line + content[line_end:]
    
    # Add to Sources build phase
    sources_phase_pattern = 'isa = PBXSourcesBuildPhase;'
    sources_phase_start = content.find(sources_phase_pattern)
    if sources_phase_start != -1:
        files_start = content.find('files = (', sources_phase_start)
        if files_start != -1:
            line_end = content.find('\n', files_start)
            content = content[:line_end] + '\n\t\t\t\t' + build_file_id + ' /* AppModels.swift in Sources */,' + content[line_end:]
    
    # Write back
    with open('LyoApp.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)
    
    print('AppModels.swift added to Xcode project successfully!')

if __name__ == '__main__':
    add_appmodels_to_project()
