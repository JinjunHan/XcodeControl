//
//  BookmarkStore.swift
//  XcodeControl
//

import Foundation

/// security-scoped bookmark 的创建与解析。
///
/// 即便不开沙盒也使用 bookmark 而非裸路径：文件被移动后 bookmark 仍能跟踪到目标。
enum BookmarkStore {

    enum BookmarkError: LocalizedError {
        case creationFailed(String)
        case resolutionFailed
        case fileMissing(String)

        var errorDescription: String? {
            switch self {
            case .creationFailed(let path): L10n.t("无法为 %@ 创建书签", path)
            case .resolutionFailed: L10n.t("书签已失效，请重新选择项目")
            case .fileMissing(let path): L10n.t("找不到 %@", path)
            }
        }
    }

    static func makeBookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            // 非沙盒环境下 withSecurityScope 偶尔不可用，退回普通书签
            do {
                return try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch {
                throw BookmarkError.creationFailed(url.path)
            }
        }
    }

    /// 解析结果。`needsRefresh` 为 true 时调用方应重新生成并持久化书签。
    struct Resolved {
        let url: URL
        let needsRefresh: Bool
        /// 是否成功开启了 security scope，决定退出时是否需要 stopAccessing
        let didStartAccess: Bool
    }

    static func resolve(_ bookmark: Data) throws -> Resolved {
        var isStale = false
        var url: URL
        var scoped = true

        do {
            url = try URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            scoped = false
            do {
                url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: [],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
            } catch {
                throw BookmarkError.resolutionFailed
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BookmarkError.fileMissing(url.path)
        }

        let started = scoped ? url.startAccessingSecurityScopedResource() : false
        return Resolved(url: url, needsRefresh: isStale, didStartAccess: started)
    }

    static func endAccess(_ resolved: Resolved) {
        if resolved.didStartAccess {
            resolved.url.stopAccessingSecurityScopedResource()
        }
    }
}
