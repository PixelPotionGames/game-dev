import GameKit

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    
    static let shared = GameCenterManager()
    
    var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    
    private override init() {
        super.init()
    }
    
    func authenticateLocalPlayer(presentingVC: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { (authViewController, error) in
            if let vc = authViewController {
                presentingVC.present(vc, animated: true) {}
            } else if localPlayer.isAuthenticated {
                Logger.log("Player is Authenticated!")
                completion(true, nil)
            } else {
                Logger.log("Player not Authenticated!")
                completion(false, error)
            }
        }
    }
    
    func submit(score: Int, for leaderboardIDs: [String]) {
        let gkScores = leaderboardIDs.map { leaderboardID -> GKScore in
            let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
            gkScore.value = Int64(score)
            return gkScore
        }
        
        GKScore.report(gkScores) { (error) in
            if let error = error {
                Logger.log(error.localizedDescription)
            } else {
                Logger.log("Scores submitted successfully!")
            }
        }
    }
    
    func reportAchievement(identifier: String, percentComplete: Double) {
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { (error) in
            if let error = error {
                Logger.log("Error reporting achievement: \(error.localizedDescription)")
            } else {
                Logger.log("Achievement \(identifier) reported successfully!")
            }
        }
    }
    
    func showLeaderboard(presentingVC: UIViewController, leaderboardID: String, playerScope: GKLeaderboard.PlayerScope) {
        let gkVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: playerScope, timeScope: .allTime)
        gkVC.gameCenterDelegate = self
        presentingVC.present(gkVC, animated: true, completion: nil)
    }
    
    func submitScoreAndShowLeaderboard(from presentingVC: UIViewController, score: Int, leaderboardID: String) {
        submit(score: score, for: [leaderboardID])
        showLeaderboard(presentingVC: presentingVC, leaderboardID: leaderboardID, playerScope: .global)
    }

    // MARK: GKGameCenterControllerDelegate
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
