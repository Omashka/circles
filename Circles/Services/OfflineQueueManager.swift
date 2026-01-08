//
//  OfflineQueueManager.swift
//  Circles
//
//  Manages offline queueing for AI operations

import Foundation
import Network
import os.log

/// Manages queueing of AI operations when offline
@MainActor
class OfflineQueueManager: ObservableObject {
    static let shared = OfflineQueueManager()
    
    private let logger = Logger(subsystem: "com.circles.app", category: "OfflineQueue")
    private let queueFileURL: URL
    private let monitor = NWPathMonitor()
    private var isOnline = false
    
    @Published var queuedOperations: [QueuedAIOperation] = []
    
    // MARK: - Initialization
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        queueFileURL = documentsPath.appendingPathComponent("ai_operations_queue.json")
        
        loadQueue()
        startNetworkMonitoring()
    }
    
    // MARK: - Queue Management
    
    /// Add an operation to the queue
    func enqueue(_ operation: QueuedAIOperation) {
        queuedOperations.append(operation)
        saveQueue()
        logger.info("Enqueued AI operation: \(operation.id)")
        
        // If online, try to process immediately
        if isOnline {
            Task {
                await processQueue()
            }
        }
    }
    
    /// Remove an operation from the queue
    func dequeue(_ operationId: UUID) {
        queuedOperations.removeAll { $0.id == operationId }
        saveQueue()
        logger.info("Dequeued AI operation: \(operationId)")
    }
    
    /// Process all queued operations
    func processQueue() async {
        guard isOnline else {
            logger.info("Offline - skipping queue processing")
            return
        }
        
        let operations = queuedOperations
        logger.info("Processing \(operations.count) queued operations")
        
        for operation in operations {
            do {
                try await processOperation(operation)
                dequeue(operation.id)
            } catch {
                logger.error("Failed to process operation \(operation.id): \(error.localizedDescription)")
                // Keep in queue for retry
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processOperation(_ operation: QueuedAIOperation) async throws {
        switch operation.type {
        case .voiceNoteSummarization:
            // This will be handled by the caller with the AI service
            // We just mark it as ready to process
            logger.info("Processing voice note summarization: \(operation.id)")
        }
    }
    
    private func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isOnline = path.status == .satisfied
                if self.isOnline {
                    await self.processQueue()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func saveQueue() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(queuedOperations)
            try data.write(to: queueFileURL)
        } catch {
            logger.error("Failed to save queue: \(error.localizedDescription)")
        }
    }
    
    private func loadQueue() {
        guard FileManager.default.fileExists(atPath: queueFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: queueFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loaded = try decoder.decode([QueuedAIOperation].self, from: data)
            self.queuedOperations = loaded
            logger.info("Loaded \(loaded.count) queued operations")
        } catch {
            logger.error("Failed to load queue: \(error.localizedDescription)")
            self.queuedOperations = []
        }
    }
}

// MARK: - Queued Operation Model

struct QueuedAIOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let transcription: String
    let contactId: UUID?
    let createdAt: Date
    
    enum OperationType: String, Codable {
        case voiceNoteSummarization
    }
}

