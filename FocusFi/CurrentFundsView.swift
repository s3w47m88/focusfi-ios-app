import SwiftUI
import SwiftData

struct CurrentFundsView: View {
    @Query private var bankAccounts: [BankAccount]

    let totalBalance: Double
    @State private var isExpanded = false
    @State private var expandedBanks: Set<String> = []

    private var groupedAccounts: [String: [BankAccount]] {
        Dictionary(grouping: bankAccounts) { $0.bankName }
    }

    private var sortedGroupIds: [String] {
        groupedAccounts.keys.sorted { lhs, rhs in
            let lhsAccounts = groupedAccounts[lhs] ?? []
            let rhsAccounts = groupedAccounts[rhs] ?? []
            let lhsCreditOnly = !lhsAccounts.isEmpty && lhsAccounts.allSatisfy { $0.isCredit }
            let rhsCreditOnly = !rhsAccounts.isEmpty && rhsAccounts.allSatisfy { $0.isCredit }
            if lhsCreditOnly != rhsCreditOnly {
                return !lhsCreditOnly
            }
            let lhsName = displayName(for: lhs)
            let rhsName = displayName(for: rhs)
            return lhsName < rhsName
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Accounts")
                        .font(.headline)

                    Spacer()

                    Text("$\(totalBalance, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(balanceColor(totalBalance))
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
                    ForEach(sortedGroupIds, id: \.self) { groupId in
                        BankSection(
                            bankName: displayName(for: groupId),
                            accounts: groupedAccounts[groupId] ?? [],
                            isExpanded: bindingForBank(groupId)
                        )
                    }
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            if expandedBanks.isEmpty {
                expandedBanks = Set(groupedAccounts.keys)
            }
        }
    }

    private func bindingForBank(_ groupId: String) -> Binding<Bool> {
        Binding(
            get: { expandedBanks.contains(groupId) },
            set: { isOpen in
                if isOpen {
                    expandedBanks.insert(groupId)
                } else {
                    expandedBanks.remove(groupId)
                }
            }
        )
    }

    private func displayName(for groupId: String) -> String {
        groupedAccounts[groupId]?.first?.bankName ?? groupId
    }
}

struct BankSection: View {
    let bankName: String
    let accounts: [BankAccount]
    @Binding var isExpanded: Bool

    private var bankTotal: Double {
        accounts
            .filter { $0.includeInTotal }
            .reduce(0) { $0 + $1.currentBalance }
    }

    private var sortedAccounts: [BankAccount] {
        accounts.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }
            if lhs.isCredit != rhs.isCredit {
                return !lhs.isCredit
            }
            return lhs.accountName < rhs.accountName
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                ForEach(sortedAccounts) { account in
                    AccountRow(account: account)
                }
            }
            .padding(.horizontal)
        } label: {
            HStack {
                Text(bankName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("$\(bankTotal, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(balanceColor(bankTotal))
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

struct AccountRow: View {
    @Bindable var account: BankAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: account.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(account.isFavorite ? Color.yellow : Color.secondary)
                    .font(.footnote)

                Text(account.accountName)
                    .font(.subheadline)

                Spacer()
            }

            HStack(spacing: 12) {
                Text("Available")
                    .foregroundStyle(.secondary)
                Text("$\(account.availableBalance, specifier: "%.2f")")
                    .foregroundStyle(.green)

                Text("Current")
                    .foregroundStyle(.secondary)
                Text("$\(account.currentBalance, specifier: "%.2f")")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            Toggle("Include in Accounts Total", isOn: $account.includeInTotal)
                .font(.footnote)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                account.isFavorite.toggle()
            } label: {
                Label(account.isFavorite ? "Unfavorite" : "Favorite", systemImage: account.isFavorite ? "star.slash" : "star")
            }
            .tint(.yellow)
        }
    }
}

private func balanceColor(_ value: Double) -> Color {
    if value > 0 {
        return .green
    }
    if value < 0 {
        return .red
    }
    return .secondary
}

#Preview {
    CurrentFundsView(totalBalance: 19880.50)
        .modelContainer(for: BankAccount.self, inMemory: true)
}
