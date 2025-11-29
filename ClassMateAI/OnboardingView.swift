import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to StudyHack.ai!",
            subtitle: "Your AI-powered study companion",
            description: "Meet Oso, your friendly guide who'll help you ace your classes! 🎓",
            imageName: "oso_welcome",
            color: .purple,
            features: []
        ),
        OnboardingPage(
            title: "Organize Your Classes",
            subtitle: "Stay on top of everything",
            description: "Create subjects, add lectures, and keep all your coursework in one place.",
            imageName: "folder.badge.plus",
            color: .blue,
            features: ["📚 Add subjects", "📝 Create lectures", "🗂️ Organize materials"]
        ),
        OnboardingPage(
            title: "Connect to Canvas",
            subtitle: "Sync your assignments",
            description: "Link your Canvas account and see all your assignments, due dates, and grades automatically.",
            imageName: "link.circle.fill",
            color: .orange,
            features: ["📅 View assignments", "⏰ Track due dates", "✅ Mark complete"]
        ),
        OnboardingPage(
            title: "Capture Everything",
            subtitle: "Never miss a detail",
            description: "Take photos of whiteboards, upload documents, and record lectures with ease.",
            imageName: "camera.fill",
            color: .green,
            features: ["📸 Snap visuals", "📄 Upload docs", "🎙️ Record audio"]
        ),
        OnboardingPage(
            title: "AI-Powered Notes",
            subtitle: "Smart transcription",
            description: "Record lectures and get instant transcriptions with timestamps and key points.",
            imageName: "waveform.circle.fill",
            color: .pink,
            features: ["🎤 Auto-transcribe", "⏱️ Timestamps", "📋 Organized notes"]
        ),
        OnboardingPage(
            title: "Ask Oso Anything",
            subtitle: "Your AI study buddy",
            description: "Get help with homework, clarify concepts, or quiz yourself using your lecture materials.",
            imageName: "sparkles",
            color: .cyan,
            features: ["💬 Ask questions", "📖 Reference materials", "🧠 Study smarter"]
        ),
        OnboardingPage(
            title: "Ready to Get Started?",
            subtitle: "Let's make learning easier!",
            description: "Oso is excited to help you succeed. Tap below to begin your journey!",
            imageName: "oso_ready",
            color: .purple,
            features: []
        )
    ]
    
    var body: some View {
        ZStack {
            // Light gradient background
            LinearGradient(
                colors: [Color.white, pages[currentPage].color.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.mateSecondary)
                        }
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(pages[currentPage].color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(pages[currentPage].color.opacity(0.15))
                            )
                        }
                    }
                    
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            Image(systemName: currentPage == pages.count - 1 ? "arrow.right.circle.fill" : "chevron.right")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: pages[currentPage].color.opacity(0.4), radius: 8, y: 4)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
    let features: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon or mascot
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.3), page.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                if page.imageName.starts(with: "oso_") {
                    // Placeholder for Oso mascot - will be replaced with actual image
                    Text("🐕")
                        .font(.system(size: 120))
                } else {
                    Image(systemName: page.imageName)
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(.bottom, 20)
            
            // Title
            VStack(spacing: 8) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.mateSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.mateText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            
            // Features
            if !page.features.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(page.color)
                                .frame(width: 8, height: 8)
                            
                            Text(feature)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.mateText)
                            
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: page.color.opacity(0.15), radius: 12, y: 4)
                )
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            
            Spacer()
        }
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

