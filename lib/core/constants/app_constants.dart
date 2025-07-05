class AppConstants {
  // App Information
  static const String appName = 'Artifact Review Portal';
  static const String appVersion = '1.0.0';
  
  // Grid Configuration
  static const int gridCrossAxisCount = 4;
  static const double gridChildAspectRatio = 0.5;
  static const double gridSpacing = 32.0;
  static const double gridPadding = 16.0;
  
  // Animation Durations
  static const Duration cardExpandDuration = Duration(milliseconds: 300);
  static const Duration cardShrinkDuration = Duration(milliseconds: 200);
  static const Duration fadeDuration = Duration(milliseconds: 250);
  
  // Drawing Configuration
  static const double strokeWidth = 3.0;
  static const double eraserWidth = 20.0;
  
  // Storage Keys
  static const String reviewsBoxName = 'artifact_reviews';
  static const String artifactsBoxName = 'artifacts';
  
  // Sample Artifacts (for demo purposes)
  static const List<String> sampleArtifactImages = [
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
  ];
  
  static const List<String> sampleArtifactDocuments = [
    'assets/documents/pdf1.pdf',
    'assets/documents/pdf2.pdf',
  ];
  
  static const List<String> sampleArtifactNames = [
    'Project Overview',
    'Design Mockup',
    'Technical Specification',
    'User Interface',
    'Architecture Diagram',
    'Data Flow Chart',
    'System Integration',
    'Performance Metrics',
    'Security Analysis',
    'Deployment Guide',
  ];
} 