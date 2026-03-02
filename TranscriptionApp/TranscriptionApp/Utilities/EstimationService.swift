import Foundation

@Observable
final class EstimationService {
    var estimatedRemainingSeconds: Double?

    private var processingStartTime: Date?
    private var lastProgress: Double = 0

    /// Demarre le suivi de temps pour un nouveau traitement
    func startTracking() {
        processingStartTime = Date()
        estimatedRemainingSeconds = nil
        lastProgress = 0
    }

    /// Met a jour l'estimation basee sur la progression actuelle (0-1)
    func update(progress: Double) {
        guard progress > 0.01, let startTime = processingStartTime else {
            return
        }

        lastProgress = progress
        let elapsed = Date().timeIntervalSince(startTime)

        // Estimation lineaire : temps total = elapsed / progress
        let estimatedTotal = elapsed / progress
        let remaining = estimatedTotal - elapsed

        // Ne mettre a jour que si raisonnable (> 1s restant)
        if remaining > 1 {
            estimatedRemainingSeconds = remaining
        } else {
            estimatedRemainingSeconds = nil
        }
    }

    /// Remet a zero le service
    func reset() {
        processingStartTime = nil
        estimatedRemainingSeconds = nil
        lastProgress = 0
    }

    /// Texte formate pour l'estimation restante
    var formattedRemaining: String? {
        guard let remaining = estimatedRemainingSeconds else { return nil }
        if remaining < 60 {
            return "~\(Int(remaining))s restantes"
        } else if remaining < 3600 {
            let min = Int(remaining / 60)
            let sec = Int(remaining.truncatingRemainder(dividingBy: 60))
            if sec > 0 {
                return "~\(min) min \(sec)s restantes"
            }
            return "~\(min) min restantes"
        } else {
            let h = Int(remaining / 3600)
            let m = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
            return "~\(h)h \(m)min restantes"
        }
    }

    /// Texte court pour la barre de menu
    var shortFormattedRemaining: String? {
        guard let remaining = estimatedRemainingSeconds else { return nil }
        if remaining < 60 {
            return "~\(Int(remaining))s"
        } else if remaining < 3600 {
            return "~\(Int(remaining / 60))min"
        } else {
            let h = Int(remaining / 3600)
            let m = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
            return "~\(h)h\(m)m"
        }
    }
}
