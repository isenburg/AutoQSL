import Foundation

public final class PersistenceService {
    public static let shared = PersistenceService()
    
    private let appSupportDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        let fileManager = FileManager.default
        let baseAppSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = baseAppSupport.appendingPathComponent("AutoQSL", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        let cardsDir = appDir.appendingPathComponent("RenderedCards", isDirectory: true)
        if !fileManager.fileExists(atPath: cardsDir.path) {
            try? fileManager.createDirectory(at: cardsDir, withIntermediateDirectories: true)
        }
        
        self.appSupportDirectory = appDir
        self.encoder.outputFormatting = .prettyPrinted
    }
    
    public var renderedCardsDirectory: URL {
        return appSupportDirectory.appendingPathComponent("RenderedCards", isDirectory: true)
    }
    
    // MARK: - AppSettings
    public func loadSettings() -> AppSettings {
        let url = appSupportDirectory.appendingPathComponent("settings.json")
        guard let data = try? Data(contentsOf: url),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    public func saveSettings(_ settings: AppSettings) {
        let url = appSupportDirectory.appendingPathComponent("settings.json")
        if let data = try? encoder.encode(settings) {
            try? data.write(to: url)
        }
    }
    
    // MARK: - Templates
    public func loadTemplates(myCall: String = "KG4OJT") -> [QSLCardTemplate] {
        let url = appSupportDirectory.appendingPathComponent("templates.json")
        guard let data = try? Data(contentsOf: url),
              let templates = try? decoder.decode([QSLCardTemplate].self, from: data),
              !templates.isEmpty else {
            let defaultTemplate = QSLCardTemplate.createDefaultTemplate(myCall: myCall)
            saveTemplates([defaultTemplate])
            return [defaultTemplate]
        }
        return templates
    }
    
    public func saveTemplates(_ templates: [QSLCardTemplate]) {
        let url = appSupportDirectory.appendingPathComponent("templates.json")
        if let data = try? encoder.encode(templates) {
            try? data.write(to: url)
        }
    }
    
    // MARK: - QSO History
    public func loadQSOQueue() -> [QSO] {
        let url = appSupportDirectory.appendingPathComponent("qso_history.json")
        guard let data = try? Data(contentsOf: url),
              let qsos = try? decoder.decode([QSO].self, from: data) else {
            return []
        }
        return qsos
    }
    
    public func saveQSOQueue(_ qsos: [QSO]) {
        let url = appSupportDirectory.appendingPathComponent("qso_history.json")
        if let data = try? encoder.encode(qsos) {
            try? data.write(to: url)
        }
    }
}
