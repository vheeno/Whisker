//
//  WhiskerApp.swift
//  Whisker
//
//  Created by Julia Yu on 4/8/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FacebookLogin

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    static let shared = AuthenticationManager()
    
    private init() {
        // Check if user is already logged in
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        }
    }
    
    // Email/password login
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.isAuthenticated = true
            completion(.success(()))
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    // Sign up with email/password
    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.isAuthenticated = true
            completion(.success(()))
        }
    }
    
    // Google Sign-In
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting, hint: nil) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google authentication failed"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Firebase authentication with Google credential
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                self?.isAuthenticated = true
                completion(.success(()))
            }
        }
    }
    
    func signInWithFacebook(completion: @escaping (Result<Void, Error>) -> Void) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result, !result.isCancelled else {
                completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Facebook login cancelled"])))
                return
            }
            
            guard let accessToken = AccessToken.current?.tokenString else {
                completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Facebook access token"])))
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)
            
            // Firebase authentication with Facebook credential
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                self?.isAuthenticated = true
                completion(.success(()))
            }
        }
    }
    
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            return true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            return false
        }
    }
}

// Helper to get root view controller for Google Sign-In
extension UIApplication {
    class func getRootViewController() -> UIViewController {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController ?? UIViewController()
    }
}
