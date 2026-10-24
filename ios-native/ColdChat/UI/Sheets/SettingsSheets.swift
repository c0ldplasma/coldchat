import SwiftUI

private var appVersion: String {
    let info = Bundle.main.infoDictionary
    return "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
}

private var appVersionTag: String {
    let info = Bundle.main.infoDictionary
    return "v\(info?["CFBundleShortVersionString"] as? String ?? "")+\(info?["CFBundleVersion"] as? String ?? "")"
}

struct SettingsSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.present) private var present

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            SheetHeader(title: L10n.settings)
            List {
                row(L10n.appearance, "paintpalette", .appearance)
                row(L10n.theme, "swatchpalette", .theme)
                row(L10n.chatSettings, "textformat", .chatSettings)
                Button {
                    present(.language)
                } label: {
                    HStack {
                        Label(L10n.language, systemImage: "globe")
                        Spacer()
                        Text(settings.locale.map(LanguageSheet.nativeName) ?? L10n.systemDefault).foregroundStyle(.secondary)
                    }
                }
                row(L10n.messageAppearance, "textformat.size", .messageAppearance)
                row(L10n.customCommands, "terminal", .customCommands)
                row(L10n.messageTriggers, "message", .messageTriggers)
                row(L10n.userTriggers, "person", .userTriggers)
                row(L10n.credits, "briefcase", .credits)
                row(L10n.about, "info.circle", .about)
                Toggle(isOn: $settings.chatHistory) {
                    Label(L10n.chatHistory, systemImage: "clock.arrow.circlepath")
                }
                Text("\(L10n.appName) \(appVersion)")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            .foregroundStyle(.primary)
        }
    }

    private func row(_ title: String, _ icon: String, _ route: Route) -> some View {
        Button {
            present(route)
        } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.row)
    }
}

struct AppearanceSheet: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            SheetHeader(title: L10n.appearance)
            List {
                Picker(selection: $settings.themeMode) {
                    Label(L10n.light, systemImage: "sun.max").tag(ThemeMode.light)
                    Label(L10n.dark, systemImage: "moon").tag(ThemeMode.dark)
                    Label(L10n.system, systemImage: "iphone").tag(ThemeMode.system)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
                Toggle(isOn: $settings.highContrast) {
                    Label(L10n.highContrast, systemImage: "circle.lefthalf.filled")
                }
            }
        }
    }
}

struct ThemeSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.theme)
            List(ThemeColors.all, id: \.name) { color in
                Button {
                    settings.themeColor = color.argb
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Circle().fill(Color(argb: color.argb)).frame(width: 36, height: 36)
                        Text(color.name)
                        Spacer()
                        if settings.themeColor == color.argb { Image(systemName: "checkmark") }
                    }
                }
                .buttonStyle(.row)
            }
        }
    }
}

struct ChatSettingsSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.present) private var present
    private var icon = EmoteButtonIcon.shared

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            SheetHeader(title: L10n.chatSettings)
            List {
                Toggle(isOn: $settings.userAutocompletionWithAt) {
                    Label(L10n.autocompleteUsersWithAt, systemImage: "at")
                }
                Toggle(isOn: $settings.emoteAutocompletionWithColon) {
                    Label(L10n.autocompleteEmotesWithColon, systemImage: "face.smiling")
                }
                Button {
                    present(.emoteButtonPicker)
                } label: {
                    HStack(spacing: 16) {
                        EmoteButtonIconView()
                        VStack(alignment: .leading) {
                            Text(L10n.emoteMenuButton)
                            Text(icon.name ?? "Kappa").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.row)
                Toggle(isOn: $settings.emoteButtonGrayscale) {
                    Label(L10n.emoteMenuButtonGrayscale, systemImage: "circle.righthalf.filled")
                }
            }
        }
    }
}

