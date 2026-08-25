import Foundation
import AppKit

public final class PersistenceService {
    public static let shared = PersistenceService()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        self.encoder.outputFormatting = .prettyPrinted
        ensureDirectoryExists(localAppSupportDirectory)
        ensureDirectoryExists(localRenderedCardsDirectory)
    }
    
    // MARK: - Directory Locations
    
    /// Local Application Support Directory: ~/Library/Application Support/AutoQSL
    public var localAppSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("AutoQSL", isDirectory: true)
    }
    
    public var localRenderedCardsDirectory: URL {
        return localAppSupportDirectory.appendingPathComponent("RenderedCards", isDirectory: true)
    }
    
    /// iCloud Drive Directory: ~/Library/Mobile Documents/com~apple~CloudDocs/AutoQSL
    public var iCloudDriveDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/AutoQSL", isDirectory: true)
    }
    
    public var iCloudRenderedCardsDirectory: URL {
        return iCloudDriveDirectory.appendingPathComponent("RenderedCards", isDirectory: true)
    }
    
    /// Returns true if iCloud Drive is configured and available on this Mac
    public var isICloudAvailable: Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudDocs = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
        return FileManager.default.fileExists(atPath: cloudDocs.path)
    }
    
    /// Returns the active base directory depending on storage location
    public func storageDirectory(for location: StorageLocation) -> URL {
        switch location {
        case .local:
            ensureDirectoryExists(localAppSupportDirectory)
            return localAppSupportDirectory
        case .iCloud:
            ensureDirectoryExists(iCloudDriveDirectory)
            return iCloudDriveDirectory
        }
    }
    
    /// Returns the active RenderedCards directory
    public func renderedCardsDirectory(for location: StorageLocation) -> URL {
        let base = storageDirectory(for: location)
        let dir = base.appendingPathComponent("RenderedCards", isDirectory: true)
        ensureDirectoryExists(dir)
        return dir
    }
    
    public var renderedCardsDirectory: URL {
        let loc = currentStorageLocation()
        return renderedCardsDirectory(for: loc)
    }
    
    // MARK: - AppSettings
    
    public func currentStorageLocation() -> StorageLocation {
        // Check if there is an active settings.json in local storage
        let localURL = localAppSupportDirectory.appendingPathComponent("settings.json")
        if let data = try? Data(contentsOf: localURL),
           let s = try? decoder.decode(AppSettings.self, from: data) {
            return s.storageLocation
        }
        return .local
    }
    
    public func loadSettings(from location: StorageLocation? = nil) -> AppSettings {
        let loc = location ?? currentStorageLocation()
        let targetURL = storageDirectory(for: loc).appendingPathComponent("settings.json")
        
        if let data = try? Data(contentsOf: targetURL),
           let settings = try? decoder.decode(AppSettings.self, from: data) {
            return settings
        }
        
        // Fallback to local if iCloud not yet populated
        if loc == .iCloud {
            let localURL = localAppSupportDirectory.appendingPathComponent("settings.json")
            if let data = try? Data(contentsOf: localURL),
               let settings = try? decoder.decode(AppSettings.self, from: data) {
                var updated = settings
                updated.storageLocation = .iCloud
                saveSettings(updated, to: .iCloud)
                return updated
            }
        }
        
        return AppSettings()
    }
    
    public func saveSettings(_ settings: AppSettings, to location: StorageLocation? = nil) {
        let loc = location ?? settings.storageLocation
        let targetURL = storageDirectory(for: loc).appendingPathComponent("settings.json")
        if let data = try? encoder.encode(settings) {
            try? data.write(to: targetURL, options: .atomic)
        }
        
        // Always write a pointer / sync copy to local storage so the app knows where to boot from
        if loc == .iCloud {
            let localURL = localAppSupportDirectory.appendingPathComponent("settings.json")
            if let data = try? encoder.encode(settings) {
                try? data.write(to: localURL, options: .atomic)
            }
        }
    }
    
    // MARK: - Templates
    
    public func loadTemplates(
        from location: StorageLocation? = nil,
        myCall: String = "DJ6GI",
        myAddress: String? = nil
    ) -> [QSLCardTemplate] {
        let loc = location ?? currentStorageLocation()
        let targetURL = storageDirectory(for: loc).appendingPathComponent("templates.json")
        
        if let data = try? Data(contentsOf: targetURL),
           let templates = try? decoder.decode([QSLCardTemplate].self, from: data),
           !templates.isEmpty {
            return templates
        }
        
        // Fallback to local if iCloud templates not yet populated
        if loc == .iCloud {
            let localURL = localAppSupportDirectory.appendingPathComponent("templates.json")
            if let data = try? Data(contentsOf: localURL),
               let templates = try? decoder.decode([QSLCardTemplate].self, from: data),
               !templates.isEmpty {
                saveTemplates(templates, to: .iCloud)
                return templates
            }
        }
        
        let defaultTemplate = QSLCardTemplate.createDefaultTemplate(myCall: myCall, myAddress: myAddress)
        saveTemplates([defaultTemplate], to: loc)
        return [defaultTemplate]
    }
    
    public func saveTemplates(_ templates: [QSLCardTemplate], to location: StorageLocation? = nil) {
        let loc = location ?? currentStorageLocation()
        let targetURL = storageDirectory(for: loc).appendingPathComponent("templates.json")
        if let data = try? encoder.encode(templates) {
            try? data.write(to: targetURL, options: .atomic)
        }
    }
    
    // MARK: - QSO History (SQLite Database Engine)
    
    public func sqliteDatabaseURL(for location: StorageLocation) -> URL {
        return storageDirectory(for: location).appendingPathComponent("autoqsl.sqlite")
    }
    
    public func loadQSOQueue(from location: StorageLocation? = nil) -> [QSO] {
        let loc = location ?? currentStorageLocation()
        let dbURL = sqliteDatabaseURL(for: loc)
        let jsonURL = storageDirectory(for: loc).appendingPathComponent("qso_history.json")
        
        // Open SQLite Database
        QSODatabaseService.shared.open(at: dbURL)
        
        // Auto-migrate from JSON if SQLite database is newly created
        QSODatabaseService.shared.migrateFromJSONIfNeeded(jsonURL: jsonURL)
        
        // Fallback to local if iCloud history not yet populated
        if loc == .iCloud && QSODatabaseService.shared.count() == 0 {
            let localJsonURL = localAppSupportDirectory.appendingPathComponent("qso_history.json")
            QSODatabaseService.shared.migrateFromJSONIfNeeded(jsonURL: localJsonURL)
        }
        
        return QSODatabaseService.shared.fetchAll()
    }
    
    public func saveQSOQueue(_ qsos: [QSO], to location: StorageLocation? = nil) {
        let loc = location ?? currentStorageLocation()
        let dbURL = sqliteDatabaseURL(for: loc)
        
        QSODatabaseService.shared.open(at: dbURL)
        QSODatabaseService.shared.syncQueue(activeQSOs: qsos)
        
        // Maintain an atomic JSON backup for safety and portability
        let targetURL = storageDirectory(for: loc).appendingPathComponent("qso_history.json")
        if let data = try? encoder.encode(qsos) {
            try? data.write(to: targetURL, options: .atomic)
        }
    }
    
    // MARK: - Sticker Collection
    
    public func stickersDirectory(for location: StorageLocation? = nil) -> URL {
        let loc = location ?? currentStorageLocation()
        let dir = storageDirectory(for: loc).appendingPathComponent("Badges", isDirectory: true)
        ensureDirectoryExists(dir)
        return dir
    }
    
    public func loadStickers(from location: StorageLocation? = nil) -> [StickerItem] {
        let loc = location ?? currentStorageLocation()
        let targetURL = storageDirectory(for: loc).appendingPathComponent("stickers.json")
        
        if let data = try? Data(contentsOf: targetURL),
           let items = try? decoder.decode([StickerItem].self, from: data), !items.isEmpty {
            return items
        }
        
        let defaults = StickerItem.builtinStickers
        saveStickers(defaults, to: loc)
        return defaults
    }
    
    public func saveStickers(_ stickers: [StickerItem], to location: StorageLocation? = nil) {
        let loc = location ?? currentStorageLocation()
        let targetURL = storageDirectory(for: loc).appendingPathComponent("stickers.json")
        if let data = try? encoder.encode(stickers) {
            try? data.write(to: targetURL, options: .atomic)
        }
    }
    
    // MARK: - Migration & Finder Integration
    
    /// Migrates all configuration, templates, QSO queue, and rendered cards from source to destination
    public func migrateData(from source: StorageLocation, to destination: StorageLocation) throws {
        let fm = FileManager.default
        let srcDir = storageDirectory(for: source)
        let dstDir = storageDirectory(for: destination)
        
        ensureDirectoryExists(dstDir)
        
        let files = ["settings.json", "templates.json", "stickers.json", "qso_history.json", "autoqsl.sqlite", "autoqsl.sqlite-wal", "autoqsl.sqlite-shm"]
        for file in files {
            let srcFile = srcDir.appendingPathComponent(file)
            let dstFile = dstDir.appendingPathComponent(file)
            if fm.fileExists(atPath: srcFile.path) {
                if fm.fileExists(atPath: dstFile.path) {
                    try? fm.removeItem(at: dstFile)
                }
                try fm.copyItem(at: srcFile, to: dstFile)
            }
        }
        
        // Copy RenderedCards
        let srcCards = srcDir.appendingPathComponent("RenderedCards", isDirectory: true)
        let dstCards = dstDir.appendingPathComponent("RenderedCards", isDirectory: true)
        ensureDirectoryExists(dstCards)
        
        if let cardFiles = try? fm.contentsOfDirectory(atPath: srcCards.path) {
            for card in cardFiles {
                let sCard = srcCards.appendingPathComponent(card)
                let dCard = dstCards.appendingPathComponent(card)
                if !fm.fileExists(atPath: dCard.path) {
                    try? fm.copyItem(at: sCard, to: dCard)
                }
            }
        }
    }
    
    /// Opens the specified storage directory in macOS Finder
    public func revealInFinder(location: StorageLocation) {
        let dir = storageDirectory(for: location)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path)
    }
    
    private func ensureDirectoryExists(_ dir: URL) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
