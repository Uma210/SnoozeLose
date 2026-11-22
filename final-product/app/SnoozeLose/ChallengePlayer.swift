import SwiftUI
import UIKit

private let lightBlue = Color(red: 224.0/255.0, green: 1, blue: 1)
private let purple = Color(red: 106.0/255.0, green: 90.0/255.0, blue: 205.0/255.0)

struct ChallengePlayer: View {
    @EnvironmentObject private var model: SnoozeModel
    let item: ChallengeItem

    var body: some View {
        VStack(spacing: 12) {
            switch item.kind {
            case .perception:
                PerceptionSetGame(item: item) { model.complete(item) }
            case .word:
                SnoozeLoseWordGame(
                    occurrenceID: item.id.uuidString,
                    alarmTime: model.session.flatMap { active in
                        model.alarms.first(where: { $0.id == active.alarmID })?.timeLabel
                    },
                    onSolved: { occurrenceID in
                        guard occurrenceID == item.id.uuidString,
                              model.session?.nextChallenge?.id == item.id else { return }
                        model.complete(item)
                    },
                    onReturnHome: { occurrenceID in
                        guard occurrenceID == item.id.uuidString else { return }
                        if model.isPractice { model.endPractice() }
                        else if model.session?.isUnlocked == true { model.dismiss() }
                    }
                )
            case .count:
                CountingGame(seed: item.puzzleSeed) { model.complete(item) }
            case .crossword:
                MiniCrosswordGame { model.complete(item) } onAlternative: { model.replaceChallenge(item) }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Offline, curated answer set. Daily selection is deterministic; AI is NOT enabled in this build.
private let fiveLetterAnswers = ["APPLE", "BREAD", "CHAIR", "CLOUD", "DREAM", "EARTH", "FLAME", "GRAPE", "HOUSE", "JUICE", "LIGHT", "MUSIC", "OCEAN", "PLANT", "RIVER", "SMILE", "STONE", "TABLE", "TRAIN", "WATER"]

struct WordGuessGame: View {
    let seed: Int
    let onSuccess: () -> Void
    @State private var guess = ""
    @State private var submitted: [String] = []
    @State private var message = "Build a five-letter word to unlock your morning."
    @State private var shake = false
    private var answer: String { fiveLetterAnswers[abs(seed % fiveLetterAnswers.count)] }
    private let rows = [Array("QWERTYUIOP"), Array("ASDFGHJKL"), Array("ZXCVBNM")]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 5) {
                Text("WORD SHIFT").font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .tracking(2).foregroundStyle(purple)
                Text("Find the five-letter word")
                    .font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(.black)
                Text("Mint: right spot   •   Gold: wrong spot")
                    .font(.system(size: 12)).foregroundStyle(.black.opacity(0.7))
            }
            VStack(spacing: 6) {
                ForEach(0..<max(4, min(6, submitted.count + 1)), id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { column in
                            let letter = row < submitted.count
                                ? String(Array(submitted[row])[column])
                                : (row == submitted.count && column < guess.count ? String(Array(guess)[column]) : "")
                            Text(letter)
                                .font(.system(size: 23, weight: .heavy, design: .rounded))
                                .foregroundStyle(row < submitted.count ? .white : .black)
                                .frame(maxWidth: .infinity).frame(height: 48)
                                .background(row < submitted.count ? feedback(for: submitted[row])[column] : Color.white,
                                            in: RoundedRectangle(cornerRadius: 9))
                                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.black.opacity(0.08)))
                        }
                    }
                }
            }.offset(x: shake ? 5 : 0)
            VStack(spacing: 6) {
                ForEach(rows.indices, id: \.self) { row in
                    HStack(spacing: 4) {
                        if row == 2 { keyboardAction("DELETE", symbol: "delete.left") { if !guess.isEmpty { guess.removeLast() } } }
                        ForEach(rows[row], id: \.self) { letter in
                            Button {
                                guard guess.count < 5 else { return }
                                UISelectionFeedbackGenerator().selectionChanged()
                                guess.append(letter)
                            } label: {
                                Text(String(letter))
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).frame(height: 43)
                                    .background(purple, in: RoundedRectangle(cornerRadius: 7))
                            }.buttonStyle(.plain)
                        }
                        if row == 2 { keyboardAction("ENTER", symbol: "return") { submit() } }
                    }
                }
            }
            Text(message).font(.system(size: 12, weight: .medium)).foregroundStyle(.black.opacity(0.77))
                .multilineTextAlignment(.center).frame(minHeight: 32)
            Button { submit() } label: {
                Label("Check word", systemImage: "arrow.right")
                    .font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity).frame(height: 48)
                    .background(purple, in: RoundedRectangle(cornerRadius: 13))
                    .foregroundStyle(.white)
            }.buttonStyle(.plain)
            Text("Works without the iPhone software keyboard")
                .font(.system(size: 10)).foregroundStyle(.black.opacity(0.55))
        }
        .padding(18)
        .background(lightBlue, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    private func keyboardAction(_ name: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white).frame(width: 37, height: 43)
                .background(purple.opacity(0.8), in: RoundedRectangle(cornerRadius: 7))
        }.buttonStyle(.plain).accessibilityLabel(name)
    }

    private func submit() {
        guard guess.count == 5 else {
            message = "Finish all five letters first."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { shake.toggle() }
            return
        }
        submitted.append(guess)
        if guess == answer {
            message = "Perfect! Challenge complete."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            message = submitted.count >= 10 ? "A little help: the word is \(answer)." :
                      (submitted.count >= 5 ? "Hint: starts with \(answer.prefix(1))." : "Not quite. Try again!")
        }
        guess = ""
    }

    // Correct duplicate-letter accounting (green pass then yellow pass).
    private func feedback(for word: String) -> [Color] {
        let a = Array(answer), g = Array(word)
        var result: [Int] = Array(repeating: 0, count: 5)
        var remaining: [Character: Int] = [:]
        for i in 0..<5 {
            if g[i] == a[i] { result[i] = 2 }
            else { remaining[a[i], default: 0] += 1 }
        }
        for i in 0..<5 where result[i] == 0 {
            if remaining[g[i], default: 0] > 0 { result[i] = 1; remaining[g[i], default: 0] -= 1 }
        }
        return result.map { $0 == 2 ? Color(red: 0.25, green: 0.56, blue: 0.42) : ($0 == 1 ? .orange : .gray) }
    }
}