/// Choosing the emote menu button from Settings: global emotes plus the last opened channel's.
struct EmoteButtonPickerSheet: View {
    @Environment(Client.self) private var client
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.emoteMenuButton)
            EmotePicker(channel: client.channel(named: settings.lastChannel) ?? client.channels.first, pickingButtonIcon: true, onPickButtonIcon: { done in
                if done { dismiss() }
            })
        }
    }
}

struct LanguageSheet: View {
    @Environment(AppSettings.self) private var settings

    /// The language's name in itself, e.g. "Deutsch".
    static func nativeName(_ tag: String) -> String {
        if tag == "en-PT" { return "English (Pirate)" }
        let identifier = tag.replacingOccurrences(of: "-", with: "_")
        return Locale(identifier: identifier).localizedString(forIdentifier: identifier)?.capitalized(with: Locale(identifier: identifier)) ?? tag
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.language)
            List {
                Button {
                    settings.locale = nil
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "iphone")
                        VStack(alignment: .leading) {
                            Text(L10n.justDefault)
                            Text(L10n.systemDefault).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if settings.locale == nil { Image(systemName: "checkmark") }
                    }
                }
                ForEach(L10n.locales, id: \.self) { tag in
                    Button {
                        settings.locale = tag
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "globe")
                            VStack(alignment: .leading) {
                                Text(tag == "en-PT" ? Self.nativeName(tag) : Locale.current.localizedString(forIdentifier: tag.replacingOccurrences(of: "-", with: "_")) ?? tag)
                                Text(Self.nativeName(tag)).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.locale == tag { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
            .buttonStyle(.row)
        }
    }
}

struct MessageAppearanceSheet: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 0) {
            SheetHeader(title: L10n.messageAppearance)
            List {
                Toggle(isOn: $settings.showTimestamps) { Label(L10n.showTimestamps, systemImage: "timer") }
                Toggle(isOn: $settings.showBadges) { Label(L10n.showBadges, systemImage: "checkmark.seal") }
                Toggle(isOn: $settings.compactMessages) { Label(L10n.compactMessages, systemImage: "rectangle.compress.vertical") }
                VStack(alignment: .leading) {
                    Slider(value: $settings.messageScale, in: 1...4, step: 0.125)
                    Text(String(format: "%.3g×", settings.messageScale)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Commands and triggers

struct CustomCommandsSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.present) private var present

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.customCommands)
            List {
                ForEach(settings.customCommands) { command in
                    Button {
                        present(.customCommand(command))
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(command.trigger)
                                Text(command.command).font(.subheadline).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "command")
                        }
                    }
                }
                .onDelete { settings.customCommands.remove(atOffsets: $0) }
                Button {
                    present(.customCommand(nil))
                } label: {
                    Label(L10n.newCustomCommand, systemImage: "plus")
                }
            }
            .buttonStyle(.row)
        }
    }
}

struct CustomCommandSheet: View {
    let command: CustomCommand?
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var trigger = ""
    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.customCommand)
            Form {
                TextField(L10n.commandTrigger, text: $trigger).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField(L10n.command, text: $text, axis: .vertical)
            }
            SaveBar(canSave: !trigger.isEmpty && !text.isEmpty) {
                var updated = command ?? CustomCommand(trigger: "", command: "")
                updated.trigger = trigger.trimmingCharacters(in: .whitespaces)
                updated.command = text.trimmingCharacters(in: .whitespaces)
                if let index = settings.customCommands.firstIndex(where: { $0.id == updated.id }) {
                    settings.customCommands[index] = updated
                } else {
                    settings.customCommands.append(updated)
                }
                dismiss()
            }
        }
        .onAppear {
            trigger = command?.trigger ?? ""
            text = command?.command ?? ""
        }
    }
}

struct MessageTriggersSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.present) private var present

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.messageTriggers)
            List {
                ForEach(settings.messageTriggers) { trigger in
                    Button {
                        present(.messageTrigger(trigger))
                    } label: {
                        Label(trigger.pattern, systemImage: trigger.type == .mention ? "at" : "nosign")
                    }
                }
                .onDelete { settings.messageTriggers.remove(atOffsets: $0) }
                Button {
                    present(.messageTrigger(nil))
                } label: {
                    Label(L10n.newMessageTrigger, systemImage: "plus")
                }
            }
            .buttonStyle(.row)
        }
    }
}

