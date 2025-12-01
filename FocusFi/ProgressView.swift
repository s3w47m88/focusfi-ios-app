import SwiftUI

struct FinanceProgressView: View {
    let title: String
    let current: Double
    let forecast: Double
    let color: Color

    private var progress: Double {
        guard forecast > 0 else { return 0 }
        return min(current / forecast, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(current, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("of $\(forecast, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Custom progress bar with glass effect
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(height: 16)

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 16)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 16)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FinanceProgressView(
            title: "Income",
            current: 7500,
            forecast: 10000,
            color: .green
        )

        FinanceProgressView(
            title: "Expenses",
            current: 5200,
            forecast: 8000,
            color: .red
        )
    }
    .padding()
}
