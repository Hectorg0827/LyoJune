#!/usr/bin/env python3

import os
import re

def fix_file_paths_in_xcode_project():
    """Fix file paths in the Xcode project to use correct relative paths."""
    
    project_file = "LyoApp.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Define files that need their paths fixed
    files_to_fix = [
        # DesignSystem files
        ("ModernViews.swift", "ModernViews.swift"),
        ("HapticManager.swift", "HapticManager.swift"), 
        ("DesignTokens.swift", "DesignTokens.swift"),
        
        # Core/Shared files
        ("ErrorTypes.swift", "Shared/ErrorTypes.swift"),
        
        # Core/Configuration files
        ("ConfigurationManager.swift", "Configuration/ConfigurationManager.swift"),
        
        # Core/Networking files
        ("APIClient.swift", "Networking/APIClient.swift"),
        ("EnhancedNetworkManager.swift", "Networking/EnhancedNetworkManager.swift"),
        
        # Core/Services files
        ("WebSocketManager.swift", "Services/WebSocketManager.swift"),
        ("GamificationAPIService.swift", "Services/GamificationAPIService.swift"),
        ("CommunityAPIService.swift", "Services/CommunityAPIService.swift"),
        ("UserAPIService.swift", "Services/UserAPIService.swift"),
        ("EnhancedAIService.swift", "Services/EnhancedAIService.swift"),
        ("AIService.swift", "Services/AIService.swift"),
        ("OfflineManager.swift", "Services/OfflineManager.swift"),
        ("ErrorManager.swift", "Services/ErrorManager.swift"),
        ("AnalyticsAPIService.swift", "Services/AnalyticsAPIService.swift"),
        ("DataManager.swift", "Services/DataManager.swift"),
        ("EnhancedServiceFactory.swift", "Services/EnhancedServiceFactory.swift"),
        ("APIServices.swift", "Services/APIServices.swift"),
        ("EnhancedAuthService.swift", "Services/EnhancedAuthService.swift"),
        
        # Core/Models files
        ("CourseModels.swift", "Models/CourseModels.swift"),
        ("CommunityModels.swift", "Models/CommunityModels.swift"),
        ("AIModels.swift", "Models/AIModels.swift"),
        ("AuthModels.swift", "Models/AuthModels.swift"),
        ("AppModels.swift", "Models/AppModels.swift"),
    ]
    
    # First, let's find all file references and fix just the ones with simple names
    for simple_name, correct_path in files_to_fix:
        # Find PBXFileReference entries for this file
        pattern = rf'(\w+) /\* {re.escape(simple_name)} \*/ = \{{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = {re.escape(simple_name)}; sourceTree = "<group>"; \}};'
        
        def replacement(match):
            file_id = match.group(1)
            return f'{file_id} /* {simple_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {correct_path}; sourceTree = "<group>"; }};'
        
        content = re.sub(pattern, replacement, content)
    
    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Fixed file paths in Xcode project.")
    print("Updated files:")
    for simple_name, correct_path in files_to_fix:
        print(f"  {simple_name} -> {correct_path}")

if __name__ == "__main__":
    fix_file_paths_in_xcode_project()
