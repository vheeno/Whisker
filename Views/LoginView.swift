//
//  ContentView.swift
//  Whisker
//
//  Created by Julia Yu on 4/8/25.

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FacebookLogin
import UIKit

// MARK: - Reusable Components
struct PasswordField: View {
    @Binding var password: String
    @Binding var showPassword: Bool
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if showPassword {
                TextField(placeholder, text: $password)
                    .whiskerTextField()
                    .frame(height: 50)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textContentType(.oneTimeCode)
            } else {
                SecureField(placeholder, text: $password)
                    .whiskerTextField()
                    .frame(height: 50)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textContentType(.oneTimeCode)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(WhiskerStyles.textColor)
            }
            .padding(.trailing, 10)
        }
        .padding(.horizontal)
    }
}

struct SocialLoginButtons: View {
    var onGoogleTap: () -> Void
    var onFacebookTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack { Divider() }
                
                Text("Or continue with")
                    .font(WhiskerStyles.Fonts.bodyLight)
                    .fixedSize()
                    .foregroundColor(WhiskerStyles.textColor)
                    .padding(.horizontal, 10)
                
                VStack { Divider() }
            }
            .padding(.horizontal)
            
            // Social login buttons
            HStack(spacing: 20) {
                // Google login button
                Button(action: onGoogleTap) {
                    HStack {
                        Text("Google")
                            .font(WhiskerStyles.Fonts.buttonText)
                            .foregroundColor(WhiskerStyles.textColor)
                    }
                }
                .socialButton(background: .white, foreground: WhiskerStyles.textColor)
                
                // Facebook login button
                Button(action: onFacebookTap) {
                    HStack {
                        Text("Facebook")
                            .font(WhiskerStyles.Fonts.buttonText)
                    }
                }
                .socialButton(background: WhiskerStyles.facebookColor, foreground: .white)
            }
            .padding(.horizontal)
        }
    }
}

struct RememberMeToggle: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(WhiskerStyles.textColor)
                    .font(.system(size: 20))
            }
            
            Text("Remember Me")
                .font(WhiskerStyles.Fonts.bodyLight)
                .foregroundColor(WhiskerStyles.textColor)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Login View