struct MessageTriggerSheet: View {
    let trigger: MessageTrigger?
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var type = TriggerType.mention
    @State private var enableRegex = false
    @State private var caseSensitive = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.messageTrigger)
            Form {
                TextField(L10n.pattern, text: $pattern).textInputAutocapitalization(.never).autocorrectionDisabled()
                Picker("", selection: $type) {
                    Text(L10n.mention).tag(TriggerType.mention)
                    Text(L10n.block).tag(TriggerType.block)
                }
                .pickerStyle(.segmented)
                Toggle(L10n.enableRegex, isOn: $enableRegex)
                Toggle(L10n.caseSensitive, isOn: $caseSensitive)
            }
            SaveBar(canSave: !pattern.isEmpty) {
                var updated = trigger ?? MessageTrigger(type: type, pattern: "")
                updated.type = type
                updated.pattern = pattern.trimmingCharacters(in: .whitespaces)
                updated.enableRegex = enableRegex
                updated.caseSensitive = caseSensitive
                if let index = settings.messageTriggers.firstIndex(where: { $0.id == updated.id }) {
                    settings.messageTriggers[index] = updated
                } else {
                    settings.messageTriggers.append(updated)
                }
                dismiss()
            }
        }
        .onAppear {
            pattern = trigger?.pattern ?? ""
            type = trigger?.type ?? .mention
            enableRegex = trigger?.enableRegex ?? false
            caseSensitive = trigger?.caseSensitive ?? false
        }
    }
}

struct UserTriggersSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.present) private var present

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.userTriggers)
            List {
                ForEach(settings.userTriggers) { trigger in
                    Button {
                        present(.userTrigger(trigger))
                    } label: {
                        Label(trigger.login, systemImage: trigger.type == .mention ? "at" : "nosign")
                    }
                }
                .onDelete { settings.userTriggers.remove(atOffsets: $0) }
                Button {
                    present(.userTrigger(nil))
                } label: {
                    Label(L10n.newUserTrigger, systemImage: "plus")
                }
            }
            .buttonStyle(.row)
        }
    }
}

struct UserTriggerSheet: View {
    let trigger: UserTrigger?
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var login = ""
    @State private var type = TriggerType.mention

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.userTrigger)
            Form {
                TextField(L10n.login, text: $login).textInputAutocapitalization(.never).autocorrectionDisabled()
                Picker("", selection: $type) {
                    Text(L10n.mention).tag(TriggerType.mention)
                    Text(L10n.block).tag(TriggerType.block)
                }
                .pickerStyle(.segmented)
            }
            SaveBar(canSave: !login.isEmpty) {
                var updated = trigger ?? UserTrigger(type: type, login: "")
                updated.type = type
                updated.login = login.trimmingCharacters(in: .whitespaces)
                if let index = settings.userTriggers.firstIndex(where: { $0.id == updated.id }) {
                    settings.userTriggers[index] = updated
                } else {
                    settings.userTriggers.append(updated)
                }
                dismiss()
            }
        }
        .onAppear {
            login = trigger?.login ?? ""
            type = trigger?.type ?? .mention
        }
    }
}

/// Cancel and Save, side by side, at the bottom of an editor sheet.
private struct SaveBar: View {
    let canSave: Bool
    let save: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(L10n.cancel) { dismiss() }.frame(maxWidth: .infinity)
            Divider().frame(height: 32)
            Button(L10n.save, action: save)
                .bold()
                .frame(maxWidth: .infinity)
                .disabled(!canSave)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Credits and about

private struct CreditedPerson: Identifiable {
    let name: String
    let description: String
    let url: String
    let avatarUrl: String
    var id: String { name }
}

struct CreditsSheet: View {
    @Environment(\.openURL) private var openURL

