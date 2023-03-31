import SwiftUI

extension Block: View {
  var body: some View {
    switch self {
    case .blockquote(let blocks):
      ApplyBlockStyle(\.blockquote, to: BlockSequence(blocks))
    case .taskList(let tight, let items):
      ApplyBlockStyle(\.list, to: TaskListView(tight: tight, items: items))
    case .bulletedList(let tight, let items):
      ApplyBlockStyle(\.list, to: BulletedListView(tight: tight, items: items))
    case .numberedList(let tight, let start, let items):
      ApplyBlockStyle(\.list, to: NumberedListView(tight: tight, start: start, items: items))
    case .codeBlock(let info, let content):
      ApplyBlockStyle(\.codeBlock, to: CodeBlockView(info: info, content: content))
            .overlay(alignment: .topTrailing) {
                CopyButton(content: content)
            }
    case .htmlBlock(let content):
      ApplyBlockStyle(\.paragraph, to: HTMLBlockView(content: content))
    case .paragraph(let inlines):
      if let imageView = ImageView(inlines) {
        ApplyBlockStyle(\.paragraph, to: imageView)
      } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
        let imageFlow = ImageFlow(inlines)
      {
        ApplyBlockStyle(\.paragraph, to: imageFlow)
      } else {
        ApplyBlockStyle(\.paragraph, to: InlineText(inlines))
      }
    case .heading(let level, let inlines):
      ApplyBlockStyle(\.headings[level - 1], to: InlineText(inlines))
        .id(inlines.text.kebabCased())
    case .table(let columnAlignments, let rows):
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        ApplyBlockStyle(\.table, to: TableView(columnAlignments: columnAlignments, rows: rows))
      } else {
        EmptyView()
      }
    case .thematicBreak:
      ApplyBlockStyle(\.thematicBreak)
    }
  }
}

struct CopyButton: View {
    let content: String
    @State var isCopied = false
    var body: some View {
        Button(action: {
            withAnimation(.linear(duration: 0.1)) {
                isCopied = true
            }
            copyCode(content)
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.linear(duration: 0.1)) {
                    isCopied = false
                }
            }
        }) {
            Image(systemName: isCopied ? "checkmark.circle" : "doc.on.doc")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
                .frame(width: 20, height: 20, alignment: .center)
                .foregroundColor(.secondary)
                .background(
                    Color.black.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 4, style: .circular)
                )
                .padding(4)
        }
        .buttonStyle(.plain)
    }
}

#if canImport(AppKit)
import AppKit
func copyCode(_ code: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(code, forType: .string)
}
#else
func copyCode(_: String) {}
#endif