struct CountingGame: View {
    let seed: Int
    let onSuccess: () -> Void
    @State private var startedAt: Date?
    @State private var response = ""
    @State private var score = 0
    @State private var checked = false
    private var count: Int { 8 + abs(seed % 11) }

    var body: some View {
        VStack(spacing: 17) {
            Text("QUICK COUNT").font(.headline.bold())
            Text("Memorize the dots. They disappear after 5 seconds.")
                .font(.subheadline).multilineTextAlignment(.center)
            if startedAt == nil {
                Button("START 5-SECOND ROUND") {
                    startedAt = Date()
                }.buttonStyle(SnoozeActionStyle()).padding(15)
            } else {
                TimelineView(.periodic(from: .now, by: 0.15)) { timeline in
                    let visible = timeline.date.timeIntervalSince(startedAt ?? .distantPast) < 5
                    if visible {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                            ForEach(0..<count, id: \.self) { _ in
                                Image(systemName: "circle.fill")
                                    .font(.title2).foregroundStyle(.mint)
                            }
                        }
                        .frame(height: 130)
                    } else {
                        VStack(spacing: 12) {
                            Text("How many dots did you see?").font(.headline)
                            TextField("Your count", text: $response).keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder).foregroundStyle(.black)
                            Button("CHECK ANSWER") {
                                guard let value = Int(response) else { return }
                                score = max(0, 100 - 3 * abs(value - count))
                                checked = true
                                if value == count { onSuccess() }
                            }.buttonStyle(SnoozeActionStyle()).padding(13)
                            if checked { Text("Score: \(score)/100. Exact answer required to finish. Try again if needed.") }
                        }
                    }
                }
            }
        }
        .padding(21).frame(maxWidth: .infinity)
        .background(Color(red: 0.15, green: 0.20, blue: 0.30), in: RoundedRectangle(cornerRadius: 20))
    }
}

// A fully crossing 3×3 word square: CAT / ARE / TEN.
// Its columns spell CAT / ARE / TEN as well.
struct MiniCrosswordGame: View {
    let onSuccess: () -> Void
    let onAlternative: () -> Void
    @State private var letters: [String] = Array(repeating: "", count: 9)
    @State private var beganAt = Date()
    @State private var message = "Fill every square; across and down both count."

    private let solution = Array("CATARETEN").map(String.init)

    var body: some View {
        VStack(spacing: 13) {
            Text("MINI CROSSWORD").font(.headline.bold())
            Text("Across: 1. Purring pet  2. Plural form of 'is'  3. Number after nine")
                .font(.subheadline).multilineTextAlignment(.leading)
            Text("Down: 1. Purring pet  2. Plural form of 'is'  3. Number after nine")
                .font(.subheadline).multilineTextAlignment(.leading)
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { r in
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { c in
                            let i = r * 3 + c
                            TextField("", text: Binding(get: { letters[i] }, set: { letters[i] = String($0.uppercased().filter { $0.isLetter }.prefix(1)) }))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(size: 27, weight: .bold, design: .monospaced))
                                .frame(width: 66, height: 66)
                                .background(.white, in: RoundedRectangle(cornerRadius: 7))
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
            Button("CHECK CROSSWORD") {
                if letters == solution { message = "Solved!"; onSuccess() }
                else { message = "Some letters aren't right yet. Keep going." }
            }.buttonStyle(SnoozeActionStyle()).padding(15)
            Text(message).font(.footnote).multilineTextAlignment(.center)
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                if timeline.date.timeIntervalSince(beganAt) >= 300 {
                    Button("5 minutes passed — switch to another game") { onAlternative() }
                        .foregroundStyle(.orange).font(.footnote.bold())
                }
            }
            Text("Prototype crossword: fixed 3×3 puzzle; daily AI grids not yet implemented.")
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .padding(20).frame(maxWidth: .infinity)
        .background(Color(red: 0.15, green: 0.20, blue: 0.30), in: RoundedRectangle(cornerRadius: 20))
    }
}
