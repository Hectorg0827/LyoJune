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
        ("ModernViews.swift", "LyoApp/DesignSystem/ModernViews.swift"),
        ("HapticManager.swift", "LyoApp/DesignSystem/HapticManager.swift"), 
        ("DesignTokens.swift", "LyoApp/DesignSystem/DesignTokens.swift"),
        
        # Core/Shared files
        ("ErrorTypes.swift", "LyoApp/Core/Shared/ErrorTypes.swift"),
        
        # Core/Configuration files
        ("ConfigurationManager.swift", "LyoApp/Core/Configuration/ConfigurationManager.swift"),
        
        # Core/Networking files
        ("APIClient.swift", "LyoApp/Core/Networking/APIClient.swift"),
        ("EnhancedNetworkManager.swift", "LyoApp/Core/Networking/EnhancedNetworkManager.swift"),
        ("NetworkingProtocols.swift", "LyoApp/Core/Networking/NetworkingProtocols.swift"),
        
        # Core/Services files
        ("WebSocketManager.swift", "LyoApp/Core/Services/WebSocketManager.swift"),
        ("GamificationAPIService.swift", "LyoApp/Core/Services/GamificationAPIService.swift"),
        ("CommunityAPIService.swift", "LyoApp/Core/Services/CommunityAPIService.swift"),
        ("UserAPIService.swift", "LyoApp/Core/Services/UserAPIService.swift"),
        ("EnhancedAIService.swift", "LyoApp/Core/Services/EnhancedAIService.swift"),
        ("AIService.swift", "LyoApp/Core/Services/AIService.swift"),
        ("OfflineManager.swift", "LyoApp/Core/Services/OfflineManager.swift"),
        ("ErrorManager.swift", "LyoApp/Core/Services/ErrorManager.swift"),
        ("AnalyticsAPIService.swift", "LyoApp/Core/Services/AnalyticsAPIService.swift"),
        ("DataManager.swift", "LyoApp/Core/Services/DataManager.swift"),
        ("EnhancedServiceFactory.swift", "LyoApp/Core/Services/EnhancedServiceFactory.swift"),
        ("APIServices.swift", "LyoApp/Core/Services/APIServices.swift"),
        ("EnhancedAuthService.swift", "LyoApp/Core/Services/EnhancedAuthService.swift"),
        
        # Core/Models files
        ("CourseModels.swift", "LyoApp/Core/Models/CourseModels.swift"),
        ("CommunityModels.swift", "LyoApp/Core/Models/CommunityModels.swift"),
        ("AIModels.swift", "LyoApp/Core/Models/AIModels.swift"),
        ("AuthModels.swift", "LyoApp/Core/Models/AuthModels.swift"),
        ("AppModels.swift", "LyoApp/Core/Models/AppModels.swift"),
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
