import SwiftUI
import SwiftData

struct CurrentFundsView: View {
    @Query private var bankAccounts: [BankAccount]

    let totalBalance: Double
    @State private var isExpanded = false

    private var groupedAccounts: [String: [BankAccount]] {
        Dictionary(grouping: bankAccounts) { $0.bankName }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Current Funds")
                        .font(.headline)

                    Spacer()

                    Text("$\(totalBalance, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(totalBalance >= 0 ? Color.green : Color.red)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedAccounts.keys.sorted(), id: \.self) { bankName in
                        BankSection(bankName: bankName, accounts: groupedAccounts[bankName] ?? [])
                    }
                }
                .padding(.top, 16)
            }
        }
    }
}

struct BankSection: View {
    let bankName: String
    let accounts: [BankAccount]

    private var bankTotal: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(bankName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("$\(bankTotal, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(bankTotal >= 0 ? Color.primary : Color.red)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(accounts.sorted(by: { $0.accountName < $1.accountName })) { account in
                    HStack {
                        Circle()
                            .fill(account.balance >= 0 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(account.accountName)
                            .font(.caption)

                        Spacer()

                        Text("$\(account.balance, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundStyle(account.balance >= 0 ? Color.primary : Color.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    CurrentFundsView(totalBalance: 19880.50)
        .modelContainer(for: BankAccount.self, inMemory: true)
}
