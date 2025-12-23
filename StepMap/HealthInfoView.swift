//
//  HealthInfoView.swift
//  StepMap
//
//  Created by Oliver Hnát on 23.12.2024.
//

import SwiftUI

struct HealthInfoView: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.thinMaterial)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Data")
                            .font(.title.bold())
                        Text("From Apple Health")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Step Length Card
                    HealthStatCard(
                        title: "Step Length",
                        value: Formatters.formatStepLength(viewModel.effectiveStepLength),
                        icon: "ruler",
                        description: viewModel.stepLengthOverride != nil 
                            ? "Manually adjusted" 
                            : (viewModel.stepLengthSource?.rawValue ?? "From Apple Health")
                    )
                    .padding(.horizontal)
                    
                    // Step Length Adjustment Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Adjust Step Length")
                                .font(.subheadline.bold())
                            Spacer()
                            if viewModel.stepLengthOverride != nil {
                                Button("Reset") {
                                    viewModel.stepLengthOverride = nil
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        let currentValue = viewModel.effectiveStepLength ?? 0.7
                        Slider(
                            value: Binding(
                                get: { currentValue * 100 },  // Convert to cm
                                set: { viewModel.stepLengthOverride = $0 / 100 }  // Convert back to meters
                            ),
                            in: 40...100,  // 40-100 cm range
                            step: 1
                        )
                        
                        HStack {
                            Text("40 cm")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(Formatters.formatStepLength(viewModel.effectiveStepLength))
                                .font(.caption.bold())
                            Spacer()
                            Text("100 cm")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Walking Speed Card
                    HealthStatCard(
                        title: "Walking Speed",
                        value: Formatters.formatWalkingSpeed(viewModel.effectiveWalkingSpeed),
                        icon: "figure.walk",
                        description: viewModel.walkingSpeedOverride != nil 
                            ? "Manually adjusted" 
                            : (viewModel.walkingSpeedSource?.rawValue ?? "From Apple Health")
                    )
                    .padding(.horizontal)
                    
                    // Walking Speed Adjustment Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Adjust Walking Speed")
                                .font(.subheadline.bold())
                            Spacer()
                            if viewModel.walkingSpeedOverride != nil {
                                Button("Reset") {
                                    viewModel.walkingSpeedOverride = nil
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        let currentSpeed = viewModel.effectiveWalkingSpeed ?? 1.4  // Default ~5 km/h
                        Slider(
                            value: Binding(
                                get: { currentSpeed * 3.6 },  // Convert m/s to km/h
                                set: { viewModel.walkingSpeedOverride = $0 / 3.6 }  // Convert back to m/s
                            ),
                            in: 2...8,  // 2-8 km/h range
                            step: 0.1
                        )
                        
                        HStack {
                            Text("2 km/h")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(Formatters.formatWalkingSpeed(viewModel.effectiveWalkingSpeed))
                                .font(.caption.bold())
                            Spacer()
                            Text("8 km/h")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How this data is used", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("StepMap uses your health data from Apple Health to provide personalized route information:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoBullet(
                                icon: "ruler",
                                text: "Step length is used to estimate the number of steps for your walking routes."
                            )
                            
                            InfoBullet(
                                icon: "clock",
                                text: "Walking speed can be used to provide more accurate time estimates."
                            )
                        }
                        
                        Text("This data is read-only and stays on your device. StepMap never uploads your health data.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
    }
}

// MARK: - Health Stat Card
struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Info Bullet
struct InfoBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HealthInfoView(viewModel: ViewModel())
}
