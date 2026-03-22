import SwiftUI

struct AILoadingView: View {
    let isLoading: Bool
    let isReceiving: Bool
    let streamingContent: String
    let theme: Theme
    
    @State private var dotAnimation: [Bool] = [false, false, false]
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                loadingState()
            } else if isReceiving {
                receivingState()
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(pulseScale)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    private func loadingState() -> some View {
        VStack(spacing: 20) {
            // Modern animated AI icon with particle effect
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(theme.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseScale)
                
                // Inner glow
                Circle()
                    .fill(theme.accent.opacity(glowOpacity))
                    .frame(width: 50, height: 50)
                    .blur(radius: 6)
                
                // Main icon
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.accent)
                    .scaleEffect(1.0 + (pulseScale - 1.0) * 0.3)
            }
            
            // Enhanced animated dots with wave effect
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimation[index] ? 1.4 : 0.8)
                        .opacity(dotAnimation[index] ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: dotAnimation[index]
                        )
                }
            }
            
            VStack(spacing: 8) {
                Text("AI is analyzing...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text("Processing your request with care")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
    
    private func receivingState() -> some View {
        VStack(spacing: 20) {
            // Modern animated writing icon with flowing effect
            ZStack {
                // Flowing background
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                
                // Writing icon with subtle rotation
                Image(systemName: "pencil.line")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(theme.accent)
                    .rotationEffect(.degrees(pulseScale == 1.0 ? 0 : -3))
            }
            
            // Modern flowing bars animation
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent)
                        .frame(width: 3, height: dotAnimation.indices.contains(index % 3) && dotAnimation[index % 3] ? 16 : 8)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                            value: dotAnimation[index % 3]
                        )
                }
            }
            
            VStack(spacing: 8) {
                Text("Receiving response...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                if !streamingContent.isEmpty {
                    Text("Processing \(streamingContent.count) characters")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    Text("Waiting for AI response")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    private func startAnimations() {
        // Start smooth dot animations with staggered timing
        for i in 0..<3 {
            dotAnimation[i] = true
        }
        
        // Start gentle pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
        
        // Start soft glow animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.7
        }
    }
    
    private func stopAnimations() {
        // Reset all animations
        for i in 0..<3 {
            dotAnimation[i] = false
        }
        pulseScale = 1.0
        glowOpacity = 0.3
    }
}

// MARK: - Streaming Text Preview

struct StreamingTextPreview: View {
    let content: String
    let theme: Theme
    @State private var visibleCharacters = 0
    @State private var showCursor = true
    
    var body: some View {
        if !content.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accent)
                    Text("Live Preview")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Spacer()
                    
                    Text("\(visibleCharacters)/\(content.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.backgroundSecondary.opacity(0.5))
                        )
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(String(content.prefix(visibleCharacters)))
                                .font(.system(size: 13, design: .default))
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .animation(.none, value: visibleCharacters)
                            
                            // Animated typing cursor
                            if visibleCharacters < content.count {
                                Rectangle()
                                    .fill(theme.accent)
                                    .frame(width: 2, height: 16)
                                    .opacity(showCursor ? 1.0 : 0.3)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
                            }
                        }
                    }
                }
                .frame(maxHeight: 140)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.background.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .onAppear {
                showCursor = true
                animateText()
            }
            .onChange(of: content) { _, _ in
                animateText()
            }
        }
    }
    
    private func animateText() {
        let targetCount = content.count
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if visibleCharacters < targetCount {
                visibleCharacters = min(visibleCharacters + 3, targetCount)
            } else {
                timer.invalidate()
                showCursor = false
            }
        }
    }
}

#if DEBUG
struct AILoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            AILoadingView(
                isLoading: true,
                isReceiving: false,
                streamingContent: "",
                theme: DarkTheme()
            )
            
            AILoadingView(
                isLoading: false,
                isReceiving: true,
                streamingContent: "This is a sample streaming response that shows how the AI content appears as it's being received...",
                theme: DarkTheme()
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
