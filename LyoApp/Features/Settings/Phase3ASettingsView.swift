//
//  Phase3ASettingsView.swift
//  LyoApp
//
//  Advanced settings view for all Phase 3A features
//

import SwiftUI

struct Phase3ASettingsView: View {
    @StateObject private var integrationManager = Phase3AIntegrationManager.shared
    @StateObject private var biometricManager = BiometricAuthManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var securityManager = SecurityManager.shared
    
    @State private var showingSystemHealthDetails = false
    @State private var showingSecurityDetails = false
    @State private var showingInitializationSheet = false
    @State private var selectedFeature: Phase3AFeature?
    
    var body: some View {
        NavigationView {
            List {
                systemHealthSection
                featuresSection
                securitySection
                advancedSection
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await integrationManager.updateSystemHealth()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Initialize All Features") {
                            showingInitializationSheet = true
                        }
                        
                        Button("Refresh System Health") {
                            Task {
                                await integrationManager.updateSystemHealth()
                            }
                        }
                        
                        Button("Reset Configuration") {
                            integrationManager.updateConfiguration(.default)
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInitializationSheet) {
            InitializationSheetView()
        }
        .sheet(item: $selectedFeature) { feature in
            FeatureDetailView(feature: feature)
        }
    }
    
    // MARK: - System Health Section
    
    private var systemHealthSection: some View {
        Section {
            HStack {
                Image(systemName: integrationManager.overallHealth.systemImage)
                    .foregroundColor(integrationManager.overallHealth.color)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("System Health")
                        .font(.headline)
                    Text(integrationManager.overallHealth.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if integrationManager.isInitialized {
                    Text("\(activeFeatureCount)/\(totalFeatureCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not Initialized")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingSystemHealthDetails = true
            }
            
            if integrationManager.isInitializing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Initializing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: integrationManager.initializationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        } header: {
            Text("Status")
        }
        .sheet(isPresented: $showingSystemHealthDetails) {
            SystemHealthDetailView()
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        Section {
            ForEach(Phase3AFeature.allCases.sorted(by: { $0.priority < $1.priority }), id: \.self) { feature in
                FeatureRowView(feature: feature)
                    .onTapGesture {
                        selectedFeature = feature
                    }
            }
        } header: {
            Text("Features")
        } footer: {
            Text("Tap any feature to view details and configure settings.")
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            HStack {
                Image(systemName: securityManager.isSecure ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(securityManager.isSecure ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text("Security Status")
                        .font(.headline)
                    Text(securityManager.isSecure ? "Secure" : "\(securityManager.currentThreats.count) threat(s) detected")
                        .font(.subheadline)
                        .foregroundColor(securityManager.isSecure ? .green : .red)
                }
                
                Spacer()
                
                Button("Details") {
                    showingSecurityDetails = true
                }
                .font(.caption)
            }
            
            Toggle("Biometric Authentication", isOn: Binding(
                get: { biometricManager.isEnabled },
                set: { newValue in
                    Task {
                        if newValue {
                            _ = await biometricManager.enableBiometricAuth()
                        } else {
                            _ = await biometricManager.disableBiometricAuth()
                        }
                    }
                }
            ))
            .disabled(!biometricManager.isAvailable)
            
        } header: {
            Text("Security")
        }
        .sheet(isPresented: $showingSecurityDetails) {
            SecurityDetailView()
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        Section {
            Toggle("Auto-start Features", isOn: Binding(
                get: { integrationManager.configuration.autoStartFeatures },
                set: { newValue in
                    var config = integrationManager.configuration
                    config.autoStartFeatures = newValue
                    integrationManager.updateConfiguration(config)
                }
            ))
            
            HStack {
                Text("Background Sync Interval")
                Spacer()
                Text(formatInterval(integrationManager.configuration.backgroundSyncInterval))
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Notification Settings") {
                NotificationSettingsView()
            }
            
            NavigationLink("Data & Privacy") {
                DataPrivacyView()
            }
            
        } header: {
            Text("Advanced")
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeFeatureCount: Int {
        integrationManager.featureStatuses.values.filter { $0.status == .active }.count
    }
    
    private var totalFeatureCount: Int {
        integrationManager.featureStatuses.count
    }
    
    // MARK: - Helper Methods
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }
}

// MARK: - Feature Row View
struct FeatureRowView: View {
    let feature: Phase3AFeature
    @StateObject private var integrationManager = Phase3AIntegrationManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: feature.systemImage)
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.headline)
                
                if let status = integrationManager.featureStatuses[feature] {
                    HStack {
                        Text(status.status.displayName)
                            .font(.caption)
                            .foregroundColor(status.status.color)
                        
                        if let error = status.errorMessage {
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: {
                    integrationManager.configuration.enabledFeatures.contains(feature.rawValue)
                },
                set: { newValue in
                    Task {
                        await integrationManager.toggleFeature(feature)
                    }
                }
            ))
        }
    }
}

// MARK: - Feature Detail View
struct FeatureDetailView: View {
    let feature: Phase3AFeature
    @StateObject private var integrationManager = Phase3AIntegrationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statusSection
                    configurationSection
                    actionsSection
                }
                .padding()
            }
            .navigationTitle(feature.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feature.systemImage)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(feature.displayName)
                        .font(.title2)
                        .bold()
                    
                    if let status = integrationManager.featureStatuses[feature] {
                        Label(status.status.displayName, systemImage: "circle.fill")
                            .foregroundColor(status.status.color)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
            }
            
            Text(featureDescription)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            
            if let status = integrationManager.featureStatuses[feature] {
                VStack(spacing: 8) {
                    InfoRow(title: "Enabled", value: status.isEnabled ? "Yes" : "No")
                    InfoRow(title: "Configured", value: status.isConfigured ? "Yes" : "No")
                    
                    if let lastUpdated = status.lastUpdated {
                        InfoRow(title: "Last Updated", value: DateFormatter.localizedString(from: lastUpdated, dateStyle: .short, timeStyle: .short))
                    }
                    
                    if let error = status.errorMessage {
                        InfoRow(title: "Error", value: error, valueColor: .red)
                    }
                }
            }
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
            
            // Feature-specific configuration options would go here
            Text("Feature-specific configuration options coming soon...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let status = integrationManager.featureStatuses[feature] {
                if !status.isConfigured {
                    AsyncButton("Initialize Feature") {
                        try await integrationManager.initializeFeature(feature)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if status.isConfigured {
                    AsyncButton(status.isEnabled ? "Stop Feature" : "Start Feature") {
                        if status.isEnabled {
                            await integrationManager.stopFeature(feature)
                        } else {
                            await integrationManager.startFeature(feature)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var featureDescription: String {
        switch feature {
        case .coreData:
            return "Offline-first data storage with automatic sync capabilities."
        case .biometricAuth:
            return "Secure authentication using Face ID, Touch ID, or Optic ID."
        case .notifications:
            return "Rich push and local notifications with custom actions."
        case .siriShortcuts:
            return "Voice commands and automation through Siri integration."
        case .spotlight:
            return "Make app content searchable through system-wide search."
        case .backgroundTasks:
            return "Background processing for content sync and maintenance."
        case .widgets:
            return "Home screen widgets showing progress and quick actions."
        case .security:
            return "Advanced security features including jailbreak detection."
        }
    }
}

// MARK: - System Health Detail View
struct SystemHealthDetailView: View {
    @StateObject private var integrationManager = Phase3AIntegrationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(healthMetrics, id: \.title) { metric in
                        HStack {
                            Text(metric.title)
                            Spacer()
                            Text(metric.value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Feature Status") {
                    ForEach(Phase3AFeature.allCases, id: \.self) { feature in
                        if let status = integrationManager.featureStatuses[feature] {
                            HStack {
                                Image(systemName: feature.systemImage)
                                    .foregroundColor(.blue)
                                
                                Text(feature.displayName)
                                
                                Spacer()
                                
                                Text(status.status.displayName)
                                    .foregroundColor(status.status.color)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("System Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var healthMetrics: [(title: String, value: String)] {
        let report = integrationManager.getSystemHealthReport()
        
        return [
            ("Overall Health", integrationManager.overallHealth.displayName),
            ("Active Features", "\(report["active_features"] ?? 0)"),
            ("Configured Features", "\(report["configured_features"] ?? 0)"),
            ("Error Features", "\(report["error_features"] ?? 0)"),
            ("Health Score", String(format: "%.1f%%", (report["health_score"] as? Double ?? 0) * 100))
        ]
    }
}

// MARK: - Security Detail View
struct SecurityDetailView: View {
    @StateObject private var securityManager = SecurityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Status") {
                    HStack {
                        Image(systemName: securityManager.isSecure ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(securityManager.isSecure ? .green : .red)
                        
                        Text(securityManager.isSecure ? "System Secure" : "Security Threats Detected")
                            .font(.headline)
                    }
                    
                    if !securityManager.currentThreats.isEmpty {
                        ForEach(Array(securityManager.currentThreats), id: \.rawValue) { threat in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                VStack(alignment: .leading) {
                                    Text(threat.rawValue.capitalized)
                                        .font(.headline)
                                    Text(threat.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(threat.severity.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(threat.severity == .critical ? .red : .orange)
                            }
                        }
                    }
                }
                
                if !securityManager.securityEvents.isEmpty {
                    Section("Recent Events") {
                        ForEach(securityManager.securityEvents.prefix(10), id: \.id) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(event.threat.rawValue.capitalized)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(DateFormatter.localizedString(from: event.timestamp, dateStyle: .none, timeStyle: .short))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(event.threat.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Security Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct InitializationSheetView: View {
    @StateObject private var integrationManager = Phase3AIntegrationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gear.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Initialize Phase 3A Features")
                    .font(.title)
                    .bold()
                
                Text("This will set up all advanced iOS features including biometric authentication, notifications, background sync, and more.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if integrationManager.isInitializing {
                    VStack(spacing: 12) {
                        ProgressView(value: integrationManager.initializationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Initializing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    AsyncButton("Initialize All Features") {
                        await integrationManager.initializeAllFeatures()
                        if integrationManager.isInitialized {
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Initialization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
        }
    }
}

struct AsyncButton<Label: View>: View {
    let action: () async throws -> Void
    @ViewBuilder let label: () -> Label
    
    @State private var isPerforming = false
    
    init(_ titleKey: LocalizedStringKey, action: @escaping () async throws -> Void) where Label == Text {
        self.action = action
        self.label = { Text(titleKey) }
    }
    
    init(action: @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            Task {
                isPerforming = true
                try? await action()
                isPerforming = false
            }
        } label: {
            if isPerforming {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    label()
                }
            } else {
                label()
            }
        }
        .disabled(isPerforming)
    }
}

// MARK: - Placeholder Views
struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
    }
}

struct DataPrivacyView: View {
    var body: some View {
        Text("Data & Privacy Settings")
            .navigationTitle("Data & Privacy")
    }
}

#Preview {
    Phase3ASettingsView()
}
