import Foundation
import SQLite3

public final class QSODatabaseService {
    public static let shared = QSODatabaseService()
    
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.autoqsl.database", qos: .userInitiated)
    private var currentDBURL: URL?
    
    public init() {}
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Open / Close
    
    public func open(at fileURL: URL) {
        queue.sync {
            if currentDBURL == fileURL && db != nil {
                return
            }
            closeDatabaseInternal()
            
            var dbPointer: OpaquePointer?
            if sqlite3_open(fileURL.path, &dbPointer) == SQLITE_OK {
                self.db = dbPointer
                self.currentDBURL = fileURL
                createTables()
            } else {
                print("Error opening SQLite database at \(fileURL.path): \(String(cString: sqlite3_errmsg(dbPointer)))")
            }
        }
    }
    
    public func closeDatabase() {
        queue.sync {
            closeDatabaseInternal()
        }
    }
    
    private func closeDatabaseInternal() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
            self.currentDBURL = nil
        }
    }
    
    // MARK: - Schema
    
    private func createTables() {
        guard let db = db else { return }
        
        // Enable WAL mode for better concurrency and performance
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA synchronous=NORMAL;", nil, nil, nil)
        
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS qsos (
            id TEXT PRIMARY KEY,
            timestamp REAL NOT NULL,
            source TEXT NOT NULL,
            dxCall TEXT NOT NULL,
            band TEXT NOT NULL,
            mode TEXT NOT NULL,
            frequencyHz REAL,
            qsoDate REAL NOT NULL,
            rstSent TEXT NOT NULL,
            rstRcvd TEXT NOT NULL,
            comment TEXT NOT NULL,
            txPowerWatts REAL,
            myCall TEXT NOT NULL,
            myGrid TEXT NOT NULL,
            myName TEXT NOT NULL,
            myAddress TEXT NOT NULL,
            myCQZone TEXT NOT NULL,
            myITUZone TEXT NOT NULL,
            dxName TEXT NOT NULL,
            dxAddress TEXT NOT NULL,
            dxGrid TEXT NOT NULL,
            dxCountry TEXT NOT NULL,
            dxEmail TEXT NOT NULL,
            qrzFound INTEGER NOT NULL,
            templateId TEXT,
            customTemplateJSON TEXT,
            status TEXT NOT NULL,
            statusMessage TEXT,
            generatedCardPath TEXT,
            sentAt REAL
        );
        CREATE INDEX IF NOT EXISTS idx_dxCall ON qsos (dxCall);
        CREATE INDEX IF NOT EXISTS idx_qsoDate ON qsos (qsoDate DESC);
        CREATE INDEX IF NOT EXISTS idx_status ON qsos (status);
        CREATE INDEX IF NOT EXISTS idx_band ON qsos (band);
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTableSQL, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("Error creating tables: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    public func insertOrReplace(_ qso: QSO) {
        queue.sync {
            insertOrReplaceInternal(qso)
        }
    }
    
    public func deleteAll() {
        queue.sync {
            guard let db = db else { return }
            sqlite3_exec(db, "DELETE FROM qsos;", nil, nil, nil)
        }
    }
    
    public func syncQueue(activeQSOs: [QSO]) {
        queue.sync {
            guard let db = db else { return }
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            if activeQSOs.isEmpty {
                sqlite3_exec(db, "DELETE FROM qsos;", nil, nil, nil)
            } else {
                let activeIds = activeQSOs.map { $0.id.uuidString }
                let placeholders = Array(repeating: "?", count: activeIds.count).joined(separator: ",")
                let deleteSql = "DELETE FROM qsos WHERE id NOT IN (\(placeholders));"
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, deleteSql, -1, &stmt, nil) == SQLITE_OK {
                    for (index, idStr) in activeIds.enumerated() {
                        sqlite3_bind_text(stmt, Int32(index + 1), (idStr as NSString).utf8String, -1, nil)
                    }
                    sqlite3_step(stmt)
                }
                sqlite3_finalize(stmt)
                
                for qso in activeQSOs {
                    insertOrReplaceInternal(qso)
                }
            }
            
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
    }

    public func insertBatch(_ qsos: [QSO]) {
        guard !qsos.isEmpty else { return }
        queue.sync {
            guard let db = db else { return }
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            for qso in qsos {
                insertOrReplaceInternal(qso)
            }
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
    }
    
    private func insertOrReplaceInternal(_ qso: QSO) {
        guard let db = db else { return }
        
        let sql = """
        INSERT OR REPLACE INTO qsos (
            id, timestamp, source, dxCall, band, mode, frequencyHz, qsoDate,
            rstSent, rstRcvd, comment, txPowerWatts, myCall, myGrid, myName,
            myAddress, myCQZone, myITUZone, dxName, dxAddress, dxGrid,
            dxCountry, dxEmail, qrzFound, templateId, customTemplateJSON,
            status, statusMessage, generatedCardPath, sentAt
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (qso.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 2, qso.timestamp.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 3, (qso.source.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (qso.dxCall as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (qso.band as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (qso.mode as NSString).utf8String, -1, nil)
            
            if let freq = qso.frequencyHz {
                sqlite3_bind_double(stmt, 7, freq)
            } else {
                sqlite3_bind_null(stmt, 7)
            }
            
            sqlite3_bind_double(stmt, 8, qso.qsoDate.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 9, (qso.rstSent as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, (qso.rstRcvd as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, (qso.comment as NSString).utf8String, -1, nil)
            
            if let pwr = qso.txPowerWatts {
                sqlite3_bind_double(stmt, 12, pwr)
            } else {
                sqlite3_bind_null(stmt, 12)
            }
            
            sqlite3_bind_text(stmt, 13, (qso.myCall as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 14, (qso.myGrid as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 15, (qso.myName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 16, (qso.myAddress as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 17, (qso.myCQZone as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 18, (qso.myITUZone as NSString).utf8String, -1, nil)
            
            sqlite3_bind_text(stmt, 19, (qso.dxName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 20, (qso.dxAddress as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 21, (qso.dxGrid as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 22, (qso.dxCountry as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 23, (qso.dxEmail as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 24, qso.qrzFound ? 1 : 0)
            
            if let tid = qso.templateId {
                sqlite3_bind_text(stmt, 25, (tid.uuidString as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 25)
            }
            
            if let customTmpl = qso.customTemplate,
               let tmplData = try? JSONEncoder().encode(customTmpl),
               let tmplStr = String(data: tmplData, encoding: .utf8) {
                sqlite3_bind_text(stmt, 26, (tmplStr as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 26)
            }
            
            sqlite3_bind_text(stmt, 27, (qso.status.rawValue as NSString).utf8String, -1, nil)
            
            if let msg = qso.statusMessage {
                sqlite3_bind_text(stmt, 28, (msg as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 28)
            }
            
            if let cardPath = qso.generatedCardPath {
                sqlite3_bind_text(stmt, 29, (cardPath as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 29)
            }
            
            if let sent = qso.sentAt {
                sqlite3_bind_double(stmt, 30, sent.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(stmt, 30)
            }
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error inserting QSO: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }
    
    public func delete(qsoId: UUID) {
        queue.sync {
            guard let db = db else { return }
            let sql = "DELETE FROM qsos WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (qsoId.uuidString as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func deleteBatch(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        queue.sync {
            guard let db = db else { return }
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            let sql = "DELETE FROM qsos WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                for id in ids {
                    sqlite3_reset(stmt)
                    sqlite3_bind_text(stmt, 1, (id.uuidString as NSString).utf8String, -1, nil)
                    sqlite3_step(stmt)
                }
            }
            sqlite3_finalize(stmt)
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
    }
    
    public func fetchAll() -> [QSO] {
        var results: [QSO] = []
        queue.sync {
            guard let db = db else { return }
            let sql = "SELECT * FROM qsos ORDER BY qsoDate DESC, timestamp DESC;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let qso = parseQSORow(stmt) {
                        results.append(qso)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }
        return results
    }
    
    public func count() -> Int {
        var count = 0
        queue.sync {
            guard let db = db else { return }
            let sql = "SELECT COUNT(*) FROM qsos;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(stmt, 0))
                }
            }
            sqlite3_finalize(stmt)
        }
        return count
    }
    
    private func parseQSORow(_ stmt: OpaquePointer?) -> QSO? {
        guard let stmt = stmt else { return nil }
        
        guard let idCStr = sqlite3_column_text(stmt, 0),
              let id = UUID(uuidString: String(cString: idCStr)) else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
        let sourceStr = String(cString: sqlite3_column_text(stmt, 2))
        let source = QSOSource(rawValue: sourceStr) ?? .wsjtx
        let dxCall = String(cString: sqlite3_column_text(stmt, 3))
        let band = String(cString: sqlite3_column_text(stmt, 4))
        let mode = String(cString: sqlite3_column_text(stmt, 5))
        
        let frequencyHz = sqlite3_column_type(stmt, 6) != SQLITE_NULL ? sqlite3_column_double(stmt, 6) : nil
        let qsoDate = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 7))
        let rstSent = String(cString: sqlite3_column_text(stmt, 8))
        let rstRcvd = String(cString: sqlite3_column_text(stmt, 9))
        let comment = String(cString: sqlite3_column_text(stmt, 10))
        let txPowerWatts = sqlite3_column_type(stmt, 11) != SQLITE_NULL ? sqlite3_column_double(stmt, 11) : nil
        
        let myCall = String(cString: sqlite3_column_text(stmt, 12))
        let myGrid = String(cString: sqlite3_column_text(stmt, 13))
        let myName = String(cString: sqlite3_column_text(stmt, 14))
        let myAddress = String(cString: sqlite3_column_text(stmt, 15))
        let myCQZone = String(cString: sqlite3_column_text(stmt, 16))
        let myITUZone = String(cString: sqlite3_column_text(stmt, 17))
        
        let dxName = String(cString: sqlite3_column_text(stmt, 18))
        let dxAddress = String(cString: sqlite3_column_text(stmt, 19))
        let dxGrid = String(cString: sqlite3_column_text(stmt, 20))
        let dxCountry = String(cString: sqlite3_column_text(stmt, 21))
        let dxEmail = String(cString: sqlite3_column_text(stmt, 22))
        let qrzFound = sqlite3_column_int(stmt, 23) != 0
        
        var templateId: UUID? = nil
        if sqlite3_column_type(stmt, 24) != SQLITE_NULL,
           let tidCStr = sqlite3_column_text(stmt, 24) {
            templateId = UUID(uuidString: String(cString: tidCStr))
        }
        
        var customTemplate: QSLCardTemplate? = nil
        if sqlite3_column_type(stmt, 25) != SQLITE_NULL,
           let jsonCStr = sqlite3_column_text(stmt, 25),
           let data = String(cString: jsonCStr).data(using: .utf8) {
            customTemplate = try? JSONDecoder().decode(QSLCardTemplate.self, from: data)
        }
        
        let statusStr = String(cString: sqlite3_column_text(stmt, 26))
        let status = QSOStatus(rawValue: statusStr) ?? .pending
        
        var statusMessage: String? = nil
        if sqlite3_column_type(stmt, 27) != SQLITE_NULL,
           let msgCStr = sqlite3_column_text(stmt, 27) {
            statusMessage = String(cString: msgCStr)
        }
        
        var generatedCardPath: String? = nil
        if sqlite3_column_type(stmt, 28) != SQLITE_NULL,
           let pathCStr = sqlite3_column_text(stmt, 28) {
            generatedCardPath = String(cString: pathCStr)
        }
        
        var sentAt: Date? = nil
        if sqlite3_column_type(stmt, 29) != SQLITE_NULL {
            sentAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 29))
        }
        
        return QSO(
            id: id,
            timestamp: timestamp,
            source: source,
            dxCall: dxCall,
            band: band,
            mode: mode,
            frequencyHz: frequencyHz,
            qsoDate: qsoDate,
            rstSent: rstSent,
            rstRcvd: rstRcvd,
            comment: comment,
            txPowerWatts: txPowerWatts,
            myCall: myCall,
            myGrid: myGrid,
            myName: myName,
            myAddress: myAddress,
            myCQZone: myCQZone,
            myITUZone: myITUZone,
            dxName: dxName,
            dxAddress: dxAddress,
            dxGrid: dxGrid,
            dxCountry: dxCountry,
            dxEmail: dxEmail,
            qrzFound: qrzFound,
            templateId: templateId,
            customTemplate: customTemplate,
            status: status,
            statusMessage: statusMessage,
            generatedCardPath: generatedCardPath,
            sentAt: sentAt
        )
    }
    
    // MARK: - Migration from Legacy JSON
    
    public func migrateFromJSONIfNeeded(jsonURL: URL) {
        let markerURL = jsonURL.deletingLastPathComponent().appendingPathComponent(".sqlite_migration_done")
        guard !FileManager.default.fileExists(atPath: markerURL.path) else { return }
        guard count() == 0, FileManager.default.fileExists(atPath: jsonURL.path) else {
            try? "".write(to: markerURL, atomically: true, encoding: .utf8)
            return
        }
        
        if let data = try? Data(contentsOf: jsonURL),
           let qsos = try? JSONDecoder().decode([QSO].self, from: data),
           !qsos.isEmpty {
            insertBatch(qsos)
            print("Successfully migrated \(qsos.count) QSOs from JSON to SQLite database.")
        }
        try? "".write(to: markerURL, atomically: true, encoding: .utf8)
    }
}
