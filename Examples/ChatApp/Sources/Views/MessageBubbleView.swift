/*
 * MIT License
 *
 * Copyright (c) 2025 Perfect Aduh
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import MarkdownUI
import SwiftUI

struct MessageBubbleView: View {
    let message: DisplayMessage

    private var isUser: Bool { message.role == .user }

    private var bubbleColor: Color {
        switch message.role {
        case .user: return .accentColor
        case .assistant: return Color(UIColor.secondarySystemBackground)
        case .system: return Color(UIColor.systemGray5)
        case .error: return Color.red.opacity(0.15)
        case .toolCall: return Color.yellow.opacity(0.2)
        case .stepInfo: return Color.blue.opacity(0.12)
        }
    }

    private var textColor: Color {
        switch message.role {
        case .user: return .white
        case .error: return .red
        default: return .primary
        }
    }

    private var leadingIcon: String? {
        switch message.role {
        case .user: return nil
        case .assistant: return "sparkles"
        case .system: return "info.circle"
        case .error: return "exclamationmark.triangle"
        case .toolCall: return "wrench.adjustable"
        case .stepInfo: return "bolt.fill"
        }
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    if let icon = leadingIcon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if message.content.isEmpty, message.isStreaming {
                        ProgressView()
                            .scaleEffect(0.75)
                    } else {
                        Markdown(message.content)
                            .markdownTheme(.basic)
                            .markdownTextStyle(\.text) {
                                ForegroundColor(textColor)
                            }
                            .markdownTextStyle(\.strong) {
                                FontWeight(.heavy)
                                ForegroundColor(textColor)
                            }
                            .markdownTextStyle(\.link) {
                                ForegroundColor(textColor)
                            }
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                .padding(12)
                .background(bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 4) {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    // Phase 1C: Optimistic send indicator — visible until agent confirms.
                    if message.isSending {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