struct LoginView: View {
    let fonts = registerFonts()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var showPassword: Bool = false
    @State private var navigateToSignUp = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Logo & Title
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 30)
                    
                    Text("Whisker")
                        .font(WhiskerStyles.Fonts.title)
                        .foregroundColor(WhiskerStyles.textColor)
                    
                    // Email field
                    TextField("Email or username", text: $email)
                        .whiskerTextField()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    // Password field
                    PasswordField(
                        password: $password,
                        showPassword: $showPassword,
                        placeholder: "Password"
                    )
                    
                    // Remember me and Forgot password
                    HStack {
                        Button(action: {
                            rememberMe.toggle()
                        }) {
                            Image(systemName: rememberMe ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(WhiskerStyles.textColor)
                                .font(.system(size: 20))
                        }
                        
                        Text("Remember Me")
                            .font(WhiskerStyles.Fonts.bodyLight)
                            .foregroundColor(WhiskerStyles.textColor)
                        
                        Spacer()
                        
                        Button(action: forgotPassword) {
                            Text("Forgot password?")
                                .font(WhiskerStyles.Fonts.bodyLight)
                                .foregroundColor(WhiskerStyles.textColor)
                                .underline()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Login button
                    Button(action: login) {
                        Text("Login")
                    }
                    .primaryButton()
                    .padding(.horizontal)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text(alertTitle),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    // Sign up link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(WhiskerStyles.textColor)
                            .font(WhiskerStyles.Fonts.bodyLight)
                        
                        NavigationLink(destination: SignUpView().navigationBarBackButtonHidden(true), isActive: $navigateToSignUp) {
                            Button(action: {
                                navigateToSignUp = true
                            }) {
                                Text("Sign up")
                                    .foregroundColor(WhiskerStyles.textColor)
                                    .underline()
                                    .font(WhiskerStyles.Fonts.bodyLight)
                            }
                        }
                    }
                    
                    // Social Login Buttons
                    SocialLoginButtons(
                        onGoogleTap: signInWithGoogle,
                        onFacebookTap: signInWithFacebook
                    )
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .background(WhiskerStyles.backgroundColor)
            .navigationBarHidden(true)
        }
    }
    
    // Authentication functions
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Error", message: "Email and password cannot be empty")
            return
        }
        
        authManager.login(email: email, password: password) { result in
            switch result {
            case .success:
                print("User logged in successfully")
            case .failure(let error):
                showAlert(title: "Login Failed", message: error.localizedDescription)
            }
        }
    }
    
    func forgotPassword() {
        guard !email.isEmpty else {
            showAlert(title: "Email Required", message: "Please enter your email address to reset your password")
            return
        }
        
        authManager.resetPassword(email: email) { result in
            switch result {
            case .success:
                showAlert(title: "Password Reset", message: "Password reset email has been sent to \(email)")
            case .failure(let error):
                showAlert(title: "Reset Failed", message: error.localizedDescription)
            }
        }
    }
    
    func signInWithGoogle() {
        let rootVC = UIApplication.getRootViewController()
        
        authManager.signInWithGoogle(presenting: rootVC) { result in
            switch result {
            case .success:
                print("Google user logged in successfully")
            case .failure(let error):
                showAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
            }
        }
    }
    
    func signInWithFacebook() {
        authManager.signInWithFacebook { result in
            switch result {
            case .success:
                print("Facebook user logged in successfully")
            case .failure(let error):
                showAlert(title: "Facebook Login Failed", message: error.localizedDescription)
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswords: Bool = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var rememberMe: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 0) {
                    Text("CREATE ACCOUNT")
                        .font(WhiskerStyles.Fonts.title)
                        .foregroundColor(WhiskerStyles.textColor)
                        .padding(.top, 30)
                        .padding(.bottom, 5)
                    
                    Text("Cooking has never been more enjoyable.")
                        .font(WhiskerStyles.Fonts.bodyLight(size: 18))
                        .foregroundColor(WhiskerStyles.textColor)
                        
                    
                    Text("Start your journey with us today.")
                        .font(WhiskerStyles.Fonts.bodyLight(size: 18))
                        .foregroundColor(WhiskerStyles.textColor)
                }
                .padding(.bottom, 10)
                
                // Email field
                TextField("Email", text: $email)
                    .whiskerTextField()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                // Password fields
                PasswordField(
                    password: $password,
                    showPassword: $showPasswords,
                    placeholder: "Password"
                )
                
                PasswordField(
                    password: $confirmPassword,
                    showPassword: $showPasswords,
                    placeholder: "Confirm Password"
                )
                
                // Remember me toggle
                RememberMeToggle(isChecked: $rememberMe)
                
                // Sign Up button
                Button(action: signUp) {
                    Text("Sign Up")
                }
                .primaryButton()
                .padding(.horizontal)
                
                // Social Login Buttons
                SocialLoginButtons(
                    onGoogleTap: signInWithGoogle,
                    onFacebookTap: signInWithFacebook
                )
                
                // Login link
                HStack {
                    Text("Have an account?")
                        .foregroundColor(WhiskerStyles.textColor)
                        .font(WhiskerStyles.Fonts.bodyLight)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Login")
                            .font(WhiskerStyles.Fonts.bodyLight)
                            .foregroundColor(WhiskerStyles.textColor)
                            .underline()
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .background(WhiskerStyles.backgroundColor)
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Error", message: "Email and password cannot be empty")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords don't match")
            return
        }
        
        // Create user with Firebase using authentication manager
        AuthenticationManager.shared.signUp(email: email, password: password) { result in
            switch result {
            case .success:
                print("User created successfully")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                showAlert(title: "Sign Up Failed", message: error.localizedDescription)
            }
        }
    }
    
    // Google Sign-In
    func signInWithGoogle() {
        let rootVC = UIApplication.getRootViewController()
        
        authManager.signInWithGoogle(presenting: rootVC) { result in
            switch result {
            case .success:
                print("Google user signed up successfully")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                showAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
            }
        }
    }
    
    // Facebook Login
    func signInWithFacebook() {
        authManager.signInWithFacebook { result in
            switch result {
            case .success:
                print("Facebook user signed up successfully")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                showAlert(title: "Facebook Login Failed", message: error.localizedDescription)
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// Extension to create Color from hex code
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