    private static let credits = [
        CreditedPerson(name: "ayyybubu", description: "Logo designer", url: "https://twitch.tv/ayyybubu", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097853110543716422/Wk0hfra.jpg"),
        CreditedPerson(name: "21mtd", description: "Vietnamese translation", url: "https://twitch.tv/21mtd", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097853110543716422/Wk0hfra.jpg"),
        CreditedPerson(name: "badpixel134", description: "Korean translation", url: "https://twitch.tv/badpixel134", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097854071873998868/image.png"),
        CreditedPerson(name: "copperrum", description: "Russian translation", url: "https://twitch.tv/copperrum", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097864604983500820/IMG_0827.jpg"),
        CreditedPerson(name: "LosFarmosCTL", description: "German translation", url: "https://twitch.tv/losfarmosctl", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097872548542283836/IMG_2004.jpg"),
        CreditedPerson(name: "rix", description: "Greek translation", url: "https://twitch.tv/rix_ow", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097872819020369940/pfp.png"),
        CreditedPerson(name: "captkayy", description: "Hindi translation", url: "https://twitch.tv/captkayy", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097889786712313926/5DE7BB29-22F9-4B02-8069-872B5F1F8008.jpg"),
        CreditedPerson(name: "supdos", description: "Spanish translation", url: "https://twitch.tv/supdos", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097894994506961016/SupCut.png"),
        CreditedPerson(name: "Boleto", description: "Brazilian Portugese translation", url: "https://twitch.tv/boletodosub", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097925179029585970/ImageGlass_6wULGSK0yA.png"),
        CreditedPerson(name: "Symphonystars", description: "Italian translation", url: "https://twitch.tv/symphonystars", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1097936569781993622/roko.jpg"),
        CreditedPerson(name: "oakley", description: "Canadian English translation", url: "https://twitch.tv/oakleydog13", avatarUrl: "https://cdn.discordapp.com/attachments/1097848618091806730/1100949775710425088/B2E92DCA-B52C-4CBF-9365-A8E5AD35BB77.jpg"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.credits)
            List(Self.credits) { person in
                Button {
                    if let url = URL(string: person.url) { openURL(url) }
                } label: {
                    HStack(spacing: 16) {
                        RemoteFillImage(url: URL(string: person.avatarUrl), maxPixelSize: 128)
                            .frame(width: 40, height: 40)
                            .background(Color.secondary.opacity(0.3))
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(person.name)
                            Text(person.description).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.row)
            }
        }
    }
}

/// The notices the AGPL asks an interactive program to show: copyright, license, no warranty and where the
/// source is.
struct AboutSheet: View {
    @Environment(\.openURL) private var openURL
    static let copyright = "© Chatsen contributors\n© 2026 C0ldPlasma"

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.about)
            List {
                Text("\(L10n.appName) \(appVersion)\n\n\(Self.copyright)\n\n\(L10n.aboutLegalese)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                // Releases are tagged with their version, so this opens the exact source of the installed build.
                link(L10n.sourceCode, appVersionTag, "chevron.left.forwardslash.chevron.right", repositoryURL.appendingPathComponent("tree/\(appVersionTag)"))
                link(L10n.license, "GNU Affero General Public License v3.0", "building.columns", repositoryURL.appendingPathComponent("blob/main/LICENSE"))
                link(L10n.basedOnChatsen, "github.com/chatsen/chatsen", "arrow.triangle.branch", .api("https://github.com/chatsen/chatsen"))
                link(L10n.contact, "github.com/c0ldplasma/coldchat/issues", "envelope", repositoryURL.appendingPathComponent("issues"))
                link(L10n.privacyPolicy, nil, "hand.raised", privacyPolicyURL)
                link(L10n.termsOfService, nil, "doc.text", termsOfServiceURL)
            }
        }
    }

    private func link(_ title: String, _ subtitle: String?, _ icon: String, _ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text(title)
                    if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
                }
            } icon: {
                Image(systemName: icon)
            }
        }
        .buttonStyle(.row)
    }
}
