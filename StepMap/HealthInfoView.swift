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
                        value: Formatters.formatStepLength(viewModel.stepLength),
                        icon: "ruler",
                        description: "Average length of your walking step"
                    )
                    .padding(.horizontal)
                    
                    // Walking Speed Card
                    HealthStatCard(
                        title: "Walking Speed",
                        value: Formatters.formatWalkingSpeed(viewModel.walkingSpeed),
                        icon: "figure.walk",
                        description: "Your average walking pace"
                    )
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
