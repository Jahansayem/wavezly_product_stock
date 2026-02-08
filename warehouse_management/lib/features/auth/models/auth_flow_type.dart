/// Authentication flow types for routing and screen behavior
enum AppAuthFlowType {
  /// New user signup flow: OTP → Business Info → PIN Setup → Business Type → Main
  signup,

  /// Existing user login flow: OTP → PIN Verification → Main
  login,

  /// Forgot PIN recovery flow: OTP → PIN Setup (reset) → Main
  forgotPin,
}
