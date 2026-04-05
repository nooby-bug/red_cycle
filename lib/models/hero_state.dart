class HeroState {
  final String primaryText;
  final String secondaryText;
  final String infoText;
  final bool showLogButton;

  const HeroState({
    required this.primaryText,
    required this.secondaryText,
    required this.infoText,
    required this.showLogButton,
  });

  // Implemented copyWith and equality for production-ready testability
  HeroState copyWith({
    String? primaryText,
    String? secondaryText,
    String? infoText,
    bool? showLogButton,
  }) {
    return HeroState(
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      infoText: infoText ?? this.infoText,
      showLogButton: showLogButton ?? this.showLogButton,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is HeroState &&
              runtimeType == other.runtimeType &&
              primaryText == other.primaryText &&
              secondaryText == other.secondaryText &&
              infoText == other.infoText &&
              showLogButton == other.showLogButton;

  @override
  int get hashCode =>
      primaryText.hashCode ^
      secondaryText.hashCode ^
      infoText.hashCode ^
      showLogButton.hashCode;
}