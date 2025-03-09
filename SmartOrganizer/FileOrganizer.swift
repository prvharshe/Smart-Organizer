import Foundation
import AppKit

class FileOrganizer {
    
    static func requestDownloadsFolderAccess() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Select your Downloads folder"
        openPanel.prompt = "Grant Access"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.urls.first {
            saveSecurityBookmark(for: url)
            return url
        }
        return nil
    }

    static func getDownloadsFolder() -> URL? {
        if let savedURL = loadSecurityBookmark() {
            return savedURL
        }
        return requestDownloadsFolderAccess()
    }

    static func organizeDownloads() {
        let fileManager = FileManager.default

        guard let downloadsURL = getDownloadsFolder() else {
            print("❌ Could not get access to Downloads folder")
            return
        }

        print("📂 Downloads folder path: \(downloadsURL.path)")

        let hasAccess = downloadsURL.startAccessingSecurityScopedResource()
        guard hasAccess else {
            print("❌ Failed to access security-scoped resource for: \(downloadsURL.path)")
            return
        }

        defer { downloadsURL.stopAccessingSecurityScopedResource() }  // Ensure cleanup

        do {
            let files = try fileManager.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)

            for file in files {
                print("📄 Processing file: \(file.lastPathComponent)")

                let destinationFolder = getDestinationFolder(for: file, in: downloadsURL)
                
                if !fileManager.fileExists(atPath: destinationFolder.path) {
                    try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
                }

                let destinationURL = destinationFolder.appendingPathComponent(file.lastPathComponent)
                try fileManager.moveItem(at: file, to: destinationURL)
            }

            print("✅ Files organized successfully!")
        } catch {
            print("❌ Error organizing files: \(error.localizedDescription)")
        }
    }

    
    private static func organizeFiles(in downloadsFolder: URL) {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: downloadsFolder, includingPropertiesForKeys: nil)
            
            for file in files {
                print("📄 Processing file:", file.lastPathComponent)
                
                // 🔐 Ensure we have permission to access this file
                guard file.startAccessingSecurityScopedResource() else {
                    print("❌ Failed to access security-scoped resource for:", file.path)
                    continue
                }
                
                defer { file.stopAccessingSecurityScopedResource() } // Cleanup
                
                let destinationFolder = getDestinationFolder(for: file, in: downloadsFolder)
                
                if !fileManager.fileExists(atPath: destinationFolder.path) {
                    try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
                }
                
                let destinationURL = destinationFolder.appendingPathComponent(file.lastPathComponent)
                
                do {
                    try fileManager.moveItem(at: file, to: destinationURL)
                    print("✅ Moved \(file.lastPathComponent) to \(destinationFolder.path)")
                } catch {
                    print("❌ Error moving file '\(file.lastPathComponent)':", error.localizedDescription)
                }
            }
        } catch {
            print("❌ Error organizing files:", error.localizedDescription)
        }
    }
    
    static func resetFolderAccess() {
        UserDefaults.standard.removeObject(forKey: "DownloadsFolderBookmark")
        print("🔄 Security bookmark reset. Restart the app and reselect the Downloads folder.")
    }

    
    private static func getDestinationFolder(for file: URL, in downloadsFolder: URL) -> URL {
        let fileExtension = file.pathExtension.lowercased()
        let folderName: String
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic":
            folderName = "Images"
        case "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "txt":
            folderName = "Documents"
        case "zip", "rar", "7z", "tar", "gz":
            folderName = "Archives"
        case "mp3", "wav", "m4a", "flac":
            folderName = "Audio"
        case "mp4", "mov", "avi", "mkv":
            folderName = "Videos"
        default:
            folderName = "Others"
        }
        
        return downloadsFolder.appendingPathComponent(folderName, isDirectory: true)
    }
    
    // MARK: - Security Scoped Bookmarks Handling
    
    private static let bookmarkKey = "DownloadsFolderBookmark"

    private static func saveSecurityBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            print("🔐 Security bookmark saved")
        } catch {
            print("❌ Failed to save security bookmark:", error.localizedDescription)
        }
    }

    private static func loadSecurityBookmark() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("⚠️ Security bookmark is stale. Requesting access again.")
                return requestDownloadsFolderAccess()
            }
            
            return url
        } catch {
            print("❌ Failed to load security bookmark:", error.localizedDescription)
            return nil
        }
    }
}
